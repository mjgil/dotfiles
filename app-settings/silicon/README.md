# Silicon Configuration

[Silicon](https://github.com/Aloxaf/silicon) is a powerful command-line tool for creating beautiful images of your source code, similar to Carbon but running entirely offline.

## Installation

Silicon is automatically installed through the dotfiles package system:

```bash
# Install all dotfiles packages (includes Silicon)
./shared/install-packages.sh

# Or install just terminal utilities
./shared/install-packages.sh terminal_utils

# Or install Silicon specifically with its dependencies
./shared/install-packages.sh development terminal_utils
```

## Configuration

The configuration file is located at `~/.config/silicon/config.toml` and includes:

- **Theme**: Default is "Dracula" (use `silicon --list-themes` to see all options)
- **Font**: Fira Code with 14pt size
- **Background**: Dark theme (#1e1e1e)
- **Window**: Shadow, controls, and rounded corners enabled
- **Line numbers**: Enabled by default
- **Output format**: PNG

## Available Aliases and Functions

The dotfiles include several convenient aliases and functions:

### Basic Aliases
- `si` - Short alias for silicon
- `silicon-themes` - List all available themes
- `silicon-help` - Show help

### Quick Functions
- `silicon-quick <file> [output]` - Quick screenshot with default settings
- `silicon-clipboard [output]` - Screenshot from clipboard content
- `silicon-lines <file> <range> [output]` - Screenshot specific line ranges

### Themed Functions
- `silicon-dark <file>` - Screenshot with Dracula theme
- `silicon-light <file>` - Screenshot with GitHub (light) theme
- `silicon-oceanic <file>` - Screenshot with Oceanic Next theme

### Specialized Functions
- `silicon-presentation <file> [output]` - High-quality screenshots for presentations
- `silicon-social <file> [output]` - Optimized for social media sharing
- `silicon-batch [theme] <files...>` - Batch screenshot multiple files

## Usage Examples

```bash
# Basic screenshot
silicon main.py -o screenshot.png

# Screenshot with custom theme
silicon --theme "GitHub" main.py -o light-screenshot.png

# Screenshot specific lines with highlighting
silicon main.py --highlight-lines "10-20" --line-number -o function.png

# Quick screenshot using alias
silicon-quick main.py

# Social media optimized screenshot
silicon-social main.py my-code.png

# Batch screenshots
silicon-batch Dracula *.py *.js *.rs
```

## Themes

Silicon uses the same themes as `bat`. Popular themes include:

- **Dracula** - Dark purple theme (default)
- **GitHub** - Light theme, good for presentations
- **Monokai Extended** - Popular dark theme
- **OneHalfDark** - Balanced dark theme
- **Oceanic Next** - Blue-green dark theme
- **Solarized (dark)** - Classic dark theme
- **Solarized (light)** - Classic light theme

List all themes: `silicon --list-themes`

## Adding Custom Themes

You can add themes that work with `bat`:

1. Download `.tmTheme` files to `~/.config/bat/themes/`
2. Run `bat cache --build` to build the cache
3. Run `silicon --build-cache` to build Silicon's cache
4. Use with `silicon --theme "Your Theme Name"`

## Dependencies

The following system libraries are automatically installed:

- pkg-config
- libfontconfig1-dev
- libfreetype6-dev  
- libxcb-composite0-dev
- libxcb-render0-dev
- libxcb-shape0-dev
- libxcb-xfixes0-dev
- libharfbuzz-dev
- libexpat1-dev
- libxml2-dev

## Troubleshooting

### Installation Issues
If Silicon fails to install:
1. Ensure Rust/Cargo is installed: `cargo --version`
2. Install system dependencies: `./shared/install-packages.sh development`
3. Try manual installation: `cargo install silicon`

### Font Issues
If fonts don't render correctly:
1. Install Fira Code: `sudo apt install fonts-firacode`
2. Or change font in config: `family = "JetBrains Mono"`

### Theme Issues
If themes don't work:
1. List available themes: `silicon --list-themes`
2. Rebuild theme cache: `silicon --build-cache`
3. Check bat themes: `bat --list-themes`

## Alternatives

If Silicon doesn't work for your use case:

- **Carbon CLI**: `npm install -g carbon-now-cli`
- **CodeShot**: Web-based at carbon.now.sh
- **Ray.so**: Web-based code screenshot tool
- **Manual**: Take screenshots of your editor

## Contributing

To improve the Silicon configuration:

1. Edit `app-settings/silicon/config.toml` for default settings
2. Add new aliases/functions to `shared/.aliases`
3. Update this README with new features
4. Test changes with `./shared/install-packages.sh terminal_utils`
