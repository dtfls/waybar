#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/home/chira/.config/waybar/network-common.sh
source "$script_dir/network-common.sh"

iface="$(get_default_iface || true)"

if [[ -z "$iface" ]]; then
  jq -cRn \
    --arg text '󰌙' \
    --arg tooltip 'Sem conexao' \
    '{text: $text, tooltip: $tooltip, class: ["disconnected"]}'
  exit 0
fi

ipv4="$(get_ipv4_for_iface "$iface")"
ipv6="$(get_ipv6_for_iface "$iface")"

if [[ -z "$ipv4" && -z "$ipv6" ]]; then
  jq -cRn \
    --arg text '󰌙' \
    --arg tooltip 'Sem conexao' \
    '{text: $text, tooltip: $tooltip, class: ["disconnected"]}'
  exit 0
fi

if is_wireless_iface "$iface"; then
  icon='󰖩'
  kind='wifi'
else
  icon='󰈀'
  kind='wired'
fi

tooltip="$iface"
if [[ -n "$ipv4" ]]; then
  tooltip="$tooltip
IPv4 $ipv4"
fi
if [[ -n "$ipv6" ]]; then
  tooltip="$tooltip
IPv6 $ipv6"
fi

jq -cRn \
  --arg text "$icon" \
  --arg tooltip "$tooltip" \
  --arg kind "$kind" \
  '{text: $text, tooltip: $tooltip, class: ["connected", $kind]}'
