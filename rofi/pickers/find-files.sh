#!/usr/bin/env bash

DIR="${SEARCH_DIR:-$HOME}"

if [ -z "$1" ]; then
    fdfind -t f . "$DIR" | awk -F/ '{printf "%s\0info\x1f%s\n", $NF, $0}'
else
    xdg-open "$ROFI_INFO" > /dev/null 2>&1 &
    exit 0
fi
