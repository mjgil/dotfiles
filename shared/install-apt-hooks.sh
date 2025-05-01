#!/usr/bin/env bash

# Script to install APT hooks to prevent installation of ASDF-managed packages
# These hooks will work regardless of how apt is invoked (directly, via sudo, etc.)

# Exit on error
set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ensure yq is installed
if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required but not installed. Please run bootstrap.sh first."
  exit 1
fi

# Get blocked package list from YAML file
get_blocked_packages() {
  BLOCKED_PACKAGES=""
  
  # Get number of ASDF languages
  local num_languages=$(yq e ".asdf_languages | length" "$SCRIPT_DIR/packages.yml")
  
  for ((i=0; i<num_languages; i++)); do
    local name=$(yq e ".asdf_languages[$i].name" "$SCRIPT_DIR/packages.yml")
    BLOCKED_PACKAGES="$BLOCKED_PACKAGES $name"
    
    # Add common variations
    case "$name" in
      "nodejs")
        BLOCKED_PACKAGES="$BLOCKED_PACKAGES node npm"
        ;;
      "python")
        BLOCKED_PACKAGES="$BLOCKED_PACKAGES python3 python-pip python3-pip pip pip3"
        ;;
      "golang")
        BLOCKED_PACKAGES="$BLOCKED_PACKAGES go"
        ;;
      "java")
        BLOCKED_PACKAGES="$BLOCKED_PACKAGES openjdk default-jdk default-jre"
        ;;
    esac
  done
  
  echo "$BLOCKED_PACKAGES"
}

# Create the script that will be called by the APT hook
create_dpkg_blocker_script() {
  local script_path="/usr/local/bin/dpkg-asdf-block.sh"
  local blocked_packages=$(get_blocked_packages)
  
  echo "Creating dpkg blocker script at $script_path"
  
  cat > /tmp/dpkg-asdf-block.sh << EOF
#!/usr/bin/env bash

# ASDF package blocker script
# This script is called by APT to check for blocked packages
# Blocked packages: $blocked_packages

# Check if bypass flag is set
if [ -n "\$BYPASS_ASDF_CHECK" ]; then
  exit 0
fi

# Get list of packages being installed
PACKAGES=\$(cat)

# Initialize arrays
BLOCKED_PKGS=()
ALLOWED_PKGS=()

# Check each package
for pkg in $blocked_packages; do
  if echo "\$PACKAGES" | grep -q "Package: \$pkg" && echo "\$PACKAGES" | grep -q "Status: install\|Status: hold"; then
    BLOCKED_PKGS+=("\$pkg")
  fi
done

# If any blocked packages found
if [ \${#BLOCKED_PKGS[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Direct installation of the following packages is blocked:" >&2
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
  
  # Extract non-blocked packages if any
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
    
    if [[ \${#ALLOWED_ARGS[@]} -gt 0 ]]; then
      echo "" >&2
      echo "You can install the non-blocked packages with:" >&2
      if [[ "\$CMD" =~ sudo ]]; then
        echo "  sudo apt install \${ALLOWED_ARGS[*]}" >&2
      else
        echo "  apt install \${ALLOWED_ARGS[*]}" >&2
      fi
    fi
  fi
  
  exit 1
fi

exit 0
EOF

  # Install the script using sudo
  sudo mv /tmp/dpkg-asdf-block.sh "$script_path"
  sudo chmod +x "$script_path"
  
  echo "dpkg blocker script installed successfully"
}

# Create directory for APT hooks
sudo mkdir -p /etc/apt/apt.conf.d

# Create the APT hook file
HOOK_FILE="/etc/apt/apt.conf.d/00-asdf-block"
create_dpkg_blocker_script

echo "Creating APT hook at $HOOK_FILE"

cat > /tmp/asdf-hook << EOF
// APT hook to prevent installation of packages managed by ASDF

DPkg::Pre-Install-Pkgs {
  "/usr/local/bin/dpkg-asdf-block.sh";
};
EOF

# Install the hook file using sudo
sudo mv /tmp/asdf-hook "$HOOK_FILE"

echo "APT hook installed successfully"
echo "This hook will prevent direct installation of packages that should be managed through ASDF"
echo "even when using sudo apt install or other methods"
