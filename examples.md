# 🚀 Cursor Setup Ubuntu - Examples & Usage Guide

This document provides examples and explanations of the enhanced features in the Cursor Setup Ubuntu script.

## 🌍 Language Auto-Detection Examples

### How Language Detection Works

The script automatically detects your system language using multiple methods:

#### Example 1: Spanish System (LANG=es_ES.UTF-8)
```bash
$ ./cursor-setup-ubuntu.sh
[2024-01-15 10:30:15] INFO: System compatible: Ubuntu 22.04.3 LTS
[2024-01-15 10:30:15] INFO: Language detected: ES (ES)
[2024-01-15 10:30:15] INFO: Desktop directory: /home/user/Escritorio
[2024-01-15 10:30:15] INFO: Downloads directory: /home/user/Descargas
```

#### Example 2: English System (LANG=en_US.UTF-8)
```bash
$ ./cursor-setup-ubuntu.sh
[2024-01-15 10:30:15] INFO: System compatible: Ubuntu 22.04.3 LTS
[2024-01-15 10:30:15] INFO: Language detected: EN (EN)
[2024-01-15 10:30:15] INFO: Desktop directory: /home/user/Desktop
[2024-01-15 10:30:15] INFO: Downloads directory: /home/user/Downloads
```

### Manual Language Override

You can override auto-detection by setting the `LANG_SETTING` environment variable:

```bash
# Force Spanish
LANG_SETTING=ES ./cursor-setup-ubuntu.sh

# Force English
LANG_SETTING=EN ./cursor-setup-ubuntu.sh
```

## 🔧 Configuration Examples

### Custom Timeouts
```bash
# Faster timeouts for quick testing
MENU_TIMEOUT=60 CONFIRMATION_TIMEOUT=30 ./cursor-setup-ubuntu.sh

# Longer timeouts for slow connections
DOWNLOAD_TIMEOUT=600 CURL_TIMEOUT=10 ./cursor-setup-ubuntu.sh
```

### Debug Mode
```bash
# Enable debug logging
DEBUG_MODE=true ./cursor-setup-ubuntu.sh
```

### Disable Colors
```bash
# For terminals that don't support colors
LOG_COLORS=false ./cursor-setup-ubuntu.sh
```

## 📊 System Information Display

The script now shows detailed system information during startup:

```
=== System Information ===
Operating System: Linux 6.2.0-39-generic
Architecture: x86_64
Auto-detected Language: ES
Using Language Setting: ES
Desktop Directory: /home/user/Escritorio
Downloads Directory: /home/user/Descargas
LANG Environment: es_ES.UTF-8
LANGUAGE Environment: es_ES:es
Currently Installed: Cursor v1.5.6
```

## 🔍 Version Detection & Download Process

### Two-Step Process Explained

1. **Version Detection** (from GitHub repository):
   ```bash
   # Script fetches from: https://github.com/oslook/cursor-ai-downloads
   # Extracts version info from repository metadata
   # NO downloads happen from GitHub repository
   ```

2. **Actual Download** (from official servers):
   ```bash
   # Downloads from: https://downloads.cursor.com/production/...
   # Uses official Cursor CDN for fast, secure downloads
   # Validates file integrity after download
   ```

### Example Process Output:
```
[2024-01-15 10:30:20] INFO: Version information obtained from cursor-ai-downloads repository
[2024-01-15 10:30:20] INFO: Latest stable version: 1.5.6
[2024-01-15 10:30:20] INFO: Downloading file: Cursor-1.5.6-x86_64.AppImage
[2024-01-15 10:30:20] INFO: Download URL: https://downloads.cursor.com/production/.../Cursor-1.5.6-x86_64.AppImage
[2024-01-15 10:30:25] SUCCESS: Downloaded and validated file: /home/user/Descargas/Cursor-1.5.6-x86_64.AppImage
```

## 🛠️ Troubleshooting Examples

### Network Issues
```bash
# If you have connectivity problems
CURL_TIMEOUT=10 MAX_RETRY_ATTEMPTS=5 ./cursor-setup-ubuntu.sh
```

### Permission Issues
```bash
# If you get permission errors
sudo -E ./cursor-setup-ubuntu.sh  # Preserve environment variables
```

### Language Detection Issues
```bash
# Check what language is detected
DEBUG_MODE=true ./cursor-setup-ubuntu.sh
# Look for: "Language detected: XX"
```

## 📋 Menu Options

The enhanced menu now includes:

1. **Check for Updates & Install/Update Cursor**
   - Intelligent version comparison
   - Only downloads when needed
   - Smart process detection

2. **Update Desktop Shortcut**
   - Recreates desktop icon
   - Updates AppArmor profile
   - Refreshes executable symlink

3. **Show System Information**
   - Displays detected language
   - Shows directory paths
   - Lists environment variables
   - Shows current installation status

4. **Exit**
   - Clean exit with proper cleanup

## 🎯 Advanced Usage

### Custom Repository URL
```bash
# Use a different repository for version info
CURSOR_REPO_URL="https://your-custom-repo.com/README.md" ./cursor-setup-ubuntu.sh
```

### Custom Download URL
```bash
# Use a different download source (advanced users only)
CURSOR_DOWNLOAD_BASE_URL="https://your-cdn.com/cursor/" ./cursor-setup-ubuntu.sh
```

### Batch Mode (Non-Interactive)
```bash
# For automation scripts (be careful!)
echo "1" | timeout 300 ./cursor-setup-ubuntu.sh
```

## 🔒 Security Features

- **Official Downloads**: Only downloads from official Cursor servers
- **File Validation**: Checks file size and format
- **Process Detection**: Prevents conflicts during updates
- **Backup System**: Automatic backups before replacement
- **URL Validation**: Verifies download URLs before use

## 📝 Logging Levels

The script supports different logging levels:

```bash
# Show only errors and important messages
./cursor-setup-ubuntu.sh

# Show debug information
DEBUG_MODE=true ./cursor-setup-ubuntu.sh

# Disable colors for log files
LOG_COLORS=false ./cursor-setup-ubuntu.sh 2>&1 | tee install.log
```
