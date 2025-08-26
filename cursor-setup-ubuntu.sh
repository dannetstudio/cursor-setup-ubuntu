#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------------------
# Use the real user's home directory even when running with sudo
# -------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ]; then
  readonly REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  readonly REAL_HOME="$HOME"
fi

# -------------------------------------------------------------------
# Define language (set to "EN" for English or "ES" for Spanish)
# -------------------------------------------------------------------
readonly LANG_SETTING="EN"

# Set language-dependent paths using the real user's home directory
if [[ "$LANG_SETTING" == "EN" ]]; then
  readonly USER_DESKTOP_DIR="$REAL_HOME/Desktop"
  readonly USER_DOWNLOADS_DIR="$REAL_HOME/Downloads"
else
  readonly USER_DESKTOP_DIR="$REAL_HOME/Escritorio"
  readonly USER_DOWNLOADS_DIR="$REAL_HOME/Descargas"
fi



# -------------------------------------------------------------------
# Simple logging function: prints messages with a prefix
# -------------------------------------------------------------------
logg() {
  local TYPE="$1"
  local MSG="$2"
  case "$TYPE" in
    error)   echo "ERROR: $MSG" ;;
    info)    echo "INFO: $MSG" ;;
    prompt)  echo "PROMPT: $MSG" ;;
    success) echo "SUCCESS: $MSG" ;;
    warn)    echo "WARNING: $MSG" ;;
    *)       echo "$MSG" ;;
  esac
}

# -------------------------------------------------------------------
# Simple delay with message
# -------------------------------------------------------------------
show_message() {
  local message="$1"
  echo "$message"
}



# -------------------------------------------------------------------
# Remove older versions, keeping only the newest one.
# -------------------------------------------------------------------
remove_old_versions() {
  local newest_file
  newest_file=$(ls -1t $APPIMAGE_PATTERN 2>/dev/null | head -n 1 || true)
  if [[ -n "$newest_file" ]]; then
    local older_files
    older_files=$(ls -1t $APPIMAGE_PATTERN 2>/dev/null | tail -n +2 || true)
    if [[ -n "$older_files" ]]; then
      logg info "Removing older versions in $DOWNLOAD_DIR..."
      rm -f $older_files
    fi
  fi
}

# -------------------------------------------------------------------
# Confirmation function (YES/NO) using read.
# Returns 0 if answer is yes, 1 if no.
# -------------------------------------------------------------------
confirm_action() {
  local question="$1"
  read -rp "$question [y/N]: " response
  [[ "$response" =~ ^[Yy]$ ]]
}



# -------------------------------------------------------------------
# Detect system architecture (x86_64 or aarch64)
# -------------------------------------------------------------------
detect_architecture() {
  local arch
  arch=$(uname -m)
  case "$arch" in
    x86_64)
      echo "x64"
      ;;
    aarch64)
      echo "arm64"
      ;;
    *)
      logg error "Unsupported architecture: $arch"
      return 1
      ;;
  esac
  return 0
}

# -------------------------------------------------------------------
# Get latest stable version from cursor-ai-downloads repository
# -------------------------------------------------------------------
get_latest_stable_version() {
  local repo_content
  repo_content=$(curl -s --max-time 10 \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
    https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/README.md)

  if [[ -z "$repo_content" ]]; then
    return 1
  fi

  # Extract the latest version from the main download link
  local latest_version
  latest_version=$(echo "$repo_content" | grep -oE "Cursor [0-9]+\.[0-9]+\.[0-9]+" | head -1 | sed 's/Cursor //')

  if [[ -z "$latest_version" ]]; then
    return 1
  fi

  printf "%s" "$latest_version"
  return 0
}

# -------------------------------------------------------------------
# Download the latest stable AppImage from cursor-ai-downloads repository
# -------------------------------------------------------------------
download_latest_stable() {
  logg prompt "Checking latest stable version from cursor-ai-downloads repository..."

  local arch
  arch=$(detect_architecture)
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  
  local latest_version
  latest_version=$(get_latest_stable_version)
  if [[ $? -ne 0 ]]; then
    logg error "Could not fetch repository content."
    return 1
  fi
  
  local filename="Cursor-$latest_version"
  if [[ "$arch" == "x64" ]]; then
    filename="${filename}-x86_64.AppImage"
  else
    filename="${filename}-aarch64.AppImage"
  fi

  local url="https://downloads.cursor.com/production/823f58d4f60b795a6aefb9955933f3a2f0331d7b/linux/$arch/$filename"

  logg info "Latest stable version: $latest_version"
  logg info "Downloading file: $filename"
  logg info "Download URL: $url"
  
  pushd "$USER_DOWNLOADS_DIR" >/dev/null
  
  if [[ -f "$filename" ]]; then
    logg info "File $filename already exists. Removing old version..."
    rm -f "$filename"
  fi

  curl -L -o "$filename" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" "$url"

  if [[ ! -f "$filename" ]]; then
    popd >/dev/null
    logg error "Failed to download the stable file."
    return 1
  fi
  
  popd >/dev/null
  
  # Update global variable to point to the downloaded file
  LOCAL_APPIMAGE_PATH="$USER_DOWNLOADS_DIR/$filename"
  logg success "Downloaded file: $LOCAL_APPIMAGE_PATH"
  return 0
}

# -------------------------------------------------------------------
# Common variables and constants
# -------------------------------------------------------------------
readonly DOWNLOAD_DIR="$REAL_HOME/.AppImage"
readonly ICON_DIR="$REAL_HOME/.local/share/icons"
readonly ICON_URL="https://mintlify.s3-us-west-1.amazonaws.com/cursor/images/logo/app-logo.svg"
readonly CLI_COMMAND_NAME="cursor"
readonly USER_DESKTOP_FILE="$USER_DESKTOP_DIR/cursor.desktop"
readonly SYSTEM_DESKTOP_FILE="$REAL_HOME/.local/share/applications/cursor.desktop"
readonly DESKTOP_NAME="Cursor"
readonly APPARMOR_PROFILE="/etc/apparmor.d/cursor-appimage"
readonly SCRIPT_ALIAS_NAME="cursor-setup-ubuntu"
readonly APPIMAGE_PATTERN="$DOWNLOAD_DIR/Cursor-[0-9]*.AppImage"

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"

# Global variable for the AppImage path (will be set by download functions)
LOCAL_APPIMAGE_PATH=""

# -------------------------------------------------------------------
# Function to extract version from the AppImage filename
# -------------------------------------------------------------------
extract_version() {
  local filename="$1"
  if [[ "$filename" =~ Cursor-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    printf "%s" "${BASH_REMATCH[1]}"
      return
  fi
  printf "unknown"
}

# -------------------------------------------------------------------
# Function to update the executable symlink in /usr/local/bin.
# It creates a wrapper script that launches the AppImage with "--no-sandbox".
# -------------------------------------------------------------------
update_executable_symlink() {
  local target="$DOWNLOAD_DIR/$(basename "$LOCAL_APPIMAGE_PATH")"
  local wrapper="$DOWNLOAD_DIR/wrapper-${CLI_COMMAND_NAME}.sh"
  local link="/usr/local/bin/${CLI_COMMAND_NAME}"
  logg info "Creating wrapper script: $wrapper"
  cat > "$wrapper" <<EOF
#!/usr/bin/env bash
# Wrapper to launch the AppImage with --no-sandbox
if [ -z "$target" ]; then
  echo "Error: target is empty."
  exit 1
fi
echo "Launching AppImage: $target"
"\$target" --no-sandbox "\$@"
EOF
  chmod +x "$wrapper"
  logg info "Updating executable symlink: $link -> $wrapper"
  if sudo test -L "$link" || sudo test -f "$link"; then
    sudo rm -f "$link"
  fi
  sudo ln -s "$wrapper" "$link"
  logg success "Symlink updated: $link -> $wrapper"
}

# -------------------------------------------------------------------
# Function to update the desktop shortcut and icon
# -------------------------------------------------------------------
update_desktop_shortcut() {
  logg info "Updating desktop shortcut and icon..."
  mkdir -p "$ICON_DIR"
  curl -L -o "$ICON_DIR/cursor.svg" "$ICON_URL"
  cat > "$USER_DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=$DESKTOP_NAME
Exec=$DOWNLOAD_DIR/$(basename "$LOCAL_APPIMAGE_PATH") --no-sandbox
Icon=$ICON_DIR/cursor.svg
Type=Application
Categories=Utility;
EOF
  mkdir -p "$(dirname "$SYSTEM_DESKTOP_FILE")"
  cp "$USER_DESKTOP_FILE" "$SYSTEM_DESKTOP_FILE"
  logg success "Desktop shortcut updated at: $USER_DESKTOP_FILE and $SYSTEM_DESKTOP_FILE"
}

# -------------------------------------------------------------------
# Function to update the AppArmor profile.
# It writes an embedded profile to the specified file and reloads it.
# -------------------------------------------------------------------
update_apparmor_profile() {
  logg info "Updating AppArmor profile..."
  if ! sudo -v; then
    logg error "Sudo privileges are required to update the AppArmor profile."
    return 1
  fi
  local APPARMOR_PROFILE_CONTENT="
#include <tunables/global>
profile cursor-appimage flags=(attach_disconnected,mediate_deleted) {
    /home/*/.AppImage/Cursor-*.AppImage ix,
    /etc/{passwd,group,shadow} r,
    /usr/bin/env rix,
    /usr/bin/{bash,sh} rix,
}
"
  echo "$APPARMOR_PROFILE_CONTENT" | sudo tee "$APPARMOR_PROFILE" >/dev/null
  logg info "Profile copied to $APPARMOR_PROFILE"
  sudo apparmor_parser -r "$APPARMOR_PROFILE"
  logg success "AppArmor profile updated and reloaded."
}

# -------------------------------------------------------------------
# Function to install the AppImage:
# - Copy the file to DOWNLOAD_DIR
# - Set executable permissions
# - Update desktop shortcut and icon
# - Update AppArmor profile
# - Update executable symlink in /usr/local/bin
# -------------------------------------------------------------------
install_appimage() {
  local file="$1"
  local filename
  filename=$(basename "$file")
  local target_path="$DOWNLOAD_DIR/$filename"

  logg info "Installing AppImage: $file"

  mkdir -p "$DOWNLOAD_DIR"

  # Check if target file already exists and is busy
  if [[ -f "$target_path" ]]; then
    logg info "Target file exists, checking if it's in use..."

    # Try to find processes using the file
    local pids_using_file
    pids_using_file=$(lsof "$target_path" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u || true)

    if [[ -n "$pids_using_file" ]]; then
      logg warn "File is currently in use by processes: $pids_using_file"
      if confirm_action "Terminate processes using the file and continue?"; then
        for pid in $pids_using_file; do
          if kill -TERM "$pid" 2>/dev/null; then
            logg info "Terminated process $pid"
            sleep 2
          fi
        done
      else
        logg info "Installation cancelled by user."
        return 1
      fi
    fi

    # Backup existing file before replacement
    local backup_file="$target_path.backup.$(date +%Y%m%d_%H%M%S)"
    logg info "Creating backup: $backup_file"
    mv "$target_path" "$backup_file"
  fi

  # Copy the new file
  if cp "$file" "$target_path"; then
    chmod +x "$target_path"
  # Update global variable to point to the installed file
    LOCAL_APPIMAGE_PATH="$target_path"
    logg success "AppImage installed to $target_path"

    # Remove old versions (excluding the backup we just created)
    remove_old_versions

    # Update system integration
  update_desktop_shortcut
  update_apparmor_profile
  update_executable_symlink

    logg success "Installation completed successfully!"
  else
    logg error "Failed to install AppImage. You may need to close Cursor and try again."
    return 1
  fi
}

# -------------------------------------------------------------------
# Function to compare the installed version with the new version and act accordingly
# -------------------------------------------------------------------
check_version() {
  # Check current installation status
  local installed_version
  installed_version=$(check_cursor_installation)

  # Log installation status
  if [[ -n "$installed_version" ]]; then
    logg info "Cursor is already installed (version: $installed_version)"
  else
    logg info "Cursor is not installed on this system"
  fi

  # Check for updates
  local latest_version
  latest_version=$(check_for_updates "$installed_version")
  local update_status=$?

  case $update_status in
    0)  # Update available or installation needed
      if handle_download_decision "$latest_version" "$installed_version"; then
        # Download was successful, now install
        if [[ -f "$LOCAL_APPIMAGE_PATH" ]]; then
          install_appimage "$LOCAL_APPIMAGE_PATH"
        else
          logg error "Download completed but AppImage file not found."
          return 1
        fi
      fi
      ;;
    1)  # Error checking for updates
      logg error "Could not check for updates. Please try again later."
      ;;
    2)  # No update needed
      logg success "Your Cursor installation is up to date!"
      ;;
  esac
}



# -------------------------------------------------------------------
# Validate the operating system (must be Ubuntu or derivative)
# -------------------------------------------------------------------
validate_os() {
  show_message "Checking system compatibility..."
  local os_name
  os_name=$(grep -i '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
  if ! grep -iqE "ubuntu|kubuntu|xubuntu|lubuntu|pop!_os|elementary|zorin|linux mint" /etc/os-release; then
    logg error "This script is intended for Ubuntu and its derivatives. Detected: $os_name. Exiting..."
    exit 1
  fi
  logg success "System compatible: $os_name"
}

# -------------------------------------------------------------------
# Create an alias for this script in the user's shell RC files
# -------------------------------------------------------------------
install_script_alias() {
  local alias_command="alias ${SCRIPT_ALIAS_NAME}=\"$SCRIPT_PATH\""
  local alias_added=false
  local rc_files=("$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc")
  for rc_file in "${rc_files[@]}"; do
    if [[ -f "$rc_file" && ! $(grep -Fx "$alias_command" "$rc_file" 2>/dev/null) ]]; then
      echo -e "\n\n# Alias for the $DESKTOP_NAME Setup Wizard\n$alias_command\n" >>"$rc_file"
      alias_added=true
      if [[ "$SHELL" == *"${rc_file##*.}" ]]; then
        eval "$alias_command"
      fi
    fi
  done
  if [[ "$alias_added" == true ]]; then
    logg success "Alias created and defined: ${SCRIPT_ALIAS_NAME}"
  fi
}

# -------------------------------------------------------------------
# Main menu (text-based, loops until exit)
# -------------------------------------------------------------------
menu() {
  while true; do
    echo
    echo "=== Cursor Setup Menu ==="
    echo "1) Check for Updates & Install/Update Cursor"
    echo "2) Update Desktop Shortcut Only"
    echo "3) Exit"
    read -rp "Select option [1-3]: " choice
    case "$choice" in
      1) check_version ;;
      2) update_desktop_shortcut ;;
      3|"") logg info "Exiting..."; exit 0 ;;
      *) logg error "Invalid option. Please choose 1-3." ;;
    esac
  done
}

# -------------------------------------------------------------------
# Function to check if Cursor is already installed and get version info
# -------------------------------------------------------------------
check_cursor_installation() {
  local installed_file
  installed_file=$(ls -1t $APPIMAGE_PATTERN 2>/dev/null | head -n 1 || true)

  if [[ -n "$installed_file" ]]; then
    local installed_version
    installed_version=$(extract_version "$(basename "$installed_file")")
    # Return version without logging (logging will be done by caller)
    echo "$installed_version"
  else
    # Return empty string for not installed
    echo ""
  fi
}

# -------------------------------------------------------------------
# Function to compare versions and determine if update is needed
# -------------------------------------------------------------------
check_for_updates() {
  local installed_version="$1"

  logg prompt "Checking for updates from cursor-ai-downloads repository..."

  local latest_version
  latest_version=$(get_latest_stable_version)
  if [[ $? -ne 0 ]]; then
    logg error "Could not fetch latest version information."
    return 1
  fi

  # Return version and status without additional logging
  # (logging will be handled by caller for cleaner output)

  if [[ -n "$installed_version" ]]; then
    if [[ "$installed_version" == "$latest_version" ]]; then
      return 2  # No update needed
    else
      echo "$latest_version"
      return 0  # Update available
    fi
  else
    echo "$latest_version"
    return 0  # Installation needed
  fi
}

# -------------------------------------------------------------------
# Function to handle the download decision
# -------------------------------------------------------------------
handle_download_decision() {
  local latest_version="$1"
  local installed_version="$2"

  # Build action message
  local action_message
  if [[ -z "$installed_version" ]]; then
    action_message="install Cursor $latest_version"
  else
    action_message="update from $installed_version to $latest_version"
  fi

  # Show current status clearly
  if [[ -n "$installed_version" ]]; then
    logg info "Update available: $installed_version → $latest_version"
  else
    logg info "Latest version available: $latest_version"
  fi

  # Ask for confirmation
  if confirm_action "Do you want to $action_message"; then
    logg info "Downloading Cursor $latest_version..."
    if ! download_latest_stable; then
      logg error "Failed to download Cursor $latest_version. Please check your internet connection and try again."
      return 1
    fi
    logg success "Download completed successfully!"
    return 0
  else
    logg info "Download cancelled by user."
    return 2
  fi
}

# -------------------------------------------------------------------
# Main function: validate OS, install alias, initialize, then show menu
# -------------------------------------------------------------------
main() {
  clear
  validate_os
  install_script_alias
  show_message "Starting up..."
  menu
}

# Execute main function
main
