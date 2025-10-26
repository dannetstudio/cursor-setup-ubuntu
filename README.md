# 🚀 Cursor Setup Ubuntu

**Version 2.1.2** - Cursor 2.x Compatibility & Detection Fixes

This repository contains the bash script **cursor-setup-ubuntu**, inspired by the [cursor-setup-wizard](https://github.com/jorcelinojunior/cursor-setup-wizard) repository. This script automatically downloads and installs the latest version of the **Cursor AI AppImage** on Ubuntu and its derivatives. **Cursor AI** is a powerful AI-assisted code editor, available at [cursor.com](https://www.cursor.com).

## 🎉 What's New in v2.1.2

- **✅ Cursor 2.x Support**: Full compatibility with Cursor 2.0.11 and newer 2.x versions
- **🔍 Fixed Version Detection**: Resolved automatic version check failures from cursor-ai-downloads repository
- **🐛 Fixed Installation Detection**: Script now properly detects installed Cursor AppImages (glob pattern fix)
- **⚡ Improved Network Resilience**: More flexible connectivity checks with fallback to Google DNS (8.8.8.8)
- **📊 Better Timeout Handling**: Increased curl timeout from 5s to 10s for slow or unstable connections
- **🛡️ Enhanced Content Validation**: Validates downloaded repository content size (minimum 1KB) before processing
- **🐞 Enhanced Debug Mode**: Extensive debug logging available with `DEBUG_MODE=true` for troubleshooting
- **🔧 Fixed Pattern Expansion**: Removed quotes from glob patterns to allow proper shell expansion in file detection

## 🎉 Previous Release - v2.1.1

- **🔒 Critical Security Fixes**: Fixed unsafe variable expansion and dangerous eval usage
- **🛡️ Enhanced Input Validation**: Comprehensive version checking and security validation
- **🐛 Critical Bug Fixes**: Fixed "target is empty" wrapper script bug (GitHub issue #1)
- **📋 Standardized Exit Codes**: Named constants for better error handling
- **⚡ Optimized Performance**: Improved process detection and atomic operations
- **🔧 Code Quality**: Extracted magic numbers to named configuration constants

## 🎉 Previous Features (v2.1.0)

- **🌍 Automatic Language Detection**: Smart detection of system language (English/Spanish)
- **🔧 Enhanced Configuration**: Extensive environment variable support
- **📊 System Information**: New menu option to display detected settings
- **🎨 Improved Logging**: Colored output with timestamps and debug levels
- **⚡ Better Performance**: Optimized functions and cleaner code architecture

## 🔧 About This Script

The **cursor-setup-ubuntu** script automates the installation, updating, and management of the **Cursor AI AppImage** on Ubuntu-based systems. It provides the following functionalities:

- **Automated Installation & Updates**: Automatically downloads and installs the latest version of Cursor AI.
- **Automatic Downloads**: Downloads the latest version directly from the cursor-ai-downloads repository without manual intervention.
- **Architecture Detection**: Automatically detects and downloads the appropriate AppImage for your system (x64 or ARM64).
- **Version Comparison**: Checks for the latest version and prompts for an update if necessary.
- **Desktop Integration**: Creates or updates a desktop shortcut with an application icon.
- **Executable Symlink Creation**: Allows launching Cursor AI from the terminal.
- **AppArmor Profile Management**: Ensures proper execution security.
- **Automatic Language Detection**: Intelligently detects system language (English/Spanish) from environment variables, directories, and system settings.
- **System Information Display**: Shows detected language, directories, and current installation status.
- **Enhanced Process Management**: Smart detection and handling of running Cursor processes during updates.
- **Flexible Configuration**: Extensive environment variable support for customization.

---

## 🔄 Differences from cursor-setup-wizard

### No GUM Dependency

Unlike the original `cursor-setup-wizard`, this version does not use **GUM** for user interface prompts. All interactions are handled using standard shell commands (e.g., `read`).

### Fully Automated Download

This script automatically downloads the latest version from the [cursor-ai-downloads repository](https://github.com/oslook/cursor-ai-downloads). The script will:

1. Detect your system architecture (x64 or ARM64)
2. Fetch the latest version information from the repository
3. Automatically download the appropriate AppImage for your system
4. Install and configure the application

This ensures you always get the most recent version available, eliminating the need for manual downloads.

### 🔗 Download Source & Trust

#### Official Download Repository
The script automatically downloads Cursor AI AppImages from the **[cursor-ai-downloads repository](https://github.com/oslook/cursor-ai-downloads)** on GitHub. This repository is:

- **Maintained by the community** with official Cursor AI releases
- **Regularly updated** with the latest stable versions
- **Verified source** for Linux AppImage downloads
- **Trusted by the community** for automated installations

#### How Version Detection Works
1. **Repository Query**: The script queries the `README.md` file from `cursor-ai-downloads`
2. **Version Extraction**: Parses the latest version number using pattern matching
3. **Architecture Detection**: Determines your system (x64/ARM64) automatically
4. **URL Construction**: Builds the correct download URL for your specific version and architecture
5. **Secure Download**: Downloads directly from GitHub's CDN for fast and reliable transfers

#### Version Format
The script recognizes and handles Cursor versions in the format: `Cursor-X.Y.Z`
- **X**: Major version (e.g., 1, 2, 3...)
- **Y**: Minor version (e.g., 0, 1, 2...)
- **Z**: Patch version (e.g., 0, 1, 5, 11...)

#### Security & Verification
- **SHA256 Checksums**: The repository provides checksums for verification
- **Official Builds**: Downloads come from official Cursor AI builds
- **GitHub CDN**: Downloads use GitHub's secure content delivery network
- **Transparent Process**: You can manually verify the download URLs before installation

#### How Version Detection & Download Works

The script uses a **two-step process** for security and reliability:

1. **Version Detection** (from GitHub repository):
   - Fetches version information from `cursor-ai-downloads` repository
   - Extracts the latest version number from the repository's README
   - **No downloads** happen from this repository - only metadata

2. **Actual Download** (from official Cursor servers):
   - Uses the version info to construct official download URLs
   - Downloads directly from `downloads.cursor.com` (official CDN)
   - Validates file integrity after download

**Example Process:**
```
1. Check https://github.com/oslook/cursor-ai-downloads → Finds version 1.5.6
2. Download from https://downloads.cursor.com/production/.../Cursor-1.5.6-x86_64.AppImage
```

**Manual Verification**: You can visit the [cursor-ai-downloads repository](https://github.com/oslook/cursor-ai-downloads) to see the latest available versions and verify the download URLs that the script will use.

### Language Support

The script now **automatically detects** your system language using multiple methods:

#### Auto-Detection Methods (in order of priority):
1. **Environment Variables**: `LANG` and `LANGUAGE` variables
2. **Directory Existence**: Checks for `~/Escritorio` or `~/Desktop`
3. **System Locale**: Uses `locale` command output
4. **GNOME/KDE Settings**: Reads `~/.config/user-dirs.dirs`

#### Directory Mapping:
- **English (EN):**
  - Downloads folder: `~/Downloads`
  - Desktop folder: `~/Desktop`
- **Spanish (ES):**
  - Downloads folder: `~/Descargas`
  - Desktop folder: `~/Escritorio`

#### Manual Override:
You can override auto-detection by setting the `LANG_SETTING` environment variable:
```bash
LANG_SETTING=EN ./cursor-setup-ubuntu.sh  # Force English
LANG_SETTING=ES ./cursor-setup-ubuntu.sh  # Force Spanish
```

The script will show which language was detected during the system requirements check.

---

## 📥 Installation

### Clone the Repository or Download the Script

#### Clone via Git:

```bash
git clone https://github.com/dannetstudio/cursor-setup-ubuntu.git
cd cursor-setup-ubuntu
```

#### Download the Script Manually:

```bash
wget https://raw.githubusercontent.com/dannetstudio/cursor-setup-ubuntu/main/cursor-setup-ubuntu.sh
```

### Make the Script Executable

```bash
chmod +x cursor-setup-ubuntu.sh
```

### Run the Script

The script automatically detects your system language (English/Spanish) and configures directories accordingly. You can override auto-detection by setting the `LANG_SETTING` environment variable if needed.

Execute the script:

```bash
./cursor-setup-ubuntu.sh
```

Once installed for the first time, an alias `cursor-setup-ubuntu` will be created for easy future access. To make it available in your current session, run:

```bash
source ~/.bashrc  # For Bash users
source ~/.zshrc   # For Zsh users
```

After this, you can run the script anytime with:

```bash
cursor-setup-ubuntu
```

You will be presented with a text-based menu offering the following options:

1. **Check for Updates & Install/Update Cursor** - Intelligently checks your current installation, compares with the latest version, and only downloads/installs if necessary
2. **Update Desktop Shortcut** - Creates or updates the desktop shortcut and icon (useful if you manually moved the AppImage)
3. **Show System Information** - Displays detected language, directories, and system settings
4. **Exit** - Exit the script

---

## 🚀 Usage

### Intelligent Installation & Update Process

The script uses an intelligent process that avoids unnecessary downloads:

#### First-Time Installation:
1. **Check Installation**: Detects that Cursor is not installed
2. **Fetch Latest Version**: Queries the latest version from the repository
3. **Download Confirmation**: Asks if you want to download the latest version
4. **Smart Download**: Downloads only if you confirm
5. **Installation**: Installs and configures the application

#### Update Process:
1. **Check Current Version**: Detects your currently installed version
2. **Compare Versions**: Compares with the latest available version
3. **Update Assessment**:
   - **Up to date**: Shows success message, no download needed
   - **Update available**: Shows version difference and asks for confirmation
   - **Not installed**: Offers fresh installation
4. **Selective Download**: Downloads only if update is needed and confirmed
5. **Smart Installation**: Handles file conflicts and creates backups automatically

#### Key Benefits:
- **No unnecessary downloads** - Only downloads when needed
- **Bandwidth efficient** - Avoids re-downloading the same version
- **User control** - Always asks before downloading large files
- **Intelligent detection** - Knows your current installation status

### 🖥️ Desktop Shortcut & Executable Symlink

- The script creates or updates a desktop shortcut that launches the AppImage with the `--no-sandbox` flag.

- A wrapper script is generated, and a symlink is set up in `/usr/local/bin` so you can launch the AppImage from the terminal using `cursor`.

- A single alias (`cursor-setup-ubuntu`) is also created for easy future access to the script.

- The script ensures compatibility with **bashrc** and **zshrc**, so users can execute commands seamlessly from both Bash and Zsh shells.

### 🔄 Intelligent Update Handling

When updating Cursor, the script intelligently handles situations where the AppImage file is currently in use:

- **Automatic Detection**: Uses `lsof` to detect if the current AppImage is being used by running processes
- **Safe Backup**: Creates timestamped backups before replacing files
- **Process Management**: Offers to terminate conflicting processes (with user confirmation)
- **Graceful Handling**: If you run the script from within Cursor, it will detect this and ask for confirmation

**Note**: If running the script from within Cursor, it will detect that the AppImage is in use and offer to terminate the process. This is normal behavior and ensures safe updates.

---

## 🔧 Configuration

The script supports various environment variables for customization:

### Language Settings
```bash
LANG_SETTING=ES              # Force Spanish (ES) or English (EN)
                             # If not set, auto-detection is used
```

### Logging & Debug
```bash
LOG_COLORS=true             # Enable/disable colored output
DEBUG_MODE=false            # Enable debug logging
```

### Timeouts & Performance
```bash
MENU_TIMEOUT=300            # Menu timeout in seconds (default: 300)
CONFIRMATION_TIMEOUT=60     # Confirmation prompt timeout (default: 60)
DOWNLOAD_TIMEOUT=300        # Download timeout (default: 300)
CURL_TIMEOUT=5              # Repository query timeout (default: 5)
CURL_PING_TIMEOUT=2         # Connectivity test timeout (default: 2)
MAX_RETRY_ATTEMPTS=3        # Maximum retry attempts (default: 3)
```

### Custom URLs (Advanced)
```bash
CURSOR_REPO_URL="https://..."                    # Override repository URL
CURSOR_DOWNLOAD_BASE_URL="https://..."           # Override download base URL
```

## 🛠️ Requirements

- **Operating System:** Ubuntu or Ubuntu-based distributions (e.g., Xubuntu, Kubuntu, Linux Mint, etc.)
- **Tools Required:** `curl`, `sudo`, and standard shell utilities.
- **Permissions:** Ability to modify files in `/etc/apparmor.d/` and create symlinks in `/usr/local/bin/`.

---

## 💡 Inspiration

This project is not affiliated with Cursor AI. It is an independent effort to improve the installation and update experience on Linux, addressing common setup steps and potential issues.

This script is inspired by the original `cursor-setup-wizard` project and has been adapted to automatically download the latest version on Ubuntu without using GUM.

## 🤝 Contributing

Contributions are welcome! If you have improvements or suggestions, please open an issue or submit a pull request.

---

## ✍️ Author

This script was created by **Daniel Ignacio Fernández** ([https://dannetstudio.com](https://dannetstudio.com)).

