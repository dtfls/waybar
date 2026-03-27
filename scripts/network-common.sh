#!/usr/bin/env bash

get_default_iface() {
  local iface

  iface=$(ip -4 route show default 2>/dev/null | awk '/default/ {for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
  if [[ -n "$iface" ]]; then
    printf '%s\n' "$iface"
    return 0
  fi

  iface=$(ip -6 route show default 2>/dev/null | awk '/default/ {for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
  if [[ -n "$iface" ]]; then
    printf '%s\n' "$iface"
  fi
}

is_wireless_iface() {
  [[ -d "/sys/class/net/$1/wireless" ]]
}

get_ipv4_for_iface() {
  ip -o -4 addr show dev "$1" scope global up 2>/dev/null |
    awk '
      {
        sub(/\/.*/, "", $4)
        if (out != "") {
          out = out ", " $4
        } else {
          out = $4
        }
      }
      END {
        if (out != "") {
          print out
        }
      }
    '
}

get_ipv6_for_iface() {
  ip -o -6 addr show dev "$1" scope global up 2>/dev/null |
    awk '
      {
        sub(/\/.*/, "", $4)
        if ($4 ~ /^fe80:/) {
          next
        }
        if (out != "") {
          out = out ", " $4
        } else {
          out = $4
        }
      }
      END {
        if (out != "") {
          print out
        }
      }
    '
}

build_ip_payload() {
  local ipv4="$1"
  local ipv6="$2"

  if [[ -n "$ipv4" && -n "$ipv6" ]]; then
    printf '%s | %s\n' "$ipv4" "$ipv6"
  elif [[ -n "$ipv4" ]]; then
    printf '%s\n' "$ipv4"
  elif [[ -n "$ipv6" ]]; then
    printf '%s\n' "$ipv6"
  fi
}
