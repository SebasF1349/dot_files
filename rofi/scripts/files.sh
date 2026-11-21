#!/bin/sh
DB="$HOME/.cache/home.db"
q=""
set -f   # allow unquoted $q word-splitting without globbing

while :; do
  q=$(rofi -dmenu -lines 0 -p "search" -format f -filter "$q" </dev/null) || exit
  list=$(plocate -d "$DB" -i -A -l 2000 -- $q)
  [ -z "$list" ] && continue

  i=$(printf '%s\n' "$list" \
    | perl -ne 'chomp; ($b=$_) =~ s{.*/}{}; print "$b\0meta\x1f$_\n"' \
    | rofi -dmenu -i -format i -p "open" \
     -matching fuzzy -sort -sorting-method fzf \
     -kb-custom-1 "Alt+Tab" -mesg "Alt+Tab: refine query")
  case $? in
    0)  f=$(printf '%s\n' "$list" | sed -n "$((i+1))p")
        [ -n "$f" ] && xdg-open "$f"; exit ;;
    10) continue ;;   # Alt+Left: back to the query
    *)  exit ;;       # Esc: quit
  esac
done
