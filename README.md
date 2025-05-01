# Dotfiles

My personal configuration files and setup scripts for macOS and Linux (Ubuntu/Mint).

## Features

- Automated setup for common development tools and applications.
- Configuration for shells (Bash), editors, and various utilities.
- Uses `asdf` for managing runtime versions (Node.js, Python, Go, Java, etc.).
- Uses Homebrew on macOS and APT on Debian/Ubuntu for package management.
- Package definitions managed centrally in `shared/packages.json`.
- Idempotent installation scripts (safe to re-run).
- Centralized logging using `shared/log_utils.sh`.

## Installation

**Warning:** Review the scripts and `shared/packages.json` before running to understand what will be installed and configured.

### Linux (Ubuntu / Linux Mint)

#### Option 1: Direct Install (Recommended for fresh setup)

Run this command in your terminal. It downloads and executes the main installation script:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/mjgil/dotfiles/master/linux/install.sh)
```

This method downloads all necessary scripts to a temporary directory and executes them.

#### Option 2: Manual Clone

1. Clone the repository:

```bash
git clone https://github.com/mjgil/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
```

2. Run the local installation script:

```bash
./install-local.sh
```

### macOS

1. Clone the repository:

```bash
git clone https://github.com/mjgil/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
```

2. Run the macOS installation script:

```bash
./mac/install-mac.sh
```

This script will:
- Install Xcode Command Line Tools if missing.
- Install Rosetta on Apple Silicon if missing.
- Install Homebrew if missing.
- Install packages defined in `shared/packages.json` via Homebrew.
- Run Mac-specific setup (`mac/install-programs-and-apps.sh`, `mac/install-defaults.sh`, `mac/update-bashrc.sh`).

## Structure

- `linux/`: Linux-specific scripts and configuration.
- `mac/`: macOS-specific scripts and configuration.
- `shared/`: Scripts and configuration shared between platforms.
  * `packages.json`: Central definition of packages to install.
  * `install-packages.sh`: Script to parse `packages.json` and install packages using the appropriate package manager (APT/Brew/Snap/ASDF).
  * `log_utils.sh`: Centralized logging functions.
  * `create-package-blockers.sh` & `install-apt-hooks.sh`: Scripts to set up APT hooks for ASDF protection (Linux).
  * ... other shared utilities ...
- `install-local.sh`: Main script for installing from a local clone (primarily for Linux).

## ASDF Language Management & Protection (Linux)

Certain language runtimes (like Node.js, Python, Go, Java, etc., as defined in `packages.json`) are managed exclusively via `asdf-vm`. To prevent accidental installation of system versions of these runtimes via `apt` (which could lead to conflicts), APT hooks are automatically installed on Linux.

*   **How it works:** Scripts (`create-package-blockers.sh` and `install-apt-hooks.sh`) configure APT to run a check *before* installing packages.
*   **Protection:** If you try to `sudo apt install <package-managed-by-asdf>`, the hook will detect it and cause the `apt` command to fail for that specific package, preventing the installation.
*   **Non-Interactive:** This protection is automatic and does **not** prompt the user. It simply prevents the conflicting installation directly.
*   **Bypassing (Use with Caution):** If you absolutely need to install a system version managed by ASDF, you would need to temporarily remove or disable the APT hook configuration file located in `/etc/apt/apt.conf.d/`.

## Package Management

All packages are defined in `shared/packages.yml` and organized by category. To install a specific category of packages:

```bash
./shared/install-packages.sh development
```

To check which packages are installed:

```