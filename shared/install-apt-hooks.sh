#!/usr/bin/env bash
# Import logging utilities
# Define logging functions
function log_info() { echo -e "\\033[0;34m[INFO]\\033[0m $1"; }
function log_success() { echo -e "\\033[0;32m[SUCCESS]\\033[0m $1"; }
function log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m $1"; }
function log_error() { echo -e "\\033[0;31m[ERROR]\\033[0m $1"; }

# Script to install APT hooks to prevent installation of ASDF-managed packages
# These hooks will work regardless of how apt is invoked (directly, via sudo, etc.)

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


# Get blocked package list from JSON file
# Mirrors the logic from create-package-blockers.sh for consistency
get_blocked_packages() {
    jq -r '
        .asdf_languages[] | 
        # Only consider languages that might have apt alternatives defined or common names
        # (We dont strictly need select(.apt?) here as we add common names regardless)
        {name: .name, apt: .apt} | 
        # Output the asdf name
        .name, 
        # Output apt packages if defined (handle string or array)
        (if .apt? | type == "array" then .apt[] else .apt? // empty end), 
        # Add common variations based on asdf name
        (if .name == "nodejs" then "node", "npm" 
         elif .name == "python" then "python3", "python-pip", "python3-pip", "pip", "pip3" 
         elif .name == "golang" then "go" 
         elif .name == "java" then "openjdk", "default-jdk", "default-jre" 
         # Add other cases as needed
         else empty end)
    ' "$SCRIPT_DIR/$PACKAGE_FILE" | 
    # Remove duplicates and empty lines, then join with space
    sort -u | grep . | paste -sd ' ' || {
        log_warning "Failed to extract blocked packages using jq. APT hook might be incomplete."
        echo "" # Return empty string on error
    }
}

# Create the script that will be called by the APT hook
create_dpkg_blocker_script() {
  local script_path="/usr/local/bin/dpkg-asdf-block.sh"
  local blocked_packages=$(get_blocked_packages) # Call once
  
  if [[ -z "$blocked_packages" ]]; then
      log_info "No ASDF-managed packages found to block via APT hook. Skipping hook creation."
      # Optionally remove existing hook/script if desired
      # sudo rm -f "$script_path" "/etc/apt/apt.conf.d/00-asdf-block"
      return
  fi

  log_info "Creating dpkg blocker script at $script_path"
  log_info "Blocked packages for APT hook: $blocked_packages"
  
  # Use cat with sudo tee to write the script content
  # This avoids needing a temporary file owned by root
  cat << EOF | sudo tee "$script_path" > /dev/null
#!/usr/bin/env bash

# ASDF package blocker script
# This script is called by APT to check for blocked packages
# Blocked packages: $blocked_packages

# Check if bypass flag is set
if [ -n "\$BYPASS_ASDF_CHECK" ]; then
  exit 0
fi

# Get list of packages being installed (passed via stdin by APT)
PACKAGES=\$(cat)

# Initialize arrays
BLOCKED_PKGS=()
# ALLOWED_PKGS=() # Not actually used in this script's logic

# Convert space-separated string to array for reliable iteration
# Ensure the array declaration is safe even if $blocked_packages is empty
local blocked_array=()
read -r -a blocked_array <<< "$blocked_packages"

# Check each package defined in blocked_array
for pkg in "\${blocked_array[@]}"; do
  # Check if the package name appears in the input from APT
  # The input format is like:
  # Package: <name>
  # Version: <version>
  # Architecture: <arch>
  # Multi-Arch: <value>
  # Status: install
  # ... (repeated for each package)
  # We look for "Package: pkg_name" followed by "Status: install" or "Status: hold" later
  if echo "\$PACKAGES" | grep -qE "^Package:[[:space:]]*\$pkg\$"; then
    # Now check if the status for this specific package block is install or hold
     # This is tricky because the status line might be far below the Package line
     # A simpler, though potentially less precise, check is if "Status: install" or "Status: hold" exists anywhere
     # A more robust approach might use awk
     if echo "\$PACKAGES" | grep -qE "^Status:[[:space:]]*(install|hold)\$"; then
        # Found a blocked package being installed/held
        BLOCKED_PKGS+=("\$pkg")
     fi
  fi
done

# Remove duplicates just in case (shouldn't happen with loop logic but safe)
BLOCKED_PKGS=(\$(printf "%s\\n" "\${BLOCKED_PKGS[@]}" | sort -u))

# If any blocked packages found
if [ \${#BLOCKED_PKGS[@]} -gt 0 ]; then
  # Use systemd-cat for logging if available, otherwise echo to stderr
  log_cmd="echo"
  if command -v systemd-cat >/dev/null 2>&1; then
      log_cmd="systemd-cat -t asdf-blocker"
  fi

  \$log_cmd "--- ASDF Blocker Triggered ---"
  \$log_cmd "Blocked packages detected: \${BLOCKED_PKGS[*]}"
  \$log_cmd "Command executed: \$(ps -o cmd= \$PPID)"
  \$log_cmd "-----------------------------"

  # Output user-friendly message to stderr (which apt/dpkg usually shows)
  echo "⚠️  WARNING: Direct installation/hold of the following packages is blocked:" >&2
  for pkg in "\${BLOCKED_PKGS[@]}"; do
    echo "  - \$pkg" >&2
  done
  
  echo "" >&2
  echo "These packages should be managed using ASDF instead." >&2
  echo "" >&2
  echo "To install with ASDF, use:" >&2
  echo "  asdf plugin add <plugin>" >&2
  echo "  asdf install <plugin> <version>" >&2
  echo "  asdf global <plugin> <version>" >&2
  echo "" >&2
  echo "To bypass this check and force installation, run:" >&2
  echo "  BYPASS_ASDF_CHECK=1 sudo apt install <package>" >&2
  
  # Get command line used
  CMD=\$(ps -o cmd= \$PPID)
  
  # Extract non-blocked packages if any (This logic might be brittle)
  # Only attempt if the command looks like apt/apt-get install/add
  if [[ "\$CMD" =~ apt(-get)?[[:space:]]+(install|add)[[:space:]]+(.+) ]]; then
    ALL_ARGS=(\${BASH_REMATCH[3]})
    ALLOWED_ARGS=()
    
    for arg in "\${ALL_ARGS[@]}"; do
      # Skip if it's an option
      if [[ "\$arg" == -* ]]; then
        ALLOWED_ARGS+=("\$arg")
        continue
      fi
      
      # Check if it's a blocked package
      BLOCKED=0
      for blocked in "\${BLOCKED_PKGS[@]}"; do
        if [[ "\$arg" == "\$blocked" ]]; then
          BLOCKED=1
          break
        fi
      done
      
      if [[ \$BLOCKED -eq 0 ]]; then
        ALLOWED_ARGS+=("\$arg")
      fi
    done
    
    # Suggest command only if there are non-blocked arguments left
    if [[ \${#ALLOWED_ARGS[@]} -gt 0 && \${#ALLOWED_ARGS[@]} -ne \${#ALL_ARGS[@]} ]]; then
      echo "" >&2
      echo "You can attempt to install only the non-blocked packages with:" >&2
      # Extract the original command part (apt or apt-get)
      local apt_cmd=\${BASH_REMATCH[1]} 
      if [[ "\$CMD" =~ sudo ]]; then
        echo "  sudo \$apt_cmd install \$(printf "'"%s"' " "\${ALLOWED_ARGS[@]}")" >&2
      else
        echo "  \$apt_cmd install \$(printf "'"%s"' " "\${ALLOWED_ARGS[@]}")" >&2
      fi
    fi
  fi
  
  # Exit with error to prevent dpkg from proceeding with blocked packages
  exit 1 
fi

# No blocked packages detected in the transaction, exit successfully
exit 0
EOF

  # Ensure the script is executable
  sudo chmod +x "$script_path"
  
  log_info "dpkg blocker script installed/updated successfully"
}

# --- Main Execution ---

log_info "Setting up APT hook for ASDF package blocking..."

# Create directory for APT hooks if it doesn't exist
sudo mkdir -p /etc/apt/apt.conf.d

# Create/Update the blocker script itself
create_dpkg_blocker_script

# Check if the blocker script was actually created (it might be skipped if no blocked packages)
if [[ -f "/usr/local/bin/dpkg-asdf-block.sh" ]]; then
    # Create the APT hook configuration file using sudo tee
    HOOK_FILE="/etc/apt/apt.conf.d/00-asdf-block"
    log_info "Creating/Updating APT hook configuration at $HOOK_FILE"

    # Note: Using // comments might not be universally supported, sticking to simple format
    cat << EOF | sudo tee "$HOOK_FILE" > /dev/null
DPkg::Pre-Install-Pkgs { "/usr/local/bin/dpkg-asdf-block.sh"; };
EOF

    log_info "APT hook configured successfully"
    log_info "This hook will prevent direct installation of packages that should be managed through ASDF"
    log_info "(unless BYPASS_ASDF_CHECK=1 is set)."
else
    log_info "Skipped creating APT hook configuration as blocker script was not needed."
fi

log_success "APT hook setup process completed."
