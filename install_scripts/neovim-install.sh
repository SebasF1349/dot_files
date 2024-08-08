#!/usr/bin/bash

neovim_dir="$HOME/apps/neovim"

if [ ! -d "$HOME/apps" ]; then
    mkdir "$HOME/apps"
fi

if [ ! -d "$neovim_dir" ]; then
    cd "$HOME/apps" && git clone https://github.com/neovim/neovim

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID_LIKE
    fi
    if [ "$DISTRO" = "debian" ]; then
        sudo apt-get install ninja-build gettext cmake unzip curl build-essential
    elif [ "$DISTRO" = "arch" ]; then
        sudo pacman -Syu base-devel cmake unzip ninja curl
    fi
else
    cd "$neovim_dir" && git fetch origin

    # https://stackoverflow.com/a/3278427
    UPSTREAM="master"
    LOG=$(cd "$neovim_dir" && git log HEAD..origin/$UPSTREAM --oneline)

    if [[ -z "$LOG" ]]; then
        echo "up-to-date"
        exit 1
    fi
fi

cd "$neovim_dir" && git pull origin master &&
    sudo make CMAKE_BUILD_TYPE=RelWithDebInfo && sudo make install
