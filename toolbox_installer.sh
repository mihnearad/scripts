#!/bin/bash

set -e

### 1. Ensure gum is installed
install_gum() {
  echo "Gum is not installed. Installing gum..."
  ARCH=$(uname -m)
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')

  case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64 | arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
  esac

  VERSION=$(curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest | grep tag_name | cut -d '"' -f 4)
  if [ -z "$VERSION" ]; then
    echo "Failed to fetch the latest gum version."
    exit 1
  fi

  URL="https://github.com/charmbracelet/gum/releases/download/${VERSION}/gum_${VERSION#v}_${OS}_${ARCH}.tar.gz"

  echo "Downloading gum from $URL..."
  curl -L "$URL" -o gum.tar.gz
  mkdir -p gum-install
  tar -xzf gum.tar.gz -C gum-install
  sudo mv gum-install/gum /usr/local/bin/
  rm -rf gum.tar.gz gum-install

  if ! command -v gum &> /dev/null; then
    echo "Failed to install gum."
    exit 1
  fi

  echo "Gum installed successfully!"
}

### 2. Install selected tools
install_micro() {
  echo "Installing Micro..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install micro
  else
    sudo apt update && sudo apt install -y micro
  fi
}

install_ranger() {
  echo "Installing Ranger..."
  sudo apt update && sudo apt install -y ranger
}

install_ohmyzsh() {
  echo "Installing Oh My Zsh..."
  if ! command -v zsh &> /dev/null; then
    sudo apt update && sudo apt install -y zsh
  fi
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

### 3. Show menu and execute selections
main_menu() {
  choices=$(gum choose --no-limit --cursor ">" --header "Select tools to install:" micro ranger oh-my-zsh exit)

  for choice in $choices; do
    case $choice in
      micro)
        install_micro
        ;;
      ranger)
        install_ranger
        ;;
      oh-my-zsh)
        install_ohmyzsh
        ;;
      exit)
        echo "Exiting installer."
        exit 0
        ;;
      *)
        echo "Unknown choice: $choice"
        ;;
    esac
  done
}

### Run
install_gum_if_needed
main_menu
