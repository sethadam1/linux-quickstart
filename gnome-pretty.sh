#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

SUDO=""
if [[ "${EUID}" -ne 0 ]]; then
  SUDO="sudo"
fi

if ! command -v dnf >/dev/null 2>&1; then
  echo "dnf not found. This script is for Fedora."
  exit 1
fi

log "Install fonts (safe defaults + great mono font)"
${SUDO} dnf -y install \
  google-noto-sans-fonts \
  google-noto-serif-fonts \
  google-noto-sans-mono-fonts \
  jetbrains-mono-fonts \
  fira-code-fonts \
  fontconfig

# Inter is nice if it exists in repos on your Fedora version.
# If it doesn't, we quietly continue.
log "Try installing Inter (optional)"
${SUDO} dnf -y install rsms-inter-fonts 2>/dev/null || true
${SUDO} dnf -y install inter-fonts 2>/dev/null || true

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
# Fedora defaults are already decent, but these usually look nicer on laptop panels.
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