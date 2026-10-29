# inno-screensaver

A minimal burn-in protection screensaver for **KDE Plasma 6 on Wayland**.

After a period of inactivity it covers every screen with a slideshow of your pictures:
slow, random pan and zoom on still images, plus muted videos and GIFs. It disappears the
moment you touch the mouse or keyboard. Configure it in System Settings like any other
part of Plasma.

- Covers everything, including fullscreen apps and panels. Only the lock screen goes
  above it.
- Stays out of the way while you watch a video, or while anything else is blocking screen
  locking. Apps that only block *sleep* (like downloads) don't stop it.
- Takes no memory while it isn't showing. The slideshow is a separate process that's
  closed completely when you come back; only a small watcher keeps running.

> **A note before you use it:** this was a quick one-off project I made for my own
> personal use. It has only been tested on my own setup (KDE neon, Plasma 6.8, Wayland,
> NVIDIA). I heavily encourage you to open issues with feedback, or to fork it and make
> it your own. Edits, fixes and spin-offs are all welcome.

## Install

```sh
git clone https://github.com/Ingotine/inno-linux-screensaver.git
cd inno-linux-screensaver
./install.sh
```

That's it. The script installs the build tools (apt, pacman or dnf), builds, installs, and
starts the screensaver. It also starts by itself at every login.

Then open **System Settings → Security & Privacy → Screensaver** to choose folders,
timing and effects. Changes apply immediately. Use **Preview** to try it out.

To update: `git pull && ./install.sh`. It rebuilds, reinstalls and restarts the
screensaver.

> Tip: Plasma's lock screen also kicks in after 5 minutes by default. Set the screensaver
> to start earlier than that, or the lock screen will cover it.

## Uninstall

```sh
./uninstall.sh
```

This stops the screensaver and removes the files it installed. It doesn't need the build
folder. It doesn't remove the build dependencies `install.sh` pulled in, since other
software may use them; your package manager will offer to clean them up once nothing
needs them. Your settings stay in `~/.config/innoscreensaverrc`; delete that file for a
full clean.

## Settings

| Setting | Default |
|---|---|
| On/off | On |
| Start after | 5 minutes |
| Change picture every | 20 seconds |
| Folders | The folders your lock screen slideshow uses, otherwise `~/Pictures` |
| Also use the system's installed wallpapers | Off |
| Also play videos and GIFs (muted) | On |
| Pan and zoom on still pictures | On, medium movement |

Supported files: jpg, png, webp, bmp, avif, jxl, gif, mp4, webm, mkv, mov, avi, m4v.
Folders are searched including subfolders.

## How it works

- **`inno-screensaverd`** (`src/watcher`): a small background process, started at login
  from `/etc/xdg/autostart`. It uses KIdleTime, the same idle detection the lock screen
  uses, to start the screensaver after the timeout and close it when you come back. It
  won't start while the screen is locked or something is blocking screen locking.
- **`inno-screensaver`** (`src/screensaver`): the slideshow. It puts one window per
  screen in the Wayland overlay layer (via layer-shell-qt).
- **Settings page** (`src/kcm`): a standard Plasma settings module.
- **Shared settings** (`src/settings`): stored in `~/.config/innoscreensaverrc`.

## Requirements

KDE Plasma 6 on Wayland. Only tested on KDE neon (Plasma 6.8). The Arch and Fedora
package lists in `install.sh` were written without testing, so they may need fixing.
X11 isn't supported: the window-on-top mechanism is Wayland-only.

Manual build, if you'd rather not use the script:

```sh
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
sudo cmake --install build
```

## Troubleshooting

Logs go to the journal: `journalctl --user -f | grep inno-screensaver`

## License

GPL-2.0-or-later. See [LICENSE](LICENSE). You're free to use, change and share it; if
you distribute a changed version, share your changes under the same license.
