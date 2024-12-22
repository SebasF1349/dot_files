#!/bin/bash

title=$(playerctl metadata title | sed -e 's/ - YouTube Music//; s/ - YouTube//; s/&/\&amp;/g; s/"/\\\"/g' | tr -d '\n')
status=$(playerctl status | tr -d '\n')
artist=$(playerctl metadata artist | tr -d '\n')
trackid=$(playerctl metadata mpris:trackid | tr -d '\n')

text="${title} - ${artist}"
if [[ $trackid == *"firefox"* && $status == "Playing" ]]; then
    alt="Firefox"
else
    alt="${status}"
fi

if [ ! -z "$title" ]; then
    echo "{\"alt\": \"$alt\", \"tooltip\": \"$text\", \"text\": \"$text\"}" 
fi
