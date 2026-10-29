#!/usr/bin/env bash
# Builds and installs inno-screensaver, then starts it right away - no logout needed.
# Run as your normal user; it asks for sudo when it needs it. Safe to re-run to update.
set -euo pipefail
cd "$(dirname "$0")"

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root - it starts the screensaver in your session."
    exit 1
fi

echo "==> Installing build dependencies"
if command -v apt-get >/dev/null; then
    sudo apt-get install -y --no-install-recommends cmake g++ extra-cmake-modules \
        qt6-base-dev qt6-declarative-dev libkf6idletime-dev libkf6kcmutils-dev \
        libkf6config-dev libkf6coreaddons-dev qml6-module-qtmultimedia qml6-module-qtquick-dialogs
elif command -v pacman >/dev/null; then
    sudo pacman -S --needed --noconfirm cmake gcc extra-cmake-modules qt6-base qt6-declarative \
        qt6-multimedia kidletime kcmutils kconfig kcoreaddons layer-shell-qt
elif command -v dnf >/dev/null; then
    sudo dnf install -y cmake gcc-c++ extra-cmake-modules qt6-qtbase-devel qt6-qtdeclarative-devel \
        qt6-qtmultimedia kf6-kidletime-devel kf6-kcmutils-devel kf6-kconfig-devel \
        kf6-kcoreaddons-devel layer-shell-qt
else
    echo "Unknown package manager - install the dependencies listed in README.md, then re-run."
    echo "Continuing in case they're already there..."
fi

echo "==> Building"
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"

echo "==> Installing (sudo)"
sudo cmake --install build
# keep the list of installed files somewhere permanent so uninstall.sh works even
# after this folder is gone
sudo install -Dm644 build/install_manifest.txt /usr/share/inno-screensaver/install_manifest.txt

echo "==> Starting the screensaver watcher"
# restart rather than start, so re-running this after an update picks up the new build
pkill -u "$USER" -f '(^|/)inno-screensaverd$' || true
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    setsid -f /usr/bin/inno-screensaverd >/dev/null 2>&1
    echo "Running. It also starts by itself at every login."
else
    echo "No Wayland session found here - it will start at your next Plasma login."
fi

echo
echo "Done. Configure it in System Settings -> Security & Privacy -> Screensaver."
