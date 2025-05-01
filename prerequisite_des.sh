#!/bin/bash
trap error_callback ERR 
error_callback() {      
  echo 'Error Occurs'   
  exit 1                
}                       

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

# google test installation
sudo apt-get install libgtest-dev -y

