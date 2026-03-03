#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

if ! command -v dnf >/dev/null 2>&1; then
  echo "This script expects Fedora (dnf not found)."
  exit 1
fi

SUDO=""
if [[ "${EUID}" -ne 0 ]]; then
  SUDO="sudo"
fi

log "Update Fedora"
${SUDO} dnf -y upgrade --refresh

log "Base tools + GNOME helpers"
${SUDO} dnf -y install \
  curl wget git unzip tar \
  ca-certificates gnupg2 \
  fwupd \
  gnome-tweaks dconf-editor gnome-extensions-app

log "Enable RPM Fusion (free + nonfree)"
FEDVER="$(rpm -E %fedora)"
${SUDO} dnf -y install \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDVER}.noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDVER}.noarch.rpm" || true

log "Multimedia groups (RPM Fusion)"
${SUDO} dnf -y groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin || true
${SUDO} dnf -y groupupdate sound-and-video || true

log "Install system packages via dnf (includes mpv)"
${SUDO} dnf -y install \
  firefox \
  vlc mpv \
  transmission \
  syncthing \
  tailscale \
  audacity \
  handbrake \
  kid3 \
  remmina \
  libreoffice \
  thunderbird \
  mtp-tools gvfs-mtp \
  flatpak

log "Enable and start tailscale"
${SUDO} systemctl enable --now tailscaled || true

log "Enable syncthing for current user"
systemctl --user enable --now syncthing.service || true

log "Add Flathub"
${SUDO} flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

log "Install Flatpaks (GNOME-first where possible)"
# GNOME-native Mastodon client: Tuba
# WezTerm terminal
flatpak install -y flathub \
  dev.geopjr.Tuba \
  org.wezfurlong.wezterm \
  com._1password.1Password \
  com.slack.Slack \
  us.zoom.Zoom \
  md.obsidian.Obsidian \
  com.visualstudio.code \
  io.github.shiftey.Desktop \
  com.dropbox.Client \
  com.openai.ChatGPT \
  sh.cider.Cider \
  org.whatsapp.WhatsApp \
  com.github.IsmaelMartinez.teams_for_linux || true

log "Install Microsoft Edge (official Microsoft repo)"
if ! rpm -q microsoft-edge-stable >/dev/null 2>&1; then
  ${SUDO} rpm --import https://packages.microsoft.com/keys/microsoft.asc || true
  ${SUDO} tee /etc/yum.repos.d/microsoft-edge.repo >/dev/null <<'EOF'
[microsoft-edge]
name=Microsoft Edge
baseurl=https://packages.microsoft.com/yumrepos/edge
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
  ${SUDO} dnf -y install microsoft-edge-stable || true
fi

curl -fsSL https://cli.kiro.dev/install | bash

#log "Install Homebrew (Linuxbrew)"
# Official installer; installs to /home/linuxbrew/.linuxbrew on Linux.
#NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true

# Make brew available in this shell if it installed successfully
#if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
#  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
#fi

log "Install Tabularis (Snap on Linux)"
# Tabularis documents Snap/AppImage on Linux.
${SUDO} dnf -y install snapd || true
${SUDO} systemctl enable --now snapd.socket || true
${SUDO} ln -sf /var/lib/snapd/snap /snap || true
${SUDO} snap install tabularis || true

sh pretty-gnome.sh 
sh install-fonts.sh

log "Done"
echo
echo "Next:"
echo "  - Reboot (helps snap + services settle)"
echo "  - In GNOME Extensions, enable AppIndicator if you want tray icons"
echo "  - Optional: alias wezterm='flatpak run org.wezfurlong.wezterm'"