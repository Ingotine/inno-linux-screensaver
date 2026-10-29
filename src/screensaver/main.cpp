// The fullscreen part. Collects every picture/video from the configured folders, shuffles
// them, and hands the list to Main.qml, which puts one overlay window on each screen.
// The watcher starts and kills this process; it never decides to quit on its own.

#include "innoscreensaversettings.h"

#include <QDir>
#include <QDirIterator>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QScreen>
#include <QStandardPaths>
#include <QUrl>

#include <algorithm>

static const QStringList stillTypes = {QStringLiteral("jpg"), QStringLiteral("jpeg"), QStringLiteral("png"),
                                       QStringLiteral("webp"), QStringLiteral("bmp"), QStringLiteral("avif"),
                                       QStringLiteral("jxl")};
static const QStringList gifTypes = {QStringLiteral("gif")};
static const QStringList videoTypes = {QStringLiteral("mp4"), QStringLiteral("webm"), QStringLiteral("mkv"),
                                       QStringLiteral("mov"), QStringLiteral("avi"), QStringLiteral("m4v")};

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("inno-screensaver"));

    // --preview comes from the settings page: no watcher is around to close us, so the
    // window closes itself on input
    bool preview = app.arguments().contains(QStringLiteral("--preview"));

    InnoScreensaverSettings settings;
    bool includeAnimated = settings.includeAnimated();

    QVariantList media;
    auto addFile = [&](const QString &path) {
        QString _suffix = QFileInfo(path).suffix().toLower();
        QString _kind;
        if (stillTypes.contains(_suffix))
            _kind = QStringLiteral("still");
        else if (includeAnimated && gifTypes.contains(_suffix))
            _kind = QStringLiteral("gif");
        else if (includeAnimated && videoTypes.contains(_suffix))
            _kind = QStringLiteral("video");
        else
            return;
        media << QVariantMap{{QStringLiteral("source"), QUrl::fromLocalFile(path)}, {QStringLiteral("kind"), _kind}};
    };

    for (const QString &folder : settings.folders()) {
        QDirIterator _files(folder, QDir::Files | QDir::Readable, QDirIterator::Subdirectories | QDirIterator::FollowSymlinks);
        while (_files.hasNext())
            addFile(_files.next());
    }

    if (settings.includeInstalledWallpapers()) {
        // Wallpaper packages ship one image per resolution as contents/images/WIDTHxHEIGHT.ext,
        // so we take the biggest one and let Qt scale it down. Loose image files count too.
        static const QRegularExpression resolution(QStringLiteral("^(\\d+)x(\\d+)$"));
        const QStringList _roots = QStandardPaths::locateAll(QStandardPaths::GenericDataLocation, QStringLiteral("wallpapers"), QStandardPaths::LocateDirectory);
        for (const QString &_root : _roots) {
            for (const QFileInfo &_entry : QDir(_root).entryInfoList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot)) {
                if (_entry.isFile()) {
                    addFile(_entry.absoluteFilePath());
                    continue;
                }
                QString _best;
                qint64 _bestPixels = 0;
                for (const QFileInfo &_image : QDir(_entry.absoluteFilePath() + QStringLiteral("/contents/images")).entryInfoList(QDir::Files)) {
                    QRegularExpressionMatch _match = resolution.match(_image.completeBaseName());
                    qint64 _pixels = _match.hasMatch() ? _match.captured(1).toLongLong() * _match.captured(2).toLongLong() : 1;
                    if (_pixels > _bestPixels) {
                        _bestPixels = _pixels;
                        _best = _image.absoluteFilePath();
                    }
                }
                if (!_best.isEmpty())
                    addFile(_best);
            }
        }
    }

    std::shuffle(media.begin(), media.end(), *QRandomGenerator::global());
    qInfo("inno-screensaver: %lld files", static_cast<long long>(media.size()));

    // QML's own Qt.application.screens hands out wrapper objects the layer shell can't take,
    // so pass the real QScreens in
    QVariantList screens;
    for (QScreen *_screen : QGuiApplication::screens())
        screens << QVariant::fromValue(_screen);

    QQmlApplicationEngine engine;
    engine.setInitialProperties({
        {QStringLiteral("screens"), screens},
        {QStringLiteral("preview"), preview},
        {QStringLiteral("media"), media},
        {QStringLiteral("slideSeconds"), settings.slideSeconds()},
        {QStringLiteral("panZoom"), settings.panZoom()},
        {QStringLiteral("panZoomStrength"), settings.panZoomStrength()},
    });
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] {
        QCoreApplication::exit(1);
    }, Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));
    return app.exec();
}
