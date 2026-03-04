#!/usr/bin/env bash
set -euo pipefail

URL="https://www.dropbox.com/scl/fi/hs6xnqz20s73dr8ewhyl9/fonts.zip?rlkey=wneouza61d5pc0bgk4a05676c&dl=1"

MODE="${1:-}"
INSTALL_SYSTEM=false
if [[ "${MODE}" == "--system" ]]; then
  INSTALL_SYSTEM=true
fi

log() { printf "\n==> %s\n" "$*"; }

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Installing missing dependency: $1"
    sudo dnf install -y "$1"
  fi
}

need curl
need unzip
need fontconfig

WORKDIR="$(mktemp -d)"
ZIPFILE="${WORKDIR}/fonts.zip"
UNPACKDIR="${WORKDIR}/unpacked"

cleanup() { rm -rf "${WORKDIR}"; }
trap cleanup EXIT

log "Downloading fonts.zip from Dropbox"
curl -L --fail --retry 3 --retry-delay 2 -o "${ZIPFILE}" "${URL}"

mkdir -p "${UNPACKDIR}"

log "Unzipping"
unzip -q "${ZIPFILE}" -d "${UNPACKDIR}"

# Pick install target
if ${INSTALL_SYSTEM}; then
  TARGET_DIR="/usr/local/share/fonts/Custom"
  log "Installing system-wide to ${TARGET_DIR}"
  sudo mkdir -p "${TARGET_DIR}"
else
  TARGET_DIR="${HOME}/.local/share/fonts/Custom"
  log "Installing for current user to ${TARGET_DIR}"
  mkdir -p "${TARGET_DIR}"
fi

log "Finding font files (.ttf, .otf, .ttc)"
mapfile -t FONTFILES < <(find "${UNPACKDIR}" -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.ttc" \))

if [[ "${#FONTFILES[@]}" -eq 0 ]]; then
  echo "No font files found in the zip."
  exit 1
fi

log "Copying ${#FONTFILES[@]} font files"
if ${INSTALL_SYSTEM}; then
  # Preserve filenames; don't overwrite unless same name
  for f in "${FONTFILES[@]}"; do
    sudo install -m 0644 -D "$f" "${TARGET_DIR}/$(basename "$f")" || true
  done
else
  for f in "${FONTFILES[@]}"; do
    install -m 0644 -D "$f" "${TARGET_DIR}/$(basename "$f")" || true
  done
fi

log "Rebuilding font cache"
if ${INSTALL_SYSTEM}; then
  sudo fc-cache -f
else
  fc-cache -f
fi

log "Done"
echo "Installed fonts into: ${TARGET_DIR}"
echo "Tip: log out and back in if some apps don’t pick them up immediately."