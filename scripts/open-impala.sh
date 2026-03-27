#!/usr/bin/env bash

set -euo pipefail

if ! command -v impala >/dev/null 2>&1; then
  notify-send "Waybar" "Impala nao encontrado."
  exit 1
fi

if command -v foot >/dev/null 2>&1; then
  foot --log-level=error -T impala impala >/dev/null 2>&1 &
  exit 0
fi

if command -v kitty >/dev/null 2>&1; then
  kitty --title impala impala >/dev/null 2>&1 &
  exit 0
fi

if command -v alacritty >/dev/null 2>&1; then
  alacritty -T impala -e impala >/dev/null 2>&1 &
  exit 0
fi

notify-send "Waybar" "Nenhum terminal encontrado para abrir o impala."
