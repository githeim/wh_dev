#!/bin/bash
sudo apt-get update  && \ 
sudo apt-get install software-properties-common && \
sudo add-apt-repository -y ppa:jonathonf/vim && \
sudo apt update && \
sudo apt install -y vim && \
sudo apt-get install curl build-essential cmake python-dev libncurses5-dev unzip git wget exuberant-ctags clang-8 libclang-8-dev llvm-8-dev rapidjson-dev nodejs yarn -y \
	&& curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
       && sudo apt install gnupg ca-certificates -y \
       && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
       && echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list \
       && sudo apt update && sudo apt install mono-devel -y \
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash - && \
sudo apt install nodejs && \
echo finfin

