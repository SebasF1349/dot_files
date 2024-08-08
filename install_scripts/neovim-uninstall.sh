#!/usr/bin/bash

force=false

while getopts 'f' flag; do
    case "${flag}" in
    f) force=true ;;
    *) ;;
    esac
done

if ! command -v "nvim" &>/dev/null; then
    echo "nvim could not be found"
    if [ "$force" = false ]; then
        exit 1
    else
        echo "Removing orphan files"
    fi
fi

sudo rm /usr/local/share/man/man1/nvim.1
sudo rm /usr/local/share/applications/nvim.desktop
sudo rm /usr/local/bin/nvim
sudo rm -rf /usr/local/share/nvim/
sudo rm -rf "$HOME/apps/neovim"
