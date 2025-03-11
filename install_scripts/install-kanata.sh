# this is not installing but setting it up,
# should add the install part later also, possible curling from releases, as in ps

_link() {
    local source=${1}
    local link=${2}
    if [ -f "$link" ] || [ -d "$link" ]; then
        echo "⚠ $link already exists"
    elif sudo -E ln -s "$source" "$link"; then
        echo "✓ $source linked"
    else
        echo "𐄂 Error linking $source"
    fi
}

DOT_FILES_DIR="$HOME/dot_files"

sudo mkdir /etc/kanata/

_link "$DOT_FILES_DIR/kanata/kanata.service" "/lib/systemd/system/kanata.service"
_link "$DOT_FILES_DIR/kanata/kanata.kbd" "/etc/kanata/kanata.kbd"

sudo -E systemctl daemon-reload
sudo -E systemctl enable kanata.service
sudo -E systemctl start kanata.service
sudo -E systemctl status kanata.service # check whether the service is running
