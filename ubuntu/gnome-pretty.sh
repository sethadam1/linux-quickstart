#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

SUDO=""
if [[ "${EUID}" -ne 0 ]]; then
  SUDO="sudo"
fi

if ! command -v apt >/dev/null 2>&1; then
  echo "apt not found. This script is for Ubuntu."
  exit 1
fi

log "Install fonts (safe defaults + great mono font)"
${SUDO} apt -y install \
  fonts-noto \
  fonts-noto-color-emoji \
  fonts-jetbrains-mono \
  fonts-firacode \
  fontconfig

# Inter is nice if it exists in repos
log "Try installing Inter (optional)"
${SUDO} apt -y install fonts-inter 2>/dev/null || true

log "Refresh font cache"
fc-cache -f >/dev/null 2>&1 || true

log "Set GNOME font defaults (macOS-ish, still GNOME)"
# Prefer Inter if it actually installed, otherwise fall back to Noto Sans.
UI_FONT="Noto Sans 11"
DOC_FONT="Noto Sans 11"
TITLE_FONT="Noto Sans Bold 11"

if fc-list | grep -qi "Inter"; then
  UI_FONT="Inter 11"
  DOC_FONT="Inter 11"
  TITLE_FONT="Inter Bold 11"
fi

MONO_FONT="JetBrains Mono 11"

gsettings set org.gnome.desktop.interface font-name "${UI_FONT}"
gsettings set org.gnome.desktop.interface document-font-name "${DOC_FONT}"
gsettings set org.gnome.desktop.interface monospace-font-name "${MONO_FONT}"
gsettings set org.gnome.desktop.wm.preferences titlebar-font "${TITLE_FONT}"

log "Improve font rendering"
gsettings set org.gnome.desktop.interface font-antialiasing "rgba"
gsettings set org.gnome.desktop.interface font-hinting "slight"

log "A few GNOME touches that feel more 'Mac' without becoming a theme project"
# Natural scrolling like macOS
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true

# Tap-to-click on touchpad
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

# Show battery percentage
gsettings set org.gnome.desktop.interface show-battery-percentage true

# A little quicker key repeat feels snappier for dev work
gsettings set org.gnome.desktop.peripherals.keyboard repeat true
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 25

log "Done"
echo
echo "Next:"
echo "  - Log out and back in (or reboot) so all apps pick up the new fonts cleanly."
echo "  - Open GNOME Tweaks if you want to adjust font sizes per category."
