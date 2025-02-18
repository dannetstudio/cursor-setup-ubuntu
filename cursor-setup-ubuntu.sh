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
# Colors (currently unused, but retained for future use)
# -------------------------------------------------------------------
readonly CLR_SCS="#16FF15"   # success
readonly CLR_INF="#0095FF"   # info
readonly CLR_BG="#131313"    # background
readonly CLR_PRI="#6B30DA"   # primary
readonly CLR_ERR="#FB5854"   # error
readonly CLR_WRN="#FFDA33"   # warning
readonly CLR_LGT="#F9F5E2"   # light

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
# Spinner function: shows a simple spinner while a command runs
# -------------------------------------------------------------------
spinner() {
  local message="$1"
  local command="$2"
  local delay=0.1
  local spin_chars='-\|/'
  local i=0

  eval "$command" &
  local pid=$!

  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % 4 ))
    printf "\r%s %s" "$message" "${spin_chars:$i:1}"
    sleep $delay
  done

  wait "$pid"
  printf "\r%s ✓\n" "$message"
}

# -------------------------------------------------------------------
# If true, older versions (with the same CLI_COMMAND_NAME) will be removed after installation.
# -------------------------------------------------------------------
readonly REMOVE_PREVIOUS=true

# -------------------------------------------------------------------
# Remove older versions, keeping only the newest one.
# -------------------------------------------------------------------
remove_old_versions() {
  local pattern
  if $NIGHTLY_MODE; then
    pattern="$DOWNLOAD_DIR/cursor-nightly-*.AppImage"
  else
    pattern="$DOWNLOAD_DIR/cursor-[0-9]*.AppImage"
  fi
  local newest_file
  newest_file=$(ls -1t $pattern 2>/dev/null | head -n 1 || true)
  if [[ -n "$newest_file" ]]; then
    local older_files
    older_files=$(ls -1t $pattern 2>/dev/null | tail -n +2 || true)
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
  echo -e "$question [y/N]"
  read -rp "> " response
  case "$response" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# -------------------------------------------------------------------
# Download the Nightly AppImage (saves to USER_DOWNLOADS_DIR)
# -------------------------------------------------------------------
download_latest_nightly() {
  logg prompt "Checking remote version headers from https://nightlymagic.cursor.sh/ ..."
  local remote_headers
  remote_headers=$(curl -sD - -o /dev/null --max-time 10 \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
    https://nightlymagic.cursor.sh/)
  
  local remote_filename
  remote_filename=$(echo "$remote_headers" | grep -i "content-disposition:" | sed -E 's/.*filename="([^"]+)".*/\1/I')
  
  if [[ -z "$remote_filename" ]]; then
    logg error "Could not extract remote filename from headers."
    return 1
  fi
  
  if [[ "$remote_filename" != *.AppImage ]]; then
    logg error "Remote file ($remote_filename) does not appear to be an AppImage."
    return 1
  fi
  
  logg info "Downloading file: $remote_filename"
  
  pushd "$USER_DOWNLOADS_DIR" >/dev/null
  
  if [[ -f "$remote_filename" ]]; then
    logg info "File $remote_filename already exists. Removing old version..."
    rm -f "$remote_filename"
  fi
  
  curl -L -OJ -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" https://nightlymagic.cursor.sh/
  
  if [[ ! -f "$remote_filename" ]]; then
    popd >/dev/null
    logg error "Failed to download the Nightly file."
    return 1
  fi
  
  popd >/dev/null
  
  # Update global variable to point to the downloaded file
  LOCAL_APPIMAGE_PATH="$USER_DOWNLOADS_DIR/$remote_filename"
  logg success "Downloaded file: $LOCAL_APPIMAGE_PATH"
  return 0
}

# -------------------------------------------------------------------
# Ask the user to choose between Stable and Nightly versions (text menu)
# -------------------------------------------------------------------
echo "Select the version to install:"
echo "1) Stable"
echo "2) Nightly"
read -rp "Enter choice [1-2]: " version_choice
if [[ "$version_choice" == "2" ]]; then
  NIGHTLY_MODE=true
  readonly CLI_COMMAND_NAME="cursor-nightly"
  readonly USER_DESKTOP_FILE="$USER_DESKTOP_DIR/cursor-nightly.desktop"
  readonly SYSTEM_DESKTOP_FILE="$REAL_HOME/.local/share/applications/cursor-nightly.desktop"
  readonly DESKTOP_NAME="Cursor Nightly"
  readonly APPARMOR_PROFILE="/etc/apparmor.d/cursor-nightly-appimage"
else
  NIGHTLY_MODE=false
  readonly CLI_COMMAND_NAME="cursor"
  readonly USER_DESKTOP_FILE="$USER_DESKTOP_DIR/cursor.desktop"
  readonly SYSTEM_DESKTOP_FILE="$REAL_HOME/.local/share/applications/cursor.desktop"
  readonly DESKTOP_NAME="Cursor"
  readonly APPARMOR_PROFILE="/etc/apparmor.d/cursor-appimage"
  # For Stable mode, prompt only for the filename.
  echo "For Stable mode, please download the AppImage from https://www.cursor.com/ (click the 'Download' icon)."
  echo "Then, enter only the filename (e.g., cursor-0.45.11x86_64.AppImage) that is located in:"
  echo "  $USER_DOWNLOADS_DIR"
  read -rp "> " stable_filename
  if [[ -z "$stable_filename" ]]; then
    stable_filename="cursor-0.45.11x86_64.AppImage"
  fi
  LOCAL_APPIMAGE_PATH="$USER_DOWNLOADS_DIR/$stable_filename"
fi

# -------------------------------------------------------------------
# Common variables and constants
# -------------------------------------------------------------------
readonly DOWNLOAD_DIR="$REAL_HOME/.AppImage"
readonly ICON_DIR="$REAL_HOME/.local/share/icons"
readonly ICON_URL="https://mintlify.s3-us-west-1.amazonaws.com/cursor/images/logo/app-logo.svg"
# Set a unique alias for the script regardless of mode
readonly SCRIPT_ALIAS_NAME="cursor-setup-ubuntu"
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"

# -------------------------------------------------------------------
# Function to extract version from the AppImage filename
# For Nightly, allow two or three numeric groups.
# -------------------------------------------------------------------
extract_version() {
  local filename="$1"
  if [[ "$filename" == *nightly* ]]; then
    if [[ "$filename" =~ cursor-nightly-([0-9]+\.[0-9]+(\.[0-9]+)?) ]]; then
      echo "${BASH_REMATCH[1]}"
      return
    fi
  else
    if [[ "$filename" =~ cursor-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
      echo "${BASH_REMATCH[1]}"
      return
    fi
  fi
  echo "unknown"
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
  local APPARMOR_PROFILE_CONTENT
  if $NIGHTLY_MODE; then
    APPARMOR_PROFILE_CONTENT="  
#include <tunables/global>
profile cursor-nightly-appimage flags=(attach_disconnected,mediate_deleted) {
    /home/*/.AppImage/cursor-nightly-*.AppImage ix,
    /etc/{passwd,group,shadow} r,
    /usr/bin/env rix,
    /usr/bin/{bash,sh} rix,
}
"
  else
    APPARMOR_PROFILE_CONTENT="
#include <tunables/global>
profile cursor-appimage flags=(attach_disconnected,mediate_deleted) {
    /home/*/.AppImage/cursor-*.AppImage ix,
    /etc/{passwd,group,shadow} r,
    /usr/bin/env rix,
    /usr/bin/{bash,sh} rix,
}
"
  fi
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
  logg info "Installing AppImage: $file"
  mkdir -p "$DOWNLOAD_DIR"
  cp "$file" "$DOWNLOAD_DIR/"
  chmod +x "$DOWNLOAD_DIR/$(basename "$file")"
  # Update global variable to point to the installed file
  LOCAL_APPIMAGE_PATH="$DOWNLOAD_DIR/$(basename "$file")"
  logg success "AppImage installed to $DOWNLOAD_DIR/$(basename "$file")"
  if [ "$REMOVE_PREVIOUS" = true ]; then
    remove_old_versions
  fi
  update_desktop_shortcut
  update_apparmor_profile
  update_executable_symlink
}

# -------------------------------------------------------------------
# Function to compare the installed version with the new version and act accordingly
# -------------------------------------------------------------------
check_version() {
  if $NIGHTLY_MODE; then
    local pattern="$DOWNLOAD_DIR/cursor-nightly-*.AppImage"
    local installed_file
    installed_file=$(ls -1t $pattern 2>/dev/null | head -n 1 || true)
    local installed_ver="none"
    if [[ -n "$installed_file" ]]; then
      installed_ver=$(extract_version "$(basename "$installed_file")")
      logg info "Installed version detected: $installed_ver"
    else
      logg info "No installed version detected."
    fi
    local remote_headers
    remote_headers=$(curl -sD - -o /dev/null --max-time 10 \
      -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
      https://nightlymagic.cursor.sh/)
    local remote_filename
    remote_filename=$(echo "$remote_headers" | grep -i "content-disposition:" | sed -E 's/.*filename="([^"]+)".*/\1/I')
    if [[ -z "$remote_filename" ]]; then
      logg error "Could not extract remote filename from headers."
      return 1
    fi
    local remote_ver
    remote_ver=$(extract_version "$remote_filename")
    logg info "Remote version detected: $remote_ver"
    if [[ "$installed_ver" == "none" ]]; then
      if confirm_action "No previous installation detected. Install version $remote_ver?"; then
        download_latest_nightly && install_appimage "$LOCAL_APPIMAGE_PATH"
      else
        logg info "Installation cancelled. Returning to main menu."
        return 0
      fi
    else
      if [[ "$installed_ver" == "$remote_ver" ]]; then
        if confirm_action "Version $installed_ver is already installed. Reinstall?"; then
          download_latest_nightly && install_appimage "$LOCAL_APPIMAGE_PATH"
        else
          logg info "Installation cancelled. Returning to main menu."
          return 0
        fi
      else
        if [[ "$remote_ver" > "$installed_ver" ]]; then
          if confirm_action "Update from version $installed_ver to $remote_ver?"; then
            download_latest_nightly && install_appimage "$LOCAL_APPIMAGE_PATH"
          else
            logg info "Update cancelled. Returning to main menu."
            return 0
          fi
        else
          if confirm_action "Remote version ($remote_ver) seems older than installed ($installed_ver). Reinstall anyway?"; then
            download_latest_nightly && install_appimage "$LOCAL_APPIMAGE_PATH"
          else
            logg info "Installation cancelled. Returning to main menu."
            return 0
          fi
        fi
      fi
    fi
  else
    local pattern="$DOWNLOAD_DIR/cursor-[0-9]*.AppImage"
    local new_file="$LOCAL_APPIMAGE_PATH"
    if [[ ! -f "$new_file" ]]; then
      logg error "Stable AppImage not found at $new_file"
      return 1
    fi
    local new_filename
    new_filename=$(basename "$new_file")
    local new_ver
    new_ver=$(extract_version "$new_filename")
    local installed_file
    installed_file=$(ls -1t $pattern 2>/dev/null | head -n 1 || true)
    if [[ -n "$installed_file" ]]; then
      # Discard any file that is Nightly if running in Stable mode
      if [[ "$(basename "$installed_file")" == *nightly* ]]; then
        installed_file=""
      fi
    fi
    if [[ -n "$installed_file" ]]; then
      local installed_ver
      installed_ver=$(extract_version "$(basename "$installed_file")")
      logg info "Installed version detected: $installed_ver"
      if [[ "$installed_ver" == "$new_ver" ]]; then
        if confirm_action "Version $new_ver is already installed. Reinstall?"; then
          install_appimage "$new_file"
        else
          logg info "Installation cancelled. Returning to main menu."
          return 0
        fi
      else
        if confirm_action "Update from version $installed_ver to $new_ver?"; then
          install_appimage "$new_file"
        else
          logg info "Update cancelled. Returning to main menu."
          return 0
        fi
      fi
    else
      if confirm_action "No previous installation detected. Install version $new_ver?"; then
        install_appimage "$new_file"
      else
        logg info "Installation cancelled. Returning to main menu."
        return 0
      fi
    fi
  fi
}

# -------------------------------------------------------------------
# For Stable mode: validate that the local AppImage file exists.
# -------------------------------------------------------------------
validate_local_appimage() {
  if [[ ! -f "$LOCAL_APPIMAGE_PATH" && "$NIGHTLY_MODE" == false ]]; then
    logg error "AppImage file not found at: $LOCAL_APPIMAGE_PATH
Please ensure that:
  1. You enter only the filename (e.g., cursor-0.45.11x86_64.AppImage) located in $USER_DOWNLOADS_DIR."
    exit 1
  fi
}

# -------------------------------------------------------------------
# Validate the operating system (must be Ubuntu or derivative)
# -------------------------------------------------------------------
validate_os() {
  local os_name
  spinner "Checking system compatibility..." "sleep 1"
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
    echo "=== MAIN MENU ==="
    echo "1) Install AppImage"
    echo "2) Create Desktop Shortcut"
    echo "3) Exit"
    read -rp "Select an option [1-3]: " choice
    case "$choice" in
      1) check_version ;;
      2) update_desktop_shortcut ;;
      3) logg info "Exiting..."; exit 0 ;;
      *) logg error "Invalid selection." ;;
    esac
  done
}

# -------------------------------------------------------------------
# Main function: validate OS, install alias, then show menu
# -------------------------------------------------------------------
main() {
  clear
  validate_os
  install_script_alias
  if ! $NIGHTLY_MODE; then
    validate_local_appimage
  fi
  spinner "Starting up..." "sleep 1"
  menu
}

# Execute main function
main
