# need developer tools for git
# Check if Command Line Tools are already installed
if xcode-select -p &>/dev/null; then
    echo "Xcode Command Line Tools are already installed."
else
    echo "Xcode Command Line Tools are not installed. Proceeding with installation..."
    # Create the marker file to enable installation via softwareupdate
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # Install the Command Line Tools
    echo "Finding Xcode Software Name..."
    UPDATE_LABEL=$(softwareupdate --list | \
                    awk -F: '/^ *\* Label: / {print $2}' | \
                    grep -i "Command Line Tools for Xcode" | \
                    head -n 1 | \
                    xargs)
    echo "Name Found: $UPDATE_LABEL"
    echo "Installing Xcode Command Line Tools..."
    echo "Running: `softwareupdate --install $UPDATE_LABEL --verbose`"
    softwareupdate --install "$UPDATE_LABEL" --verbose

    # Remove the marker file
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # Verify installation
    if xcode-select -p &>/dev/null; then
        echo "Xcode Command Line Tools successfully installed."
    else
        echo "Failed to install Xcode Command Line Tools."
        exit 1
    fi
fi

# Setup Git
git config --global user.name "Malcom Gilbert"
git config --global user.email malcomgilbert@gmail.com
git config --global core.editor "subl -n -w"
git config --global push.default matching
git config --global core.excludesfile ~/.gitignore
echo *.DS_Store >> ~/.gitignore

if [ ! -f ~/.git-prompt.sh ]; then
  curl -o ~/.git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi

mkdir ~/git
cd ~/git

# pull down dotfiles
git clone https://github.com/mjgil/dotfiles.git

# make sure dot files have correct remote origin
cd dotfiles
git remote set-url origin git@github.com:mjgil/dotfiles.git
cd ~/git

git clone https://github.com/mjgil/z.git
#
/Users/$(whoami)/git/dotfiles/mac/installSettingsAndApps.sh
/Users/$(whoami)/git/dotfiles/mac/update-bashrc.sh

ssh-keygen -t rsa -b 4096 -C "malcomgilbert@gmail.com"
