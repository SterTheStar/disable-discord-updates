@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ===== CONFIG =====
set "DISCORD_STABLE=%ProgramFiles%\Discord\resources"
set "DISCORD_PTB=%ProgramFiles%\DiscordPTB\resources"
set "DISCORD_CANARY=%ProgramFiles%\DiscordCanary\resources"
set "ASAR_FILE=app.asar"
set "ASAR_BAK=app.asar.bak"
set "UNPACKED_DIR=app-unpacked"
set "PATCH_MARK=patch.true"
set "NODE_PATH="
set "ASAR_PATH="
set "DISCORD_RESOURCES="

REM ===== FUNCTIONS =====
:check_node
where node >nul 2>nul
if %errorlevel%==0 (
    set "NODE_PATH=node"
    exit /b 0
) else (
    echo [ERROR] Node.js is not installed. Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

:check_asar
where asar >nul 2>nul
if %errorlevel%==0 (
    set "ASAR_PATH=asar"
    exit /b 0
) else (
    echo [ERROR] asar is not installed globally. Please run: npm install -g asar
    pause
    exit /b 1
)

:detect_discord_installations
setlocal
set "found=0"
set "choices="
if exist "%DISCORD_STABLE%\%ASAR_FILE%" set /a found+=1 & set "choices=!choices!1) Discord (Stable) [%DISCORD_STABLE%]
"
if exist "%DISCORD_PTB%\%ASAR_FILE%" set /a found+=1 & set "choices=!choices!2) Discord PTB [%DISCORD_PTB%]
"
if exist "%DISCORD_CANARY%\%ASAR_FILE%" set /a found+=1 & set "choices=!choices!3) Discord Canary [%DISCORD_CANARY%]
"
if !found! equ 0 (
    echo [WARN] No known Discord installations found.
    endlocal & set "DISCORD_RESOURCES="
    exit /b 1
)
set /a idx=1
for %%I in ("%DISCORD_STABLE%" "%DISCORD_PTB%" "%DISCORD_CANARY%") do (
    if exist "%%~I\%ASAR_FILE%" (
        set "path[!idx!]=%%~I"
        set /a idx+=1
    )
)
:choose_discord
cls
set /a total=%found%+1
echo Select which Discord installation to use:
echo !choices!%total%) Enter custom location manually
set /p sel="Select an option [1-%total%]: "
if "%sel%"=="%total%" goto custom_location
set /a selnum=%sel%
if defined path[%selnum%] (
    set "DISCORD_RESOURCES=!path[%selnum%]!"
    endlocal & set "DISCORD_RESOURCES=%DISCORD_RESOURCES%"
    exit /b 0
) else (
    echo Invalid option!
    pause
    goto choose_discord
)

:custom_location
set /p user_path="Enter the full path to the folder containing %ASAR_FILE%: "
if exist "%user_path%\%ASAR_FILE%" (
    endlocal & set "DISCORD_RESOURCES=%user_path%"
    exit /b 0
) else (
    echo [ERROR] %ASAR_FILE% not found in %user_path%. Try again.
    pause
    goto custom_location
)

REM ===== BACKUP =====
:backup_asar
if not exist "%DISCORD_RESOURCES%\%ASAR_BAK%" (
    echo [INFO] Creating backup: %ASAR_BAK%
    copy "%DISCORD_RESOURCES%\%ASAR_FILE%" "%DISCORD_RESOURCES%\%ASAR_BAK%" >nul
) else (
    echo [INFO] Backup already exists: %ASAR_BAK%
)
exit /b

REM ===== PATCH =====
:patch_discord
call :check_node || exit /b 1
call :check_asar || exit /b 1
call :backup_asar
cd /d "%DISCORD_RESOURCES%"
if exist "%UNPACKED_DIR%" rmdir /s /q "%UNPACKED_DIR%"
"%ASAR_PATH%" extract "%ASAR_FILE%" "%UNPACKED_DIR%"
del /f /q "%UNPACKED_DIR%\app_bootstrap\hostUpdater.js"
call :write_patched_hostupdater "%UNPACKED_DIR%\app_bootstrap\hostUpdater.js"
del /f /q "%ASAR_FILE%"
"%ASAR_PATH%" pack "%UNPACKED_DIR%" "%ASAR_FILE%"
echo. > "%PATCH_MARK%"
echo [OK] Patch applied successfully!
pause
exit /b

REM ===== UNPATCH =====
:unpatch_discord
call :check_node || exit /b 1
call :check_asar || exit /b 1
call :backup_asar
cd /d "%DISCORD_RESOURCES%"
if exist "%UNPACKED_DIR%" rmdir /s /q "%UNPACKED_DIR%"
"%ASAR_PATH%" extract "%ASAR_FILE%" "%UNPACKED_DIR%"
del /f /q "%UNPACKED_DIR%\app_bootstrap\hostUpdater.js"
call :write_original_hostupdater "%UNPACKED_DIR%\app_bootstrap\hostUpdater.js"
del /f /q "%ASAR_FILE%"
"%ASAR_PATH%" pack "%UNPACKED_DIR%" "%ASAR_FILE%"
del /f /q "%PATCH_MARK%"
echo [OK] Patch unapplied and original restored!
pause
exit /b

REM ===== RESTORE BACKUP =====
:restore_backup
if exist "%DISCORD_RESOURCES%\%ASAR_BAK%" (
    copy /y "%DISCORD_RESOURCES%\%ASAR_BAK%" "%DISCORD_RESOURCES%\%ASAR_FILE%"
    del /f /q "%PATCH_MARK%"
    echo [OK] Original restored from backup.
) else (
    echo [ERROR] No backup found to restore.
)
pause
exit /b

REM ===== WRITE PATCHED HOSTUPDATER =====
:write_patched_hostupdater
REM Patched hostUpdater.js content
>"%~1" echo "use strict";
>>"%~1" echo.
>>"%~1" echo Object.defineProperty(exports, "__esModule", {
>>"%~1" echo   value: true
>>"%~1" echo });
>>"%~1" echo exports.default = void 0;
>>"%~1" echo var _electron = require("electron");
>>"%~1" echo var _events = require("events");
>>"%~1" echo var _request = _interopRequireDefault(require("./request"));
>>"%~1" echo var squirrelUpdate = _interopRequireWildcard(require("./squirrelUpdate"));
>>"%~1" echo function _getRequireWildcardCache(e) { if ("function" != typeof WeakMap) return null; var r = new WeakMap(), t = new WeakMap(); return (_getRequireWildcardCache = function (e) { return e ? t : r; })(e); }
>>"%~1" echo function _interopRequireWildcard(e, r) { if (!r && e && e.__esModule) return e; if (null === e || "object" != typeof e && "function" != typeof e) return { default: e }; var t = _getRequireWildcardCache(r); if (t && t.has(e)) return t.get(e); var n = { __proto__: null }, a = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var u in e) if ("default" !== u && {}.hasOwnProperty.call(e, u)) { var i = a ? Object.getOwnPropertyDescriptor(e, u) : null; i && (i.get || i.set) ? Object.defineProperty(n, u, i) : n[u] = e[u]; } return n.default = e, t && t.set(e, n), n; }
>>"%~1" echo function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
>>"%~1" echo function versionParse(verString) {
>>"%~1" echo   return verString.split('.').map(i ^> parseInt(i));
>>"%~1" echo }
>>"%~1" echo function versionNewer(verA, verB) {
>>"%~1" echo   let i = 0;
>>"%~1" echo   while (true) {
>>"%~1" echo     const a = verA[i];
>>"%~1" echo     const b = verB[i];
>>"%~1" echo     i++;
>>"%~1" echo     if (a === undefined) {
>>"%~1" echo       return false;
>>"%~1" echo     } else {
>>"%~1" echo       if (b === undefined || a ^> b) {
>>"%~1" echo         return true;
>>"%~1" echo       }
>>"%~1" echo       if (a ^< b) {
>>"%~1" echo         return false;
>>"%~1" echo       }
>>"%~1" echo     }
>>"%~1" echo   }
>>"%~1" echo }
>>"%~1" echo function versionEqual(verA, verB) {
>>"%~1" echo   if (verA.length !== verB.length) {
>>"%~1" echo     return false;
>>"%~1" echo   }
>>"%~1" echo   for (let i = 0; i ^< verA.length; ++i) {
>>"%~1" echo     const a = verA[i];
>>"%~1" echo     const b = verB[i];
>>"%~1" echo     if (a !== b) {
>>"%~1" echo       return false;
>>"%~1" echo     }
>>"%~1" echo   }
>>"%~1" echo   return true;
>>"%~1" echo }
>>"%~1" echo class AutoUpdaterWin32 extends _events.EventEmitter {
>>"%~1" echo   constructor() {
>>"%~1" echo     super();
>>"%~1" echo     this.updateUrl = null;
>>"%~1" echo     this.updateVersion = null;
>>"%~1" echo   }
>>"%~1" echo   setFeedURL(updateUrl) {
>>"%~1" echo     this.updateUrl = updateUrl;
>>"%~1" echo   }
>>"%~1" echo   quitAndInstall() {
>>"%~1" echo     REM Does nothing to prevent auto install
>>"%~1" echo   }
>>"%~1" echo   downloadAndInstallUpdate(callback) {
>>"%~1" echo     REM Calls callback directly as if finished
>>"%~1" echo     callback();
>>"%~1" echo   }
>>"%~1" echo   checkForUpdates() {
>>"%~1" echo     this.emit('checking-for-update');
>>"%~1" echo     REM Always says no update
>>"%~1" echo     this.emit('update-not-available');
>>"%~1" echo   }
>>"%~1" echo }
>>"%~1" echo.
>>"%~1" echo class AutoUpdaterLinux extends _events.EventEmitter {
>>"%~1" echo   constructor() {
>>"%~1" echo     super();
>>"%~1" echo     this.updateUrl = null;
>>"%~1" echo   }
>>"%~1" echo   setFeedURL(url) {
>>"%~1" echo     this.updateUrl = url;
>>"%~1" echo   }
>>"%~1" echo   quitAndInstall() {
>>"%~1" echo     REM Just relaunches the app, installs nothing
>>"%~1" echo     _electron.app.relaunch();
>>"%~1" echo     _electron.app.quit();
>>"%~1" echo   }
>>"%~1" echo   async checkForUpdates() {
>>"%~1" echo     this.emit('checking-for-update');
>>"%~1" echo     REM Always notifies no update available
>>"%~1" echo     this.emit('update-not-available');
>>"%~1" echo   }
>>"%~1" echo }
>>"%~1" echo.
>>"%~1" echo let autoUpdater;
>>"%~1" echo switch (process.platform) {
>>"%~1" echo   case 'darwin':
>>"%~1" echo     autoUpdater = require('electron').autoUpdater;
>>"%~1" echo     break;
>>"%~1" echo   case 'win32':
>>"%~1" echo     autoUpdater = new AutoUpdaterWin32();
>>"%~1" echo     break;
>>"%~1" echo   case 'linux':
>>"%~1" echo     autoUpdater = new AutoUpdaterLinux();
>>"%~1" echo     break;
>>"%~1" echo }
>>"%~1" echo.
>>"%~1" echo var _default = exports.default = autoUpdater;
>>"%~1" echo module.exports = exports.default;
exit /b

REM ===== WRITE ORIGINAL HOSTUPDATER =====
:write_original_hostupdater
REM Original hostUpdater.js content
>"%~1" echo "use strict";
>>"%~1" echo.
>>"%~1" echo Object.defineProperty(exports, "__esModule", {
>>"%~1" echo   value: true
>>"%~1" echo });
>>"%~1" echo exports.default = void 0;
>>"%~1" echo var _electron = require("electron");
>>"%~1" echo var _events = require("events");
>>"%~1" echo var _request = _interopRequireDefault(require("./request"));
>>"%~1" echo var squirrelUpdate = _interopRequireWildcard(require("./squirrelUpdate"));
>>"%~1" echo function _getRequireWildcardCache(e) { if ("function" != typeof WeakMap) return null; var r = new WeakMap(), t = new WeakMap(); return (_getRequireWildcardCache = function (e) { return e ? t : r; })(e); }
>>"%~1" echo function _interopRequireWildcard(e, r) { if (!r && e && e.__esModule) return e; if (null === e || "object" != typeof e && "function" != typeof e) return { default: e }; var t = _getRequireWildcardCache(r); if (t && t.has(e)) return t.get(e); var n = { __proto__: null }, a = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var u in e) if ("default" !== u && {}.hasOwnProperty.call(e, u)) { var i = a ? Object.getOwnPropertyDescriptor(e, u) : null; i && (i.get || i.set) ? Object.defineProperty(n, u, i) : n[u] = e[u]; } return n.default = e, t && t.set(e, n), n; }
>>"%~1" echo function _interopRequireDefault(e) { return e && e.__esModule ? e : { default: e }; }
>>"%~1" echo function versionParse(verString) {
>>"%~1" echo   return verString.split('.').map(i ^> parseInt(i));
>>"%~1" echo }
>>"%~1" echo function versionNewer(verA, verB) {
>>"%~1" echo   let i = 0;
>>"%~1" echo   while (true) {
>>"%~1" echo     const a = verA[i];
>>"%~1" echo     const b = verB[i];
>>"%~1" echo     i++;
>>"%~1" echo     if (a === undefined) {
>>"%~1" echo       return false;
>>"%~1" echo     } else {
>>"%~1" echo       if (b === undefined || a ^> b) {
>>"%~1" echo         return true;
>>"%~1" echo       }
>>"%~1" echo       if (a ^< b) {
>>"%~1" echo         return false;
>>"%~1" echo       }
>>"%~1" echo     }
>>"%~1" echo   }
>>"%~1" echo }
>>"%~1" echo function versionEqual(verA, verB) {
>>"%~1" echo   if (verA.length !== verB.length) {
>>"%~1" echo     return false;
>>"%~1" echo   }
>>"%~1" echo   for (let i = 0; i ^< verA.length; ++i) {
>>"%~1" echo     const a = verA[i];
>>"%~1" echo     const b = verB[i];
>>"%~1" echo     if (a !== b) {
>>"%~1" echo       return false;
>>"%~1" echo     }
>>"%~1" echo   }
>>"%~1" echo   return true;
>>"%~1" echo }
>>"%~1" echo class AutoUpdaterWin32 extends _events.EventEmitter {
>>"%~1" echo   constructor() {
>>"%~1" echo     super();
>>"%~1" echo     this.updateUrl = null;
>>"%~1" echo     this.updateVersion = null;
>>"%~1" echo   }
>>"%~1" echo   setFeedURL(updateUrl) {
>>"%~1" echo     this.updateUrl = updateUrl;
>>"%~1" echo   }
>>"%~1" echo   quitAndInstall() {
>>"%~1" echo     if (squirrelUpdate.updateExistsSync()) {
>>"%~1" echo       squirrelUpdate.restart(_electron.app, this.updateVersion ?? _electron.app.getVersion());
>>"%~1" echo     } else {
>>"%~1" echo       require('auto-updater').quitAndInstall();
>>"%~1" echo     }
>>"%~1" echo   }
>>"%~1" echo   downloadAndInstallUpdate(callback) {
>>"%~1" echo     if (this.updateUrl == null) {
>>"%~1" echo       throw new Error('Update URL is not set');
>>"%~1" echo     }
>>"%~1" echo     void squirrelUpdate.spawnUpdateInstall(this.updateUrl, progress ^> {
>>"%~1" echo       this.emit('update-progress', progress);
>>"%~1" echo     }).catch(err ^> callback(err)).then(() ^> callback());
>>"%~1" echo   }
>>"%~1" echo   checkForUpdates() {
>>"%~1" echo     if (this.updateUrl == null) {
>>"%~1" echo       throw new Error('Update URL is not set');
>>"%~1" echo     }
>>"%~1" echo     this.emit('checking-for-update');
>>"%~1" echo     if (!squirrelUpdate.updateExistsSync()) {
>>"%~1" echo       this.emit('update-not-available');
>>"%~1" echo       return;
>>"%~1" echo     }
>>"%~1" echo     squirrelUpdate.spawnUpdate(['--check', this.updateUrl], (error, stdout) ^> {
>>"%~1" echo       if (error != null) {
>>"%~1" echo         this.emit('error', error);
>>"%~1" echo         return;
>>"%~1" echo       }
>>"%~1" echo       try {
>>"%~1" echo         const json = stdout.trim().split('^\n').pop();
>>"%~1" echo         const releasesFound = JSON.parse(json).releasesToApply;
>>"%~1" echo         if (releasesFound == null || releasesFound.length === 0) {
>>"%~1" echo           this.emit('update-not-available');
>>"%~1" echo           return;
>>"%~1" echo         }
>>"%~1" echo         const update = releasesFound.pop();
>>"%~1" echo         this.emit('update-available');
>>"%~1" echo         this.downloadAndInstallUpdate(error ^> {
>>"%~1" echo           if (error != null) {
>>"%~1" echo             this.emit('error', error);
>>"%~1" echo             return;
>>"%~1" echo           }
>>"%~1" echo           this.updateVersion = update.version;
>>"%~1" echo           this.emit('update-downloaded', {}, update.release, update.version, new Date(), this.updateUrl, this.quitAndInstall.bind(this));
>>"%~1" echo         });
>>"%~1" echo       } catch (error) {
>>"%~1" echo         error.stdout = stdout;
>>"%~1" echo         this.emit('error', error);
>>"%~1" echo       }
>>"%~1" echo     });
>>"%~1" echo   }
>>"%~1" echo }
>>"%~1" echo class AutoUpdaterLinux extends _events.EventEmitter {
>>"%~1" echo   constructor() {
>>"%~1" echo     super();
>>"%~1" echo     this.updateUrl = null;
>>"%~1" echo   }
>>"%~1" echo   setFeedURL(url) {
>>"%~1" echo     this.updateUrl = url;
>>"%~1" echo   }
>>"%~1" echo   quitAndInstall() {
>>"%~1" echo     _electron.app.relaunch();
>>"%~1" echo     _electron.app.quit();
>>"%~1" echo   }
>>"%~1" echo   async checkForUpdates() {
>>"%~1" echo     if (this.updateUrl == null) {
>>"%~1" echo       throw new Error('Update URL is not set');
>>"%~1" echo     }
>>"%~1" echo     const currVersion = versionParse(_electron.app.getVersion());
>>"%~1" echo     this.emit('checking-for-update');
>>"%~1" echo     try {
>>"%~1" echo       const response = await _request.default.get(this.updateUrl);
>>"%~1" echo       if (response.statusCode === 204) {
>>"%~1" echo         this.emit('update-not-available');
>>"%~1" echo         return;
>>"%~1" echo       }
>>"%~1" echo       let latestVerStr = '';
>>"%~1" echo       let latestVersion = [];
>>"%~1" echo       try {
>>"%~1" echo         var _response$body;
>>"%~1" echo         const latestMetadata = JSON.parse(((_response$body = response.body) === null || _response$body === void 0 ? void 0 : _response$body.toString('utf-8')) ?? '');
>>"%~1" echo         latestVerStr = latestMetadata.name;
>>"%~1" echo         latestVersion = versionParse(latestVerStr);
>>"%~1" echo       } catch (_) {}
>>"%~1" echo       if (versionNewer(latestVersion, currVersion)) {
>>"%~1" echo         console.log('[Updates] You are out of date!');
>>"%~1" echo         this.emit('update-manually', latestVerStr);
>>"%~1" echo       } else if (versionNewer(currVersion, latestVersion)) {
>>"%~1" echo         console.log('[Updates] You are living in the future! Come back time traveller!');
>>"%~1" echo         this.emit('update-manually', latestVerStr);
>>"%~1" echo       } else if (versionEqual(latestVersion, currVersion)) {
>>"%~1" echo         console.log('[Updates] You are up to date.');
>>"%~1" echo         this.emit('update-not-available');
>>"%~1" echo       } else {
>>"%~1" echo         console.log('[Updates] You are in a very strange place.');
>>"%~1" echo         this.emit('update-not-available');
>>"%~1" echo       }
>>"%~1" echo     } catch (err) {
>>"%~1" echo       console.error('[Updates] Error fetching ' + this.updateUrl + ': ' + err.message);
>>"%~1" echo       this.emit('error', err);
>>"%~1" echo     }
>>"%~1" echo   }
>>"%~1" echo }
>>"%~1" echo let autoUpdater;
>>"%~1" echo switch (process.platform) {
>>"%~1" echo   case 'darwin':
>>"%~1" echo     autoUpdater = require('electron').autoUpdater;
>>"%~1" echo     break;
>>"%~1" echo   case 'win32':
>>"%~1" echo     autoUpdater = new AutoUpdaterWin32();
>>"%~1" echo     break;
>>"%~1" echo   case 'linux':
>>"%~1" echo     autoUpdater = new AutoUpdaterLinux();
>>"%~1" echo     break;
>>"%~1" echo }
>>"%~1" echo var _default = exports.default = autoUpdater;
>>"%~1" echo module.exports = exports.default;
exit /b

REM ===== CHECK IF DISCORD IS RUNNING =====
:check_discord_running
for %%N in (Discord.exe DiscordPTB.exe DiscordCanary.exe) do (
    tasklist /FI "IMAGENAME eq %%N" | find /I "%%N" >nul && set "found=1"
)
if defined found (
    echo [WARN] Discord is currently running.
    set /p killit="Discord must be closed to continue. Kill Discord processes now? (y/N): "
    if /I "!killit!"=="y" (
        for %%N in (Discord.exe DiscordPTB.exe DiscordCanary.exe) do taskkill /F /IM %%N >nul 2>nul
        echo [INFO] Discord processes killed.
    ) else (
        echo [INFO] Exiting. Please close Discord and run the script again.
        exit /b 1
    )
)
exit /b

REM ===== CHECK ADMIN =====
:check_admin
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] This script is not running as administrator. Some operations may fail.
    echo Please right-click and 'Run as administrator' for full functionality.
    pause
)
exit /b

REM ===== CHECK BACKUP =====
:has_backup
if exist "%DISCORD_RESOURCES%\%ASAR_BAK%" (
    exit /b 0
) else (
    exit /b 1
)

REM ===== CHECK PATCH =====
:check_patch
if exist "%DISCORD_RESOURCES%\%PATCH_MARK%" (
    exit /b 0
) else (
    exit /b 1
)

REM ===== DETECT ALL INSTALLATIONS (with status) =====
:detect_discord_installations_full
setlocal EnableDelayedExpansion
set "all_paths=1|%ProgramFiles%\Discord\resources:Discord (Stable) 2|%ProgramFiles%\DiscordPTB\resources:Discord PTB 3|%ProgramFiles%\DiscordCanary\resources:Discord Canary"
set "choices="
for %%A in (%all_paths%) do (
    for /f "tokens=1,2 delims=|" %%B in ("%%A") do (
        set "idx=%%B"
        for /f "tokens=1,* delims=:" %%C in ("%%C") do (
            set "path=%%C"
            set "label=%%D"
            if exist "!path!\%ASAR_FILE%" (
                set "choices=!choices!!idx!) !label! [Installed] (!path!)\n"
            ) else (
                set "choices=!choices!!idx!) !label! [Not installed] (!path!)\n"
            )
        )
    )
)
set "choices=!choices!4) Enter custom location manually\n"
(for /f "delims=" %%l in ("!choices!") do @echo %%l)
endlocal & exit /b

REM ===== SELECT INSTALLATION (all options) =====
:select_discord_installation
setlocal EnableDelayedExpansion
set "all_paths=1|%ProgramFiles%\Discord\resources:Discord (Stable) 2|%ProgramFiles%\DiscordPTB\resources:Discord PTB 3|%ProgramFiles%\DiscordCanary\resources:Discord Canary"
set "paths[1]=%ProgramFiles%\Discord\resources"
set "paths[2]=%ProgramFiles%\DiscordPTB\resources"
set "paths[3]=%ProgramFiles%\DiscordCanary\resources"
:choose_discord_full
cls
call :detect_discord_installations_full
set /p sel="Select an option [1-4]: "
if "%sel%"=="4" goto custom_location
if "%sel%"=="1" set "DISCORD_RESOURCES=%ProgramFiles%\Discord\resources" & goto :eof
if "%sel%"=="2" set "DISCORD_RESOURCES=%ProgramFiles%\DiscordPTB\resources" & goto :eof
if "%sel%"=="3" set "DISCORD_RESOURCES=%ProgramFiles%\DiscordCanary\resources" & goto :eof
if "%sel%"=="" goto choose_discord_full
REM Check if selected path exists
set "chosen_path=!paths[%sel%]!"
if not exist "!chosen_path!\%ASAR_FILE%" (
    set /p confirm="[WARN] This installation is not present. Use anyway? (y/N): "
    if /I "!confirm!"=="y" set "DISCORD_RESOURCES=!chosen_path!" & goto :eof
    goto choose_discord_full
) else (
    set "DISCORD_RESOURCES=!chosen_path!"
    goto :eof
)

REM ===== MAIN MENU =====
:main_menu
cls
call :check_patch
if %errorlevel%==0 (
    set "patch_status=Applied"
) else (
    set "patch_status=Not applied"
)
call :has_backup
if %errorlevel%==0 (
    set "backup_status=Exists"
) else (
    set "backup_status=Not found"
)

call :check_admin

echo ==== Discord ASAR Patch Menu ====
echo Discord resources: %DISCORD_RESOURCES%
echo Patch: %patch_status%
echo Backup: %backup_status%
echo ---------------------------------
echo 1) Install Node.js and asar (instructions)
echo 2) Apply patch
echo 3) Unapply patch (restore original)
if "%backup_status%"=="Exists" echo 4) Restore original from backup
echo 5) Select Discord installation
echo 6) Exit
echo ---------------------------------
set /p opt="Choose an option: "
if "%opt%"=="1" goto install_instructions
if "%opt%"=="2" goto patch_discord
if "%opt%"=="3" goto unpatch_discord
if "%opt%"=="4" if "%backup_status%"=="Exists" goto restore_backup
if "%opt%"=="5" goto select_discord_installation
if "%opt%"=="6" exit /b

goto main_menu

REM ===== INSTALL INSTRUCTIONS =====
:install_instructions
cls
echo To use this script, you must have Node.js and asar installed globally.
echo 1. Download Node.js from https://nodejs.org/
echo 2. Open a command prompt and run: npm install -g asar
echo 3. Restart this script after installation.
pause
goto main_menu

REM ===== INIT =====
call :check_discord_running
call :detect_discord_installations
if "%DISCORD_RESOURCES%"=="" goto select_discord_installation
call :backup_asar
goto main_menu 