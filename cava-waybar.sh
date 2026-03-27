#!/usr/bin/env bash

set -uo pipefail

config_file="/home/chira/.config/waybar/cava-waybar.conf"
bars=10
cava_pid=""
cava_fd=""
visible=0

has_playing_player() {
  playerctl -a -s -f '{{status}}' status 2>/dev/null | grep -qx 'Playing'
}

cleanup_cava() {
  if [[ -n "$cava_fd" ]]; then
    exec {cava_fd}<&- 2>/dev/null || true
    cava_fd=""
  fi

  if [[ -n "$cava_pid" ]]; then
    kill "$cava_pid" 2>/dev/null || true
    wait "$cava_pid" 2>/dev/null || true
    cava_pid=""
  fi
}

cleanup_all() {
  cleanup_cava
  exit 0
}

trap cleanup_all PIPE INT TERM
trap cleanup_cava EXIT

render_frame() {
  local value
  local out=""

  for value in "$@"; do
    case "$value" in
      0) out+=" " ;;
      1) out+="▁" ;;
      2) out+="▂" ;;
      3) out+="▃" ;;
      4) out+="▄" ;;
      5) out+="▅" ;;
      6) out+="▆" ;;
      *) out+="▇" ;;
    esac
  done

  printf '%s\n' "$out" || exit 0
}

hide_module() {
  if (( visible == 1 )); then
    printf '\n' || exit 0
    visible=0
  fi
}

start_cava() {
  cleanup_cava
  coproc CAVA_STREAM { exec cava -p "$config_file" 2>/dev/null; }
  cava_pid=$CAVA_STREAM_PID
  cava_fd=${CAVA_STREAM[0]}
  exec {CAVA_STREAM[1]}>&- 2>/dev/null || true
}

read_frame() {
  local frame=()
  local value

  for ((i = 0; i < bars; i++)); do
    if ! IFS= read -r -t 1 -u "$cava_fd" value; then
      return 1
    fi
    frame+=("$value")
  done

  render_frame "${frame[@]}"
  visible=1
}

command -v cava >/dev/null 2>&1 || exit 0

while :; do
  if ! has_playing_player; then
    cleanup_cava
    hide_module
    sleep 0.3
    continue
  fi

  if [[ -z "$cava_pid" ]] || ! kill -0 "$cava_pid" 2>/dev/null; then
    start_cava
    sleep 0.1
  fi

  if ! read_frame; then
    cleanup_cava
    sleep 0.2
  fi
done
