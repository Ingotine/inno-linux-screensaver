// The always-running part. Asks KWin (through KIdleTime) to tell us when the user has been
// away long enough, starts the screensaver process, and kills it the moment they come back.
// Kept tiny on purpose: everything heavy lives in the screensaver process, which only exists
// while it's on screen.

#include "innoscreensaversettings.h"

#include <KConfigWatcher>
#include <KIdleTime>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QGuiApplication>
#include <QProcess>
#include <QTimer>

#include <csignal>
#include <sys/prctl.h>

// PowerDevil's inhibition type for "don't touch the screen" (dim, lock, blank). Video players
// and the "block screen locking" toggle set this; plain sleep blockers like downloads don't.
static const uint ChangeScreenSettings = 4;

int main(int argc, char **argv)
{
    // KIdleTime's Wayland backend needs a GUI connection to KWin, even though we never show a window
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("inno-screensaverd"));
    app.setQuitOnLastWindowClosed(false);

    InnoScreensaverSettings settings;
    KIdleTime *idle = KIdleTime::instance();

    QProcess screensaver;
    screensaver.setProgram(QCoreApplication::applicationDirPath() + QStringLiteral("/inno-screensaver"));
    screensaver.setProcessChannelMode(QProcess::ForwardedChannels);
    // if the watcher ever dies, take the screensaver down with it so it can't get stuck on screen
    screensaver.setChildProcessModifier([] {
        prctl(PR_SET_PDEATHSIG, SIGTERM);
    });

    QDBusInterface lockScreen(QStringLiteral("org.freedesktop.ScreenSaver"),
                              QStringLiteral("/ScreenSaver"),
                              QStringLiteral("org.freedesktop.ScreenSaver"));
    QDBusInterface policyAgent(QStringLiteral("org.kde.Solid.PowerManagement"),
                               QStringLiteral("/org/kde/Solid/PowerManagement/PolicyAgent"),
                               QStringLiteral("org.kde.Solid.PowerManagement.PolicyAgent"));

    // While idle we keep re-asking "should the screensaver be up right now?" - that covers a
    // video ending while you're away, the lock screen kicking in on top of us, and the
    // screensaver crashing, all with the same check.
    QTimer recheck;
    recheck.setInterval(15 * 1000);

    auto reconcile = [&]() {
        QDBusReply<bool> _locked = lockScreen.call(QStringLiteral("GetActive"));
        QDBusReply<bool> _inhibited = policyAgent.call(QStringLiteral("HasInhibition"), ChangeScreenSettings);
        bool _blocked = (_locked.isValid() && _locked.value()) || (_inhibited.isValid() && _inhibited.value());
        bool _running = screensaver.state() != QProcess::NotRunning;
        if (!_blocked && !_running) {
            qInfo("inno-screensaverd: starting screensaver");
            screensaver.start();
        } else if (_blocked && _running) {
            qInfo("inno-screensaverd: blocked (locked or inhibited), stopping screensaver");
            screensaver.terminate();
        }
    };

    int timeoutId = -1;
    auto armTimeout = [&]() {
        if (timeoutId != -1)
            idle->removeIdleTimeout(timeoutId);
        timeoutId = -1;
        if (!settings.enabled()) {
            recheck.stop();
            screensaver.terminate();
            qInfo("inno-screensaverd: disabled");
            return;
        }
        timeoutId = idle->addIdleTimeout(settings.idleTimeoutMinutes() * 60 * 1000);
        qInfo("inno-screensaverd: idle timeout set to %d min", settings.idleTimeoutMinutes());
    };

    QObject::connect(idle, &KIdleTime::timeoutReached, &app, [&](int id, int) {
        if (id != timeoutId)
            return;
        idle->catchNextResumeEvent();
        recheck.start();
        reconcile();
    });
    QObject::connect(&recheck, &QTimer::timeout, &app, reconcile);

    QObject::connect(idle, &KIdleTime::resumingFromIdle, &app, [&]() {
        recheck.stop();
        if (screensaver.state() != QProcess::NotRunning) {
            qInfo("inno-screensaverd: activity, stopping screensaver");
            screensaver.terminate();
        }
    });

    KConfigWatcher::Ptr configWatcher = KConfigWatcher::create(settings.sharedConfig());
    QObject::connect(configWatcher.data(), &KConfigWatcher::configChanged, &app, [&]() {
        settings.read();
        armTimeout();
    });

    armTimeout();
    return app.exec();
}
