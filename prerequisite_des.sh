#!/bin/bash
error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}
trap 'error ${LINENO}' ERR

sudo apt-get update  && \
sudo apt-get install -y software-properties-common && \
sudo apt update && \
sudo apt install -y vim && \
curl -sL https://deb.nodesource.com/setup_22.x | sudo bash - && \
sudo apt-get install curl build-essential cmake python3-dev libncurses5-dev unzip git wget exuberant-ctags clang-14 libclang-14-dev llvm-14-dev rapidjson-dev yarn nodejs -y \
	&& curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
       && sudo apt install gnupg ca-certificates -y \
       && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
       && sudo apt update && sudo apt install mono-devel -y
sudo apt install -y ninja-build 

# Install lsp server
# c++ lsp : clangd install
sudo apt-get install clangd -y

# python lsp 
sudo apt-get install python3-pylsp -y

# cmake lsp
sudo apt install python3-venv -y
pip install --break-system-packages cmake-language-server

# create LSP server download directory
mkdir -p $HOME/.local/share/vim-lsp-settings/servers

# google test installation
sudo apt-get install libgtest-dev -y

