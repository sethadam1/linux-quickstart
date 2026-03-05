#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$*"; }

if ! command -v apt >/dev/null 2>&1; then
  echo "This script expects Ubuntu (apt not found)."
  exit 1
fi

SUDO=""
if [[ "${EUID}" -ne 0 ]]; then
  SUDO="sudo"
fi

log "Update Ubuntu"
${SUDO} apt update
${SUDO} apt -y upgrade

log "Base tools + GNOME helpers"
${SUDO} apt -y install \
  curl wget git unzip tar \
  ca-certificates gnupg2 \
  fwupd \
  gnome-tweaks dconf-editor gnome-shell-extensions \
  bat fd-find ripgrep

log "Install system packages via apt"
${SUDO} apt -y install \
  firefox \
  vlc mpv \
  transmission-gtk \
  syncthing \
  audacity \
  handbrake \
  kid3 \
  remmina \
  libreoffice \
  mtp-tools gvfs-backends \
  flatpak \
  strawberry \
  celluloid \
  timeshift \
  gnome-boxes

log "Install GNOME core apps and utilities"
${SUDO} apt -y install \
  python3-nautilus \
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
${SUDO} apt -y install \
  gnome-shell-extension-appindicator \
  gnome-shell-extension-caffeine || true

log "Install GTK themes and fonts"
${SUDO} apt -y install \
  fonts-noto \
  fonts-noto-color-emoji \
  fonts-jetbrains-mono \
  fonts-firacode \
  fonts-fira-sans \
  fonts-fira-mono

# Install Inter font
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

log "Install Tailscale"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
  ${SUDO} systemctl enable --now tailscaled || true
fi

log "Add Flathub"
${SUDO} flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

log "Install Flatpaks (GNOME-first where possible)"
flatpak install -y flathub \
  dev.geopjr.Tuba \
  org.wezfurlong.wezterm \
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

# Install 1Password separately due to package name issues
flatpak install -y flathub com._1password.1Password || true

log "Install Microsoft Edge"
if ! command -v microsoft-edge >/dev/null 2>&1; then
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | ${SUDO} tee /usr/share/keyrings/microsoft-edge.gpg > /dev/null
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" | ${SUDO} tee /etc/apt/sources.list.d/microsoft-edge.list
  ${SUDO} apt update
  ${SUDO} apt -y install microsoft-edge-stable || true
fi

log "Install Vivaldi"
if ! command -v vivaldi >/dev/null 2>&1; then
  curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub | ${SUDO} gpg --dearmor -o /usr/share/keyrings/vivaldi.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vivaldi.gpg] https://repo.vivaldi.com/archive/deb/ stable main" | ${SUDO} tee /etc/apt/sources.list.d/vivaldi.list
  ${SUDO} apt update
  ${SUDO} apt -y install vivaldi-stable || true
fi

log "Install OpenSnitch (application firewall)"
if ! command -v opensnitch-ui >/dev/null 2>&1; then
  OPENSNITCH_VERSION="1.6.6"
  curl -fsSL "https://github.com/evilsocket/opensnitch/releases/download/v${OPENSNITCH_VERSION}/opensnitch_${OPENSNITCH_VERSION}-1_amd64.deb" -o /tmp/opensnitch.deb
  curl -fsSL "https://github.com/evilsocket/opensnitch/releases/download/v${OPENSNITCH_VERSION}/python3-opensnitch-ui_${OPENSNITCH_VERSION}-1_all.deb" -o /tmp/opensnitch-ui.deb
  ${SUDO} apt -y install /tmp/opensnitch.deb /tmp/opensnitch-ui.deb || true
  rm /tmp/opensnitch.deb /tmp/opensnitch-ui.deb
fi

sh gnome-pretty.sh 
sh install-fonts.sh

log "Install Kiro IDE (full version)"
KIRO_DOWNLOAD_URL="https://www.dropbox.com/scl/fi/ehiym9xcibsmretqo2sul/kiro-ide-0.10.32-stable-linux-x64.tar.gz?rlkey=ysgln3ngn03yw069cr3u85doc&dl=1"
KIRO_INSTALL_DIR="/opt/kiro-ide"

if [[ ! -d "${KIRO_INSTALL_DIR}" ]]; then
  echo "  Downloading Kiro IDE..."
  curl -fsSL "${KIRO_DOWNLOAD_URL}" -o /tmp/kiro-ide.tar.gz
  
  echo "  Extracting Kiro IDE..."
  ${SUDO} mkdir -p "${KIRO_INSTALL_DIR}"
  ${SUDO} tar -xzf /tmp/kiro-ide.tar.gz -C "${KIRO_INSTALL_DIR}" --strip-components=1
  rm /tmp/kiro-ide.tar.gz
  
  echo "  Creating desktop entry..."
  ${SUDO} tee /usr/share/applications/kiro-ide.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Kiro
Comment=Agentic AI development IDE
Exec=${KIRO_INSTALL_DIR}/bin/kiro
Icon=${KIRO_INSTALL_DIR}/resources/app/out/media/code-icon.svg
Terminal=false
Type=Application
Categories=Development;IDE;
EOF
  
  echo "  Creating symlink..."
  ${SUDO} ln -sf "${KIRO_INSTALL_DIR}/bin/kiro" /usr/local/bin/kiro
  
  echo "  ✓ Kiro IDE installed to ${KIRO_INSTALL_DIR}"
else
  echo "  ✓ Kiro IDE already installed"
fi

log "Install Tabularis (Snap)"
${SUDO} snap install tabularis || true

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
echo "  - In GNOME Extensions, enable installed extensions"
echo "  - In Extension Manager, install 'Just Perfection' and 'Blur My Shell'"
echo "  - Optional: alias wezterm='flatpak run org.wezfurlong.wezterm'"
