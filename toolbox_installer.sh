#!/bin/bash
set -e

# Detect shell rc
SHELL_RC="$HOME/.bashrc"
[[ $SHELL = */zsh ]] && SHELL_RC="$HOME/.zshrc"


# Check if gum is installed
if ! command -v gum &>/dev/null; then
  echo "gum is not installed. Installing gum..."

  if [ -f /etc/debian_version ]; then
    sudo apt update
    sudo apt install -y curl gnupg
    echo "deb [trusted=yes] https://apt.charm.sh/ stable main" | sudo tee /etc/apt/sources.list.d/charm.list
    curl -fsSL https://github.com/charmbracelet/gum/releases/latest/download/gum_0.13.0_amd64.deb -o /tmp/gum.deb
    sudo apt install -y /tmp/gum.deb
  else
    echo "Your OS is not supported for auto gum install. Please install gum manually from:"
    echo "https://github.com/charmbracelet/gum#installation"
    exit 1
  fi
fi
# Select packages
SELECTED=$(gum choose --no-limit "fzf" "ranger" "micro" "zsh" "git" "curl" "skip" \
    --header="Select tools to install:")

PACKAGES=()
for tool in $SELECTED; do
    [[ "$tool" != "skip" ]] && PACKAGES+=("$tool")
done

# Detect OS + install selected packages
if [ -f /etc/debian_version ]; then
    sudo apt update
    for pkg in "${PACKAGES[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            echo "Installing $pkg..."
            sudo apt install -y "$pkg"
        fi
    done
elif [ -f /etc/SuSE-release ]; then
    sudo zypper refresh
    for pkg in "${PACKAGES[@]}"; do
        sudo zypper install -y "$pkg"
    done
else
    echo "Unsupported OS."
    exit 1
fi

# Aliases
if gum confirm "Do you want to alias ssh='kitten ssh'?"; then
    grep -qxF "alias ssh='kitten ssh'" "$SHELL_RC" || echo "alias ssh='kitten ssh'" >> "$SHELL_RC"
fi

if gum confirm "Add syntax highlighting and fzf setup to $SHELL_RC?"; then
    echo "[ -f ~/.fzf.bash ] && source ~/.fzf.bash" >> "$SHELL_RC"
    echo "alias ll='ls --color=auto -alF'" >> "$SHELL_RC"
    echo "export EDITOR='micro'" >> "$SHELL_RC"
fi

gum format --theme=dark <<EOF

# Done!
Your shell has been configured. Restart your shell or run:

\`source $SHELL_RC\`

EOF
