#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/home/chira/.config/waybar/network-common.sh
source "$script_dir/network-common.sh"

iface="$(get_default_iface || true)"

if [[ -z "$iface" ]]; then
  notify-send "Waybar" "Sem conexao para copiar IP."
  exit 0
fi

ipv4="$(get_ipv4_for_iface "$iface")"
ipv6="$(get_ipv6_for_iface "$iface")"
payload="$(build_ip_payload "$ipv4" "$ipv6")"

if [[ -z "$payload" ]]; then
  notify-send "Waybar" "Sem IP local disponivel."
  exit 0
fi

printf '%s' "$payload" | wl-copy
notify-send "Waybar" "IPs copiados: $payload"
