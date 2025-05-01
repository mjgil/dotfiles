#!/usr/bin/env bash
# Import logging utilities
# Define logging functions
function log_info() { echo -e "\\033[0;34m[INFO]\\033[0m $1"; }
function log_success() { echo -e "\\033[0;32m[SUCCESS]\\033[0m $1"; }
function log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m $1"; }
function log_error() { echo -e "\\033[0;31m[ERROR]\\033[0m $1"; }

# Exit on error
set -e

# Define package definition file
PACKAGE_FILE="packages.json"

# Script directory - adjusted for dotfiles root
if [ -n "$DOTFILES_SOURCE_DIR" ]; then
  SCRIPT_DIR="$DOTFILES_SOURCE_DIR/shared"
else
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

# Define wrappers directory
WRAPPER_DIR="$HOME/.local/bin"
mkdir -p "$WRAPPER_DIR"

# Ensure jq is installed
if ! command -v jq >/dev/null 2>&1; then
  log_error "jq is required but not installed. Please run bootstrap.sh first."
  exit 1
fi

# Check if package file exists
if [ ! -f "$SCRIPT_DIR/$PACKAGE_FILE" ]; then
    log_error "Package definition file not found: $SCRIPT_DIR/$PACKAGE_FILE"
    exit 1
fi

# Make sure the wrapper directory is in PATH
if ! echo "$PATH" | grep -q "$WRAPPER_DIR"; then
  # Suggest adding to PATH, but avoid modifying files directly
  log_warning "Wrapper directory $WRAPPER_DIR is not in your PATH."
  log_warning "Please add 'export PATH=\"$HOME/.local/bin:\$PATH\"' to your shell configuration file (e.g., ~/.bashrc, ~/.zshrc)."
  log_warning "You may need to source the file or restart your shell for changes to take effect."
fi

# Get blocked package list from JSON file
get_blocked_packages() {
    jq -r '
        .asdf_languages[] | 
        select(.apt?) | 
        # Extract the asdf name and the apt package(s)
        {name: .name, apt: .apt} | 
        # Output the asdf name
        .name, 
        # Output apt packages (handle string or array)
        (if .apt | type == "array" then .apt[] else .apt end), 
        # Add common variations based on asdf name
        (if .name == "nodejs" then "node", "npm" 
         elif .name == "python" then "python3", "python-pip", "python3-pip", "pip", "pip3" 
         elif .name == "golang" then "go" 
         elif .name == "java" then "openjdk", "default-jdk", "default-jre" 
         # Add other cases as needed
         else empty end)
    ' "$SCRIPT_DIR/$PACKAGE_FILE" | 
    # Remove duplicates and empty lines, then join with space
    sort -u | grep . | paste -sd ' '
}

# Create a wrapper for apt that checks for blocked packages
create_apt_wrapper() {
  local wrapper_path="$WRAPPER_DIR/apt"
  local blocked_packages=$(get_blocked_packages) # Call once

  if [[ -z "$blocked_packages" ]]; then
      log_info "No ASDF-managed packages with apt definitions found. Skipping apt wrapper creation."
      return
  fi
  
  log_info "Creating apt wrapper at $wrapper_path"
  log_info "Blocked packages for apt: $blocked_packages"
  
  cat > "$wrapper_path" << EOF
#!/usr/bin/env bash

# Define logging functions locally within the wrapper
_log_info() { echo -e "\\\\033[0;34m[INFO]\\\\033[0m \$1"; }
_log_warning() { echo -e "\\\\033[0;33m[WARNING]\\\\033[0m \$1"; }

# This is a wrapper script that prevents direct installation of ASDF-managed packages
# Blocked packages: $blocked_packages

# Get the real apt path, avoid infinite loop if wrapper is first in PATH
REAL_APT=\$(PATH=\$(echo "\$PATH" | sed -e 's;'"$WRAPPER_DIR"':;;' -e 's;:'"$WRAPPER_DIR"'\\\$;;' -e 's;:'"$WRAPPER_DIR"':;:;') command -v apt)

# Check if we found the real apt
if [[ -z "\$REAL_APT" || "\$REAL_APT" == "$wrapper_path" ]]; then
    _log_warning "Could not find real 'apt' executable. Cannot proceed."
    exit 1
fi

# Check if this is an install or add command
if [[ "\$1" == "install" || "\$1" == "add" ]]; then
  # Check each argument against blocked packages
  DETECTED_BLOCKED=""
  ALLOWED_ARGS=""
  shift # Remove the command (install/add)
  
  for arg in "\$@"; do
    # Skip if it starts with a dash (option)
    if [[ "\$arg" == -* ]]; then
      ALLOWED_ARGS="\$ALLOWED_ARGS \$arg"
      continue
    fi
    
    # Check if this is a blocked package
    FOUND=0
    # Convert space-separated string to array for reliable iteration
    local blocked_array=($blocked_packages) 
    for blocked_pkg in "\${blocked_array[@]}"; do
      if [[ "\$arg" == "\$blocked_pkg" ]]; then
        DETECTED_BLOCKED="\$DETECTED_BLOCKED \$arg"
        FOUND=1
        break
      fi
    done
    
    # If not blocked, add to allowed args
    if [[ \$FOUND -eq 0 ]]; then
      ALLOWED_ARGS="\$ALLOWED_ARGS \$arg"
    fi
  done
  
  # Trim leading/trailing whitespace
  DETECTED_BLOCKED=\$(echo \$DETECTED_BLOCKED | xargs)
  ALLOWED_ARGS=\$(echo \$ALLOWED_ARGS | xargs)

  if [[ -n "\$DETECTED_BLOCKED" ]]; then
    _log_warning "⚠️ WARNING: Blocked ASDF-managed packages detected: \$DETECTED_BLOCKED"
    _log_warning "These languages/runtimes should be managed using ASDF instead."
    _log_warning ""
    
    if [[ -n "\$ALLOWED_ARGS" ]]; then
      _log_info "You can install the non-blocked packages with:"
      _log_info "  $wrapper_path \$1 \$ALLOWED_ARGS" # Use wrapper path for consistency
      _log_info ""
    fi
     
    _log_info "To install with ASDF, use:"
    _log_info "  asdf plugin add <plugin>"
    _log_info "  asdf install <plugin> <version>"
    _log_info "  asdf global <plugin> <version>"
    _log_info ""
    _log_info "To bypass this check and force installation, run:"
    _log_info "  BYPASS_ASDF_CHECK=1 $wrapper_path \$@" # Use wrapper path
    _log_info ""
    _log_info "Or use the full path to apt:"
    _log_info "  \$REAL_APT \$@"
    
    # Check if bypass flag is set
    if [[ "\$BYPASS_ASDF_CHECK" == "1" ]]; then
      _log_info "BYPASS_ASDF_CHECK is set, proceeding with installation..."
      # Fall through to execute with REAL_APT below
    else
      # If we have allowed packages, offer to install just those
      if [[ -n "\$ALLOWED_ARGS" ]]; then
        _log_info ""
        read -p "Would you like to install just the non-blocked packages (\$ALLOWED_ARGS)? (y/n) " -n 1 -r
        _log_info "" # Newline after read
        if [[ \$REPLY =~ ^[Yy]$ ]]; then
          # Execute with allowed args only
          exec "\$REAL_APT" \$1 \$ALLOWED_ARGS
        else
          exit 1 # Exit if user declines
        fi
      else
         # Only blocked packages requested, exit without prompting
        exit 1
      fi
    fi
  fi
fi

# If we get here:
# - Not an install/add command
# - No blocked packages detected
# - Bypass flag was set
# Execute the original command using the real apt
exec "\$REAL_APT" "\$@"
EOF

  chmod +x "$wrapper_path"
  
  # Create similar wrapper for apt-get using the same logic
  local apt_get_path="$WRAPPER_DIR/apt-get"
  # Replace apt with apt-get carefully, especially in REAL_APT definition and messages
  sed -e "s|REAL_APT=\\\$(PATH=\\\$(echo \"\\\$PATH\" | sed -e 's;'"$WRAPPER_DIR"':;;' -e 's;:'"$WRAPPER_DIR"'\\\$;;' -e 's;:'"$WRAPPER_DIR"':;:;') command -v apt)|REAL_APT_GET=\\\$(PATH=\\\$(echo \"\\\$PATH\" | sed -e 's;'"$WRAPPER_DIR"':;;' -e 's;:'"$WRAPPER_DIR"'\\\$;;' -e 's;:'"$WRAPPER_DIR"':;:;') command -v apt-get)|g" \
      -e "s|Could not find real 'apt' executable|Could not find real 'apt-get' executable|g" \
      -e "s|full path to apt:|full path to apt-get:|g" \
      -e "s|\\\$\\REAL_APT|\\\$\\REAL_APT_GET|g" \
      -e "s|$wrapper_path|$apt_get_path|g" \
      "$wrapper_path" > "$apt_get_path"

  chmod +x "$apt_get_path"
  
  log_success "apt and apt-get wrappers created successfully"
}

# Create a wrapper for brew
create_brew_wrapper() {
  local wrapper_path="$WRAPPER_DIR/brew"
  # Use the same blocked packages list determined by get_blocked_packages
  # This list might include apt package names, but brew often uses the same or similar names.
  # We could refine this to only use brew-specific names if needed, but simple blocking is often sufficient.
  local blocked_packages=$(get_blocked_packages) 

  if [[ -z "$blocked_packages" ]]; then
      log_info "No ASDF-managed packages found. Skipping brew wrapper creation."
      return
  fi

  log_info "Creating brew wrapper at $wrapper_path"
  log_info "Blocked packages for brew (using combined list): $blocked_packages"
  
  cat > "$wrapper_path" << EOF
#!/usr/bin/env bash

# Define logging functions locally within the wrapper
_log_info() { echo -e "\\\\033[0;34m[INFO]\\\\033[0m \$1"; }
_log_warning() { echo -e "\\\\033[0;33m[WARNING]\\\\033[0m \$1"; }

# This is a wrapper script that prevents direct installation of ASDF-managed packages
# Blocked packages: $blocked_packages

# Get the real brew path, avoid infinite loop
REAL_BREW=\$(PATH=\$(echo "\$PATH" | sed -e 's;'"$WRAPPER_DIR"':;;' -e 's;:'"$WRAPPER_DIR"'\\\$;;' -e 's;:'"$WRAPPER_DIR"':;:;') command -v brew)

if [[ -z "\$REAL_BREW" || "\$REAL_BREW" == "$wrapper_path" ]]; then
    _log_warning "Could not find real 'brew' executable. Cannot proceed."
    exit 1
fi

# Check if this is an install or reinstall command
if [[ "\$1" == "install" || "\$1" == "reinstall" ]]; then
  # Check each argument against blocked packages
  DETECTED_BLOCKED=""
  ALLOWED_ARGS=""
  shift # Remove the command (install/reinstall)
  
  for arg in "\$@"; do
    # Skip if it starts with a dash (option) or is a path/URL
    if [[ "\$arg" == -* || "\$arg" == */* || "\$arg" == *:* ]]; then
      ALLOWED_ARGS="\$ALLOWED_ARGS \$arg"
      continue
    fi
    
    # Check if this is a blocked package (formula name)
    FOUND=0
    # Convert space-separated string to array for reliable iteration
    local blocked_array=($blocked_packages)
    for blocked_pkg in "\${blocked_array[@]}"; do
      # Simple string comparison - might need refinement for complex brew names
      if [[ "\$arg" == "\$blocked_pkg" ]]; then
        DETECTED_BLOCKED="\$DETECTED_BLOCKED \$arg"
        FOUND=1
        break
      fi
    done
    
    # If not blocked, add to allowed args
    if [[ \$FOUND -eq 0 ]]; then
      ALLOWED_ARGS="\$ALLOWED_ARGS \$arg"
    fi
  done

  # Trim leading/trailing whitespace
  DETECTED_BLOCKED=\$(echo \$DETECTED_BLOCKED | xargs)
  ALLOWED_ARGS=\$(echo \$ALLOWED_ARGS | xargs)
  
  if [[ -n "\$DETECTED_BLOCKED" ]]; then
    _log_warning "⚠️ WARNING: Blocked ASDF-managed packages detected: \$DETECTED_BLOCKED"
    _log_warning "These languages/runtimes should be managed using ASDF instead."
    _log_warning ""
    
    if [[ -n "\$ALLOWED_ARGS" ]]; then
      _log_info "You can install the non-blocked packages with:"
      _log_info "  $wrapper_path \$1 \$ALLOWED_ARGS" # Use wrapper path
      _log_info ""
    fi
    
    _log_info "To install with ASDF, use:"
    _log_info "  asdf plugin add <plugin>"
    _log_info "  asdf install <plugin> <version>"
    _log_info "  asdf global <plugin> <version>"
    _log_info ""
    _log_info "To bypass this check and force installation, run:"
    _log_info "  BYPASS_ASDF_CHECK=1 $wrapper_path \$@" # Use wrapper path
    _log_info ""
    _log_info "Or use the full path to brew:"
    _log_info "  \$REAL_BREW \$@"
    
    # Check if bypass flag is set
    if [[ "\$BYPASS_ASDF_CHECK" == "1" ]]; then
      _log_info "BYPASS_ASDF_CHECK is set, proceeding with installation..."
      # Fall through to execute with REAL_BREW below
    else
      # If we have allowed packages, offer to install just those
      if [[ -n "\$ALLOWED_ARGS" ]]; then
        _log_info ""
        read -p "Would you like to install just the non-blocked packages (\$ALLOWED_ARGS)? (y/n) " -n 1 -r
        _log_info "" # Newline after read
        if [[ \$REPLY =~ ^[Yy]$ ]]; then
          # Execute with allowed args only
          exec "\$REAL_BREW" \$1 \$ALLOWED_ARGS
        else
           exit 1 # Exit if user declines
        fi
      else
        # Only blocked packages requested, exit without prompting
        exit 1
      fi
    fi
  fi
fi

# If we get here:
# - Not an install/reinstall command
# - No blocked packages detected
# - Bypass flag was set
# Execute the original command using the real brew
exec "\$REAL_BREW" "\$@"
EOF

  chmod +x "$wrapper_path"
  log_success "brew wrapper created successfully"
}

# Create sudo wrapper to handle sudo apt install / sudo apt-get install
create_sudo_wrapper() {
  local wrapper_path="$WRAPPER_DIR/sudo"
  # Capture the output without logging, use the same combined list
  local blocked_packages=$(get_blocked_packages)

  if [[ -z "$blocked_packages" ]]; then
      log_info "No ASDF-managed packages found. Skipping sudo wrapper creation."
      return
  fi

  log_info "Creating sudo wrapper at $wrapper_path"
  # Don't log blocked packages here, the underlying apt/apt-get wrapper will if needed

  cat > "$wrapper_path" << EOF
#!/usr/bin/env bash

# Define logging functions locally within the wrapper
_log_info() { echo -e "\\\\033[0;34m[INFO]\\\\033[0m \$1"; }
_log_warning() { echo -e "\\\\033[0;33m[WARNING]\\\\033[0m \$1"; }

# This is a wrapper for sudo that mainly ensures our wrapped apt/apt-get is called if present

# Get the real sudo path, avoid infinite loop
REAL_SUDO=\$(PATH=\$(echo "\$PATH" | sed -e 's;'"$WRAPPER_DIR"':;;' -e 's;:'"$WRAPPER_DIR"'\\\$;;' -e 's;:'"$WRAPPER_DIR"':;:;') command -v sudo)

if [[ -z "\$REAL_SUDO" ]]; then
    # This should almost never happen
     echo "[ERROR] Could not find real 'sudo' executable. Cannot proceed." >&2
     exit 1
fi

# Check if the command being run with sudo is 'apt' or 'apt-get'
# If it is, we don't need to intercept here. The PATH modification ensures that
# if our apt/apt-get wrappers exist in $WRAPPER_DIR, they will be called *by sudo*.
# Sudo preserves the PATH by default unless configured otherwise (e.g., secure_path).
# We rely on $WRAPPER_DIR being early in the PATH for the user running the script.

# Just execute the command with the real sudo
exec "\$REAL_SUDO" "\$@"
EOF

  chmod +x "$wrapper_path"
  log_success "sudo wrapper created successfully"
  log_info "Note: The sudo wrapper relies on '$WRAPPER_DIR' being early in your PATH."
}

# === Main Script Execution ===

log_info "Generating ASDF package manager wrappers..."

# Determine OS
OS_TYPE=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="macos"
elif [[ -f /etc/os-release ]]; then
  OS_TYPE="linux" # Assuming Debian/Ubuntu based on previous context
else
  log_warning "Unsupported OS detected. Cannot reliably create wrappers."
  exit 1
fi

# Create wrappers based on detected OS
if [[ "$OS_TYPE" == "macos" ]]; then
  # Check if brew is installed before creating wrapper
  if command -v brew >/dev/null 2>&1; then
      create_brew_wrapper
  else
      log_warning "Homebrew (brew) not found. Skipping brew wrapper creation."
  fi
elif [[ "$OS_TYPE" == "linux" ]]; then
  # Check if apt is installed before creating wrapper
  if command -v apt >/dev/null 2>&1; then
      create_apt_wrapper # This also creates apt-get wrapper
  else
      log_warning "'apt' command not found. Skipping apt/apt-get wrapper creation."
  fi
  # Create sudo wrapper regardless, as it's generally useful
  create_sudo_wrapper
fi

log_success "Wrapper script creation process completed."
log_info "If wrappers were created/updated, ensure $WRAPPER_DIR is in your PATH."
