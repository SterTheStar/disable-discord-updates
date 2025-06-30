# Discord ASAR Patch

This script automates the patching and restoration process of Discord's `app.asar` file on Linux and Windows systems, allowing you to safely and reversibly modify Discord's behavior.

## Available Versions

### Linux Version (Stable)
- **File**: `patch_discord.sh`
- **Status**: Fully tested and stable
- **Features**: Complete functionality with all features

### Windows Version (Development)
- **File**: `patch_discord.ps1`
- **Status**: **Still in development - may not work properly**
- **Features**: Basic functionality, experimental
- **Note**: This version is provided as-is and may have issues or incomplete features

## Features
- **Automatic OS detection** (Arch, Debian/Ubuntu, Fedora, openSUSE)
- **Automatic installation** of Node.js and the global `asar` package
- **Automatic backup** of the `app.asar` file when the script starts
- **Patch and unpatch** the `hostUpdater.js` file inside `app.asar`
- **Easy restoration** from the original backup
- **Interactive menu** and automatic Discord path detection
- **Multi-installation support**: Detects Stable, PTB, Canary, and Snap installations
- **Flexible location selection**: Choose from detected installations, or set a custom path

## Requirements

### Linux Version
- Linux (Arch, Debian/Ubuntu, Fedora, openSUSE)
- Superuser permissions (sudo)
- Discord installed via the official package or Snap

### Windows Version
- Windows 10/11
- Node.js installed (the script will attempt to install it)
- Discord installed in Program Files or AppData
- **Note**: This version is experimental and may not work as expected

## How to Use

### Linux Version

1. **Give the script execution permission:**
   ```bash
   chmod +x patch_discord.sh
   ```

2. **Run the script:**
   ```bash
   ./patch_discord.sh
   ```

3. **Follow the interactive menu:**
   - The script will automatically detect your system and all known Discord installations (Stable, PTB, Canary, Snap).
   - If only one installation is found, it will be selected automatically. If multiple are found, you will be prompted to choose.
   - If none are found, you can manually provide the path to the folder containing `app.asar`.
   - A backup of `app.asar` will be created automatically on the first run.

### Windows Version

1. **Run the PowerShell script:**
   - Right-click `patch_discord.ps1` and select "Run with PowerShell" or run it from PowerShell
   - **Note**: This version is experimental and may not work properly

2. **Follow the interactive menu:**
   - The script will attempt to detect Discord installations in Program Files and AppData
   - Select from available installations or provide a custom path
   - A backup will be created automatically

**⚠️ Warning**: The Windows version is still in development and may have issues or incomplete functionality. Use at your own risk.

## Menu Options
- **Install Node.js and asar**: Installs the required dependencies to handle ASAR files.
- **Apply patch**: Applies the patch to `hostUpdater.js` inside `app.asar`.
- **Unapply patch (restore original)**: Reverts the patch, restoring Discord's default behavior.
- **Restore original from backup**: Restores the `app.asar` file from the automatically created backup.
- **Select Discord installation**: Lets you choose between all detected installations (Stable, PTB, Canary, Snap), even if not installed (shows [Not installed]). You can also set a custom path.
- **Exit**: Exits the script.

## Important Notes
- The backup is created only once, on the first run, and is saved as `app.asar.bak` in the same Discord folder.
- The script only allows restoring from backup if it exists.
- The patch creates a `patch.true` file to indicate that the patch is active.
- If you select a Discord installation marked as [Not installed], the script will warn you and ask for confirmation before proceeding.

## Troubleshooting Tips

### Linux Version
- **Permission denied**: Run the script as a user with sudo privileges.
- **Discord not found**: Manually provide the path to the folder containing `app.asar` when prompted.
- **Problems after patching**: Use the restore option to revert to the original.
- **Multiple Discords**: Use the "Select Discord installation" menu to switch between Stable, PTB, Canary, or Snap versions.

### Windows Version
- **Execution policy blocked**: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` in PowerShell as Administrator
- **Script opens and closes immediately**: Run from PowerShell to see error messages
- **Node.js not found**: The script will attempt to install it, but you may need to install manually
- **Discord not detected**: Manually provide the path to the Discord installation
- **Permission issues**: Run as Administrator if needed

## Support
- **Linux Version**: Fully supported - open an issue or send a PR for any problems
- **Windows Version**: Limited support due to experimental status - use at your own risk 