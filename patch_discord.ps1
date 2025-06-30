# Requires -Version 5.0
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Check-Node {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host '[ERROR] Node.js is not installed. Please install Node.js from https://nodejs.org/' -ForegroundColor Red
        Pause
        return $false
    }
    return $true
}

function Check-Asar {
    if (-not (Get-Command asar -ErrorAction SilentlyContinue)) {
        Write-Host '[ERROR] asar is not installed globally. Please run: npm install -g asar' -ForegroundColor Red
        Pause
        return $false
    }
    return $true
}

function Get-DiscordInstallations {
    $results = @()
    $idx = 1
    $flavors = @(
        @{ Name = 'Discord (Stable)'; Path = "$env:LOCALAPPDATA\Discord" },
        @{ Name = 'Discord PTB'; Path = "$env:LOCALAPPDATA\DiscordPTB" },
        @{ Name = 'Discord Canary'; Path = "$env:LOCALAPPDATA\DiscordCanary" }
    )
    foreach ($flavor in $flavors) {
        $found = $false
        if (Test-Path $flavor.Path) {
            Get-ChildItem -Path $flavor.Path -Directory -Filter 'app-*' | ForEach-Object {
                $resPath = Join-Path $_.FullName 'resources'
                $asarPath = Join-Path $resPath 'app.asar'
                if (Test-Path $asarPath) {
                    $results += [PSCustomObject]@{
                        Index = $idx
                        Label = "$($flavor.Name) [$($_.Name)] [Installed] ($resPath)"
                        Path = $resPath
                        Installed = $true
                    }
                    $idx++
                    $found = $true
                }
            }
        }
        if (-not $found) {
            $results += [PSCustomObject]@{
                Index = $idx
                Label = "$($flavor.Name) [Not installed]"
                Path = 'NOT_INSTALLED'
                Installed = $false
            }
            $idx++
        }
    }
    $results += [PSCustomObject]@{
        Index = $idx
        Label = 'Enter custom location manually'
        Path = 'CUSTOM'
        Installed = $false
    }
    return $results
}

function Select-DiscordInstallation {
    $global:DISCORD_RESOURCES = $null
    while ($null -eq $global:DISCORD_RESOURCES) {
        $installs = Get-DiscordInstallations
        Write-Host 'Select which Discord installation to use:'
        foreach ($item in $installs) {
            Write-Host ("$($item.Index)) $($item.Label)")
        }
        $sel = Read-Host "Select an option [1-$($installs.Count)]"
        if ($sel -match '^[0-9]+$' -and $sel -ge 1 -and $sel -le $installs.Count) {
            $chosen = $installs[$sel-1]
            if ($chosen.Path -eq 'CUSTOM') {
                $userPath = Read-Host 'Enter the full path to the folder containing app.asar'
                if (Test-Path (Join-Path $userPath 'app.asar')) {
                    $global:DISCORD_RESOURCES = $userPath
                } else {
                    Write-Host '[ERROR] app.asar not found in that path. Try again.' -ForegroundColor Red
                }
            } elseif ($chosen.Path -eq 'NOT_INSTALLED') {
                Write-Host '[WARN] This installation is not present. Use a different option or enter a custom path.' -ForegroundColor Yellow
            } else {
                $global:DISCORD_RESOURCES = $chosen.Path
            }
        } else {
            Write-Host 'Invalid option!'
        }
    }
}

function Has-Backup {
    return Test-Path (Join-Path $global:DISCORD_RESOURCES 'app.asar.bak')
}

function Check-Patch {
    return Test-Path (Join-Path $global:DISCORD_RESOURCES 'patch.true')
}

function Backup-Asar {
    $asar = Join-Path $global:DISCORD_RESOURCES 'app.asar'
    $bak = Join-Path $global:DISCORD_RESOURCES 'app.asar.bak'
    if (-not (Test-Path $bak)) {
        Write-Host "[INFO] Creating backup: app.asar.bak"
        Copy-Item $asar $bak
    } else {
        Write-Host "[INFO] Backup already exists: app.asar.bak"
    }
}

function Remove-Unpacked {
    $unpacked = Join-Path $global:DISCORD_RESOURCES 'app-unpacked'
    if (Test-Path $unpacked) {
        Remove-Item $unpacked -Recurse -Force
    }
}

function Patch-Discord {
    if (-not (Check-Node)) { return }
    if (-not (Check-Asar)) { return }
    Backup-Asar
    Remove-Unpacked
    Push-Location $global:DISCORD_RESOURCES
    asar extract app.asar app-unpacked
    Remove-Item 'app-unpacked\app_bootstrap\hostUpdater.js' -Force -ErrorAction SilentlyContinue
    Write-PatchedHostUpdater 'app-unpacked\app_bootstrap\hostUpdater.js'
    Remove-Item 'app.asar' -Force
    asar pack app-unpacked app.asar
    Set-Content 'patch.true' ''
    Remove-Unpacked
    Pop-Location
    Write-Host '[OK] Patch applied successfully!'
    Pause
}

function Unpatch-Discord {
    if (-not (Check-Node)) { return }
    if (-not (Check-Asar)) { return }
    Backup-Asar
    Remove-Unpacked
    Push-Location $global:DISCORD_RESOURCES
    asar extract app.asar app-unpacked
    Remove-Item 'app-unpacked\app_bootstrap\hostUpdater.js' -Force -ErrorAction SilentlyContinue
    Write-OriginalHostUpdater 'app-unpacked\app_bootstrap\hostUpdater.js'
    Remove-Item 'app.asar' -Force
    asar pack app-unpacked app.asar
    Remove-Item 'patch.true' -Force -ErrorAction SilentlyContinue
    Remove-Unpacked
    Pop-Location
    Write-Host '[OK] Patch unapplied and original restored!'
    Pause
}

function Restore-Backup {
    $bak = Join-Path $global:DISCORD_RESOURCES 'app.asar.bak'
    $asar = Join-Path $global:DISCORD_RESOURCES 'app.asar'
    if (Test-Path $bak) {
        Copy-Item $bak $asar -Force
        Remove-Item (Join-Path $global:DISCORD_RESOURCES 'patch.true') -Force -ErrorAction SilentlyContinue
        Write-Host '[OK] Original restored from backup.'
    } else {
        Write-Host '[ERROR] No backup found to restore.' -ForegroundColor Red
    }
    Pause
}

function Write-PatchedHostUpdater($path) {
@'
"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var _electron = require("electron");
var _events = require("events");
var _request = _interopRequireDefault(require("./request"));
var squirrelUpdate = _interopRequireWildcard(require("./squirrelUpdate"));
function _getRequireWildcardCache(e) { if ("function" != typeof WeakMap) return null; var r = new WeakMap(), t = new WeakMap(); return (_getRequireWildcardCache = function (e) { return e ? t : r; })(e); }
function _interopRequireWildcard(e, r) { if (!r && e && e.__esModule) return e; if (null === e || "object" != typeof e && "function" != typeof e) return { default: e }; var t = _getRequireWildcardCache(r); if (t && t.has(e)) return t.get(e); var n = { __proto__: null }, a = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var u in e) if ("default" !== u && {}.hasOwnProperty.call(e, u)) { var i = a ? Object.getOwnPropertyDescriptor(e, u) : null; i && (i.get || i.set) ? Object.defineProperty(n, u, i) : n[u] = e[u]; } return n.default = e, t && t.set(e, n), n; }
function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
function versionParse(verString) {
  return verString.split('.').map(i => parseInt(i));
}
function versionNewer(verA, verB) {
  let i = 0;
  while (true) {
    const a = verA[i];
    const b = verB[i];
    i++;
    if (a === undefined) {
      return false;
    } else {
      if (b === undefined || a > b) {
        return true;
      }
      if (a < b) {
        return false;
      }
    }
  }
}
function versionEqual(verA, verB) {
  if (verA.length !== verB.length) {
    return false;
  }
  for (let i = 0; i < verA.length; ++i) {
    const a = verA[i];
    const b = verB[i];
    if (a !== b) {
      return false;
    }
  }
  return true;
}
class AutoUpdaterWin32 extends _events.EventEmitter {
  constructor() {
    super();
    this.updateUrl = null;
    this.updateVersion = null;
  }
  setFeedURL(updateUrl) {
    this.updateUrl = updateUrl;
  }
  quitAndInstall() {
    // Does nothing to prevent auto install
  }
  downloadAndInstallUpdate(callback) {
    // Calls callback directly as if finished
    callback();
  }
  checkForUpdates() {
    this.emit('checking-for-update');
    // Always says no update
    this.emit('update-not-available');
  }
}

class AutoUpdaterLinux extends _events.EventEmitter {
  constructor() {
    super();
    this.updateUrl = null;
  }
  setFeedURL(url) {
    this.updateUrl = url;
  }
  quitAndInstall() {
    // Just relaunches the app, installs nothing
    _electron.app.relaunch();
    _electron.app.quit();
  }
  async checkForUpdates() {
    this.emit('checking-for-update');
    // Always notifies no update available
    this.emit('update-not-available');
  }
}

let autoUpdater;
switch (process.platform) {
  case 'darwin':
    autoUpdater = require('electron').autoUpdater;
    break;
  case 'win32':
    autoUpdater = new AutoUpdaterWin32();
    break;
  case 'linux':
    autoUpdater = new AutoUpdaterLinux();
    break;
}

var _default = exports.default = autoUpdater;
module.exports = exports.default;
'@ | Set-Content -Path $path -Encoding UTF8
}

function Write-OriginalHostUpdater($path) {
@'
"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;
var _electron = require("electron");
var _events = require("events");
var _request = _interopRequireDefault(require("./request"));
var squirrelUpdate = _interopRequireWildcard(require("./squirrelUpdate"));
function _getRequireWildcardCache(e) { if ("function" != typeof WeakMap) return null; var r = new WeakMap(), t = new WeakMap(); return (_getRequireWildcardCache = function (e) { return e ? t : r; })(e); }
function _interopRequireWildcard(e, r) { if (!r && e && e.__esModule) return e; if (null === e || "object" != typeof e && "function" != typeof e) return { default: e }; var t = _getRequireWildcardCache(r); if (t && t.has(e)) return t.get(e); var n = { __proto__: null }, a = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var u in e) if ("default" !== u && {}.hasOwnProperty.call(e, u)) { var i = a ? Object.getOwnPropertyDescriptor(e, u) : null; i && (i.get || i.set) ? Object.defineProperty(n, u, i) : n[u] = e[u]; } return n.default = e, t && t.set(e, n), n; }
function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
function versionParse(verString) {
  return verString.split('.').map(i => parseInt(i));
}
function versionNewer(verA, verB) {
  let i = 0;
  while (true) {
    const a = verA[i];
    const b = verB[i];
    i++;
    if (a === undefined) {
      return false;
    } else {
      if (b === undefined || a > b) {
        return true;
      }
      if (a < b) {
        return false;
      }
    }
  }
}
function versionEqual(verA, verB) {
  if (verA.length !== verB.length) {
    return false;
  }
  for (let i = 0; i < verA.length; ++i) {
    const a = verA[i];
    const b = verB[i];
    if (a !== b) {
      return false;
    }
  }
  return true;
}
class AutoUpdaterWin32 extends _events.EventEmitter {
  constructor() {
    super();
    this.updateUrl = null;
    this.updateVersion = null;
  }
  setFeedURL(updateUrl) {
    this.updateUrl = updateUrl;
  }
  quitAndInstall() {
    if (squirrelUpdate.updateExistsSync()) {
      squirrelUpdate.restart(_electron.app, this.updateVersion ?? _electron.app.getVersion());
    } else {
      require('auto-updater').quitAndInstall();
    }
  }
  downloadAndInstallUpdate(callback) {
    if (this.updateUrl == null) {
      throw new Error('Update URL is not set');
    }
    void squirrelUpdate.spawnUpdateInstall(this.updateUrl, progress => {
      this.emit('update-progress', progress);
    }).catch(err => callback(err)).then(() => callback());
  }
  checkForUpdates() {
    if (this.updateUrl == null) {
      throw new Error('Update URL is not set');
    }
    this.emit('checking-for-update');
    if (!squirrelUpdate.updateExistsSync()) {
      this.emit('update-not-available');
      return;
    }
    squirrelUpdate.spawnUpdate(['--check', this.updateUrl], (error, stdout) => {
      if (error != null) {
        this.emit('error', error);
        return;
      }
      try {
        const json = stdout.trim().split('\n').pop();
        const releasesFound = JSON.parse(json).releasesToApply;
        if (releasesFound == null || releasesFound.length === 0) {
          this.emit('update-not-available');
          return;
        }
        const update = releasesFound.pop();
        this.emit('update-available');
        this.downloadAndInstallUpdate(error => {
          if (error != null) {
            this.emit('error', error);
            return;
          }
          this.updateVersion = update.version;
          this.emit('update-downloaded', {}, update.release, update.version, new Date(), this.updateUrl, this.quitAndInstall.bind(this));
        });
      } catch (error) {
        error.stdout = stdout;
        this.emit('error', error);
      }
    });
  }
}
class AutoUpdaterLinux extends _events.EventEmitter {
  constructor() {
    super();
    this.updateUrl = null;
  }
  setFeedURL(url) {
    this.updateUrl = url;
  }
  quitAndInstall() {
    _electron.app.relaunch();
    _electron.app.quit();
  }
  async checkForUpdates() {
    if (this.updateUrl == null) {
      throw new Error('Update URL is not set');
    }
    const currVersion = versionParse(_electron.app.getVersion());
    this.emit('checking-for-update');
    try {
      const response = await _request.default.get(this.updateUrl);
      if (response.statusCode === 204) {
        this.emit('update-not-available');
        return;
      }
      let latestVerStr = '';
      let latestVersion = [];
      try {
        var _response$body;
        const latestMetadata = JSON.parse(((_response$body = response.body) === null || _response$body === void 0 ? void 0 : _response$body.toString('utf-8')) ?? '');
        latestVerStr = latestMetadata.name;
        latestVersion = versionParse(latestVerStr);
      } catch (_) {}
      if (versionNewer(latestVersion, currVersion)) {
        console.log('[Updates] You are out of date!');
        this.emit('update-manually', latestVerStr);
      } else if (versionNewer(currVersion, latestVersion)) {
        console.log('[Updates] You are living in the future! Come back time traveller!');
        this.emit('update-manually', latestVerStr);
      } else if (versionEqual(latestVersion, currVersion)) {
        console.log('[Updates] You are up to date.');
        this.emit('update-not-available');
      } else {
        console.log('[Updates] You are in a very strange place.');
        this.emit('update-not-available');
      }
    } catch (err) {
      console.error('[Updates] Error fetching ' + this.updateUrl + ': ' + err.message);
      this.emit('error', err);
    }
  }
}
let autoUpdater;
switch (process.platform) {
  case 'darwin':
    autoUpdater = require('electron').autoUpdater;
    break;
  case 'win32':
    autoUpdater = new AutoUpdaterWin32();
    break;
  case 'linux':
    autoUpdater = new AutoUpdaterLinux();
    break;
}
var _default = exports.default = autoUpdater;
module.exports = exports.default;
'@ | Set-Content -Path $path -Encoding UTF8
}

function Check-DiscordRunning {
    $procs = Get-Process | Where-Object { $_.ProcessName -match 'Discord(PTB|Canary)?' }
    if ($procs) {
        Write-Host '[WARN] Discord is currently running.' -ForegroundColor Yellow
        $kill = Read-Host 'Discord must be closed to continue. Kill Discord processes now? (y/N)'
        if ($kill -match '^[Yy]$') {
            $procs | Stop-Process -Force
            Write-Host '[INFO] Discord processes killed.'
        } else {
            Write-Host '[INFO] Exiting. Please close Discord and run the script again.'
            Pause
            exit
        }
    }
}

function Show-Menu {
    while ($true) {
        Clear-Host
        $patchStatus = if (Check-Patch) { 'Applied' } else { 'Not applied' }
        $backupStatus = if (Has-Backup) { 'Exists' } else { 'Not found' }
        $isAdmin = Test-Admin
        Write-Host '==== Discord ASAR Patch Menu ===='
        Write-Host "Discord resources: $global:DISCORD_RESOURCES"
        Write-Host "Patch: $patchStatus"
        Write-Host "Backup: $backupStatus"
        if (-not $isAdmin) {
            Write-Host '[WARN] Not running as administrator. Some operations may fail.' -ForegroundColor Yellow
        }
        Write-Host '---------------------------------'
        Write-Host '1) Install Node.js and asar (instructions)'
        Write-Host '2) Apply patch'
        Write-Host '3) Unapply patch (restore original)'
        if ($backupStatus -eq 'Exists') { Write-Host '4) Restore original from backup' }
        Write-Host '5) Select Discord installation'
        Write-Host '6) Exit'
        Write-Host '---------------------------------'
        $opt = Read-Host 'Choose an option'
        switch ($opt) {
            '1' { Show-InstallInstructions }
            '2' { Patch-Discord }
            '3' { Unpatch-Discord }
            '4' { if ($backupStatus -eq 'Exists') { Restore-Backup } }
            '5' { Select-DiscordInstallation }
            '6' { break }
            default { Write-Host 'Invalid option!'; Pause }
        }
    }
}

function Show-InstallInstructions {
    Clear-Host
    Write-Host 'To use this script, you must have Node.js and asar installed globally.'
    Write-Host '1. Download Node.js from https://nodejs.org/'
    Write-Host '2. Open a command prompt and run: npm install -g asar'
    Write-Host '3. Restart this script after installation.'
    Pause
}

# ===== MAIN =====
Check-DiscordRunning
Select-DiscordInstallation
Backup-Asar
Show-Menu 