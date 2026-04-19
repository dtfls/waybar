#!/usr/bin/env sh

player=$(
  playerctl -a -s -f '{{playerName}} {{status}}' status 2>/dev/null |
    awk '
      $2 == "Playing" { print $1; found=1; exit }
      $2 == "Paused" && paused == "" { paused=$1 }
      END { if (!found && paused != "") print paused }
    '
)

[ -z "$player" ] && exit 0

status=$(playerctl -s -p "$player" status 2>/dev/null) || exit 0
artist=$(playerctl -s -p "$player" metadata artist 2>/dev/null | awk 'NR == 1 { printf "%s", $0; next } { printf ", %s", $0 } END { if (NR) printf "\n" }')
title=$(playerctl -s -p "$player" metadata title 2>/dev/null)
album=$(playerctl -s -p "$player" metadata album 2>/dev/null)
url=$(playerctl -s -p "$player" metadata xesam:url 2>/dev/null)
trackid=$(playerctl -s -p "$player" metadata mpris:trackid 2>/dev/null)

if printf '%s\n%s\n' "$url" "$trackid" | grep -q 'music.youtube.com'; then
  if [ -n "$title" ] && [ -n "$artist" ]; then
    text_body="$title - $artist"
  elif [ -n "$title" ]; then
    text_body="$title"
  elif [ -n "$artist" ]; then
    text_body="$artist"
  else
    text_body="$player"
  fi
elif [ -n "$title" ]; then
  text_body="$title"
elif [ -n "$artist" ]; then
  text_body="$artist"
else
  text_body="$player"
fi

tooltip="$player"
if [ -n "$url" ]; then
  tooltip="$tooltip
$url"
fi
if [ -n "$album" ]; then
  tooltip="$tooltip
$album"
fi
if [ "$text_body" != "$player" ]; then
  tooltip="$tooltip
$text_body"
fi

case "$status" in
  Playing)
    class="playing"
    icon="󰎆"
    ;;
  Paused)
    class="paused"
    icon="󰏤"
    ;;
  *)
    exit 0
    ;;
esac

jq -cRn \
  --arg text "$icon $text_body" \
  --arg tooltip "$tooltip" \
  --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
