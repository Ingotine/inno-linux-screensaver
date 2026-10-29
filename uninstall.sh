#!/usr/bin/env bash
# Stops inno-screensaver and removes every file install.sh put on the system.
# Your settings file (~/.config/innoscreensaverrc) is left alone.
set -euo pipefail

manifest=/usr/share/inno-screensaver/install_manifest.txt

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root - it stops the screensaver in your session."
    exit 1
fi

echo "==> Stopping the screensaver"
# the screensaver itself dies along with the watcher; this also catches a stray preview
pkill -u "$USER" -f '(^|/)inno-screensaverd$' || true
pkill -u "$USER" -f '(^|/)inno-screensaver( --preview)?$' || true

if [[ ! -f "$manifest" ]]; then
    echo "Nothing to remove - $manifest not found (not installed with install.sh?)."
    exit 1
fi

echo "==> Removing installed files (sudo)"
sudo xargs -d '\n' rm -fv < "$manifest"
sudo rm -rf /usr/share/inno-screensaver

echo
echo "Uninstalled. Your settings are still in ~/.config/innoscreensaverrc - delete it for a full clean."
