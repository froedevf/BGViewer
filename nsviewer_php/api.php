<?php
// api.php — NSViewer backend
// Handles: account storage, Dexcom proxy, server-side cache
// All Dexcom API calls are made here (server-to-Dexcom), never browser-to-Dexcom.
// Results are cached in cache.json so N devices share one Dexcom poll per cycle.

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

define('ACCOUNTS_FILE', __DIR__ . '/accounts.json');
define('CACHE_FILE',    __DIR__ . '/cache.json');
define('SESSION_FILE',  __DIR__ . '/sessions.json');

function dexBase($region) {
    if ($region === 'ous') return 'https://shareous1.dexcom.com/ShareWebServices/Services';
    if ($region === 'jp')  return 'https://share.dexcom.jp/ShareWebServices/Services';
    return 'https://share2.dexcom.com/ShareWebServices/Services';
}
function dexAppId($region) {
    return ($region === 'jp')
        ? 'd8665ade-9673-4e27-9ff6-92db4ce13d13'
        : 'd89443d2-327c-4a6f-89e5-496bbb0317db';
}

function curlPost($url, $payload) {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode($payload),
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json', 'Accept: application/json'],
        CURLOPT_TIMEOUT        => 15,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);
    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err  = curl_error($ch);
    curl_close($ch);
    return ['body' => $body, 'code' => $code, 'err' => $err];
}

function curlGet($url) {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => ['Accept: application/json'],
        CURLOPT_TIMEOUT        => 15,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);
    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err  = curl_error($ch);
    curl_close($ch);
    return ['body' => $body, 'code' => $code, 'err' => $err];
}

function readJson($file, $default = []) {
    if (!file_exists($file)) return $default;
    $data = json_decode(file_get_contents($file), true);
    return is_array($data) ? $data : $default;
}

function writeJson($file, $data) {
    $tmp = $file . '.tmp';
    file_put_contents($tmp, json_encode($data, JSON_PRETTY_PRINT));
    rename($tmp, $file);
}

function defaultAccount($i) {
    return ['name' => "Account ".($i+1), 'srcType' => 'ns',
            'url' => '', 'dexUser' => '', 'dexPass' => '', 'dexRegion' => 'us'];
}

function loadAccounts() {
    $arr = readJson(ACCOUNTS_FILE, []);
    return array_map(function($a, $i) {
        return array_merge(defaultAccount($i), is_array($a) ? $a : []);
    }, array_slice(array_pad($arr, 4, []), 0, 4), [0,1,2,3]);
}

function saveAccounts($arr) {
    $accounts = array_map(function($a, $i) {
        return array_merge(defaultAccount($i), is_array($a) ? $a : []);
    }, array_slice(array_pad($arr, 4, []), 0, 4), [0,1,2,3]);
    writeJson(ACCOUNTS_FILE, $accounts);
}

// Cache TTL mirrors JS calcRefreshSec(): 15s per active Dexcom account, min 15s
function cacheTtl($accounts) {
    $dexCount = 0;
    foreach ($accounts as $a) {
        if (($a['srcType'] ?? '') === 'dx' && !empty($a['dexUser']) && !empty($a['dexPass']))
            $dexCount++;
    }
    if ($dexCount === 0) return 15;
    return max(15, $dexCount * 15);
}

function dexLogin($acct) {
    $base  = dexBase($acct['dexRegion']);
    $appId = dexAppId($acct['dexRegion']);
    $r = curlPost("$base/General/LoginPublisherAccountByName", [
        'accountName'   => $acct['dexUser'],
        'password'      => $acct['dexPass'],
        'applicationId' => $appId,
    ]);
    if ($r['code'] !== 200 || empty($r['body'])) return null;
    return trim($r['body'], '"');
}

function dexFetch($acct, $sessionId) {
    $base  = dexBase($acct['dexRegion']);
    $curR  = curlGet("$base/Publisher/ReadPublisherLatestGlucoseValues?sessionId=$sessionId&minutes=1440&maxCount=1");
    $histR = curlGet("$base/Publisher/ReadPublisherLatestGlucoseValues?sessionId=$sessionId&minutes=180&maxCount=36");

    if ($curR['code'] === 429 || $histR['code'] === 429)
        return ['error' => 'rate_limited', 'code' => 429];
    if ($curR['code'] !== 200)
        return ['error' => 'fetch_failed', 'code' => $curR['code']];

    $cur  = json_decode($curR['body'],  true) ?? [];
    $hist = json_decode($histR['body'], true) ?? [];
    $latest = $cur[0] ?? null;

    $trendMap = ['','DoubleUp','SingleUp','FortyFiveUp','Flat',
                 'FortyFiveDown','SingleDown','DoubleDown','None',
                 'NOT COMPUTABLE','RATE OUT OF RANGE'];
    $sgv  = $latest['Value']  ?? -1;
    $dir  = $trendMap[intval($latest['Trend'] ?? 0)] ?? 'Flat';
    $date = 0;
    if (!empty($latest['WT'])) {
        preg_match('/\((\d+)/', $latest['WT'], $m);
        $date = isset($m[1]) ? intval($m[1]) : 0;
    }
    $readings = [];
    foreach (array_reverse($hist) as $e) {
        if (!empty($e['Value']) && $e['Value'] > 0) $readings[] = $e['Value'];
    }
    return ['sgv' => $sgv, 'direction' => $dir, 'date' => $date, 'readings' => $readings];
}

function nsFetch($acct) {
    $base  = rtrim($acct['url'], '/');
    $curR  = curlGet("$base/api/v1/entries/current.json");
    $histR = curlGet("$base/api/v1/entries.json?count=36");

    if ($curR['code'] !== 200) return ['error' => 'fetch_failed', 'code' => $curR['code']];

    $cur   = json_decode($curR['body'], true) ?? [];
    $hist  = json_decode($histR['body'], true) ?? [];
    $entry = is_array($cur) ? ($cur[0] ?? $cur) : $cur;

    $readings = [];
    foreach (array_reverse($hist) as $e) {
        if (!empty($e['sgv']) && $e['sgv'] > 0) $readings[] = $e['sgv'];
    }
    return [
        'sgv'       => $entry['sgv']       ?? -1,
        'direction' => $entry['direction'] ?? 'Flat',
        'date'      => $entry['date']      ?? 0,
        'readings'  => $readings,
    ];
}

function pollAll() {
    $accounts = loadAccounts();
    $sessions = loadSessions();
    $cache    = loadCache();
    $ttl      = cacheTtl($accounts);
    $now      = time();
    $changed  = false;

    foreach ($accounts as $i => $acct) {
        $isNS   = ($acct['srcType'] === 'ns');
        $isDX   = ($acct['srcType'] === 'dx');
        $active = $isNS ? !empty($acct['url'])
                        : (!empty($acct['dexUser']) && !empty($acct['dexPass']));
        if (!$active) continue;

        // Still fresh? Skip poll
        $cached = $cache[$i] ?? null;
        if ($cached && !isset($cached['error']) &&
            isset($cached['fetched_at']) && ($now - $cached['fetched_at']) < $ttl) {
            continue;
        }

        if ($isNS) {
            $result = nsFetch($acct);
        } else {
            $sessionId = $sessions[$i] ?? '';
            if (empty($sessionId)) {
                $sessionId = dexLogin($acct);
                if (!$sessionId) {
                    $cache[$i] = ['error' => 'login_failed', 'fetched_at' => $now];
                    $changed = true;
                    continue;
                }
                $sessions[$i] = $sessionId;
            }
            $result = dexFetch($acct, $sessionId);
            // Session expired — re-auth once
            if (isset($result['error']) && in_array($result['code'] ?? 0, [500, 401])) {
                $sessions[$i] = '';
                $sessionId = dexLogin($acct);
                if ($sessionId) {
                    $sessions[$i] = $sessionId;
                    $result = dexFetch($acct, $sessionId);
                }
            }
        }

        $result['fetched_at'] = $now;
        $cache[$i] = $result;
        $changed = true;
    }

    if ($changed) {
        saveCache($cache);
        saveSessions($sessions);
    }

    return ['ok' => true, 'data' => $cache, 'ttl' => $ttl];
}

function loadCache()    { return readJson(CACHE_FILE,   []); }
function loadSessions() { return readJson(SESSION_FILE, []); }
function saveCache($d)    { writeJson(CACHE_FILE,   $d); }
function saveSessions($d) { writeJson(SESSION_FILE, $d); }

// ── Routing ───────────────────────────────────────────────────────────────────

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

if ($method === 'GET'  && $action === 'load') {
    echo json_encode(['ok' => true, 'accounts' => loadAccounts()]);
    exit;
}

if ($method === 'POST' && $action === 'save') {
    $body = file_get_contents('php://input');
    $data = json_decode($body, true);
    if (!isset($data['accounts']) || !is_array($data['accounts'])) {
        http_response_code(400);
        echo json_encode(['ok' => false, 'error' => 'Invalid payload']);
        exit;
    }
    saveAccounts($data['accounts']);
    if (file_exists(CACHE_FILE))   unlink(CACHE_FILE);
    if (file_exists(SESSION_FILE)) unlink(SESSION_FILE);
    echo json_encode(['ok' => true]);
    exit;
}

if ($method === 'GET'  && $action === 'data') {
    echo json_encode(pollAll());
    exit;
}

http_response_code(400);
echo json_encode(['ok' => false, 'error' => 'Unknown request']);
