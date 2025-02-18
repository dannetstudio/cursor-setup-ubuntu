# 🚀 Cursor Setup Ubuntu

This repository contains the bash script **cursor-setup-ubuntu**, inspired by the [cursor-setup-wizard](https://github.com/jorcelinojunior/cursor-setup-wizard) repository. This version supports both **Stable** and **Nightly** modes for installing and configuring the **Cursor AI AppImage** on Ubuntu and its derivatives. **Cursor AI** is a powerful AI-assisted code editor, available at [cursor.com](https://www.cursor.com).

## 🔧 About This Script

The **cursor-setup-ubuntu** script automates the installation, updating, and management of the **Cursor AI AppImage** on Ubuntu-based systems. It provides the following functionalities:

- **Automated Installation & Updates**: Install or update either the latest **Stable** or **Nightly** version of Cursor AI.
- **Simultaneous Installations**: Allows both **Stable** and **Nightly** versions to coexist on the same system.
- **Version Comparison**: Checks for the latest version and prompts for an update if necessary.
- **Desktop Integration**: Creates or updates a desktop shortcut with an application icon.
- **Executable Symlink Creation**: Allows launching Cursor AI from the terminal.
- **AppArmor Profile Management**: Ensures proper execution security.
- **Language Customization**: Supports English (`EN`) and Spanish (`ES`) for defining download and desktop directory locations.

---

## 🔄 Differences from cursor-setup-wizard

### No GUM Dependency

Unlike the original `cursor-setup-wizard`, this version does not use **GUM** for user interface prompts. All interactions are handled using standard shell commands (e.g., `read`).

### Support for Nightly/Beta Mode

This script supports both **Stable** and **Nightly** (beta) installations. In **Nightly mode**, it automatically downloads the latest version from the official source.

### Manual Stable Download

Since Cursor AI releases stable versions in stages, the **Stable** download is not automated. You must manually download the Stable AppImage from [Cursor AI's official website](https://www.cursor.com/) and provide the filename when prompted. This ensures that you install the version you want, as the website may sometimes offer an older version than the one already installed.

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

Before running the script, open `cursor-setup-ubuntu.sh` and verify the `LANG_SETTING="EN"` variable. Set it to either `EN` (English) or `ES` (Spanish) to ensure the correct directory paths are used.

```bash
nano cursor-setup-ubuntu.sh  # Edit this line if needed
```

After verifying the language setting, execute the script:

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

1. **Install or update Cursor AI AppImage** (Choose between Stable and Nightly modes)
2. **Create or update the desktop shortcut**
3. **Exit the script**

---

## 🚀 Usage

### Stable Mode

1. Download the Stable AppImage from [Cursor AI's website](https://www.cursor.com/) (click the "Download" button).
2. When prompted, enter only the filename (e.g., `cursor-0.45.11-x86_64.AppImage`). The file must be located in your `Downloads` folder.
3. The script will install and configure the application accordingly.

### Nightly Mode

1. The script will automatically download the latest Nightly AppImage from [Cursor AI's Nightly builds](https://nightlymagic.cursor.sh/).
2. It will compare the installed version (if any) with the new version.
3. You will be prompted to either update, reinstall, or cancel the operation.

### Simultaneous Installation of Stable and Nightly Versions

- Both **Stable** and **Nightly** versions can be installed and used simultaneously without conflicts.
- The script maintains separate installations:
  - **Stable version:** Launched with `cursor`
  - **Nightly version:** Launched with `cursor-nightly`

### 🖥️ Desktop Shortcut & Executable Symlink

- The script creates or updates a desktop shortcut that launches the AppImage with the `--no-sandbox` flag.

- A wrapper script is generated, and a symlink is set up in `/usr/local/bin` so you can launch the AppImage from the terminal:

  - **For Stable:** `cursor`
  - **For Nightly:** `cursor-nightly`

- A single alias (`cursor-setup-ubuntu`) is also created for easy future access to the script.

- The script ensures compatibility with **bashrc** and **zshrc**, so users can execute commands seamlessly from both Bash and Zsh shells.

- The script creates or updates a desktop shortcut that launches the AppImage with the `--no-sandbox` flag.

- A wrapper script is generated, and a symlink is set up in `/usr/local/bin` so you can launch the AppImage from the terminal:

  - **For Stable:** `cursor`
  - **For Nightly:** `cursor-nightly`

- A single alias (`cursor-setup-ubuntu`) is also created for easy future access to the script.

---

## 🛠️ Requirements

- **Operating System:** Ubuntu or Ubuntu-based distributions (e.g., Xubuntu, Kubuntu, Linux Mint, etc.)
- **Tools Required:** `curl`, `sudo`, and standard shell utilities.
- **Permissions:** Ability to modify files in `/etc/apparmor.d/` and create symlinks in `/usr/local/bin/`.

---

## 💡 Inspiration

This project is not affiliated with Cursor AI. It is an independent effort to improve the installation and update experience on Linux, addressing common setup steps and potential issues.

This script is inspired by the original `cursor-setup-wizard` project and has been adapted to support both Stable and Nightly modes on Ubuntu without using GUM.

## 🤝 Contributing

Contributions are welcome! If you have improvements or suggestions, please open an issue or submit a pull request.

---

## ✍️ Author

This script was created by **Daniel Ignacio Fernández** ([https://dannetstudio.com](https://dannetstudio.com)).

