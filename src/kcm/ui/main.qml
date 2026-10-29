import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    Kirigami.FormLayout {
        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Screensaver:")
            text: i18n("Start when the computer is idle")
            checked: kcm.settings.enabled
            onToggled: kcm.settings.enabled = checked
            KCM.SettingStateBinding {
                configObject: kcm.settings
                settingName: "Enabled"
            }
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Start after:")
            enabled: kcm.settings.enabled
            from: 1
            to: 240
            value: kcm.settings.idleTimeoutMinutes
            textFromValue: (value, locale) => i18np("%1 minute", "%1 minutes", value)
            onValueModified: kcm.settings.idleTimeoutMinutes = value
            KCM.SettingStateBinding {
                configObject: kcm.settings
                settingName: "IdleTimeoutMinutes"
            }
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Change picture every:")
            from: 5
            to: 600
            value: kcm.settings.slideSeconds
            textFromValue: (value, locale) => i18np("%1 second", "%1 seconds", value)
            onValueModified: kcm.settings.slideSeconds = value
            KCM.SettingStateBinding {
                configObject: kcm.settings
                settingName: "SlideSeconds"
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Folders:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24

            KCM.SettingStateBinding {
                configObject: kcm.settings
                settingName: "Folders"
            }

            Repeater {
                model: kcm.settings.folders
                delegate: RowLayout {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: modelData
                        elide: Text.ElideMiddle
                    }
                    QQC2.ToolButton {
                        icon.name: "list-remove"
                        display: QQC2.AbstractButton.IconOnly
                        text: i18n("Remove folder")
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered
                        onClicked: {
                            const _folders = kcm.settings.folders.slice()
                            _folders.splice(index, 1)
                            kcm.settings.folders = _folders
                        }
                    }
                }
            }

            QQC2.Button {
                icon.name: "folder-add"
                text: i18n("Add Folder…")
                onClicked: folderDialog.open()
            }
        }

        QQC2.CheckBox {
            text: i18n("Also use the wallpapers installed on the system")
            checked: kcm.settings.includeInstalledWallpapers
            onToggled: kcm.settings.includeInstalledWallpapers = checked
            KCM.SettingStateBinding {
                configObject: kcm.settings
                settingName: "IncludeInstalledWallpapers"
            }
        }

        QQC2.CheckBox {
            text: i18n("Also play videos and GIFs (muted)")
            checked: kcm.settings.includeAnimated
            onToggled: kcm.settings.includeAnimated = checked
            KCM.SettingStateBinding {
                configObject: kcm.settings
                settingName: "IncludeAnimated"
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Effects:")
            text: i18n("Slowly pan and zoom across still pictures")
            checked: kcm.settings.panZoom
            onToggled: kcm.settings.panZoom = checked
            KCM.SettingStateBinding {
                configObject: kcm.settings
                settingName: "PanZoom"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Movement:")
            enabled: kcm.settings.panZoom

            QQC2.Label {
                text: i18nc("small amount of pan and zoom", "Subtle")
            }
            QQC2.Slider {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                from: 1
                to: 100
                stepSize: 1
                value: kcm.settings.panZoomStrength
                onMoved: kcm.settings.panZoomStrength = value
                KCM.SettingStateBinding {
                    configObject: kcm.settings
                    settingName: "PanZoomStrength"
                }
            }
            QQC2.Label {
                text: i18nc("large amount of pan and zoom", "Strong")
            }
        }
    }

    // the preview runs the real screensaver, which reads the saved settings, so unsaved
    // changes have to be applied first to show up in it
    footer: QQC2.ToolBar {
        RowLayout {
            anchors.fill: parent
            Item {
                Layout.fillWidth: true
            }
            QQC2.Button {
                icon.name: "view-preview"
                text: i18n("Preview")
                enabled: !kcm.needsSave
                onClicked: kcm.preview()
                QQC2.ToolTip.text: kcm.needsSave ? i18n("Apply your changes first") : i18n("Move the mouse or press any key to close")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: i18n("Choose a Folder")
        onAccepted: {
            const _path = decodeURIComponent(selectedFolder.toString().replace(/^file:\/\//, ""))
            if (!kcm.settings.folders.includes(_path))
                kcm.settings.folders = kcm.settings.folders.concat([_path])
        }
    }
}
