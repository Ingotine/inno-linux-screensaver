#include "kcm_innoscreensaver.h"

#include <KPluginFactory>
#include <QProcess>
#include <QStandardPaths>
#include <QQmlEngine>

K_PLUGIN_CLASS_WITH_JSON(KCMInnoScreensaver, "kcm_innoscreensaver.json")

KCMInnoScreensaver::KCMInnoScreensaver(QObject *parent, const KPluginMetaData &data)
    : KQuickManagedConfigModule(parent, data)
    , m_settings(new InnoScreensaverSettings(this))
{
    qmlRegisterAnonymousType<InnoScreensaverSettings>("org.inno.screensaver", 1);
    setButtons(Apply | Default);
}

InnoScreensaverSettings *KCMInnoScreensaver::settings() const
{
    return m_settings;
}

void KCMInnoScreensaver::preview()
{
    QString _program = QStandardPaths::findExecutable(QStringLiteral("inno-screensaver"));
    if (_program.isEmpty()) {
        qWarning("kcm_innoscreensaver: inno-screensaver not found in PATH");
        return;
    }
    QProcess::startDetached(_program, {QStringLiteral("--preview")});
}

#include "kcm_innoscreensaver.moc"
