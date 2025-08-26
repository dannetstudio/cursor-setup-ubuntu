# 🚀 Cursor Setup Ubuntu

This repository contains the bash script **cursor-setup-ubuntu**, inspired by the [cursor-setup-wizard](https://github.com/jorcelinojunior/cursor-setup-wizard) repository. This script automatically downloads and installs the latest version of the **Cursor AI AppImage** on Ubuntu and its derivatives. **Cursor AI** is a powerful AI-assisted code editor, available at [cursor.com](https://www.cursor.com).

## 🔧 About This Script

The **cursor-setup-ubuntu** script automates the installation, updating, and management of the **Cursor AI AppImage** on Ubuntu-based systems. It provides the following functionalities:

- **Automated Installation & Updates**: Automatically downloads and installs the latest version of Cursor AI.
- **Automatic Downloads**: Downloads the latest version directly from the cursor-ai-downloads repository without manual intervention.
- **Architecture Detection**: Automatically detects and downloads the appropriate AppImage for your system (x64 or ARM64).
- **Version Comparison**: Checks for the latest version and prompts for an update if necessary.
- **Desktop Integration**: Creates or updates a desktop shortcut with an application icon.
- **Executable Symlink Creation**: Allows launching Cursor AI from the terminal.
- **AppArmor Profile Management**: Ensures proper execution security.
- **Language Customization**: Supports English (`EN`) and Spanish (`ES`) for defining download and desktop directory locations.

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

**Manual Verification**: You can visit the [cursor-ai-downloads repository](https://github.com/oslook/cursor-ai-downloads) to see the latest available versions and verify the download URLs that the script will use.

### Language Support

You can define the language to determine where the script will store and manage files. Set `LANG_SETTING` to `EN` for English or `ES` for Spanish. Depending on the chosen language, download and desktop directories will be assigned accordingly:

- **English (EN):**
  - Downloads folder: `~/Downloads`
  - Desktop folder: `~/Desktop`
- **Spanish (ES):**
  - Downloads folder: `~/Descargas`
  - Desktop folder: `~/Escritorio`

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

The script is ready to use with English language settings by default. If you prefer Spanish, you can optionally modify the `LANG_SETTING` variable in the script.

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
3. **Exit** - Exit the script

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

