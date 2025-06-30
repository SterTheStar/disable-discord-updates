# Discord ASAR Patch

This script automates the patching and restoration process of Discord's `app.asar` file on Linux systems, allowing you to safely and reversibly modify Discord's behavior.

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
- Linux (Arch, Debian/Ubuntu, Fedora, openSUSE)
- Superuser permissions (sudo)
- Discord installed via the official package or Snap

## How to Use

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
- **Permission denied**: Run the script as a user with sudo privileges.
- **Discord not found**: Manually provide the path to the folder containing `app.asar` when prompted.
- **Problems after patching**: Use the restore option to revert to the original.
- **Multiple Discords**: Use the "Select Discord installation" menu to switch between Stable, PTB, Canary, or Snap versions.

## Support
If you need support for other distributions or encounter any issues, open an issue or send a PR! 