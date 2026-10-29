add_executable(inno-screensaverd main.cpp)
target_link_libraries(inno-screensaverd PRIVATE innoscreensaver_settings Qt6::Gui Qt6::DBus KF6::IdleTime)
install(TARGETS inno-screensaverd ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
