#!/usr/bin/env sh

set -u

emit_status() {
  text="$1"
  tooltip="$2"
  class_name="$3"

  jq -cn \
    --arg text "$text" \
    --arg tooltip "$tooltip" \
    --arg class "$class_name" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

if ! command -v pactl >/dev/null 2>&1; then
  emit_status "🎙 ?" "pactl nao encontrado" "error"
  exit 0
fi

source_name=$(pactl get-default-source 2>/dev/null) || {
  emit_status "🎙 ?" "Fonte de entrada padrao nao encontrada" "error"
  exit 0
}

mute_state=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}')
volume=$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | awk -F'/' 'NR == 1 {gsub(/ /, "", $2); print $2}')

if [ -z "$mute_state" ] || [ -z "$volume" ]; then
  emit_status "🎙 ?" "Nao foi possivel ler o estado do microfone" "error"
  exit 0
fi

tooltip="Microfone
Fonte: $source_name
Volume: $volume
Clique esquerdo: mute/unmute
Scroll: ajustar volume"

if [ "$mute_state" = "yes" ]; then
  emit_status "🎙 OFF" "$tooltip
Estado: mutado" "muted"
  exit 0
fi

emit_status "🎙 $volume" "$tooltip
Estado: ativo" "active"
