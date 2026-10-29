kcmutils_add_qml_kcm(kcm_innoscreensaver SOURCES kcm_innoscreensaver.cpp)
target_link_libraries(kcm_innoscreensaver PRIVATE innoscreensaver_settings Qt6::Quick KF6::KCMUtilsQuick KF6::CoreAddons)
