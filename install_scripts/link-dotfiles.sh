CONFIG_DIR="$HOME/.config"
DOT_FILES_DIR="$HOME/dot_files"

declare -A file_links=(
    ["$HOME/.bashrc"]="$DOT_FILES_DIR/bash/.bashrc"
    ["$HOME/.gitconfig"]="$DOT_FILES_DIR/git/.gitconfig"
    ["$HOME/.vimrc"]="$DOT_FILES_DIR/vim/.vimrc"
    ["$HOME/.ideavimrc"]="$DOT_FILES_DIR/ideavim/.ideavimrc"
    ["$CONFIG_DIR/starship.toml"]="$DOT_FILES_DIR/starship/starship.toml"
)

declare -A dir_links=(
    ["$CONFIG_DIR/bat"]="$DOT_FILES_DIR/bat/"
    ["$CONFIG_DIR/nvim"]="$DOT_FILES_DIR/nvim/"
    ["$CONFIG_DIR/waybar"]="$DOT_FILES_DIR/waybar/"
    ["$CONFIG_DIR/wezterm"]="$DOT_FILES_DIR/wezterm/"
    ["$CONFIG_DIR/tealdeer"]="$DOT_FILES_DIR/tealdeer/"
    ["$CONFIG_DIR/rofi"]="$DOT_FILES_DIR/rofi/" # both??
    ["$CONFIG_DIR/wofi"]="$DOT_FILES_DIR/wofi/" # both??
)

declare -A hypr_dir_links=(
    ["$CONFIG_DIR/hypr"]="$DOT_FILES_DIR/hypr/"
    ["$CONFIG_DIR/hyprland-autoname-workspaces"]="$DOT_FILES_DIR/hyprland-autoname-workspaces/"
    ["$CONFIG_DIR/hypr"]="$DOT_FILES_DIR/hypr/"
)

declare -A i3_dir_links=(
    ["$CONFIG_DIR/i3"]="$DOT_FILES_DIR/i3/"
)

# LibreOffice?

_link() {
    local source=${1}
    local link=${2}
    if [ -f "$link" ] || [ -d "$link" ]; then
        echo "⚠ $link already exists"
    elif ln -s "$source" "$link"; then
        echo "✓ $source linked"
    else
        echo "𐄂 Error linking $source"
    fi
}

for i in "${!file_links[@]}"; do
    _link "${file_links[$i]}" "$i"
done

for i in "${!dir_links[@]}"; do
    _link "${dir_links[$i]}" "$i"
done

if command -v "hyprland" >/dev/null 2>&1; then
    for i in "${!hypr_dir_links[@]}"; do
        _link "${hypr_dir_links[$i]}" "$i"
    done
fi

if command -v "i3" >/dev/null 2>&1; then
    for i in "${!i3_dir_links[@]}"; do
        _link "${i3_dir_links[$i]}" "$i"
    done
fi
