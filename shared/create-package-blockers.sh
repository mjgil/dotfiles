#!/usr/bin/env bash

# Exit on error
set -e

# Script to create wrappers that block installation of specific packages
# that should be managed exclusively through ASDF

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define wrappers directory
WRAPPER_DIR="$HOME/.local/bin"
mkdir -p "$WRAPPER_DIR"

# Ensure yq is installed
if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required but not installed. Please run bootstrap.sh first."
  exit 1
fi

# Make sure the wrapper directory is in PATH
if ! echo "$PATH" | grep -q "$WRAPPER_DIR"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  echo "Added $WRAPPER_DIR to PATH in ~/.bashrc"
  echo "Please source ~/.bashrc or restart your shell for this to take effect"
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

# Create a wrapper for apt that checks for blocked packages
create_apt_wrapper() {
  local wrapper_path="$WRAPPER_DIR/apt"
  local blocked_packages="$(get_blocked_packages)"
  
  echo "Creating apt wrapper at $wrapper_path"
  
  cat > "$wrapper_path" << EOF
#!/usr/bin/env bash

# This is a wrapper script that prevents direct installation of ASDF-managed packages
# Blocked packages: $blocked_packages

# Get the real apt path
REAL_APT=\$(which -a apt | grep -v "$WRAPPER_DIR" | head -1)

# Check if this is an install command
if [[ "\$1" == "install" || "\$1" == "add" ]]; then
  # Check each argument against blocked packages
  BLOCKED=""
  ALLOWED=""
  
  for arg in "\${@:2}"; do
    # Skip if it starts with a dash (option)
    if [[ "\$arg" == -* ]]; then
      ALLOWED="\$ALLOWED \$arg"
      continue
    fi
    
    # Check if this is a blocked package
    FOUND=0
    for blocked_pkg in $blocked_packages; do
      if [[ "\$arg" == "\$blocked_pkg" ]]; then
        BLOCKED="\$BLOCKED \$arg"
        FOUND=1
        break
      fi
    done
    
    # If not blocked, add to allowed
    if [[ \$FOUND -eq 0 ]]; then
      ALLOWED="\$ALLOWED \$arg"
    fi
  done
  
  if [[ -n "\$BLOCKED" ]]; then
    echo "⚠️  WARNING: Blocked ASDF-managed packages detected:\$BLOCKED"
    echo "These languages/runtimes should be managed using ASDF instead."
    echo ""
    
    if [[ -n "\$ALLOWED" ]]; then
      echo "You can install the non-blocked packages with:"
      echo "  \$0 \$1\$ALLOWED"
      echo ""
    fi
    
    echo "To install with ASDF, use:"
    echo "  asdf plugin add <plugin>"
    echo "  asdf install <plugin> <version>"
    echo "  asdf global <plugin> <version>"
    echo ""
    echo "To bypass this check and force installation, run:"
    echo "  BYPASS_ASDF_CHECK=1 \$0 \$@"
    echo ""
    echo "Or use the full path to apt:"
    echo "  \$REAL_APT \$@"
    
    # Check if bypass flag is set
    if [[ "\$BYPASS_ASDF_CHECK" == "1" ]]; then
      echo "BYPASS_ASDF_CHECK is set, proceeding with installation..."
    else
      # If we have allowed packages, offer to install just those
      if [[ -n "\$ALLOWED" && "\$ALLOWED" != " " ]]; then
        echo ""
        read -p "Would you like to install just the non-blocked packages? (y/n) " -n 1 -r
        echo ""
        if [[ \$REPLY =~ ^[Yy]$ ]]; then
          exec \$REAL_APT \$1\$ALLOWED
        else
          exit 1
        fi
      else
        exit 1
      fi
    fi
  fi
fi

# If we get here, no blocked packages were detected, or it wasn't an install command
exec "\$REAL_APT" "\$@"
EOF

  chmod +x "$wrapper_path"
  
  # Create similar wrapper for apt-get
  local apt_get_path="$WRAPPER_DIR/apt-get"
  sed "s/apt/apt-get/g" "$wrapper_path" > "$apt_get_path"
  chmod +x "$apt_get_path"
  
  echo "apt and apt-get wrappers created successfully"
}

# Create a wrapper for brew
create_brew_wrapper() {
  local wrapper_path="$WRAPPER_DIR/brew"
  local blocked_packages="$(get_blocked_packages)"
  
  echo "Creating brew wrapper at $wrapper_path"
  
  cat > "$wrapper_path" << EOF
#!/usr/bin/env bash

# This is a wrapper script that prevents direct installation of ASDF-managed packages
# Blocked packages: $blocked_packages

# Get the real brew path
REAL_BREW=\$(which -a brew | grep -v "$WRAPPER_DIR" | head -1)

# Check if this is an install command
if [[ "\$1" == "install" || "\$1" == "reinstall" ]]; then
  # Check each argument against blocked packages
  BLOCKED=""
  ALLOWED=""
  
  for arg in "\${@:2}"; do
    # Skip if it starts with a dash (option)
    if [[ "\$arg" == -* ]]; then
      ALLOWED="\$ALLOWED \$arg"
      continue
    fi
    
    # Check if this is a blocked package
    FOUND=0
    for blocked_pkg in $blocked_packages; do
      if [[ "\$arg" == "\$blocked_pkg" ]]; then
        BLOCKED="\$BLOCKED \$arg"
        FOUND=1
        break
      fi
    done
    
    # If not blocked, add to allowed
    if [[ \$FOUND -eq 0 ]]; then
      ALLOWED="\$ALLOWED \$arg"
    fi
  done
  
  if [[ -n "\$BLOCKED" ]]; then
    echo "⚠️  WARNING: Blocked ASDF-managed packages detected:\$BLOCKED"
    echo "These languages/runtimes should be managed using ASDF instead."
    echo ""
    
    if [[ -n "\$ALLOWED" ]]; then
      echo "You can install the non-blocked packages with:"
      echo "  \$0 \$1\$ALLOWED"
      echo ""
    fi
    
    echo "To install with ASDF, use:"
    echo "  asdf plugin add <plugin>"
    echo "  asdf install <plugin> <version>"
    echo "  asdf global <plugin> <version>"
    echo ""
    echo "To bypass this check and force installation, run:"
    echo "  BYPASS_ASDF_CHECK=1 \$0 \$@"
    echo ""
    echo "Or use the full path to brew:"
    echo "  \$REAL_BREW \$@"
    
    # Check if bypass flag is set
    if [[ "\$BYPASS_ASDF_CHECK" == "1" ]]; then
      echo "BYPASS_ASDF_CHECK is set, proceeding with installation..."
    else
      # If we have allowed packages, offer to install just those
      if [[ -n "\$ALLOWED" && "\$ALLOWED" != " " ]]; then
        echo ""
        read -p "Would you like to install just the non-blocked packages? (y/n) " -n 1 -r
        echo ""
        if [[ \$REPLY =~ ^[Yy]$ ]]; then
          exec \$REAL_BREW \$1\$ALLOWED
        else
          exit 1
        fi
      else
        exit 1
      fi
    fi
  fi
fi

# If we get here, no blocked packages were detected, or it wasn't an install command
exec "\$REAL_BREW" "\$@"
EOF

  chmod +x "$wrapper_path"
  echo "brew wrapper created successfully"
}

# Create sudo wrapper to handle sudo apt install
create_sudo_wrapper() {
  local wrapper_path="$WRAPPER_DIR/sudo"
  local blocked_packages="$(get_blocked_packages)"
  
  echo "Creating sudo wrapper at $wrapper_path"
  
  cat > "$wrapper_path" << EOF
#!/usr/bin/env bash

# This is a wrapper for sudo that checks for blocked packages when using apt/apt-get

# Get the real sudo path
REAL_SUDO=\$(which -a sudo | grep -v "$WRAPPER_DIR" | head -1)

# If the first argument is apt or apt-get, check for blocked packages
if [[ "\$1" == "apt" || "\$1" == "apt-get" ]]; then
  if [[ "\$2" == "install" || "\$2" == "add" ]]; then
    # Check each argument against blocked packages
    BLOCKED=""
    ALLOWED=""
    
    for arg in "\${@:3}"; do
      # Skip if it starts with a dash (option)
      if [[ "\$arg" == -* ]]; then
        ALLOWED="\$ALLOWED \$arg"
        continue
      fi
      
      # Check if this is a blocked package
      FOUND=0
      for blocked_pkg in $blocked_packages; do
        if [[ "\$arg" == "\$blocked_pkg" ]]; then
          BLOCKED="\$BLOCKED \$arg"
          FOUND=1
          break
        fi
      done
      
      # If not blocked, add to allowed
      if [[ \$FOUND -eq 0 ]]; then
        ALLOWED="\$ALLOWED \$arg"
      fi
    done
    
    if [[ -n "\$BLOCKED" ]]; then
      echo "⚠️  WARNING: Blocked ASDF-managed packages detected:\$BLOCKED"
      echo "These languages/runtimes should be managed using ASDF instead."
      echo ""
      
      if [[ -n "\$ALLOWED" ]]; then
        echo "You can install the non-blocked packages with:"
        echo "  \$0 \$1 \$2\$ALLOWED"
        echo ""
      fi
      
      echo "To install with ASDF, use:"
      echo "  asdf plugin add <plugin>"
      echo "  asdf install <plugin> <version>"
      echo "  asdf global <plugin> <version>"
      echo ""
      echo "To bypass this check and force installation, run:"
      echo "  BYPASS_ASDF_CHECK=1 \$0 \$@"
      echo ""
      echo "Or use the full path to sudo:"
      echo "  \$(which -a sudo | grep -v "$WRAPPER_DIR" | head -1) \$@"
      
      # Check if bypass flag is set
      if [[ "\$BYPASS_ASDF_CHECK" == "1" ]]; then
        echo "BYPASS_ASDF_CHECK is set, proceeding with installation..."
      else
        # If we have allowed packages, offer to install just those
        if [[ -n "\$ALLOWED" && "\$ALLOWED" != " " ]]; then
          echo ""
          read -p "Would you like to install just the non-blocked packages? (y/n) " -n 1 -r
          echo ""
          if [[ \$REPLY =~ ^[Yy]$ ]]; then
            exec \$REAL_SUDO \$1 \$2\$ALLOWED
          else
            exit 1
          fi
        else
          exit 1
        fi
      fi
    fi
  fi
fi

# If we get here, either it's not apt/apt-get, not an install command, or no blocked packages
exec "\$REAL_SUDO" "\$@"
EOF

  chmod +x "$wrapper_path"
  echo "sudo wrapper created successfully"
}

# Create wrappers based on detected OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  create_brew_wrapper
elif [[ -f /etc/os-release ]]; then
  create_apt_wrapper
  create_sudo_wrapper
fi

echo "All wrapper scripts created successfully"
echo "These wrappers will prevent direct installation of packages that should be managed through ASDF"
echo "Please source ~/.bashrc or restart your shell for these changes to take effect"
