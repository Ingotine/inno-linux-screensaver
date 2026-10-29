#pragma once

#include <QStringList>

// The folders the lock screen's slideshow uses, or ~/Pictures if it isn't on a slideshow.
// Used as the default folder list so the screensaver starts out matching the lock screen.
QStringList lockScreenFolders();
