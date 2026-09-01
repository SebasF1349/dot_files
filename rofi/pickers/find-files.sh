#!/usr/bin/env bash

DIR="${SEARCH_DIR:-$HOME}"
CACHE_FILE="/tmp/rofi_fd_cache"

generate_cache() {
    fdfind -t f . "$DIR" 2>/dev/null | awk -F/ '{printf "%s\0info\x1f%s\n", $NF, $0}' >"$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

if [ ! -f "$CACHE_FILE" ]; then
    generate_cache
elif [ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -gt 3600 ]; then
    generate_cache &
fi

if [ -n "$ROFI_INFO" ]; then
    xdg-open "$ROFI_INFO" >/dev/null 2>&1 &
    exit 0
fi

cat "$CACHE_FILE"
