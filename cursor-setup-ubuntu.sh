#!/usr/bin/env bash
# -------------------------------------------------------------------
# Cursor Setup Ubuntu Script - Enhanced Version
# -------------------------------------------------------------------
# This script provides an intelligent, automated way to download,
# install, and manage Cursor AI AppImage on Ubuntu-based systems.
#
# FEATURES:
# - Enhanced security with file validation
# - Robust error handling and process management
# - Internationalization support (EN/ES)
# - Configurable timeouts and retry logic
# - Smart process detection and backup management
# - Colored logging with timestamps
# - System requirements validation
#
# Author: Daniel Ignacio Fernández
# Version: 2.1.1 - Security & Stability Edition with Critical Fixes
#
# CRITICAL IMPROVEMENTS IN v2.1.0:
# - Fixed version comparison logic (no more false update detection)
# - Automatic language detection from system settings
# - Clean function outputs (no log pollution)
# - Enhanced process detection and management
# - New system information display
# -------------------------------------------------------------------
set -euo pipefail

# -------------------------------------------------------------------
# Standard Exit Codes
# -------------------------------------------------------------------
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_NO_ACTION=2
readonly EXIT_USER_CANCEL=3

# -------------------------------------------------------------------
# Configuration Constants
# -------------------------------------------------------------------
readonly MIN_APPIMAGE_SIZE=104857600  # 100MB minimum size for AppImage validation
readonly MAX_WAIT_ATTEMPTS=12         # Maximum wait attempts for process termination (2 minutes with 10s intervals)
readonly WAIT_INTERVAL=10             # Wait interval in seconds between process checks
readonly MENU_CHOICE_TIMEOUT=30       # Timeout for menu choice selection
readonly DEFAULT_CONFIRMATION_TIMEOUT=60  # Default confirmation timeout

# -------------------------------------------------------------------
# Use the real user's home directory even when running with sudo
# -------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ]; then
  readonly REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  readonly REAL_HOME="$HOME"
fi

# -------------------------------------------------------------------
# Auto-detect system language
# -------------------------------------------------------------------
detect_system_language() {
  local detected_lang="EN"

  # Method 1: Check LANG/LANGUAGE environment variables
  if [[ "${LANG,,}" == *"es"* ]] || [[ "${LANGUAGE,,}" == *"es"* ]]; then
    detected_lang="ES"
  fi

  # Method 2: Check if Spanish desktop directories exist
  if [[ -d "$REAL_HOME/Escritorio" ]] || [[ -d "$REAL_HOME/Descargas" ]]; then
    detected_lang="ES"
  fi

  # Method 3: Check if English desktop directories exist (fallback)
  if [[ -d "$REAL_HOME/Desktop" ]] && [[ ! -d "$REAL_HOME/Escritorio" ]]; then
    detected_lang="EN"
  fi

  # Method 4: Check system locale
  if command -v locale >/dev/null 2>&1; then
    if locale | grep -i "LANG.*es" >/dev/null 2>&1; then
      detected_lang="ES"
    fi
  fi

  # Method 5: Check GNOME/KDE language settings
  if [[ -f "$REAL_HOME/.config/user-dirs.dirs" ]]; then
    if grep -q "Escritorio\|Descargas" "$REAL_HOME/.config/user-dirs.dirs" 2>/dev/null; then
      detected_lang="ES"
    fi
  fi

  echo "$detected_lang"
}

# Use auto-detected language or override with environment variable
readonly LANG_SETTING="${LANG_SETTING:-$(detect_system_language)}"

# -------------------------------------------------------------------
# User experience settings
# -------------------------------------------------------------------
readonly ENABLE_COLORS="${ENABLE_COLORS:-true}"
readonly ENABLE_DEBUG="${DEBUG_MODE:-false}"
readonly MENU_TIMEOUT="${MENU_TIMEOUT:-300}"
readonly CONFIRMATION_TIMEOUT="${CONFIRMATION_TIMEOUT:-60}"
readonly DOWNLOAD_TIMEOUT="${DOWNLOAD_TIMEOUT:-300}"
readonly MAX_RETRY_ATTEMPTS="${MAX_RETRY_ATTEMPTS:-3}"

# Set language-dependent paths using the real user's home directory
if [[ "$LANG_SETTING" == "EN" ]]; then
  readonly USER_DESKTOP_DIR="$REAL_HOME/Desktop"
  readonly USER_DOWNLOADS_DIR="$REAL_HOME/Downloads"
else
  readonly USER_DESKTOP_DIR="$REAL_HOME/Escritorio"
  readonly USER_DOWNLOADS_DIR="$REAL_HOME/Descargas"
fi



# -------------------------------------------------------------------
# Enhanced logging function with timestamps and colors
# Usage: logg <type> <message>
# Types: error, info, prompt, success, warn, debug
# -------------------------------------------------------------------
logg() {
  local TYPE="$1"
  local MSG="$2"
  local TIMESTAMP
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  # Color codes (can be disabled with LOG_COLORS=false)
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local BLUE='\033[0;34m'
  local NC='\033[0m' # No Color

  case "$TYPE" in
    error)
      if [[ "${LOG_COLORS:-true}" == "true" ]]; then
        echo -e "${RED}[$TIMESTAMP] ERROR: $MSG${NC}" >&2
      else
        echo "[$TIMESTAMP] ERROR: $MSG" >&2
      fi
      ;;
    info)
      if [[ "${LOG_COLORS:-true}" == "true" ]]; then
        echo -e "${BLUE}[$TIMESTAMP] INFO: $MSG${NC}"
      else
        echo "[$TIMESTAMP] INFO: $MSG"
      fi
      ;;
    prompt)
      if [[ "${LOG_COLORS:-true}" == "true" ]]; then
        echo -e "${YELLOW}[$TIMESTAMP] PROMPT: $MSG${NC}"
      else
        echo "[$TIMESTAMP] PROMPT: $MSG"
      fi
      ;;
    success)
      if [[ "${LOG_COLORS:-true}" == "true" ]]; then
        echo -e "${GREEN}[$TIMESTAMP] SUCCESS: $MSG${NC}"
      else
        echo "[$TIMESTAMP] SUCCESS: $MSG"
      fi
      ;;
    warn)
      if [[ "${LOG_COLORS:-true}" == "true" ]]; then
        echo -e "${YELLOW}[$TIMESTAMP] WARNING: $MSG${NC}"
      else
        echo "[$TIMESTAMP] WARNING: $MSG"
      fi
      ;;
    debug)
      if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        if [[ "${LOG_COLORS:-true}" == "true" ]]; then
          echo -e "${BLUE}[$TIMESTAMP] DEBUG: $MSG${NC}"
        else
          echo "[$TIMESTAMP] DEBUG: $MSG"
        fi
      fi
      ;;
    *)
      echo "[$TIMESTAMP] $MSG"
      ;;
  esac
}

# -------------------------------------------------------------------
# Internationalization function for user messages
# -------------------------------------------------------------------
i18n() {
  local key="$1"
  local fallback="${2:-}"

  case "$LANG_SETTING" in
    "ES")
      case "$key" in
        "menu_title") echo "=== Menú de Configuración de Cursor ===" ;;
        "menu_option_1") echo "1) Buscar Actualizaciones e Instalar/Actualizar Cursor" ;;
        "menu_option_2") echo "2) Actualizar Solo el Acceso Directo del Escritorio" ;;
        "menu_option_3") echo "3) Mostrar Información del Sistema" ;;
        "menu_option_4") echo "4) Salir" ;;
        "menu_select") echo "Seleccionar opción" ;;
        "update_check") echo "Buscando actualizaciones..." ;;
        "download_prompt") echo "¿Desea descargar la última versión disponible?" ;;
        "install_success") echo "Instalación completada exitosamente" ;;
        "network_error") echo "Error de conexión. Verifique su internet." ;;
        "invalid_option") echo "Opción inválida. Por favor elija 1-4." ;;
        "exiting") echo "Saliendo..." ;;
        "version_current") echo "Su instalación está actualizada" ;;
        "version_update") echo "Actualización disponible" ;;
        *) echo "$fallback" ;;
      esac
      ;;
    "EN"|*)
      case "$key" in
        "menu_title") echo "=== Cursor Setup Menu ===" ;;
        "menu_option_1") echo "1) Check for Updates & Install/Update Cursor" ;;
        "menu_option_2") echo "2) Update Desktop Shortcut Only" ;;
        "menu_option_3") echo "3) Show System Information" ;;
        "menu_option_4") echo "4) Exit" ;;
        "menu_select") echo "Select option" ;;
        "update_check") echo "Checking for updates..." ;;
        "download_prompt") echo "Do you want to download the latest version?" ;;
        "install_success") echo "Installation completed successfully" ;;
        "network_error") echo "Network error. Check your internet connection." ;;
        "invalid_option") echo "Invalid option. Please choose 1-4." ;;
        "exiting") echo "Exiting..." ;;
        "version_current") echo "Your installation is up to date" ;;
        "version_update") echo "Update available" ;;
        *) echo "$fallback" ;;
      esac
      ;;
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
  newest_file=$(ls -1t "$APPIMAGE_PATTERN" 2>/dev/null | head -n 1 || true)
  if [[ -n "$newest_file" ]]; then
    local older_files
    older_files=$(ls -1t "$APPIMAGE_PATTERN" 2>/dev/null | tail -n +2 || true)
    if [[ -n "$older_files" ]]; then
      logg info "Removing older versions in $DOWNLOAD_DIR..."
      rm -f "$older_files"
    fi
  fi
}

# -------------------------------------------------------------------
# Confirmation function (YES/NO) using read with timeout and validation.
# Returns 0 if answer is yes, 1 if no, 2 if timeout/invalid input.
# -------------------------------------------------------------------
confirm_action() {
  local question="$1"
  local timeout="${2:-$DEFAULT_CONFIRMATION_TIMEOUT}"
  local default="${3:-N}"   # Default answer (Y/N)
  local attempts=0
  local max_attempts=3

  while [[ $attempts -lt $max_attempts ]]; do
    if ! read -t "$timeout" -rp "$question [y/N]: " response; then
      logg warn "Confirmation timeout after $timeout seconds"
      return 2
    fi

    # Remove whitespace and convert to lowercase
    response=$(echo "$response" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

    case "$response" in
      y|yes|s|si|yeah|yep|sure)
        return 0
        ;;
      n|no|nope|nah|"")
        return 1
        ;;
      *)
        attempts=$((attempts + 1))
        if [[ $attempts -lt $max_attempts ]]; then
          logg warn "Invalid response. Please enter 'y' for yes or 'n' for no."
        else
          logg error "Too many invalid attempts. Assuming 'no'."
          return 1
        fi
        ;;
    esac
  done

  return 1
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
# This function:
# 1. Fetches version information from cursor-ai-downloads repository
# 2. Extracts the latest version number from the repository content
# 3. Returns only the version info - the actual download uses official URLs
#
# Note: We get version info from GitHub repo but download from official Cursor URLs
# -------------------------------------------------------------------
get_latest_stable_version() {
  # Use configurable timeouts
  local ping_timeout="${CURL_PING_TIMEOUT:-2}"
  local curl_timeout="${CURL_TIMEOUT:-5}"
  local max_retries="${CURL_MAX_RETRIES:-3}"

  # Check internet connectivity with configurable timeout
  if ! ping -c 1 -W $ping_timeout github.com >/dev/null 2>&1 && \
     ! ping -c 1 -W $ping_timeout gitlab.com >/dev/null 2>&1; then
    return 1
  fi

  # Try to fetch repository content with retries and fallback URLs
  local repo_content=""
  local attempt=0

  while [[ $attempt -lt $max_retries && -z "$repo_content" ]]; do
    for url in "${CURSOR_REPO_URLS[@]}"; do
      if repo_content=$(curl -s --max-time $curl_timeout \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
        -H "Accept: text/plain, */*" \
        --retry 2 --retry-delay 1 \
        "$url" 2>/dev/null); then

        if [[ -n "$repo_content" ]]; then
          break 2
        fi
      fi
    done

    attempt=$((attempt + 1))
    if [[ $attempt -lt $max_retries ]]; then
      sleep 2
    fi
  done

  if [[ -z "$repo_content" ]]; then
    return 1
  fi

  # Extract the latest version from the main download link
  local latest_version
  latest_version=$(echo "$repo_content" | grep -oE "Cursor [0-9]+\.[0-9]+\.[0-9]+" | head -1 | sed 's/Cursor //')

  if [[ -z "$latest_version" ]]; then
    return 1
  fi

  # Validate version format
  if ! [[ "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 1
  fi

  printf "%s" "$latest_version"
  return 0
}

# -------------------------------------------------------------------
# Extract the correct download base URL from the repository content
# -------------------------------------------------------------------
get_dynamic_base_url() {
  # Use configurable timeouts  
  local ping_timeout="${CURL_PING_TIMEOUT:-2}"
  local curl_timeout="${CURL_TIMEOUT:-5}"
  local max_retries="${CURL_MAX_RETRIES:-3}"

  # Check internet connectivity with configurable timeout
  if ! ping -c 1 -W $ping_timeout github.com >/dev/null 2>&1 && \
     ! ping -c 1 -W $ping_timeout gitlab.com >/dev/null 2>&1; then
    return 1
  fi

  # Try to fetch repository content with retries and fallback URLs
  local repo_content=""
  local attempt=0

  while [[ $attempt -lt $max_retries && -z "$repo_content" ]]; do
    for url in "${CURSOR_REPO_URLS[@]}"; do
      if repo_content=$(curl -s --max-time $curl_timeout \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
        -H "Accept: text/plain, */*" \
        --retry 2 --retry-delay 1 \
        "$url" 2>/dev/null); then

        if [[ -n "$repo_content" ]]; then
          break 2
        fi
      fi
    done

    attempt=$((attempt + 1))
    if [[ $attempt -lt $max_retries ]]; then
      sleep 2
    fi
  done

  if [[ -z "$repo_content" ]]; then
    return 1
  fi

  # Look for the first Linux x64 download link which contains the version
  local latest_download_url
  latest_download_url=$(echo "$repo_content" | grep -oE "https://downloads\.cursor\.com/production/[a-f0-9]+/linux/x64/Cursor-[0-9]+\.[0-9]+\.[0-9]+-x86_64\.AppImage" | head -1)
  
  if [[ -z "$latest_download_url" ]]; then
    return 1
  fi

  # Extract the base URL (up to production/hash/linux, without x64)
  local base_url
  base_url=$(echo "$latest_download_url" | sed 's|/linux/.*|/linux|')
  
  [[ "${DEBUG_MODE:-false}" == "true" ]] && logg debug "Found download URL: '$latest_download_url'"
  [[ "${DEBUG_MODE:-false}" == "true" ]] && logg debug "Extracted base URL: '$base_url'"

  printf "%s" "$base_url"
  return 0
}

# -------------------------------------------------------------------
# Download the latest stable AppImage from official Cursor servers
# -------------------------------------------------------------------
# This function:
# 1. Gets version info from cursor-ai-downloads repository (metadata only)
# 2. Downloads the actual AppImage from official Cursor servers
# 3. Validates the downloaded file
#
# Note: Only downloads from official URLs, repository is used for version detection
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
    logg error "Could not fetch repository content"
    return 1
  fi

  local filename="Cursor-$latest_version"
  if [[ "$arch" == "x64" ]]; then
    filename="${filename}-x86_64.AppImage"
  else
    filename="${filename}-aarch64.AppImage"
  fi

  # Get the dynamic base URL from repository
  local base_url
  base_url=$(get_dynamic_base_url)
  if [[ $? -ne 0 || -z "$base_url" ]]; then
    logg warn "Could not get dynamic URL, falling back to hardcoded URL"
    base_url="$CURSOR_DOWNLOAD_BASE_URL"
  fi
  
  local url="$base_url/$arch/$filename"

  logg info "Latest stable version: $latest_version"
  logg info "Downloading file: $filename"
  [[ "${DEBUG_MODE:-false}" == "true" ]] && logg debug "Using base URL: '$base_url'"
  logg info "Download URL: $url"

  pushd "$USER_DOWNLOADS_DIR" >/dev/null

  if [[ -f "$filename" ]]; then
    logg info "File $filename already exists. Removing old version..."
    rm -f "$filename"
  fi

  # Download with progress and error handling
  if ! curl -L -o "$filename" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" \
       --progress-bar --retry 3 --retry-delay 2 "$url"; then
    popd >/dev/null
    logg error "Failed to download the stable file after 3 attempts"
    return 1
  fi

  if [[ ! -f "$filename" ]]; then
    popd >/dev/null
    logg error "Failed to download the stable file"
    return 1
  fi

  # Validate downloaded file
  if ! validate_appimage "$filename"; then
    popd >/dev/null
    logg error "Downloaded file validation failed"
    rm -f "$filename"
    return 1
  fi

  popd >/dev/null

  # Update global variable to point to the downloaded file
  LOCAL_APPIMAGE_PATH="$USER_DOWNLOADS_DIR/$filename"
  logg success "Downloaded and validated file: $LOCAL_APPIMAGE_PATH"
  return 0
}

# -------------------------------------------------------------------
# Configuration variables - can be overridden by environment variables
# -------------------------------------------------------------------
readonly CURSOR_REPO_URL="${CURSOR_REPO_URL:-https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/README.md}"
readonly CURSOR_DOWNLOAD_BASE_URL="${CURSOR_DOWNLOAD_BASE_URL:-https://downloads.cursor.com/production/823f58d4f60b795a6aefb9955933f3a2f0331d7b/linux}"

# Fallback URLs for repository access
readonly CURSOR_REPO_URLS=(
  "https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/README.md"
  "https://cdn.jsdelivr.net/gh/oslook/cursor-ai-downloads@main/README.md"
  "https://raw.githubusercontent.com/oslook/cursor-ai-downloads/master/README.md"
  "https://cdn.jsdelivr.net/gh/oslook/cursor-ai-downloads@master/README.md"
)

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
# Validate URL format and accessibility
# -------------------------------------------------------------------
validate_url() {
  local url="$1"

  # Basic URL format validation
  if ! [[ "$url" =~ ^https?:// ]]; then
    logg error "Invalid URL format: $url"
    return 1
  fi

  # Check if URL is accessible (quick timeout)
  if ! curl -I --max-time 5 --silent "$url" >/dev/null 2>&1; then
    logg warn "URL is not accessible: $url"
    return 1
  fi

  return 0
}

# -------------------------------------------------------------------
# Validate AppImage file integrity
# -------------------------------------------------------------------
validate_appimage() {
  local file_path="$1"

  # Check if file exists and has content
  if [[ ! -s "$file_path" ]]; then
    logg error "AppImage file is empty or doesn't exist: $file_path"
    return 1
  fi

  # Check file size (AppImages are typically > 100MB)
  local file_size
  file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null)
  if [[ $file_size -lt $MIN_APPIMAGE_SIZE ]]; then
    logg error "AppImage file seems too small ($file_size bytes). Download may be corrupted"
    return 1
  fi

  # Check if file is executable
  if [[ ! -x "$file_path" ]]; then
    logg warn "AppImage file is not executable. Setting executable permissions."
    chmod +x "$file_path"
  fi

  # Basic file type check
  if command -v file >/dev/null 2>&1; then
    if ! file "$file_path" | grep -q "AppImage"; then
      logg warn "File doesn't appear to be a valid AppImage format"
      # Don't fail here as file command might not recognize newer AppImages
    fi
  fi

  logg info "AppImage validation passed for: $file_path"
  return 0
}

# -------------------------------------------------------------------
# Create directory with proper error handling
# -------------------------------------------------------------------
create_directory() {
  local dir_path="$1"
  local dir_name="${2:-directory}"

  if [[ ! -d "$dir_path" ]]; then
    logg debug "Creating $dir_name: $dir_path"
    if ! mkdir -p "$dir_path" 2>/dev/null; then
      logg error "Failed to create $dir_name: $dir_path"
      return 1
    fi
  fi

  return 0
}

# -------------------------------------------------------------------
# Clean up old backup files
# -------------------------------------------------------------------
cleanup_backups() {
  local target_dir="$1"
  local max_backups="${2:-5}"

  if [[ ! -d "$target_dir" ]]; then
    return 0
  fi

  local backup_count
  backup_count=$(find "$target_dir" -name "*.backup.*" -type f | wc -l)

  if [[ $backup_count -gt $max_backups ]]; then
    logg info "Cleaning up old backup files (keeping $max_backups most recent)"

    # Remove oldest backup files
    find "$target_dir" -name "*.backup.*" -type f -printf '%T@ %p\n' | \
      sort -n | head -n -$max_backups | cut -d' ' -f2- | \
      xargs -r rm -f

    logg success "Cleanup completed"
  fi
}

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
  local target_appimage="$DOWNLOAD_DIR/$(basename "$LOCAL_APPIMAGE_PATH")"
  local wrapper="$DOWNLOAD_DIR/wrapper-${CLI_COMMAND_NAME}.sh"
  local link="/usr/local/bin/${CLI_COMMAND_NAME}"
  
  # Security: Validate target exists and is executable
  if [[ ! -f "$target_appimage" ]]; then
    logg error "Target AppImage not found: $target_appimage"
    return $EXIT_ERROR
  fi
  
  if [[ ! -x "$target_appimage" ]]; then
    logg error "Target AppImage is not executable: $target_appimage"
    return $EXIT_ERROR
  fi
  
  # Security: Validate target path doesn't contain dangerous characters
  local basename_target="$(basename "$LOCAL_APPIMAGE_PATH")"
  if [[ "$basename_target" =~ [^a-zA-Z0-9._-] ]]; then
    logg error "Invalid characters in AppImage filename: $basename_target"
    return $EXIT_ERROR
  fi
  
  logg info "Creating wrapper script: $wrapper"
  
  # Fix: Hardcode the target path in the generated script instead of using variable expansion
  cat > "$wrapper" <<EOF
#!/usr/bin/env bash
# Wrapper to launch the Cursor AppImage with --no-sandbox
# Generated on $(date) by cursor-setup-ubuntu.sh
readonly TARGET_APPIMAGE="$target_appimage"

if [[ ! -f "\$TARGET_APPIMAGE" ]]; then
  echo "Error: AppImage not found: \$TARGET_APPIMAGE" >&2
  exit 1
fi

if [[ ! -x "\$TARGET_APPIMAGE" ]]; then
  echo "Error: AppImage is not executable: \$TARGET_APPIMAGE" >&2
  exit 1
fi

echo "Launching Cursor AppImage: \$TARGET_APPIMAGE"
exec "\$TARGET_APPIMAGE" --no-sandbox "\$@"
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
  if ! create_directory "$ICON_DIR" "icon directory"; then
    return 1
  fi
  curl -L -o "$ICON_DIR/cursor.svg" "$ICON_URL"
  cat > "$USER_DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=$DESKTOP_NAME
Exec=$DOWNLOAD_DIR/$(basename "$LOCAL_APPIMAGE_PATH") --no-sandbox
Icon=$ICON_DIR/cursor.svg
Type=Application
Categories=Utility;
EOF
  if ! create_directory "$(dirname "$SYSTEM_DESKTOP_FILE")" "system desktop directory"; then
    return 1
  fi
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
    logg error "Sudo privileges are required to update the AppArmor profile"
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

  if ! create_directory "$DOWNLOAD_DIR" "AppImage directory"; then
    return 1
  fi

  # Clean up old backup files
  cleanup_backups "$DOWNLOAD_DIR"

  # Check if target file already exists and is busy
  if [[ -f "$target_path" ]]; then
    logg info "Target file exists, checking if it's in use..."

    # Optimized process detection using the most efficient method available
    local pids_using_file=""
    local processes_info=""
    local detection_method=""

    # Method 1: Using lsof (most reliable and efficient)
    if command -v lsof >/dev/null 2>&1; then
      local lsof_output
      lsof_output=$(lsof "$target_path" 2>/dev/null || true)
      if [[ -n "$lsof_output" ]]; then
        pids_using_file=$(echo "$lsof_output" | awk 'NR>1 {print $2}' | sort -u)
        processes_info=$(echo "$lsof_output" | awk 'NR>1 {print $2, $1}' | sort -u)
        detection_method="lsof"
        logg debug "Processes using file (lsof): $processes_info"
      fi
    fi

    # Method 2: Using fuser as fallback (only if lsof failed)
    if [[ -z "$pids_using_file" ]] && command -v fuser >/dev/null 2>&1; then
      local fuser_pids
      fuser_pids=$(fuser "$target_path" 2>/dev/null | sed 's/.*://' | tr ',' '\n' | tr -d '[:space:]' || true)
      if [[ -n "$fuser_pids" ]]; then
        pids_using_file="$fuser_pids"
        processes_info=$(fuser -v "$target_path" 2>/dev/null || true)
        detection_method="fuser"
        logg debug "Processes using file (fuser): $processes_info"
      fi
    fi

    # Method 3: Enhanced cursor process check (only if necessary)
    if [[ -n "$pids_using_file" ]]; then
      local cursor_pids
      cursor_pids=$(pgrep -f "cursor" 2>/dev/null || true)
      if [[ -n "$cursor_pids" ]]; then
        logg debug "Found running Cursor processes: $cursor_pids"
        # More efficient check using associative array concept
        for pid in $cursor_pids; do
          if echo "$pids_using_file" | grep -q "^$pid$"; then
            logg warn "Cursor process $pid is using the AppImage file"
          fi
        done
      fi
    fi

    if [[ -n "$pids_using_file" ]]; then
      logg warn "File is currently in use by processes:"
      echo "$processes_info" | while read -r line; do
        if [[ -n "$line" ]]; then
          local pid proc_name
          pid=$(echo "$line" | awk '{print $1}')
          proc_name=$(echo "$line" | awk '{print $2}')
          logg warn "  PID $pid: $proc_name"
        fi
      done

      # Offer different options for handling busy file
      echo
      logg prompt "Options:"
      echo "1) Wait for processes to finish (recommended)"
      echo "2) Terminate processes and continue"
      echo "3) Skip file replacement (keep existing)"
      echo "4) Cancel installation"
      echo

      local choice=""
      local wait_attempts=0
      local max_wait_attempts=$MAX_WAIT_ATTEMPTS

      while [[ -z "$choice" ]] || ! [[ "$choice" =~ ^[1-4]$ ]]; do
        read -t $MENU_CHOICE_TIMEOUT -rp "Choose option [1-4]: " choice
        if [[ $? -ne 0 ]]; then
          logg warn "Timeout waiting for choice. Cancelling installation."
          return 1
        fi

        case "$choice" in
          1)
            logg info "Waiting for processes to finish..."
            while [[ $wait_attempts -lt $max_wait_attempts ]] && [[ -n "$(lsof "$target_path" 2>/dev/null | awk 'NR>1 {print $2}' || true)" ]]; do
              sleep $WAIT_INTERVAL
              wait_attempts=$((wait_attempts + 1))
              logg debug "Still waiting... ($((wait_attempts * WAIT_INTERVAL))s elapsed)"
            done

            if [[ $wait_attempts -ge $max_wait_attempts ]]; then
              logg error "Timeout waiting for processes to finish"
              return 1
            fi
            logg success "Processes finished, continuing with installation"
            ;;
          2)
            if confirm_action "This will terminate the listed processes. Continue?"; then
              for pid in $pids_using_file; do
                if kill -TERM "$pid" 2>/dev/null; then
                  logg info "Terminated process $pid"
                  sleep 2
                else
                  logg warn "Failed to terminate process $pid"
                fi
              done
              # Wait a bit more to ensure processes are fully terminated
              sleep 3
            else
              logg info "Installation cancelled by user."
              return 1
            fi
            ;;
          3)
            logg info "Skipping file replacement. Using existing file."
            LOCAL_APPIMAGE_PATH="$target_path"
            return 0
            ;;
          4|"")
            logg info "Installation cancelled by user."
            return 1
            ;;
        esac
      done
    fi

    # Create backup with better naming (atomic operation)
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$target_path.backup.$timestamp"
    local temp_backup="$backup_file.tmp"
    logg info "Creating backup: $backup_file"

    # Atomic backup: copy to temp file first, then move to final location
    if cp "$target_path" "$temp_backup" && mv "$temp_backup" "$backup_file"; then
      logg success "Backup created successfully"
    else
      logg error "Failed to create backup file"
      # Clean up temp file if it exists
      [[ -f "$temp_backup" ]] && rm -f "$temp_backup"
      if ! confirm_action "Continue without backup?"; then
        return 1
      fi
    fi
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
    logg error "Failed to install AppImage. You may need to close Cursor and try again"
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

  # Check for updates (single attempt, no subshell timeouts)
  logg prompt "Checking for updates from cursor-ai-downloads repository..."
  local latest_version=""
  latest_version=$(check_for_updates "$installed_version")
  local update_status=$?

  # If automatic check failed, offer manual input
  if [[ $update_status -eq 1 ]] || [[ -z "$latest_version" ]]; then
    logg warn "Automatic version check failed. Options:"
    echo "1) Check repository: https://github.com/oslook/cursor-ai-downloads"
    echo "2) Enter latest version manually (e.g., 1.5.6)"
    echo "3) Skip update check"

    read -rp "Enter latest version or press Enter to skip: " manual_version
    
    # Enhanced input validation
    if [[ -z "$manual_version" ]]; then
      logg info "Skipping update check. Returning to menu."
      return 0
    elif [[ ! "$manual_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      logg error "Invalid version format. Expected format: X.Y.Z (e.g., 1.5.6)"
      return 0
    else
      # Additional validation: check reasonable version ranges
      local version_parts
      IFS='.' read -ra version_parts <<< "$manual_version"
      local major="${version_parts[0]}"
      local minor="${version_parts[1]}"
      local patch="${version_parts[2]}"
      
      # Sanity checks for version numbers (reasonable ranges)
      if [[ $major -gt 100 ]] || [[ $minor -gt 999 ]] || [[ $patch -gt 999 ]]; then
        logg error "Version numbers seem too high. Please verify: $manual_version"
        if ! confirm_action "Use this version anyway"; then
          return 0
        fi
      fi
      
      latest_version="$manual_version"
      update_status=0
      logg info "Using manual version: $latest_version"
    fi
  fi

   case $update_status in
     0)  # Update available or installation needed
       if [[ -z "$latest_version" ]]; then
         logg error "Could not determine latest version. Please check your internet connection"
         logg info "You can try again later or check the repository manually:"
         logg info "https://github.com/oslook/cursor-ai-downloads"
       return 1
       fi

       if handle_download_decision "$latest_version" "$installed_version"; then
         # Download was successful, now install
         if [[ -f "$LOCAL_APPIMAGE_PATH" ]]; then
           install_appimage "$LOCAL_APPIMAGE_PATH"
         else
           logg error "Download completed but AppImage file not found"
       return 1
         fi
        fi
        ;;
      2)  # No update needed - offer reinstall
        logg success "Your Cursor installation is up to date!"
        logg info "Current version: $installed_version"
        if confirm_action "Do you want to reinstall anyway"; then
          logg info "Reinstalling Cursor $installed_version..."
          if ! download_latest_stable; then
            logg error "Failed to download Cursor $latest_version. Please check your internet connection and try again"
            return 1
          fi
          logg success "Download completed successfully!"
          # Download was successful, now install
          if [[ -f "$LOCAL_APPIMAGE_PATH" ]]; then
            install_appimage "$LOCAL_APPIMAGE_PATH"
          else
            logg error "Download completed but AppImage file not found"
            return 1
          fi
        else
          logg info "Reinstall cancelled by user."
        fi
        ;;
      1)  # Error checking for updates
       logg error "Could not check for updates. Please check your internet connection"
       logg info "Possible solutions:"
       logg info "1. Check your internet connection"
       logg info "2. Try again in a few minutes"
       logg info "3. Check the repository manually: https://github.com/oslook/cursor-ai-downloads"
       ;;
     *)  # Unknown status
       logg error "Unknown update status: $update_status"
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
    logg error "This script is intended for Ubuntu and its derivatives. Detected: $os_name"
    exit $EXIT_ERROR
  fi
  logg success "System compatible: $os_name"
}

# -------------------------------------------------------------------
# Check system requirements and dependencies
# -------------------------------------------------------------------
check_system_requirements() {
  logg info "Checking system requirements..."

  local missing_deps=()
  local required_commands=("curl" "wget" "grep" "sed" "awk" "file" "lsof" "stat" "sudo" "chmod" "mkdir" "cp" "mv" "rm" "ln" "cat" "basename" "dirname")

  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_deps+=("$cmd")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    logg error "Missing required dependencies: ${missing_deps[*]}"
    logg info "Please install missing dependencies using: sudo apt-get install ${missing_deps[*]}"
    return 1
  fi

  # Check if running as root (not recommended for normal operation)
  if [[ $EUID -eq 0 ]]; then
    logg warn "Running as root is not recommended for normal usage."
    logg warn "The script will use sudo when necessary for system operations."
  fi

  # Check if sudo is available and working
  if ! sudo -n true 2>/dev/null; then
    logg warn "sudo may require password authentication."
    logg info "You may be prompted for your password during installation."
  fi

  # Check internet connectivity
  logg debug "Testing internet connectivity..."
  if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 && ! ping -c 1 -W 3 google.com >/dev/null 2>&1; then
    logg warn "No internet connectivity detected."
    logg info "Some features may not work without internet access."
  fi

  # Check required directories
  local dirs_to_check=("$REAL_HOME" "$USER_DOWNLOADS_DIR" "$USER_DESKTOP_DIR")
  for dir in "${dirs_to_check[@]}"; do
    if [[ ! -d "$dir" ]]; then
      logg warn "Directory does not exist: $dir"
      if ! mkdir -p "$dir" 2>/dev/null; then
        logg error "Cannot create directory: $dir"
        return 1
      fi
      logg info "Created directory: $dir"
    fi
  done

  # Show detected language information
  local detected_lang
  detected_lang=$(detect_system_language)
  logg info "Language detected: $detected_lang (${LANG_SETTING:-$detected_lang})"
  logg info "Desktop directory: $USER_DESKTOP_DIR"
  logg info "Downloads directory: $USER_DOWNLOADS_DIR"

  logg success "System requirements check completed successfully"
  return 0
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
        # Safer alternative to eval: directly set the alias
        alias "$SCRIPT_ALIAS_NAME"="$SCRIPT_PATH"
      fi
    fi
  done
  if [[ "$alias_added" == true ]]; then
    logg success "Alias created and defined: ${SCRIPT_ALIAS_NAME}"
  fi
}

# -------------------------------------------------------------------
# Signal handler for clean exit
# -------------------------------------------------------------------
cleanup() {
  local exit_code=$?
  logg info "Received signal, cleaning up..."
  # Add any cleanup operations here if needed
  exit $exit_code
}

# -------------------------------------------------------------------
# Enhanced main menu with better error handling
# -------------------------------------------------------------------
menu() {
  # Set up signal handlers
  trap cleanup SIGINT SIGTERM

  local attempts=0
  local max_attempts=5

  while true; do
    echo
    i18n "menu_title" "=== Cursor Setup Menu ==="
    i18n "menu_option_1" "1) Check for Updates & Install/Update Cursor"
    i18n "menu_option_2" "2) Update Desktop Shortcut Only"
    i18n "menu_option_3" "3) Show System Information"
    i18n "menu_option_4" "4) Exit"
    echo

    local select_prompt
    select_prompt=$(i18n "menu_select" "Select option")
    if ! read -t "$MENU_TIMEOUT" -rp "$select_prompt [1-4]: " choice; then
      logg warn "Menu timeout after $MENU_TIMEOUT seconds"
      logg info "$(i18n 'exiting' 'Exiting...')"
      exit $EXIT_SUCCESS
    fi

    # Sanitize input
    choice=$(echo "$choice" | tr -d '[:space:]')

    case "$choice" in
      1)
        if ! check_version; then
          logg error "$(i18n 'network_error' 'Network error. Check your internet connection.')"
        fi
        ;;
      2)
        if ! update_desktop_shortcut; then
          logg error "Failed to update desktop shortcut."
        fi
        ;;
      3)
        show_system_info
        ;;
      4|"")
        logg info "$(i18n 'exiting' 'Exiting...')"
        exit $EXIT_SUCCESS
        ;;
      *)
        attempts=$((attempts + 1))
        if [[ $attempts -ge $max_attempts ]]; then
          logg error "Too many invalid menu selections. $(i18n 'exiting' 'Exiting...')"
          exit $EXIT_ERROR
        fi
        logg error "$(i18n "invalid_option" "Invalid option '$choice'. Please choose 1-4.")"
        logg info "Attempts remaining: $((max_attempts - attempts))"
        ;;
    esac
  done
}

# -------------------------------------------------------------------
# Show system information and detected settings (debug function)
# -------------------------------------------------------------------
show_system_info() {
  echo
  logg info "=== System Information ==="
  logg info "Operating System: $(uname -s) $(uname -r)"
  logg info "Architecture: $(uname -m)"

  # Show detected language information
  local detected_lang
  detected_lang=$(detect_system_language)
  logg info "Auto-detected Language: $detected_lang"
  logg info "Using Language Setting: ${LANG_SETTING:-$detected_lang}"

  # Show directory information
  logg info "Desktop Directory: $USER_DESKTOP_DIR"
  logg info "Downloads Directory: $USER_DOWNLOADS_DIR"

  # Show environment information
  if [[ -n "${LANG:-}" ]]; then
    logg info "LANG Environment: $LANG"
  fi
  if [[ -n "${LANGUAGE:-}" ]]; then
    logg info "LANGUAGE Environment: $LANGUAGE"
  fi

  # Show current version if installed
  local installed_version
  installed_version=$(check_cursor_installation)
  if [[ -n "$installed_version" ]]; then
    logg info "Currently Installed: Cursor v$installed_version"
  else
    logg info "Cursor Status: Not installed"
  fi

  echo
}

# -------------------------------------------------------------------
# Function to check if Cursor is already installed and get version info
# -------------------------------------------------------------------
check_cursor_installation() {
  local installed_file
  installed_file=$(ls -1t "$APPIMAGE_PATTERN" 2>/dev/null | head -n 1 || true)

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

  local latest_version
  latest_version=$(get_latest_stable_version)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]] || [[ -z "$latest_version" ]]; then
    return 1
  fi

  if [[ -n "$installed_version" ]]; then
    if [[ "$installed_version" == "$latest_version" ]]; then
      echo "$latest_version"
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
     if [[ "$installed_version" == "$latest_version" ]]; then
       logg success "You already have the latest version ($latest_version) installed!"
       if confirm_action "Do you want to reinstall anyway"; then
         action_message="reinstall Cursor $latest_version"
       else
         logg info "Reinstall cancelled by user."
         return 2
       fi
     else
       logg info "Update available: $installed_version → $latest_version"
     fi
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

  if ! check_system_requirements; then
    logg error "System requirements check failed. Please resolve the issues above and try again"
    exit $EXIT_ERROR
  fi

  install_script_alias
  show_message "Starting up..."
  menu
}

# Execute main function
main
