#pragma once

#include "innoscreensaversettings.h"

#include <KQuickManagedConfigModule>

/**
 * The System Settings page. All the real work is in ui/main.qml; this just hands it the
 * settings object, and KQuickManagedConfigModule takes care of Apply/Reset/Defaults.
 */
class KCMInnoScreensaver : public KQuickManagedConfigModule
{
    Q_OBJECT
    Q_PROPERTY(InnoScreensaverSettings *settings READ settings CONSTANT)

public:
    KCMInnoScreensaver(QObject *parent, const KPluginMetaData &data);
    InnoScreensaverSettings *settings() const;
    Q_INVOKABLE void preview();

private:
    InnoScreensaverSettings *m_settings;
};
