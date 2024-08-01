#!/usr/bin/bash

if ! command -v "nvim" &>/dev/null; then
    echo "nvim could not be found"
    exit 1
fi

sudo rm /usr/local/share/man/man1/nvim.1
sudo rm /usr/local/share/applications/nvim.desktop
sudo rm /usr/local/bin/nvim
sudo rm -rf /usr/local/share/nvim/
rm -rf "$HOME/apps/neovim"
