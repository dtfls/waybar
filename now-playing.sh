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
artist=$(playerctl -s -p "$player" metadata artist 2>/dev/null | paste -sd ', ' -)
title=$(playerctl -s -p "$player" metadata title 2>/dev/null)
album=$(playerctl -s -p "$player" metadata album 2>/dev/null)

if [ -n "$artist" ] && [ -n "$title" ]; then
  text_body="$artist - $title"
elif [ -n "$title" ]; then
  text_body="$title"
elif [ -n "$artist" ]; then
  text_body="$artist"
else
  text_body="$player"
fi

tooltip="$player"
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
    sec=$(date +%S | sed 's/^0//')
    [ -z "$sec" ] && sec=0
    frame=$((sec % 4))
    case "$frame" in
      0) icon="|>" ;;
      1) icon="||>" ;;
      2) icon="|||" ;;
      *) icon=">||" ;;
    esac
    class="playing"
    ;;
  Paused)
    icon="||"
    class="paused"
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
