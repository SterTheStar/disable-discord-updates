#!/usr/bin/env bash
set -e

# ===== CONFIG =====
DEFAULT_DISCORD_RESOURCES="/opt/discord/resources"
ASAR_FILE="app.asar"
ASAR_BAK="app.asar.bak"
UNPACKED_DIR="app-unpacked"
HOSTUPDATER_JS="$UNPACKED_DIR/app_bootstrap/hostUpdater.js"
PATCH_MARK="patch.true"

DISCORD_RESOURCES="$DEFAULT_DISCORD_RESOURCES"

# ===== Detect OS =====
detect_os() {
    if [ -f /etc/arch-release ]; then
        OS="Arch Linux"
    elif [ -f /etc/debian_version ]; then
        OS="Debian/Ubuntu"
    elif [ -f /etc/fedora-release ]; then
        OS="Fedora"
    elif [ -f /etc/SuSE-release ] || [ -f /etc/SUSE-brand ] || [ -f /etc/os-release ] && grep -qi suse /etc/os-release; then
        OS="openSUSE"
    else
        OS="Unknown"
    fi
    echo "$OS"
}

# ===== Path Handling =====
find_discord_resources() {
    if [ -f "$DISCORD_RESOURCES/$ASAR_FILE" ]; then
        return 0
    fi
    echo "[WARN] Could not find $ASAR_FILE in $DISCORD_RESOURCES."
    while true; do
        read -e -p "Please enter the full path to the folder containing $ASAR_FILE: " user_path
        if [ -f "$user_path/$ASAR_FILE" ]; then
            DISCORD_RESOURCES="$user_path"
            return 0
        else
            echo "[ERROR] $ASAR_FILE not found in $user_path. Try again."
        fi
    done
}

# ===== Backup Handling =====
backup_asar() {
    if [ ! -f "$DISCORD_RESOURCES/$ASAR_BAK" ]; then
        echo "[INFO] Creating backup: $ASAR_BAK"
        sudo cp "$DISCORD_RESOURCES/$ASAR_FILE" "$DISCORD_RESOURCES/$ASAR_BAK"
    else
        echo "[INFO] Backup already exists: $ASAR_BAK"
    fi
}

has_backup() {
    [ -f "$DISCORD_RESOURCES/$ASAR_BAK" ]
}

restore_backup() {
    if has_backup; then
        echo "[INFO] Restoring $ASAR_FILE from backup..."
        sudo cp "$DISCORD_RESOURCES/$ASAR_BAK" "$DISCORD_RESOURCES/$ASAR_FILE"
        sudo rm -f "$DISCORD_RESOURCES/$PATCH_MARK"
        echo "[OK] Original restored from backup."
    else
        echo "[ERROR] No backup found to restore."
    fi
}

# ===== Check Functions =====
check_node() {
    if command -v node &>/dev/null; then
        echo "Installed"
        return 0
    else
        echo "Not installed"
        return 1
    fi
}

check_asar() {
    if command -v asar &>/dev/null; then
        echo "Installed"
        return 0
    else
        echo "Not installed"
        return 1
    fi
}

check_patch() {
    if [ -f "$DISCORD_RESOURCES/$PATCH_MARK" ]; then
        echo "Applied"
        return 0
    else
        echo "Not applied"
        return 1
    fi
}

# ===== Install Functions =====
install_node_and_asar() {
    need_node=0
    need_asar=0
    check_node || need_node=1
    check_asar || need_asar=1
    if [ $need_node -eq 0 ] && [ $need_asar -eq 0 ]; then
        echo "[INFO] Node.js and asar are already installed."
        return
    fi
    if [ $need_node -eq 1 ]; then
        echo "[INFO] Installing Node.js..."
        if [ "$OS" = "Arch Linux" ]; then
            sudo pacman -Sy --noconfirm nodejs npm
        elif [ "$OS" = "Debian/Ubuntu" ]; then
            sudo apt update && sudo apt install -y nodejs npm
        elif [ "$OS" = "Fedora" ]; then
            sudo dnf install -y nodejs npm
        elif [ "$OS" = "openSUSE" ]; then
            sudo zypper install -y nodejs npm
        else
            echo "[ERROR] Unsupported distro. Please install Node.js manually."
            exit 1
        fi
    fi
    if [ $need_asar -eq 1 ]; then
        echo "[INFO] Installing asar globally..."
        sudo npm install -g asar
    fi
    echo "[OK] Node.js and asar are installed."
}

# ===== Patch Discord =====
patch_discord() {
    find_discord_resources
    backup_asar
    cd "$DISCORD_RESOURCES"
    echo "[INFO] Extracting $ASAR_FILE..."
    sudo asar extract "$ASAR_FILE" "$UNPACKED_DIR"
    echo "[INFO] Removing old hostUpdater.js..."
    sudo rm -f "$HOSTUPDATER_JS"
    echo "[INFO] Writing new hostUpdater.js..."
    sudo tee "$HOSTUPDATER_JS" > /dev/null <<'EOF'
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
EOF
    echo "[INFO] Removing old $ASAR_FILE..."
    sudo rm -f "$ASAR_FILE"
    echo "[INFO] Packing new $ASAR_FILE..."
    sudo asar pack "$UNPACKED_DIR" "$ASAR_FILE"
    sudo touch "$PATCH_MARK"
    echo "[OK] Patch applied successfully!"
}

# ===== Unpatch Discord =====
unpatch_discord() {
    find_discord_resources
    backup_asar
    cd "$DISCORD_RESOURCES"
    echo "[INFO] Extracting $ASAR_FILE..."
    sudo asar extract "$ASAR_FILE" "$UNPACKED_DIR"
    echo "[INFO] Removing patched hostUpdater.js..."
    sudo rm -f "$HOSTUPDATER_JS"
    echo "[INFO] Restoring original hostUpdater.js..."
    sudo tee "$HOSTUPDATER_JS" > /dev/null <<'EOF'
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
EOF
    echo "[INFO] Removing old $ASAR_FILE..."
    sudo rm -f "$ASAR_FILE"
    echo "[INFO] Packing new $ASAR_FILE..."
    sudo asar pack "$UNPACKED_DIR" "$ASAR_FILE"
    sudo rm -f "$PATCH_MARK"
    echo "[OK] Patch unapplied and original restored!"
}

# ===== Discord Running Detection =====
check_discord_running() {
    local discord_pids
    # Busca todos os PIDs relacionados ao Discord, exceto o próprio script
    discord_pids=$(pgrep -af -i 'discord|discord-canary|discord-ptb|Discord|DiscordCanary|DiscordPTB' | grep -v 'patch_discord.sh' | awk '{print $1}' | paste -sd, -)
    if [ -n "$discord_pids" ]; then
        echo "[WARN] Discord is currently running."
        echo "Found the following Discord-related processes:"
        echo "PID      USER      CMD"
        ps -p $discord_pids -o pid=,user=,args= | awk '{cmd=substr($0, index($0,$3)); if(length(cmd)>50) cmd=substr(cmd,1,47)"..."; printf "%-8s %-9s %s\n", $1, $2, cmd}'
        echo
        read -p "Discord must be closed to continue. Kill all Discord processes now? (y/N): " yn
        case $yn in
            [Yy]*)
                echo "[INFO] Killing Discord..."
                # Convert comma-separated to space-separated for kill
                local discord_pids_space
                discord_pids_space=$(echo "$discord_pids" | tr ',' ' ')
                # Remove own PID and parent shell PID from the list
                local mypid parentpid
                mypid=$$
                parentpid=$PPID
                discord_pids_space=$(echo "$discord_pids_space" | tr ' ' '\n' | grep -v -e "^$mypid$" -e "^$parentpid$" | tr '\n' ' ')
                if [ -z "$discord_pids_space" ]; then
                    echo "[INFO] No Discord processes to kill."
                    return
                fi
                sudo kill $discord_pids_space 2>/dev/null || true
                sleep 2
                # Check again
                discord_pids=$(pgrep -af -i 'discord|discord-canary|discord-ptb|Discord|DiscordCanary|DiscordPTB' | grep -v 'patch_discord.sh' | awk '{print $1}' | paste -sd, -)
                if [ -n "$discord_pids" ]; then
                    echo "[WARN] Some Discord processes are still running. Forcing kill..."
                    discord_pids_space=$(echo "$discord_pids" | tr ',' ' ')
                    discord_pids_space=$(echo "$discord_pids_space" | tr ' ' '\n' | grep -v -e "^$mypid$" -e "^$parentpid$" | tr '\n' ' ')
                    if [ -n "$discord_pids_space" ]; then
                        sudo kill -9 $discord_pids_space 2>/dev/null || true
                        sleep 2
                    fi
                fi
                # Final check
                discord_pids=$(pgrep -af -i 'discord|discord-canary|discord-ptb|Discord|DiscordCanary|DiscordPTB' | grep -v 'patch_discord.sh' | awk '{print $1}' | paste -sd, -)
                if [ -n "$discord_pids" ]; then
                    echo "[WARN] Some Discord processes could not be killed. Please close them manually if you encounter issues."
                else
                    echo "[OK] Discord processes killed."
                fi
                clear
                ;;
            *)
                echo "[INFO] Exiting. Please close Discord and run the script again."
                exit 0
                ;;
        esac
    fi
}

detect_discord_installations_full() {
    # Lista de todas as opções padrão
    local all_paths=(
        "/opt/discord/resources:Discord (Stable)"
        "$HOME/snap/discord/current/.discord/resources:Discord (Stable - Snap)"
        "/opt/DiscordPTB/resources:Discord PTB"
        "$HOME/snap/discord-ptb/current/.discordptb/resources:Discord PTB - Snap"
        "/opt/DiscordCanary/resources:Discord Canary"
        "$HOME/snap/discord-canary/current/.discordcanary/resources:Discord Canary - Snap"
    )
    local result=()
    for entry in "${all_paths[@]}"; do
        local path="${entry%%:*}"
        local label="${entry#*:}"
        if [ -d "$path" ]; then
            result+=("$path:$label:Installed")
        else
            result+=("$path:$label:Not installed")
        fi
    done
    printf '%s\n' "${result[@]}"
}

auto_select_discord_installation() {
    local installations installed_count=0 installed_index=-1
    mapfile -t installations < <(detect_discord_installations_full)
    for idx in "${!installations[@]}"; do
        local status="${installations[$idx]##*:}"
        if [ "$status" = "Installed" ]; then
            ((installed_count++))
            installed_index=$idx
        fi
    done
    if [ "$installed_count" -eq 1 ]; then
        local chosen="${installations[$installed_index]}"
        local chosen_path="${chosen%%:*}"
        DISCORD_RESOURCES="$chosen_path"
        echo "[INFO] Using detected installation: ${chosen#*:} ($DISCORD_RESOURCES)"
        return 0
    fi
    return 1
}

select_discord_installation() {
    local installations
    mapfile -t installations < <(detect_discord_installations_full)
    echo "Select which Discord installation to use:"
    local i=1
    for inst in "${installations[@]}"; do
        local path="${inst%%:*}"
        local label_status="${inst#*:}"
        local label="${label_status%%:*}"
        local status="${label_status#*:}"
        echo "$i) $label ($path) [$status]"
        ((i++))
    done
    echo "$i) Back to previous menu"
    while true; do
        read -p "Select an option [1-$i]: " sel
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le $i ]; then
            if [ "$sel" -eq "$i" ]; then
                return 1
            else
                local chosen="${installations[$((sel-1))]}"
                local chosen_path="${chosen%%:*}"
                local chosen_status="${chosen##*:}"
                if [ "$chosen_status" = "Not installed" ]; then
                    read -p "[WARN] This installation is not present. Use anyway? (y/N): " yn
                    case $yn in
                        [Yy]*)
                            DISCORD_RESOURCES="$chosen_path"
                            echo "[INFO] Using: $chosen_path (Not installed)"
                            return 0
                            ;;
                        *)
                            continue
                            ;;
                    esac
                else
                    DISCORD_RESOURCES="$chosen_path"
                    echo "[INFO] Using: $chosen_path (Installed)"
                    return 0
                fi
            fi
        else
            echo "Invalid option!"
        fi
    done
}

change_location_menu() {
    while true; do
        clear
        echo "==== Select Discord Installation ===="
        echo "Current: $DISCORD_RESOURCES"
        echo "1) Select known installation"
        echo "2) Enter custom location manually"
        echo "3) Back to main menu"
        echo "-------------------------------"
        read -p "Choose an option: " locopt
        case $locopt in
            1)
                if ! select_discord_installation; then
                    echo "[WARN] No known installations found. Use manual entry."
                    sleep 2
                else
                    sleep 1
                    return
                fi
                ;;
            2)
                read -e -p "Enter the full path to the folder containing $ASAR_FILE: " user_path
                if [ -f "$user_path/$ASAR_FILE" ]; then
                    DISCORD_RESOURCES="$user_path"
                    echo "[INFO] Using custom location: $DISCORD_RESOURCES"
                    sleep 1
                    return
                else
                    echo "[ERROR] $ASAR_FILE not found in $user_path. Try again."
                    sleep 2
                fi
                ;;
            3)
                return
                ;;
            *)
                echo "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# ===== Menu =====
main_menu() {
    while true; do
        clear
        echo "==== Discord ASAR Patch Menu ===="
        echo "System: $(detect_os)"
        echo "Node.js: $(check_node)"
        echo "Asar: $(check_asar)"
        echo "Patch: $(check_patch)"
        echo "Discord resources: $DISCORD_RESOURCES"
        if has_backup; then
            echo "Backup: Exists ($DISCORD_RESOURCES/$ASAR_BAK)"
        else
            echo "Backup: Not found"
        fi
        echo "---------------------------------"
        echo "1) Install Node.js and asar"
        echo "2) Apply patch"
        echo "3) Unapply patch (restore original)"
        if has_backup; then
            echo "4) Restore original from backup"
            echo "5) Select Discord installation"
            echo "6) Exit"
        else
            echo "4) Select Discord installation"
            echo "5) Exit"
        fi
        echo "---------------------------------"
        read -p "Choose an option: " opt
        case $opt in
            1)
                install_node_and_asar
                read -n1 -r -p "Press any key to continue..." key
                ;;
            2)
                if check_patch; then
                    echo "[INFO] Patch already applied."
                else
                    patch_discord
                fi
                read -n1 -r -p "Press any key to continue..." key
                ;;
            3)
                if check_patch; then
                    unpatch_discord
                else
                    echo "[INFO] Patch is not applied."
                fi
                read -n1 -r -p "Press any key to continue..." key
                ;;
            4)
                if has_backup; then
                    restore_backup
                    read -n1 -r -p "Press any key to continue..." key
                else
                    change_location_menu
                fi
                ;;
            5)
                if has_backup; then
                    change_location_menu
                else
                    exit 0
                fi
                ;;
            6)
                if has_backup; then
                    exit 0
                else
                    echo "Invalid option!"
                    read -n1 -r -p "Press any key to continue..." key
                fi
                ;;
            *)
                echo "Invalid option!"
                read -n1 -r -p "Press any key to continue..." key
                ;;
        esac
    done
}

# ===== Main =====
OS=$(detect_os)
check_discord_running
if ! auto_select_discord_installation; then
    find_discord_resources
fi
backup_asar
main_menu 