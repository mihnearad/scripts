#!/bin/bash
set -e

# Define tools to install
TOOLS=("fzf" "ranger" "micro" "zsh" "git" "curl")
SELECTED_TOOLS=()

# Detect shell rc
SHELL_RC="$HOME/.bashrc"
[[ $SHELL = */zsh ]] && SHELL_RC="$HOME/.zshrc"

echo "== Shell Toolbox Installer =="

# Tool selection
echo ""
echo "Select tools to install (Y/n):"
for tool in "${TOOLS[@]}"; do
    read -rp "Install $tool? [Y/n]: " yn
    yn=${yn,,} # to lowercase
    if [[ "$yn" == "y" || "$yn" == "" ]]; then
        SELECTED_TOOLS+=("$tool")
    fi
done

# Detect OS and package manager
if [ -f /etc/debian_version ]; then
    OS="debian"
    PACKAGE_MANAGER="apt"
    sudo apt update
elif grep -qi suse /etc/os-release 2>/dev/null; then
    OS="suse"
    PACKAGE_MANAGER="zypper"
    sudo zypper refresh
else
    echo "Unsupported OS"
    exit 1
fi

# Install selected tools
for pkg in "${SELECTED_TOOLS[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
        echo "Installing $pkg..."
        sudo "$PACKAGE_MANAGER" install -y "$pkg"
    else
        echo "$pkg already installed"
    fi
done

# Function to append to shell config if not already there
append_if_missing() {
    local LINE="$1"
    grep -qxF "$LINE" "$SHELL_RC" || echo "$LINE" >> "$SHELL_RC"
}

# Alias kitten ssh
read -rp "Alias ssh='kitten ssh'? [Y/n]: " confirm_ssh
confirm_ssh=${confirm_ssh,,}
if [[ "$confirm_ssh" == "y" || "$confirm_ssh" == "" ]]; then
    append_if_missing "alias ssh='kitten ssh'"
fi

# FZF config + color aliases
read -rp "Add syntax highlighting and fzf setup to $SHELL_RC? [Y/n]: " confirm_fzf
confirm_fzf=${confirm_fzf,,}
if [[ "$confirm_fzf" == "y" || "$confirm_fzf" == "" ]]; then
    append_if_missing "[ -f ~/.fzf.bash ] && source ~/.fzf.bash"
    append_if_missing "alias ll='ls --color=auto -alF'"
    append_if_missing "export EDITOR='micro'"
fi

echo ""
echo "✅ Setup complete. Restart your shell or run:"
echo ""
echo "  source $SHELL_RC"
echo ""
