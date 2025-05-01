# Dotfiles

A collection of dotfiles and installation scripts for setting up a new development environment.

## Features

- YAML-based package management for both Linux and macOS
- ASDF-exclusive management for programming languages (Node.js, Python, Go, Java, etc.)
- Organized by categories for easy installation of specific tool groups
- Automated installation of development tools and applications
- Configuration for various applications and utilities

## Linux Instructions

```bash
bash <(wget -qO- https://raw.githubusercontent.com/mjgil/dotfiles/master/linux/install.sh)
```

## Mac OS Instructions

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mjgil/dotfiles/master/mac/install-mac.sh)
```

After installing Dropbox, run:

```bash
cp ~/Dropbox/Fonts/*.ttf ~/Library/Fonts
cp ~/Dropbox/Fonts/*.otf ~/Library/Fonts
```

## Package Management

All packages are defined in `shared/packages.yml` and organized by category. To install a specific category of packages:

```bash
./shared/install-packages.sh development
```

To check which packages are installed:

```bash
./check-installed.sh
```

## ASDF-Managed Languages

The following languages are managed exclusively through ASDF:

- Node.js
- Python
- Go
- Java
- Maven
- .NET

These languages are **not** installed through the system package manager (apt/brew).

### Smart Protection Mechanism

The system includes a smart protection system that prevents accidental installation of these languages via package managers:

1. **Smart Filtering**:
   - If you run `apt install package1 python3 package2`, it will block only python3
   - You'll be offered to install just package1 and package2 instead
   - Non-blocked packages are never affected by the protection

2. **Multiple Protection Layers**:
   - User-level command wrappers intercept `apt`, `brew`, and `sudo apt install` commands
   - System-level APT hooks work with any method of invoking apt

3. **Flexibility**:
   - You can easily bypass the protection when needed using `BYPASS_ASDF_CHECK=1`
   - Interactive prompts help guide you to the correct action

### Managing Languages with ASDF

```bash
# List installed languages
asdf list

# Install a specific version
asdf install python 3.12.8

# Set global version
asdf global python 3.12.8

# Check all ASDF plugins and versions
./check-installed.sh asdf_languages
```

### Examples of Protection in Action

```bash
# This will be blocked for python3, but will offer to install just htop and git
$ sudo apt install htop python3 git

# This will bypass the check and install all packages (not recommended)
$ BYPASS_ASDF_CHECK=1 sudo apt install htop python3 git

# This will automatically install only the non-blocked packages if you answer 'y'
$ sudo apt install htop python3 git
⚠️  WARNING: Blocked ASDF-managed packages detected: python3
...
Would you like to install just the non-blocked packages? (y/n) y
```

## Why ASDF-Exclusive Management?

- Consistent version management across different platforms
- Better isolation between projects with different language requirements
- Prevents conflicts between system and project-specific language versions
- Makes it easier to switch between language versions

## Customization

- Edit `shared/packages.yml` to add or remove packages
- Platform-specific configurations are in their respective directories
- Shared configurations and scripts are in the `shared` directory
