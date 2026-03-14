#!/bin/bash

CONFIG_DIR="$HOME/.config"
DOT_FILES_DIR="$HOME/dot_files"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
FORCE_OVERWRITE=false

while getopts "f" opt; do
    case ${opt} in
    f) FORCE_OVERWRITE=true ;;
    \?)
        echo "Usage: $0 [-f]"
        exit 1
        ;;
    esac
done

declare -A file_links=(
    ["$HOME/.bashrc"]="$DOT_FILES_DIR/bash/.bashrc"
    ["$HOME/.gitconfig"]="$DOT_FILES_DIR/git/.gitconfig"
    ["$HOME/.vimrc"]="$DOT_FILES_DIR/vim/.vimrc"
    ["$HOME/.ideavimrc"]="$DOT_FILES_DIR/ideavim/.ideavimrc"
    ["$CONFIG_DIR/starship.toml"]="$DOT_FILES_DIR/starship/starship.toml"
    ["$HOME/.xinitrc"]="$DOT_FILES_DIR/.xinitrc"
)

declare -A dir_links=(
    ["$CONFIG_DIR/bat"]="$DOT_FILES_DIR/bat/"
    ["$CONFIG_DIR/nvim"]="$DOT_FILES_DIR/nvim/"
    ["$CONFIG_DIR/waybar"]="$DOT_FILES_DIR/waybar/"
    ["$CONFIG_DIR/sway"]="$DOT_FILES_DIR/sway/"
    ["$CONFIG_DIR/wezterm"]="$DOT_FILES_DIR/wezterm/"
    ["$CONFIG_DIR/tealdeer"]="$DOT_FILES_DIR/tealdeer/"
    ["$CONFIG_DIR/rofi"]="$DOT_FILES_DIR/rofi/"
    ["$CONFIG_DIR/wofi"]="$DOT_FILES_DIR/wofi/"
    ["$CONFIG_DIR/picom"]="$DOT_FILES_DIR/picom/"
)

declare -A hypr_dir_links=(
    ["$CONFIG_DIR/hypr"]="$DOT_FILES_DIR/hypr/"
    ["$CONFIG_DIR/hyprland-autoname-workspaces"]="$DOT_FILES_DIR/hyprland-autoname-workspaces/"
)

declare -A i3_dir_links=(
    ["$CONFIG_DIR/i3"]="$DOT_FILES_DIR/i3/"
)

_process_link() {
    local source=${1}
    local link=${2}
    local exists=false

    if [ -e "$link" ] || [ -L "$link" ]; then
        exists=true
    fi

    if [ "$FORCE_OVERWRITE" = true ]; then
        choice="l"
    else
        if [ "$exists" = true ]; then
            echo -n "Action for $link: [l]ink (overwrite), [b]ackup & link, [s]kip: "
        else
            echo -n "Action for $link: [l]ink, [s]kip: "
        fi
        read -r choice
    fi

    case "$choice" in
    b | B)
        if [ "$exists" = true ]; then
            mkdir -p "$BACKUP_DIR"
            local base_name
            base_name=$(basename "$link")
            mv "$link" "$BACKUP_DIR/$base_name"
            echo "  → Backed up to $BACKUP_DIR/$base_name"
        fi
        ln -s "$source" "$link" && echo "  ✓ Linked $link"
        ;;
    l | L)
        if [ "$exists" = true ]; then
            rm -rf "$link"
        fi
        ln -s "$source" "$link" && echo "  ✓ Linked $link"
        ;;
    s | S)
        echo "  skipped $link"
        ;;
    *)
        echo "  invalid option, skipping $link..."
        ;;
    esac
}

if [ "$FORCE_OVERWRITE" = true ]; then
    echo "!!! FORCE MODE ENABLED: Overwriting existing files !!!"
else
    echo "Backup directory (if used): $BACKUP_DIR"
fi
echo "------------------------------------------------"

for i in "${!file_links[@]}"; do _process_link "${file_links[$i]}" "$i"; done
for i in "${!dir_links[@]}"; do _process_link "${dir_links[$i]}" "$i"; done

if command -v "hyprland" >/dev/null 2>&1; then
    for i in "${!hypr_dir_links[@]}"; do _process_link "${hypr_dir_links[$i]}" "$i"; done
fi

if command -v "i3" >/dev/null 2>&1; then
    for i in "${!i3_dir_links[@]}"; do _process_link "${i3_dir_links[$i]}" "$i"; done
fi

echo -e "\nDone!"
