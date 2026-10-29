#include "lockscreenfolders.h"

#include <KConfigGroup>
#include <KSharedConfig>
#include <QDir>
#include <QStandardPaths>
#include <QUrl>

QStringList lockScreenFolders()
{
    KSharedConfig::Ptr _locker = KSharedConfig::openConfig(QStringLiteral("kscreenlockerrc"));
    KConfigGroup _slideshow = _locker->group(QStringLiteral("Greeter"))
                                  .group(QStringLiteral("Wallpaper"))
                                  .group(QStringLiteral("org.kde.slideshow"))
                                  .group(QStringLiteral("General"));
    QStringList _folders;
    for (const QString &_path : _slideshow.readEntry("SlidePaths", QStringList())) {
        // entries show up both as plain paths and as file:// urls
        QString _local = _path.startsWith(QLatin1String("file:")) ? QUrl(_path).toLocalFile() : _path;
        if (!_local.isEmpty())
            _folders << QDir::cleanPath(_local);
    }
    if (_folders.isEmpty())
        _folders << QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    return _folders;
}
