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
  gnome-tweaks dconf-editor gnome-extensions-app \
  bat fd-find ripgrep

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
  flatpak \
  vivaldi-stable \
  strawberry \
  celluloid \
  timeshift \
  opensnitch \
  gnome-boxes

log "Install GNOME core apps and utilities"
${SUDO} dnf -y install \
  nautilus-python \
  file-roller \
  loupe \
  evince \
  flameshot \
  gnome-system-monitor \
  gnome-calculator \
  gnome-text-editor \
  gnome-font-viewer \
  gnome-disk-utility \
  gimp

log "Install GNOME Shell extensions"
${SUDO} dnf -y install \
  gnome-shell-extension-dash-to-panel \
  gnome-shell-extension-appindicator \
  gnome-shell-extension-blur-my-shell \
  gnome-shell-extension-user-theme \
  gnome-shell-extension-caffeine

log "Install GTK themes and fonts"
${SUDO} dnf -y install \
  adw-gtk3-theme \
  google-noto-sans-fonts \
  google-noto-serif-fonts \
  google-noto-emoji-fonts \
  jetbrains-mono-fonts \
  fira-code-fonts \
  mozilla-fira-sans-fonts \
  mozilla-fira-mono-fonts

# Install Inter font (not in Fedora repos by default)
if [[ ! -d "${HOME}/.local/share/fonts/Inter" ]]; then
  echo "  Installing Inter font..."
  mkdir -p "${HOME}/.local/share/fonts/Inter"
  curl -fsSL "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip" -o /tmp/inter.zip
  unzip -q /tmp/inter.zip -d /tmp/inter
  cp /tmp/inter/Inter\ Desktop/*.ttf "${HOME}/.local/share/fonts/Inter/"
  rm -rf /tmp/inter /tmp/inter.zip
  fc-cache -f
  echo "  ✓ Inter font installed"
fi

log "Enable and start tailscale"
${SUDO} systemctl enable --now tailscaled || true

# log "Enable syncthing for current user"
# systemctl --user enable --now syncthing.service || true

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
  com.github.IsmaelMartinez.teams_for_linux \
  com.discordapp.Discord \
  com.mattjakeman.ExtensionManager || true

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

log "Copy keybindings to VSCode and Kiro"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYBINDINGS_FILE="${SCRIPT_DIR}/vscode-keybindings.json"

if [[ -f "${KEYBINDINGS_FILE}" ]]; then
  # VSCode keybindings
  VSCODE_CONFIG_DIR="${HOME}/.config/Code/User"
  mkdir -p "${VSCODE_CONFIG_DIR}"
  cp "${KEYBINDINGS_FILE}" "${VSCODE_CONFIG_DIR}/keybindings.json"
  echo "  ✓ Copied keybindings to VSCode"
  
  # Kiro keybindings
  KIRO_CONFIG_DIR="${HOME}/.config/Kiro/User"
  mkdir -p "${KIRO_CONFIG_DIR}"
  cp "${KEYBINDINGS_FILE}" "${KIRO_CONFIG_DIR}/keybindings.json"
  echo "  ✓ Copied keybindings to Kiro"
else
  echo "  ⚠ Warning: vscode-keybindings.json not found"
fi

log "Done"
echo
echo "Next:"
echo "  - Reboot (helps snap + services settle)"
echo "  - In GNOME Extensions, enable AppIndicator if you want tray icons"
echo "  - In Extension Manager, install 'Just Perfection'"
echo "  - Optional: alias wezterm='flatpak run org.wezfurlong.wezterm'"