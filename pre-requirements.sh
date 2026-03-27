#!/usr/bin/env bash

set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  echo "Este script foi feito para Arch Linux e precisa do pacman."
  exit 1
fi

required_packages=(
  waybar
  cava
  jq
  playerctl
  zenity
  pavucontrol
  ttf-jetbrains-mono-nerd
)

missing_packages=()
for pkg in "${required_packages[@]}"; do
  if ! pacman -Qq "$pkg" >/dev/null 2>&1; then
    missing_packages+=("$pkg")
  fi
done

if [[ ${#missing_packages[@]} -eq 0 ]]; then
  echo "Todos os pacotes necessarios ja estao instalados."
else
  echo "Pacotes a instalar:"
  printf '  - %s\n' "${missing_packages[@]}"

  if [[ ${EUID} -eq 0 ]]; then
    pacman -Syu --needed "${missing_packages[@]}"
  elif command -v sudo >/dev/null 2>&1; then
    sudo pacman -Syu --needed "${missing_packages[@]}"
  elif command -v doas >/dev/null 2>&1; then
    doas pacman -Syu --needed "${missing_packages[@]}"
  else
    echo "Nao encontrei sudo nem doas. Rode como root:"
    echo "pacman -Syu --needed ${missing_packages[*]}"
    exit 1
  fi
fi

required_binaries=(
  waybar
  jq
  playerctl
  zenity
  pavucontrol
  pactl
)

echo
echo "Validando binarios usados pela configuracao..."
for bin in "${required_binaries[@]}"; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "  [ok] $bin"
  else
    echo "  [faltando] $bin"
  fi
done

echo
echo "Observacoes:"

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || pgrep -x Hyprland >/dev/null 2>&1; then
  echo "  [ok] Hyprland detectado."
else
  echo "  [aviso] Esta configuracao usa modulos do Hyprland."
fi

if pactl info >/dev/null 2>&1; then
  echo "  [ok] Servidor de audio compativel com PulseAudio detectado."
else
  echo "  [aviso] O widget de volume precisa de PulseAudio ou PipeWire-Pulse em execucao."
fi

echo "  [info] O bloco de reproducao no centro depende de players com suporte a MPRIS."
echo
echo "Concluido."
