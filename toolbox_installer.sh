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

# Always add fzf integration if installed
if [ -f ~/.fzf.bash ]; then
    append_if_missing "[ -f ~/.fzf.bash ] && source ~/.fzf.bash"
fi
append_if_missing "export EDITOR='micro'"

# Optional: color aliases and prompt
read -rp "Add color aliases and PS1 prompt to $SHELL_RC? [Y/n]: " confirm_colors
confirm_colors=${confirm_colors,,}
if [[ "$confirm_colors" == "y" || "$confirm_colors" == "" ]]; then
    append_if_missing ""
    append_if_missing "# Enable color support for ls and common commands"
    append_if_missing "if [ -x /usr/bin/dircolors ]; then"
    append_if_missing "  test -r ~/.dircolors && eval \"\$(dircolors -b ~/.dircolors)\" || eval \"\$(dircolors -b)\""
    append_if_missing "  alias ls='ls --color=auto'"
    append_if_missing "  alias dir='dir --color=auto'"
    append_if_missing "  alias vdir='vdir --color=auto'"
    append_if_missing "  alias grep='grep --color=auto'"
    append_if_missing "  alias fgrep='fgrep --color=auto'"
    append_if_missing "  alias egrep='egrep --color=auto'"
    append_if_missing "fi"

    append_if_missing ""
    append_if_missing "# Custom PS1 prompt with colors"
    append_if_missing "PS1='\\[\\e[0;32m\\]\\u@\\h \\[\\e[0;33m\\]\\w \\$\\[\\e[0m\\] '"
fi
echo ""
echo "✅ Setup complete. Restart your shell or run:"
echo ""
echo "  source $SHELL_RC"
echo ""
