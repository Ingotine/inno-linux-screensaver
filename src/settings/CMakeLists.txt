# Shared settings class, compiled into the watcher, the screensaver and the settings page
add_library(innoscreensaver_settings STATIC lockscreenfolders.cpp)
kconfig_add_kcfg_files(innoscreensaver_settings innoscreensaversettings.kcfgc GENERATE_MOC)
set_target_properties(innoscreensaver_settings PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(innoscreensaver_settings PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(innoscreensaver_settings PUBLIC Qt6::Core KF6::ConfigCore KF6::ConfigGui)
