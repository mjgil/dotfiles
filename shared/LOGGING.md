# Logging Utilities

This document explains how to use the centralized logging utilities in this repository.

## Overview

The `log_utils.sh` script provides a consistent logging interface across all shell scripts in the dotfiles repository. It automatically includes the following information in log messages:

- Timestamp
- Log level (INFO, SUCCESS, WARNING, ERROR, DEBUG)
- Source file name
- Calling function name
- Custom message

## Usage

### Including the Logging Utilities

Add this near the top of your script:

```bash
# Import logging utilities
source "$(dirname "${BASH_SOURCE[0]}")/shared/log_utils.sh"
```

### Available Logging Functions

#### Standard Logging Functions

These add context information automatically:

```bash
log_info "Starting installation process"
log_success "Package installed successfully"
log_warning "Configuration file already exists, skipping"
log_error "Failed to install package"
log_debug "Variable value: $value"
```

#### Direct Echo Replacement

For cases where you need exact formatting control:

```bash
log_echo "Regular message"
log_echo "No newline message" "-n"
log_echo "${GREEN}Colored message${NC}" "-e"
```

### Debug Logging

Debug messages are only displayed when the `DEBUG` environment variable is set:

```bash
# Enable debug logging
DEBUG=1 ./your-script.sh
```

### Color Codes

The following color variables are available:

```bash
RED    # For errors
GREEN  # For success messages
YELLOW # For warnings
BLUE   # For informational messages
PURPLE # For debug messages
CYAN   # Available for custom use
NC     # No Color - resets formatting
```

## Examples

### Basic Usage

```bash
#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/shared/log_utils.sh"

install_package() {
  local package_name="$1"
  
  log_info "Installing package: $package_name"
  
  if apt-get install -y "$package_name"; then
    log_success "Successfully installed $package_name"
    return 0
  else
    log_error "Failed to install $package_name"
    return 1
  fi
}

check_system() {
  log_echo "Checking system..." "-n"
  # Do some checks
  log_echo "Done"
  
  # Use color formatting
  log_echo "${GREEN}System check passed${NC}" "-e"
}

# Enable debugging for this run
DEBUG=1

log_debug "Starting script with parameters: $*"
install_package "example-package"
check_system
```

### Expected Output

```
[2025-05-01 11:45:23] [DEBUG] [example.sh:main] Starting script with parameters: 
[2025-05-01 11:45:23] [INFO] [example.sh:install_package] Installing package: example-package
[2025-05-01 11:45:25] [SUCCESS] [example.sh:install_package] Successfully installed example-package
Checking system...Done
System check passed
```

## Benefits

- Consistent log format across all scripts
- Built-in context tracking (file and function names)
- Color-coded log levels for better readability
- Debug logging that can be enabled/disabled
- Backward compatibility with simple echo-style logging
