# Linux Quickstart

A simple set of scripts to get **Fedora Workstation** or **Ubuntu** (GNOME) up and running with:

- Core development tools  
- Essential desktop apps  
- Beautiful fonts  
- A clean, modern GNOME setup  

The goal is a polished, macOS-adjacent experience — without drifting away from stock GNOME.

---

## 🚀 Installation

```bash
wget https://codeberg.org/sethadam1/linux-quickstart/archive/main.zip -O ~/quickstart.zip
unzip ~/quickstart.zip
cd linux-quickstart-main

### Fedora

```bash
cd fedora
chmod +x *.sh
./start.sh
```

### Ubuntu

```bash
cd ubuntu
chmod +x *.sh
./start.sh
```

---

## What's Included

- **Development Tools**: Kiro IDE, VSCode, bat, fd, ripgrep
- **Browsers**: Firefox, Microsoft Edge, Vivaldi
- **Communication**: Slack, Discord, Zoom, WhatsApp, Teams
- **Productivity**: LibreOffice, Obsidian, 1Password
- **Media**: VLC, MPV, Strawberry, Cider
- **GNOME Extensions**: Dash to Panel, AppIndicator, Blur My Shell, Caffeine
- **Beautiful Fonts**: Inter, JetBrains Mono, Fira Code, Noto fonts
- **System Tools**: Timeshift, OpenSnitch, GNOME Boxes, Flameshot

---

## Post-Installation

After running the script:

1. Reboot to let services settle
2. Enable GNOME extensions via Extension Manager
3. Install "Just Perfection" extension for UI customization
4. Configure keybindings (automatically copied to VSCode and Kiro)