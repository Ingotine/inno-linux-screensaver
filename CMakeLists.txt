cmake_minimum_required(VERSION 3.22)
project(inno-screensaver VERSION 0.1.0)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui DBus Qml Quick)
find_package(KF6 6.0 REQUIRED COMPONENTS Config CoreAddons IdleTime KCMUtils)

add_subdirectory(src/settings)
add_subdirectory(src/watcher)
add_subdirectory(src/screensaver)
add_subdirectory(src/kcm)

install(FILES data/inno-screensaverd.desktop DESTINATION ${KDE_INSTALL_AUTOSTARTDIR})
