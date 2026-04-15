NSViewer — Web Dashboard (PHP edition)
=======================================

Files
-----
  index.php      — The dashboard (open this in your browser)
  api.php        — Backend: account storage, Dexcom proxy, result cache
  accounts.json  — Created automatically on first save
  cache.json     — Server-side glucose cache (auto-managed)
  sessions.json  — Dexcom session IDs (auto-managed)
  README.txt     — This file


Architecture
------------
All Dexcom API calls are made server-to-Dexcom inside api.php,
never browser-to-Dexcom. This means:

  - No CORS errors on any device (iOS, Android, desktop)
  - Results are cached in cache.json on the server
  - No matter how many devices are viewing the dashboard,
    Dexcom is only polled ONCE per refresh cycle
  - Cache TTL scales with account count to respect rate limits:
      1 Dexcom account  ->  15s
      2 Dexcom accounts ->  30s
      3 Dexcom accounts ->  45s
      4 Dexcom accounts ->  60s


Installation
------------
1. Upload all files to a folder on your PHP-capable web server
   (Apache/Nginx/LiteSpeed with PHP 7.4+ and cURL enabled).

2. Ensure the web server can write to the folder:

     chmod 755 /path/to/nsviewer/
     touch /path/to/nsviewer/accounts.json
     touch /path/to/nsviewer/cache.json
     touch /path/to/nsviewer/sessions.json
     chmod 644 /path/to/nsviewer/*.json

   Or simply make the folder writable and let api.php create
   the files on first use.

3. Open index.php in your browser, accept the disclaimer,
   then click Settings to add your accounts.

4. Every device that opens the same URL shares the same
   account config and cached glucose data automatically.


If index.php doesn't load by default
--------------------------------------
Add a .htaccess file with:
  DirectoryIndex index.php


Security note
-------------
accounts.json and sessions.json contain your Dexcom password
and session tokens in plain text. Protect the installation:

  AuthType Basic
  AuthName "NSViewer"
  AuthUserFile /path/to/.htpasswd
  Require valid-user

Generate a .htpasswd file with:
  htpasswd -c /path/to/.htpasswd yourusername


Troubleshooting
---------------
"Save failed — check server permissions"
  -> api.php cannot write to the folder.
     chmod 777 /path/to/nsviewer/ (or pre-create the .json files)

"fetch failed" on first load
  -> Check that PHP cURL is enabled on your server.
     Most shared hosts have it; some require enabling in php.ini:
       extension=curl

Blank page / PHP errors
  -> Requires PHP 7.4+. Enable error display temporarily:
       Add  php_flag display_errors on  to .htaccess
