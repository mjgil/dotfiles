#!/usr/bin/env bash
# Purpose: Create wrapper scripts for package managers to prevent direct installation
# of packages that should be managed by ASDF version manager

# Import logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/log_utils.sh"

# Exit on error
set -e

# Define package definition file
PACKAGE_FILE="packages.json"

# Script directory - adjusted for dotfiles root
if [ -n "$DOTFILES_SOURCE_DIR" ]; then
  PACKAGE_DIR="$DOTFILES_SOURCE_DIR/shared"
else
  PACKAGE_DIR="$SCRIPT_DIR"
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
if [ ! -f "$PACKAGE_DIR/$PACKAGE_FILE" ]; then
    log_error "Package definition file not found: $PACKAGE_DIR/$PACKAGE_FILE"
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
    ' "$PACKAGE_DIR/$PACKAGE_FILE" | 
    # Remove duplicates and empty lines, then join with space
    sort -u | grep . | paste -sd ' '
}

# Create a wrapper for apt that checks for blocked packages
create_apt_wrapper() {
  local wrapper_path="$WRAPPER_DIR/apt"
  local blocked_packages
  blocked_packages=$(get_blocked_packages) # Call once

  if [[ -z "$blocked_packages" ]]; then
      log_info "No ASDF-managed packages with apt definitions found. Skipping apt wrapper creation."
      return
  fi
  
  log_info "Creating apt wrapper at $wrapper_path"
  log_info "Blocked packages for apt: $blocked_packages"
  
  cat > "$wrapper_path" << EOF
#!/usr/bin/env bash

# Define logging functions locally within the wrapper
_log_info() { echo -e "\\033[0;34m[WRAPPER_DEBUG]\\033[0m \$1"; }
_log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m \$1"; }

# This is a wrapper script that prevents direct installation of ASDF-managed packages
# Blocked packages: $blocked_packages

# Get the real apt path, avoid infinite loop if wrapper is first in PATH
_log_info "Finding real apt path..."
REAL_APT=""
IFS=':' read -ra DIRS <<< "\$PATH"
for dir in "\${DIRS[@]}"; do
  # Skip our wrapper directory to avoid infinite loop
  if [[ "\$dir" == "$WRAPPER_DIR" ]]; then
    continue
  fi
  candidate="\$dir/apt"
  if [[ -f "\$candidate" && -x "\$candidate" ]]; then
    REAL_APT="\$candidate"
    break # Found the first valid one
  fi
done
_log_info "Real apt path found: \$REAL_APT"

# Check if we found the real apt
if [[ -z "\$REAL_APT" ]]; then
    _log_warning "Could not find real 'apt' executable in PATH (excluding the wrapper). Cannot proceed."
    exit 1
fi

# Extract the command (e.g., install, update)
_log_info "Extracting command: \$1"
COMMAND="\$1"
shift

# Check if this is an install or add command
_log_info "Checking if command is install/add..."
if [[ "\$COMMAND" == "install" || "\$COMMAND" == "add" ]]; then
  _log_info "Command is install/add. Parsing arguments..."
  # Check each argument against blocked packages
  DETECTED_BLOCKED=""
  ALLOWED_ARGS_ARRAY=() # Use array for safer handling of args with spaces/special chars
  NON_PKG_ARGS_ARRAY=() # Store options like -y, --fix-broken
  
  for arg in "\$@"; do
    # If it's an option, store it separately
    if [[ "\$arg" == -* ]]; then
      NON_PKG_ARGS_ARRAY+=("\$arg")
      continue
    fi
    
    # Check if this is a blocked package
    FOUND=0
    # Convert space-separated string to array for reliable iteration
    blocked_array=($blocked_packages) 
    for blocked_pkg in "\${blocked_array[@]}"; do
      if [[ "\$arg" == "\$blocked_pkg" ]]; then
        DETECTED_BLOCKED="\$DETECTED_BLOCKED \$arg"
        FOUND=1
        break
      fi
    done
    
    # If not blocked, add to allowed package args
    if [[ \$FOUND -eq 0 ]]; then
      ALLOWED_ARGS_ARRAY+=("\$arg")
    fi
  done
  
  # Trim leading/trailing whitespace from detected blocked list
  DETECTED_BLOCKED=\$(echo \$DETECTED_BLOCKED | xargs)
  _log_info "Finished parsing arguments. Blocked: \$DETECTED_BLOCKED. Allowed: \${ALLOWED_ARGS_ARRAY[*]}"

  if [[ -n "\$DETECTED_BLOCKED" ]]; then
    _log_warning "⚠️ WARNING: Blocked ASDF-managed packages detected: \$DETECTED_BLOCKED"
    _log_warning "These languages/runtimes should be managed using ASDF instead."
    _log_warning ""
    
    # Check if bypass flag is set
    _log_info "Checking for BYPASS_ASDF_CHECK... (Value: '\$BYPASS_ASDF_CHECK')"
    if [[ "\$BYPASS_ASDF_CHECK" == "1" ]]; then
      _log_info "BYPASS_ASDF_CHECK is set, proceeding with original command..."
      _log_info "Executing: \$REAL_APT \$COMMAND \$@"
      # Execute original command with REAL_APT
      exec "\$REAL_APT" "\$COMMAND" "\$@"
    else
      # If we have allowed packages, execute with only those automatically and non-interactively.
      if [[ \${#ALLOWED_ARGS_ARRAY[@]} -gt 0 ]]; then
        _log_info "Proceeding to install non-blocked packages non-interactively: \${ALLOWED_ARGS_ARRAY[*]}"
        # Ensure -y is included
        HAS_Y=0
        for opt in "\${NON_PKG_ARGS_ARRAY[@]}"; do
          if [[ "\$opt" == "-y" || "\$opt" == "--yes" ]]; then
            HAS_Y=1
            break
          fi
        done
        if [[ \$HAS_Y -eq 0 ]]; then
          NON_PKG_ARGS_ARRAY+=("-y")
        fi
        # Execute with allowed packages and all original options + -y
        _log_info "Executing: \$REAL_APT \$COMMAND \${NON_PKG_ARGS_ARRAY[@]} \${ALLOWED_ARGS_ARRAY[@]}"
        exec "\$REAL_APT" "\$COMMAND" "\${NON_PKG_ARGS_ARRAY[@]}" "\${ALLOWED_ARGS_ARRAY[@]}"
      else
        # Only blocked packages requested, exit without doing anything
        _log_warning "Only blocked packages were requested (\$DETECTED_BLOCKED). No action taken."
        _log_warning "Use ASDF to manage these packages or set BYPASS_ASDF_CHECK=1 to force."
        _log_info "Exiting wrapper with status 1."
        exit 1 # Exit with non-zero status
      fi
    fi
  else
     _log_info "No blocked packages detected."
  fi
else
  _log_info "Command is not install/add."
fi

_log_info "Executing final command: \$REAL_APT \$COMMAND \$@"
# If we get here:
# - Not an install/add command OR
# - No blocked packages detected OR
# - Bypass flag was set (already handled by exec above)
# Execute the original command using the real apt
# Combine original command and args back
exec "\$REAL_APT" "\$COMMAND" "\$@" # Pass all original arguments
EOF

  chmod +x "$wrapper_path"
  
  # Create similar wrapper for apt-get using a separate heredoc
  local apt_get_path="$WRAPPER_DIR/apt-get"
  log_info "Creating apt-get wrapper at $apt_get_path"

  cat > "$apt_get_path" << EOF_GET
#!/usr/bin/env bash

# Define logging functions locally within the wrapper
_log_info() { echo -e "\\033[0;34m[WRAPPER_DEBUG]\\033[0m \$1"; }
_log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m \$1"; }

# This is a wrapper script that prevents direct installation of ASDF-managed packages
# Blocked packages: $blocked_packages

# Get the real apt-get path, avoid infinite loop if wrapper is first in PATH
_log_info "Finding real apt-get path..."
REAL_APT_GET=""
IFS=':' read -ra DIRS_GET <<< "\$PATH"
for dir_get in "\${DIRS_GET[@]}"; do
  # Skip our wrapper directory to avoid infinite loop
  if [[ "\$dir_get" == "$WRAPPER_DIR" ]]; then
    continue
  fi
  candidate_get="\$dir_get/apt-get"
  if [[ -f "\$candidate_get" && -x "\$candidate_get" ]]; then
    REAL_APT_GET="\$candidate_get"
    break # Found the first valid one
  fi
done
_log_info "Real apt-get path found: \$REAL_APT_GET"

# Check if we found the real apt-get
if [[ -z "\$REAL_APT_GET" ]]; then
    _log_warning "Could not find real 'apt-get' executable in PATH (excluding the wrapper). Cannot proceed."
    exit 1
fi

# Extract the command (e.g., install, update)
_log_info "Extracting command: \$1"
COMMAND="\$1"
shift

# Check if this is an install or add command
_log_info "Checking if command is install/add..."
if [[ "\$COMMAND" == "install" || "\$COMMAND" == "add" ]]; then
  _log_info "Command is install/add. Parsing arguments..."
  # Check each argument against blocked packages
  DETECTED_BLOCKED=""
  ALLOWED_ARGS_ARRAY=() # Use array for safer handling of args with spaces/special chars
  NON_PKG_ARGS_ARRAY=() # Store options like -y, --fix-broken

  for arg in "\$@"; do
    # If it's an option, store it separately
    if [[ "\$arg" == -* ]]; then
      NON_PKG_ARGS_ARRAY+=("\$arg")
      continue
    fi

    # Check if this is a blocked package
    FOUND=0
    # Convert space-separated string to array for reliable iteration
    blocked_array=($blocked_packages)
    for blocked_pkg in "\${blocked_array[@]}"; do
      if [[ "\$arg" == "\$blocked_pkg" ]]; then
        DETECTED_BLOCKED="\$DETECTED_BLOCKED \$arg"
        FOUND=1
        break
      fi
    done

    # If not blocked, add to allowed package args
    if [[ \$FOUND -eq 0 ]]; then
      ALLOWED_ARGS_ARRAY+=("\$arg")
    fi
  done

  # Trim leading/trailing whitespace from detected blocked list
  DETECTED_BLOCKED=\$(echo \$DETECTED_BLOCKED | xargs)
  _log_info "Finished parsing arguments. Blocked: \$DETECTED_BLOCKED. Allowed: \${ALLOWED_ARGS_ARRAY[*]}"

  if [[ -n "\$DETECTED_BLOCKED" ]]; then
    _log_warning "⚠️ WARNING: Blocked ASDF-managed packages detected: \$DETECTED_BLOCKED"
    _log_warning "These languages/runtimes should be managed using ASDF instead."
    _log_warning ""

    # Check if bypass flag is set
    _log_info "Checking for BYPASS_ASDF_CHECK... (Value: '\$BYPASS_ASDF_CHECK')"
    if [[ "\$BYPASS_ASDF_CHECK" == "1" ]]; then
      _log_info "BYPASS_ASDF_CHECK is set, proceeding with original command..."
      _log_info "Executing: \$REAL_APT_GET \$COMMAND \$@"
      # Execute original command with REAL_APT_GET
      exec "\$REAL_APT_GET" "\$COMMAND" "\$@"
    else
      # If we have allowed packages, execute with only those automatically and non-interactively.
      if [[ \${#ALLOWED_ARGS_ARRAY[@]} -gt 0 ]]; then
        _log_info "Proceeding to install non-blocked packages non-interactively: \${ALLOWED_ARGS_ARRAY[*]}"
        # Ensure -y is included
        HAS_Y=0
        for opt in "\${NON_PKG_ARGS_ARRAY[@]}"; do
          if [[ "\$opt" == "-y" || "\$opt" == "--yes" ]]; then
            HAS_Y=1
            break
          fi
        done
        if [[ \$HAS_Y -eq 0 ]]; then
          NON_PKG_ARGS_ARRAY+=("-y")
        fi
        # Execute with allowed packages and all original options + -y
        _log_info "Executing: \$REAL_APT_GET \$COMMAND \${NON_PKG_ARGS_ARRAY[@]} \${ALLOWED_ARGS_ARRAY[@]}"
        exec "\$REAL_APT_GET" "\$COMMAND" "\${NON_PKG_ARGS_ARRAY[@]}" "\${ALLOWED_ARGS_ARRAY[@]}"
      else
        # Only blocked packages requested, exit without doing anything
        _log_warning "Only blocked packages were requested (\$DETECTED_BLOCKED). No action taken."
        _log_warning "Use ASDF to manage these packages or set BYPASS_ASDF_CHECK=1 to force."
        _log_info "Exiting wrapper with status 1."
        exit 1 # Exit with non-zero status
      fi
    fi
  else
     _log_info "No blocked packages detected."
  fi
else
  _log_info "Command is not install/add."
fi

# If we get here:
# - Not an install/add command OR
# - No blocked packages detected OR
# - Bypass flag was set (already handled by exec above)
# Execute the original command using the real apt-get
# Combine original command and args back
_log_info "Executing final command: \$REAL_APT_GET \$COMMAND \$@"
exec "\$REAL_APT_GET" "\$COMMAND" "\$@" # Pass all original arguments
EOF_GET

  chmod +x "$apt_get_path"
  
  log_success "apt and apt-get wrappers created successfully"
}

# Create a wrapper for brew
create_brew_wrapper() {
  local wrapper_path="$WRAPPER_DIR/brew"
  # Use the same blocked packages list determined by get_blocked_packages
  # This list might include apt package names, but brew often uses the same or similar names.
  # We could refine this to only use brew-specific names if needed, but simple blocking is often sufficient.
  local blocked_packages
  blocked_packages=$(get_blocked_packages) 

  if [[ -z "$blocked_packages" ]]; then
      log_info "No ASDF-managed packages found. Skipping brew wrapper creation."
      return
  fi

  log_info "Creating brew wrapper at $wrapper_path"
  log_info "Blocked packages for brew (using combined list): $blocked_packages"
  
  cat > "$wrapper_path" << EOF
#!/usr/bin/env bash

# Define logging functions locally within the wrapper
_log_info() { echo -e "\\033[0;34m[INFO]\\033[0m \$1"; }
_log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m \$1"; }

# This is a wrapper script that prevents direct installation of ASDF-managed packages
# Blocked packages: $blocked_packages

# Get the real brew path, avoid infinite loop
REAL_BREW=""
IFS=':' read -ra DIRS <<< "\$PATH"
for dir in "\${DIRS[@]}"; do
  # Skip our wrapper directory to avoid infinite loop
  if [[ "\$dir" == "$WRAPPER_DIR" ]]; then
    continue
  fi
  candidate="\$dir/brew"
  if [[ -f "\$candidate" && -x "\$candidate" ]]; then
    REAL_BREW="\$candidate"
    break # Found the first valid one
  fi
done

if [[ -z "\$REAL_BREW" ]]; then
    _log_warning "Could not find real 'brew' executable. Cannot proceed."
    exit 1
fi

# Extract the command (e.g., install, reinstall)
COMMAND="\$1"
shift

# Check if this is an install or reinstall command
if [[ "\$COMMAND" == "install" || "\$COMMAND" == "reinstall" ]]; then
  # Check each argument against blocked packages
  DETECTED_BLOCKED=""
  ALLOWED_ARGS_ARRAY=()
  NON_PKG_ARGS_ARRAY=()

  for arg in "\$@"; do
    # Skip if it starts with a dash (option) or is a path/URL (common in brew)
    if [[ "\$arg" == -* || "\$arg" == */* || "\$arg" == *:* ]]; then
      NON_PKG_ARGS_ARRAY+=("\$arg")
      continue
    fi
    
    # Check if this is a blocked package (case-insensitive for brew often?)
    # For simplicity, sticking to case-sensitive match based on get_blocked_packages output
    FOUND=0
    blocked_array=($blocked_packages) 
    for blocked_pkg in "\${blocked_array[@]}"; do
      # Handle potential brew naming differences (e.g., python@3.10 vs python)
      # This is a simple check; more complex mapping might be needed for robustness
      local brew_check_name=\$(echo "\$arg" | cut -d'@' -f1) 
      if [[ "\$arg" == "\$blocked_pkg" || "\$brew_check_name" == "\$blocked_pkg" ]]; then
        DETECTED_BLOCKED="\$DETECTED_BLOCKED \$arg"
        FOUND=1
        break
      fi
    done
    
    # If not blocked, add to allowed args
    if [[ \$FOUND -eq 0 ]]; then
      ALLOWED_ARGS_ARRAY+=("\$arg")
    fi
  done

  # Trim leading/trailing whitespace
  DETECTED_BLOCKED=\$(echo \$DETECTED_BLOCKED | xargs)

  if [[ -n "\$DETECTED_BLOCKED" ]]; then
    _log_warning "⚠️ WARNING: Blocked ASDF-managed packages detected: \$DETECTED_BLOCKED"
    _log_warning "These should be managed using ASDF."
    _log_warning ""

    # Check if bypass flag is set
    if [[ "\$BYPASS_ASDF_CHECK" == "1" ]]; then
      _log_info "BYPASS_ASDF_CHECK is set, proceeding with original command..."
      exec "\$REAL_BREW" "\$COMMAND" "\$@"
    else
      # If we have allowed packages, execute with only those. Brew doesn't need -y
      if [[ \${#ALLOWED_ARGS_ARRAY[@]} -gt 0 ]]; then
        _log_info "Proceeding to install non-blocked packages: \${ALLOWED_ARGS_ARRAY[*]}"
        exec "\$REAL_BREW" "\$COMMAND" "\${NON_PKG_ARGS_ARRAY[@]}" "\${ALLOWED_ARGS_ARRAY[@]}"
      else
        _log_warning "Only blocked packages were requested (\$DETECTED_BLOCKED). No action taken."
        _log_warning "Use ASDF to manage these packages or set BYPASS_ASDF_CHECK=1 to force."
        exit 1
      fi
    fi
  fi
fi

# If we get here:
# - Not an install/reinstall command OR
# - No blocked packages detected OR
# - Bypass flag was set (handled above)
# Execute the original command using the real brew
exec "\$REAL_BREW" "\$COMMAND" "\$@"
EOF

  chmod +x "$wrapper_path"
  log_success "brew wrapper created successfully"
}

# Create sudo wrapper to handle sudo apt install / sudo apt-get install
create_sudo_wrapper() {
  local wrapper_path="$WRAPPER_DIR/sudo"
  # Capture the output without logging, use the same combined list
  local blocked_packages
  blocked_packages=$(get_blocked_packages)

  if [[ -z "$blocked_packages" ]]; then
      log_info "No ASDF-managed packages found. Skipping sudo wrapper creation."
      return
  fi

  log_info "Creating sudo wrapper at $wrapper_path"
  log_info "Blocked packages for sudo wrapper: $blocked_packages"

  cat > "$wrapper_path" << EOF
#!/usr/bin/env bash

# Define logging functions locally within the wrapper
_log_info() { echo -e "\\033[0;34m[INFO]\\033[0m \$1"; }
_log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m \$1"; }

# This is a wrapper for sudo that intercepts apt/apt-get commands to block ASDF-managed packages
# Blocked packages: $blocked_packages

# Get the real sudo path, avoid infinite loop
REAL_SUDO=""
IFS=':' read -ra DIRS <<< "\$PATH"
for dir in "\${DIRS[@]}"; do
  # Skip our wrapper directory to avoid infinite loop
  if [[ "\$dir" == "$WRAPPER_DIR" ]]; then
    continue
  fi
  candidate="\$dir/sudo"
  if [[ -f "\$candidate" && -x "\$candidate" ]]; then
    REAL_SUDO="\$candidate"
    break # Found the first valid one
  fi
done

if [[ -z "\$REAL_SUDO" ]]; then
    _log_warning "Could not find real 'sudo' executable. Cannot proceed."
    exit 1
fi

# Check if the command is apt/apt-get install
if [[ \$# -ge 2 && ("\$1" == "apt" || "\$1" == "apt-get") && ("\$2" == "install" || "\$2" == "add") ]]; then
  _log_info "Intercepted sudo \$1 \$2 command. Checking for blocked packages..."
  
  # Save the apt command before shifting
  APT_CMD="\$1"
  
  # Extract packages (skip the first two arguments: apt/apt-get and install/add)
  shift 2
  DETECTED_BLOCKED=""
  ALLOWED_ARGS_ARRAY=() # Arguments that are not blocked packages
  OPTIONS_ARRAY=()    # Store options like -y
  
  for arg in "\$@"; do
    # If it's an option, store it separately
    if [[ "\$arg" == -* ]]; then
      OPTIONS_ARRAY+=("\$arg")
      continue
    fi
    
    # Check if this is a blocked package
    FOUND=0
    # Convert space-separated string to array for reliable iteration
    blocked_array=($blocked_packages) 
    for blocked_pkg in "\${blocked_array[@]}"; do
      if [[ "\$arg" == "\$blocked_pkg" ]]; then
        DETECTED_BLOCKED="\$DETECTED_BLOCKED \$arg"
        FOUND=1
        break
      fi
    done
    
    # If not blocked, add to allowed args
    if [[ \$FOUND -eq 0 ]]; then
      ALLOWED_ARGS_ARRAY+=("\$arg")
    fi
  done
  
  # Trim leading/trailing whitespace
  DETECTED_BLOCKED=\$(echo \$DETECTED_BLOCKED | xargs)
  
  if [[ -n "\$DETECTED_BLOCKED" ]]; then
    _log_warning "⚠️ WARNING: Blocked ASDF-managed packages detected: \$DETECTED_BLOCKED"
    _log_warning "These languages/runtimes should be managed using ASDF instead."
    _log_warning ""
    
    # Check if bypass flag is set
    if [[ "\$BYPASS_ASDF_CHECK" == "1" ]]; then
      _log_info "BYPASS_ASDF_CHECK is set, proceeding with original command..."
      # Fall through to execute original command
    else
      # If we have allowed packages, execute with only those
      if [[ \${#ALLOWED_ARGS_ARRAY[@]} -gt 0 ]]; then
        _log_info "Proceeding to install only non-blocked packages: \${ALLOWED_ARGS_ARRAY[*]}"
        # Execute with allowed packages only - using saved APT_CMD
        exec "\$REAL_SUDO" "\$APT_CMD" "install" "\${OPTIONS_ARRAY[@]}" "\${ALLOWED_ARGS_ARRAY[@]}"
      else
        _log_warning "Only blocked packages were requested (\$DETECTED_BLOCKED). No action taken."
        _log_warning "Use ASDF to manage these packages or set BYPASS_ASDF_CHECK=1 to force."
        exit 1
      fi
    fi
  fi
fi

# If we get here and haven't exited or exec'd:
# 1. Not an apt/apt-get install command, OR
# 2. No blocked packages detected, OR
# 3. Bypass flag was set
# Just execute the original command with the real sudo
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
