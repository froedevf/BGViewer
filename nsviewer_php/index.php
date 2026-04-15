<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NSViewer — CGM Dashboard</title>
<link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@300;400;500;600;700&family=Share+Tech+Mono&display=swap" rel="stylesheet">
<style>
  :root {
    --bg:        #080c10;
    --panel:     #0d1219;
    --border:    #1a2535;
    --muted:     #2a3a50;
    --text-dim:  #4a6070;
    --text-mid:  #8aa0b0;
    --text:      #c8dae8;
    --green:     #00c853;
    --yellow:    #ffd600;
    --orange:    #ff6b00;
    --red:       #ff2d2d;
    --gray:      #444c58;
    --blue:      #1976d2;
    --accent:    #00e5ff;
    --font-main: 'Rajdhani', sans-serif;
    --font-mono: 'Share Tech Mono', monospace;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: var(--bg);
    color: var(--text);
    font-family: var(--font-main);
    min-height: 100vh;
    overflow-x: hidden;
  }

  /* ── DISCLAIMER ── */
  #disclaimer {
    position: fixed; inset: 0;
    background: var(--bg);
    display: flex; align-items: center; justify-content: center;
    z-index: 100;
    flex-direction: column;
    gap: 28px;
    padding: 40px;
  }
  #disclaimer h1 {
    font-size: 2.4rem; font-weight: 700; letter-spacing: .12em;
    color: var(--accent); text-transform: uppercase;
  }
  .disc-box {
    max-width: 680px; width: 100%;
    background: var(--panel);
    border: 1px solid var(--border);
    border-left: 3px solid var(--orange);
    padding: 28px 32px;
    line-height: 1.75;
    font-size: 1rem; color: var(--text-mid);
  }
  .disc-box strong { color: var(--text); }
  #disclaimer button {
    background: var(--accent);
    color: #000; border: none;
    padding: 14px 52px;
    font-family: var(--font-main); font-size: 1.1rem; font-weight: 700;
    letter-spacing: .12em; text-transform: uppercase;
    cursor: pointer; transition: opacity .2s;
  }
  #disclaimer button:hover { opacity: .85; }

  /* ── HEADER ── */
  header {
    display: flex; align-items: center; justify-content: space-between;
    padding: 14px 28px;
    border-bottom: 1px solid var(--border);
    background: var(--panel);
  }
  .logo {
    font-size: 1.55rem; font-weight: 700; letter-spacing: .16em;
    color: var(--accent); text-transform: uppercase;
  }
  .logo span { color: var(--text-mid); }
  #clock {
    font-family: var(--font-mono);
    font-size: 1.25rem; color: var(--text-mid);
  }
  #statusBar {
    font-size: 1rem; color: var(--text-dim);
    letter-spacing: .06em;
  }
  header nav {
    display: flex; gap: 12px; align-items: center;
  }
  .hdr-btn {
    background: transparent;
    border: 1px solid var(--muted);
    color: var(--text-mid);
    padding: 7px 18px;
    font-family: var(--font-main); font-size: 1rem; font-weight: 600;
    letter-spacing: .1em; text-transform: uppercase;
    cursor: pointer; transition: all .15s;
  }
  .hdr-btn:hover { border-color: var(--accent); color: var(--accent); }

  /* ── MAIN DASHBOARD ── */
  #main {
    padding: 24px 28px;
    display: none;
  }

  #cards {
    display: grid;
    gap: 18px;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  }

  /* ── CARD ── */
  .card {
    background: var(--panel);
    border: 1px solid var(--border);
    position: relative;
    overflow: hidden;
    transition: border-color .3s;
  }
  .card-accent {
    position: absolute; top: 0; left: 0; right: 0;
    height: 3px;
    background: var(--gray);
    transition: background .4s;
  }
  .card-body { padding: 20px 22px 16px; }

  .card-name {
    font-size: 1.6rem; font-weight: 700; letter-spacing: .18em;
    text-transform: uppercase; color: var(--gray);
    margin-bottom: 4px;
    transition: color .4s;
  }
  .card-sgv {
    font-size: 5.6rem; font-weight: 700; line-height: 1;
    font-family: var(--font-mono);
    color: var(--gray);
    transition: color .4s;
  }
  .card-unit {
    font-size: .95rem; color: var(--text-dim);
    letter-spacing: .1em; margin-top: 4px;
  }

  .card-mid {
    display: flex; align-items: center; gap: 14px;
    margin: 10px 0;
  }
  .arrow-wrap { font-size: 2.6rem; line-height: 1; transition: color .4s; }

  .card-meta { display: flex; flex-direction: column; gap: 3px; }
  .card-range {
    font-size: 1.05rem; font-weight: 600; letter-spacing: .1em;
    color: var(--gray); transition: color .4s; text-transform: uppercase;
  }
  .card-delta {
    font-size: .96rem; color: var(--text-dim);
    font-family: var(--font-mono);
  }
  .card-age {
    font-size: .92rem; color: var(--text-dim);
    letter-spacing: .05em;
  }

  /* ── GRAPH ── */
  .graph-wrap {
    margin-top: 12px;
    position: relative;
    height: 64px;
    background: #0a0f16;
    border-top: 1px solid var(--border);
  }
  .graph-wrap canvas { width: 100%; height: 64px; display: block; }

  /* ── NO DATA / LOADING ── */
  #noData {
    display: none;
    flex-direction: column; align-items: center; justify-content: center;
    height: 260px; gap: 18px;
  }
  #noData p {
    color: var(--text-dim); font-size: 1rem; letter-spacing: .08em;
  }

  /* ── SETTINGS MODAL ── */
  #settingsModal {
    display: none;
    position: fixed; inset: 0;
    background: rgba(0,0,0,.78);
    z-index: 50;
    align-items: center; justify-content: center;
    padding: 24px;
  }
  #settingsModal.open { display: flex; }

  .modal-box {
    background: var(--panel);
    border: 1px solid var(--border);
    width: 100%; max-width: 680px;
    max-height: 90vh; overflow-y: auto;
  }
  .modal-header {
    display: flex; align-items: center; justify-content: space-between;
    padding: 18px 24px;
    border-bottom: 1px solid var(--border);
  }
  .modal-header h2 {
    font-size: 1.05rem; font-weight: 700; letter-spacing: .16em; text-transform: uppercase;
    color: var(--accent);
  }
  .modal-close {
    background: none; border: none;
    color: var(--text-dim); font-size: 1.4rem; cursor: pointer; line-height: 1;
    transition: color .15s;
  }
  .modal-close:hover { color: var(--text); }

  /* Account rows */
  .acct-list { padding: 8px 0; }
  .acct-row {
    padding: 14px 24px;
    border-bottom: 1px solid var(--border);
    display: grid;
    grid-template-columns: 24px 1fr auto;
    gap: 14px; align-items: center;
    cursor: pointer;
    transition: background .15s;
  }
  .acct-row:hover { background: #111820; }
  .acct-num {
    font-family: var(--font-mono); font-size: .8rem; color: var(--text-dim);
  }
  .acct-info { }
  .acct-info-name {
    font-size: .95rem; font-weight: 600; color: var(--text);
  }
  .acct-info-sub {
    font-size: .75rem; color: var(--text-dim); margin-top: 2px;
    font-family: var(--font-mono);
  }
  .acct-edit-btn {
    background: transparent; border: 1px solid var(--muted);
    color: var(--text-mid); padding: 5px 14px;
    font-family: var(--font-main); font-size: .78rem; font-weight: 600;
    letter-spacing: .08em; text-transform: uppercase;
    cursor: pointer; transition: all .15s;
  }
  .acct-edit-btn:hover { border-color: var(--accent); color: var(--accent); }

  /* Edit panel */
  #editPanel {
    padding: 20px 24px;
    border-top: 1px solid var(--border);
    display: none;
  }
  #editPanel.open { display: block; }
  .edit-title {
    font-size: .8rem; font-weight: 700; letter-spacing: .14em;
    text-transform: uppercase; color: var(--accent);
    margin-bottom: 16px;
  }

  .field-row {
    display: flex; flex-direction: column; gap: 5px;
    margin-bottom: 14px;
  }
  .field-row label {
    font-size: .72rem; font-weight: 600; letter-spacing: .12em;
    text-transform: uppercase; color: var(--text-dim);
  }
  .field-row input, .field-row select {
    background: #111820;
    border: 1px solid var(--muted);
    color: var(--text);
    padding: 9px 12px;
    font-family: var(--font-mono); font-size: .88rem;
    outline: none; width: 100%;
    transition: border-color .15s;
  }
  .field-row input:focus, .field-row select:focus {
    border-color: var(--accent);
  }
  .field-row select option { background: #111820; }

  /* Source toggle */
  .src-toggle {
    display: flex; gap: 0;
  }
  .src-btn {
    flex: 1;
    background: transparent; border: 1px solid var(--muted);
    color: var(--text-dim);
    padding: 9px 0;
    font-family: var(--font-main); font-size: .82rem; font-weight: 600;
    letter-spacing: .1em; text-transform: uppercase;
    cursor: pointer; transition: all .15s;
  }
  .src-btn + .src-btn { border-left: none; }
  .src-btn.active {
    background: var(--blue); border-color: var(--blue); color: #fff;
  }

  .edit-actions {
    display: flex; gap: 10px; margin-top: 20px;
  }
  .btn-save {
    background: var(--accent); color: #000;
    border: none; padding: 10px 28px;
    font-family: var(--font-main); font-size: .88rem; font-weight: 700;
    letter-spacing: .1em; text-transform: uppercase;
    cursor: pointer; transition: opacity .15s;
  }
  .btn-save:hover { opacity: .85; }
  .btn-cancel {
    background: transparent; border: 1px solid var(--muted);
    color: var(--text-mid);
    padding: 10px 22px;
    font-family: var(--font-main); font-size: .88rem; font-weight: 600;
    letter-spacing: .1em; text-transform: uppercase;
    cursor: pointer; transition: all .15s;
  }
  .btn-cancel:hover { border-color: var(--text-mid); }

  .save-msg {
    font-size: .82rem; color: var(--green);
    padding: 10px 24px;
    display: none;
  }

  /* ── REFRESH BAR ── */
  #refreshBar {
    position: fixed; bottom: 0; left: 0; right: 0;
    height: 2px; background: var(--muted); z-index: 20;
  }
  #refreshProgress {
    height: 100%; background: var(--accent);
    transition: width .9s linear;
    width: 100%;
  }

  /* Responsive */
  @media(max-width:600px) {
    .card-sgv { font-size: 4.2rem; }
    .card-name { font-size: 1rem; }
    header { flex-wrap: wrap; gap: 8px; }
  }
</style>
</head>
<body>

<!-- DISCLAIMER -->
<div id="disclaimer">
  <h1>⚠ NS<span>Viewer</span></h1>
  <div class="disc-box">
    <strong>NOT FOR MEDICAL USE.</strong><br><br>
    This application is an <strong>unofficial, independent viewer</strong> for Nightscout CGM data and Dexcom Share. It is not approved by the FDA or any regulatory authority and is <strong>not intended to be used for medical decisions, treatment, or diagnosis.</strong><br><br>
    Always rely on your <strong>approved glucose meter and CGM device</strong> for medical decisions. Consult your healthcare provider before making any changes to your diabetes management.
  </div>
  <button id="discAccept">I Understand — Continue</button>
</div>

<!-- HEADER -->
<header id="appHeader" style="display:none">
  <div class="logo">NS<span>Viewer</span></div>
  <div id="statusBar">—</div>
  <div id="clock">—</div>
  <nav>
    <button class="hdr-btn" id="refreshNow">↻ Refresh</button>
    <button class="hdr-btn" id="openSettings">⚙ Settings</button>
  </nav>
</header>

<!-- MAIN -->
<div id="main">
  <div id="noData">
    <p>No accounts configured.</p>
    <button class="hdr-btn" id="openSettingsEmpty">⚙ Open Settings</button>
  </div>
  <div id="cards"></div>
</div>

<!-- SETTINGS MODAL -->
<div id="settingsModal">
  <div class="modal-box">
    <div class="modal-header">
      <h2>Configure Accounts</h2>
      <button class="modal-close" id="closeSettings">✕</button>
    </div>
    <div class="acct-list" id="acctList"></div>
    <div id="editPanel">
      <div class="edit-title" id="editTitle">Editing Account 1</div>

      <div class="field-row">
        <label>Display Name</label>
        <input type="text" id="fName" placeholder="e.g. Dad" autocomplete="off">
      </div>
      <div class="field-row">
        <label>Data Source</label>
        <div class="src-toggle">
          <button class="src-btn active" id="srcNS" onclick="setSrc('ns')">Nightscout</button>
          <button class="src-btn"        id="srcDX" onclick="setSrc('dx')">Dexcom Share</button>
        </div>
      </div>

      <!-- NS fields -->
      <div id="nsFields">
        <div class="field-row">
          <label>Nightscout URL</label>
          <input type="text" id="fUrl" placeholder="https://your-site.herokuapp.com" autocomplete="off">
        </div>
      </div>

      <!-- Dexcom fields -->
      <div id="dxFields" style="display:none">
        <div class="field-row">
          <label>Dexcom Username</label>
          <input type="text" id="fUser" placeholder="dexcom account email" autocomplete="off">
        </div>
        <div class="field-row">
          <label>Dexcom Password</label>
          <input type="password" id="fPass" placeholder="••••••••" autocomplete="new-password">
        </div>
        <div class="field-row">
          <label>Region</label>
          <select id="fRegion">
            <option value="us">United States</option>
            <option value="ous">Outside US</option>
            <option value="jp">Japan</option>
          </select>
        </div>
      </div>

      <div class="edit-actions">
        <button class="btn-save" id="saveAccount">Save Account</button>
        <button class="btn-cancel" id="cancelEdit">Cancel</button>
        <button class="btn-cancel" id="clearAccount" style="margin-left:auto;color:var(--orange);border-color:var(--orange)">Clear</button>
      </div>
    </div>
    <div class="save-msg" id="saveMsg">✓ Saved successfully</div>
  </div>
</div>

<!-- REFRESH BAR -->
<div id="refreshBar"><div id="refreshProgress"></div></div>

<script>
// ─────────────────────────────────────────────
//  STORAGE  (server-side via api.php)
// ─────────────────────────────────────────────
// TTL mirrors api.php cacheTtl(): 15s per active Dexcom account, min 15s
// The server enforces this — the browser just polls as fast as it wants
// and gets cached data back until the server decides to re-fetch.
function calcRefreshSec() {
  const dexCount = accounts.filter(a => isActive(a) && a.srcType === 'dx').length;
  if (dexCount === 0) return 15;
  return Math.max(15, dexCount * 15);
}

function defaultAccount(i) {
  return { name: `Account ${i+1}`, srcType: 'ns', url: '', dexUser: '', dexPass: '', dexRegion: 'us' };
}

async function loadAccountsFromServer() {
  try {
    const res  = await fetch('api.php?action=load');
    const data = await res.json();
    if (data.ok && Array.isArray(data.accounts))
      return data.accounts.map((a, i) => Object.assign(defaultAccount(i), a));
  } catch(e) { console.warn('Could not load accounts:', e); }
  return [0,1,2,3].map(defaultAccount);
}

async function saveAccountsToStorage(arr) {
  try {
    const res  = await fetch('api.php?action=save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ accounts: arr })
    });
    const data = await res.json();
    if (!data.ok) console.error('Save failed:', data.error);
    return data.ok;
  } catch(e) { console.error('Could not save accounts:', e); return false; }
}

// ─────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────
let accounts = [0,1,2,3].map(defaultAccount); // populated async in initApp()
let results  = [null, null, null, null];
let history  = [null, null, null, null];
// dexSessions and dexTicks managed server-side in api.php
let secsLeft = 0;
let refreshTimer = null;
let clockInterval = null;
let editingRow = -1;

function isActive(acct) {
  if (acct.srcType === 'dx') return acct.dexUser !== '' && acct.dexPass !== '';
  return acct.url !== '';
}

function activeCount() { return accounts.filter(isActive).length; }

// ─────────────────────────────────────────────
//  CLOCK
// ─────────────────────────────────────────────
function timeStr() {
  const d = new Date();
  let h = d.getHours(), m = d.getMinutes();
  const ampm = h >= 12 ? 'PM' : 'AM';
  h = h % 12 || 12;
  return `${h}:${m < 10 ? '0'+m : m} ${ampm}`;
}
function startClock() {
  document.getElementById('clock').textContent = timeStr();
  clockInterval = setInterval(() => {
    document.getElementById('clock').textContent = timeStr();
  }, 1000);
}

// ─────────────────────────────────────────────
//  REFRESH PROGRESS BAR
// ─────────────────────────────────────────────
function startRefreshBar() {
  const interval = calcRefreshSec();
  secsLeft = interval;
  updateBar(interval);
  clearInterval(refreshTimer);
  refreshTimer = setInterval(() => {
    secsLeft--;
    updateBar(calcRefreshSec());
    if (secsLeft <= 0) { clearInterval(refreshTimer); fetchAll(); }
  }, 1000);
}

function updateBar(total) {
  if (total === undefined) total = calcRefreshSec();
  const pct = (secsLeft / total) * 100;
  const bar = document.getElementById('refreshProgress');
  bar.style.transition = 'none';
  bar.style.width = pct + '%';
}

// ─────────────────────────────────────────────
//  SGV HELPERS
// ─────────────────────────────────────────────
function sgvColor(sgv) {
  if (sgv <= 0)   return 'var(--gray)';
  if (sgv < 55)   return 'var(--red)';
  if (sgv < 70)   return 'var(--orange)';
  if (sgv <= 180) return 'var(--green)';
  if (sgv <= 250) return 'var(--yellow)';
  return 'var(--red)';
}

function rangeStr(sgv) {
  if (sgv <= 0)   return '';
  if (sgv < 55)   return 'URGENT LOW';
  if (sgv < 70)   return 'LOW';
  if (sgv <= 180) return 'IN RANGE';
  if (sgv <= 250) return 'HIGH';
  return 'URGENT HIGH';
}

function arrowChar(dir) {
  const map = {
    DoubleUp: '⬆⬆', SingleUp: '↑', FortyFiveUp: '↗',
    Flat: '→',
    FortyFiveDown: '↘', SingleDown: '↓', DoubleDown: '⬇⬇',
    'None': '?', 'NOT COMPUTABLE': '?', 'RATE OUT OF RANGE': '⚡'
  };
  return map[dir] || '→';
}

function ageLabelStr(tsMs) {
  if (!tsMs) return '';
  const mins = Math.floor((Date.now() - tsMs) / 60000);
  if (mins < 1)  return 'just now';
  if (mins === 1) return '1 min ago';
  if (mins < 60) return `${mins} mins ago`;
  return 'over 1 hr ago';
}

// ─────────────────────────────────────────────
//  FETCH — via server proxy (api.php?action=data)
// ─────────────────────────────────────────────
// The server polls Dexcom/NS, caches results, and returns them here.
// Multiple devices hitting this endpoint get the same cached result —
// Dexcom is only called once per TTL cycle regardless of device count.

async function fetchAll() {
  document.getElementById('statusBar').textContent = 'refreshing…';
  try {
    const res  = await fetch('api.php?action=data');
    const data = await res.json();
    if (!data.ok) throw new Error('Server error');

    accounts.forEach((acct, i) => {
      if (!isActive(acct)) return;
      const entry = data.data[i];
      if (!entry) return;
      if (entry.error) {
        results[i] = { sgv: -1, direction: 'Unknown', date: 0, readings: [] };
        history[i] = [];
        renderCard(i, true);
      } else {
        results[i] = entry;
        history[i] = entry.readings || [];
        renderCard(i);
      }
    });

    const interval = data.ttl || calcRefreshSec();
    document.getElementById('statusBar').textContent =
      `updated ${timeStr()} · refreshing every ${interval}s`;
  } catch(e) {
    document.getElementById('statusBar').textContent = 'fetch failed';
    console.error('fetchAll error:', e);
  }
  startRefreshBar();
}

// ─────────────────────────────────────────────
//  RENDER CARDS
// ─────────────────────────────────────────────
function buildCards() {
  const container = document.getElementById('cards');
  const noData = document.getElementById('noData');
  container.innerHTML = '';

  const actives = accounts.filter(isActive);
  if (actives.length === 0) {
    noData.style.display = 'flex';
    return;
  }
  noData.style.display = 'none';

  accounts.forEach((acct, i) => {
    if (!isActive(acct)) return;
    const card = document.createElement('div');
    card.className = 'card';
    card.id = `card-${i}`;
    card.innerHTML = `
      <div class="card-accent" id="accent-${i}"></div>
      <div class="card-body">
        <div class="card-name" id="cname-${i}">${acct.name}</div>
        <div class="card-sgv"  id="csgv-${i}">---</div>
        <div class="card-unit">mg/dL</div>
        <div class="card-mid">
          <div class="arrow-wrap" id="carrow-${i}">→</div>
          <div class="card-meta">
            <div class="card-range" id="crange-${i}"></div>
            <div class="card-delta" id="cdelta-${i}"></div>
            <div class="card-age"   id="cage-${i}">loading…</div>
          </div>
        </div>
      </div>
      <div class="graph-wrap">
        <canvas id="cgraph-${i}" height="64"></canvas>
      </div>
    `;
    container.appendChild(card);
  });
}

function renderCard(i, isError = false) {
  const sgvEl    = document.getElementById(`csgv-${i}`);
  const accentEl = document.getElementById(`accent-${i}`);
  const arrowEl  = document.getElementById(`carrow-${i}`);
  const rangeEl  = document.getElementById(`crange-${i}`);
  const deltaEl  = document.getElementById(`cdelta-${i}`);
  const ageEl    = document.getElementById(`cage-${i}`);
  const nameEl   = document.getElementById(`cname-${i}`);

  if (!sgvEl) return; // card not rendered

  if (isError) {
    sgvEl.textContent  = '---';
    sgvEl.style.color  = 'var(--gray)';
    accentEl.style.background = 'var(--gray)';
    arrowEl.textContent = '?';
    arrowEl.style.color = 'var(--gray)';
    rangeEl.textContent = 'error';
    rangeEl.style.color = 'var(--gray)';
    if (nameEl) nameEl.style.color = 'var(--gray)';
    deltaEl.textContent = '';
    ageEl.textContent   = 'fetch failed';
    return;
  }

  const e = results[i];
  if (!e) return;

  const sgv   = e.sgv;
  const stale = e.date > 0 && (Date.now() - e.date) > 10 * 60 * 1000;
  const col   = stale ? 'var(--gray)' : sgvColor(sgv);

  sgvEl.textContent = sgv > 0 ? sgv : '---';
  sgvEl.style.color = col;
  accentEl.style.background = col;

  if (nameEl) nameEl.style.color = col;

  arrowEl.textContent = arrowChar(e.direction);
  arrowEl.style.color = col;

  rangeEl.textContent = stale ? 'STALE' : rangeStr(sgv);
  rangeEl.style.color = col;

  // Delta from history
  const hist = history[i] || [];
  if (hist.length >= 2) {
    const delt = hist[hist.length - 1] - hist[hist.length - 2];
    deltaEl.textContent = (delt > 0 ? '+' : '') + delt + ' mg/dL';
  } else {
    deltaEl.textContent = '';
  }

  ageEl.textContent = ageLabelStr(e.date);
  ageEl.style.color = stale ? 'var(--orange)' : 'var(--text-dim)';

  renderGraph(i);
}

// ─────────────────────────────────────────────
//  GRAPH
// ─────────────────────────────────────────────
function renderGraph(i) {
  const canvas = document.getElementById(`cgraph-${i}`);
  if (!canvas) return;
  const readings = history[i] || [];
  const ctx = canvas.getContext('2d');
  const W = canvas.offsetWidth || 300;
  const H = 64;
  canvas.width  = W;
  canvas.height = H;

  ctx.clearRect(0, 0, W, H);

  const MIN = 40, MAX = 300, RANGE = MAX - MIN;
  const HI = 180, LO = 70;

  // Threshold lines
  function yForVal(v) {
    return H - Math.round(((v - MIN) / RANGE) * H);
  }

  // Hi line
  ctx.strokeStyle = 'rgba(255,214,0,0.18)';
  ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(0, yForVal(HI)); ctx.lineTo(W, yForVal(HI)); ctx.stroke();
  // Lo line
  ctx.strokeStyle = 'rgba(255,107,0,0.18)';
  ctx.beginPath(); ctx.moveTo(0, yForVal(LO)); ctx.lineTo(W, yForVal(LO)); ctx.stroke();

  if (readings.length === 0) return;

  const count = Math.min(readings.length, 36);
  const slice = readings.slice(-count);
  const dotR  = 2.5;
  const step  = W / 36;

  slice.forEach((sgv, b) => {
    const x = Math.round((b + (36 - count)) * step + step / 2);
    const y = yForVal(Math.max(MIN, Math.min(MAX, sgv)));
    ctx.beginPath();
    ctx.arc(x, y, dotR, 0, Math.PI * 2);
    ctx.fillStyle = sgvColor(sgv);
    ctx.fill();
  });
}

// ─────────────────────────────────────────────
//  SETTINGS UI
// ─────────────────────────────────────────────
function openSettings() {
  renderAccountList();
  closeEditPanel();
  document.getElementById('settingsModal').classList.add('open');
}
function closeSettings() {
  document.getElementById('settingsModal').classList.remove('open');
}

function renderAccountList() {
  const list = document.getElementById('acctList');
  list.innerHTML = '';
  accounts.forEach((acct, i) => {
    const row = document.createElement('div');
    row.className = 'acct-row';
    const src = acct.srcType === 'dx' ? 'Dexcom' : 'Nightscout';
    const sub = acct.srcType === 'dx' ? (acct.dexUser || '—') : (acct.url || '—');
    row.innerHTML = `
      <div class="acct-num">${i+1}</div>
      <div class="acct-info">
        <div class="acct-info-name">${acct.name}</div>
        <div class="acct-info-sub">${src} · ${sub.slice(0,50)}${sub.length>50?'…':''}</div>
      </div>
      <button class="acct-edit-btn" data-i="${i}">Edit</button>
    `;
    row.querySelector('button').addEventListener('click', () => openEditPanel(i));
    list.appendChild(row);
  });
}

function openEditPanel(i) {
  editingRow = i;
  const acct = accounts[i];
  document.getElementById('editTitle').textContent = `Editing Account ${i+1}`;
  document.getElementById('fName').value = acct.name;
  document.getElementById('fUrl').value  = acct.url || '';
  document.getElementById('fUser').value = acct.dexUser || '';
  document.getElementById('fPass').value = acct.dexPass || '';
  document.getElementById('fRegion').value = acct.dexRegion || 'us';
  setSrc(acct.srcType, false);
  document.getElementById('editPanel').classList.add('open');
  document.getElementById('saveMsg').style.display = 'none';
  document.getElementById('editPanel').scrollIntoView({ behavior: 'smooth' });
}

function closeEditPanel() {
  editingRow = -1;
  document.getElementById('editPanel').classList.remove('open');
}

function setSrc(src, updateAccount = true) {
  document.getElementById('srcNS').classList.toggle('active', src === 'ns');
  document.getElementById('srcDX').classList.toggle('active', src === 'dx');
  document.getElementById('nsFields').style.display = src === 'ns' ? '' : 'none';
  document.getElementById('dxFields').style.display = src === 'dx' ? '' : 'none';
  if (updateAccount && editingRow >= 0) {
    accounts[editingRow].srcType = src;
  }
}

document.getElementById('saveAccount').addEventListener('click', async () => {
  if (editingRow < 0) return;
  const acct = accounts[editingRow];
  acct.name    = document.getElementById('fName').value.trim() || `Account ${editingRow+1}`;
  acct.url     = document.getElementById('fUrl').value.trim().replace(/\/$/, '');
  acct.dexUser = document.getElementById('fUser').value.trim();
  acct.dexPass = document.getElementById('fPass').value;
  acct.dexRegion = document.getElementById('fRegion').value;
  // normalize NS url
  if (acct.srcType === 'ns' && acct.url && !acct.url.startsWith('http')) {
    acct.url = 'https://' + acct.url;
  }
  const saved = await saveAccountsToStorage(accounts);
  renderAccountList();
  closeEditPanel();
  const msg = document.getElementById('saveMsg');
  msg.textContent  = saved ? '✓ Saved to server' : '⚠ Save failed — check server permissions';
  msg.style.color  = saved ? 'var(--green)' : 'var(--orange)';
  msg.style.display = 'block';
  setTimeout(() => { msg.style.display = 'none'; }, 3000);
  clearInterval(refreshTimer);
  results  = [null,null,null,null];
  history  = [null,null,null,null];
  buildCards();
  if (activeCount() > 0) fetchAll();
});

document.getElementById('clearAccount').addEventListener('click', async () => {
  if (editingRow < 0) return;
  accounts[editingRow] = defaultAccount(editingRow);
  await saveAccountsToStorage(accounts);
  renderAccountList();
  closeEditPanel();
  clearInterval(refreshTimer);
  results  = [null,null,null,null];
  history  = [null,null,null,null];
  buildCards();
  if (activeCount() > 0) fetchAll();
});

document.getElementById('cancelEdit').addEventListener('click', closeEditPanel);
document.getElementById('closeSettings').addEventListener('click', closeSettings);
document.getElementById('openSettings').addEventListener('click', openSettings);
document.getElementById('openSettingsEmpty')?.addEventListener('click', openSettings);
document.getElementById('refreshNow').addEventListener('click', () => {
  clearInterval(refreshTimer);
  fetchAll();
});

// ─────────────────────────────────────────────
//  AGE LABEL LIVE UPDATE
// ─────────────────────────────────────────────
setInterval(() => {
  accounts.forEach((acct, i) => {
    if (!isActive(acct) || !results[i]) return;
    const e = results[i];
    if (!e || e.date <= 0) return;
    const ageEl = document.getElementById(`cage-${i}`);
    if (ageEl) ageEl.textContent = ageLabelStr(e.date);
  });
}, 10000);

// ─────────────────────────────────────────────
//  DISCLAIMER ACCEPT
// ─────────────────────────────────────────────
document.getElementById('discAccept').addEventListener('click', async () => {
  document.getElementById('disclaimer').style.display = 'none';
  document.getElementById('appHeader').style.display  = '';
  document.getElementById('main').style.display       = 'block';
  startClock();
  accounts = await loadAccountsFromServer();
  buildCards();
  if (activeCount() === 0) {
    openSettings();
  } else {
    fetchAll();
  }
});

// Handle resize
window.addEventListener('resize', () => {
  accounts.forEach((_, i) => { if (history[i]) renderGraph(i); });
});
</script>
</body>
</html>
