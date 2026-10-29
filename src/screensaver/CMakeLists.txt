add_executable(inno-screensaver main.cpp)
qt_add_resources(inno-screensaver "qml" PREFIX "/" FILES Main.qml)
target_link_libraries(inno-screensaver PRIVATE innoscreensaver_settings Qt6::Gui Qt6::Qml Qt6::Quick)
install(TARGETS inno-screensaver ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
