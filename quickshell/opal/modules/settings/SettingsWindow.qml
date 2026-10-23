import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// "Opal Settings": a normal window (niri floats it and blurs it through the
// window rule matching this title). Every control writes straight to
// Settings, so changes apply live; there's no Apply button.
FloatingWindow {
    id: win

    title: "Opal Settings"
    color: "transparent"
    implicitWidth: 1040
    implicitHeight: 720
    minimumSize: Qt.size(860, 560)

    onVisibleChanged: if (!visible) Ui.settingsOpen = false

    readonly property var pages: [
        { id: "general", label: "General", icon: "tune" },
        { id: "appearance", label: "Appearance", icon: "palette" },
        { id: "bar", label: "Bar & island", icon: "toolbar" },
        { id: "wallpaper", label: "Wallpaper", icon: "wallpaper" },
        { id: "notifications", label: "Notifications", icon: "notifications" },
        { id: "sound", label: "Sound", icon: "volume_up" },
        { id: "network", label: "Wi-Fi", icon: "wifi" },
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" },
        { id: "power", label: "Power & idle", icon: "bolt" },
        { id: "launcher", label: "Launcher", icon: "apps" },
        { id: "keybinds", label: "Keybinds", icon: "keyboard" },
        { id: "about", label: "About", icon: "info" }
    ]
    readonly property string current: pages.some(p => p.id === Ui.settingsPage) ? Ui.settingsPage : "general"

    Glass {
        anchors.fill: parent
        radius: 24
        tint: Qt.rgba(0.075, 0.06, 0.105, Math.min(0.9, Settings.glassOpacity + 0.18))
        glow: true
    }

    // ---- sidebar --------------------------------------------------------------------
    Item {
        id: sidebar
        width: 236
        height: parent.height

        Row {
            id: brand
            x: 22
            y: 22
            spacing: 12

            Rectangle {
                width: 34
                height: 34
                radius: 17
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.pink }
                    GradientStop { position: 0.55; color: Theme.violet }
                    GradientStop { position: 1; color: Theme.cyan }
                }
                Rectangle {
                    x: 8; y: 7; width: 10; height: 7; radius: 4; rotation: -35
                    color: Qt.rgba(1, 1, 1, 0.55)
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                StyledText {
                    text: "Opal"
                    font.pixelSize: Theme.fontLg + 2
                    font.weight: 750
                }
                StyledText {
                    text: "Settings"
                    font.pixelSize: Theme.fontSm
                    color: Theme.subtext
                }
            }
        }

        ListView {
            id: nav
            anchors.top: brand.bottom
            anchors.topMargin: 22
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            x: 12
            width: parent.width - 24
            spacing: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: win.pages

            delegate: Item {
                id: item
                required property var modelData
                readonly property bool active: win.current === modelData.id
                width: nav.width
                height: 40

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: item.active ? "transparent" : hover.hovered ? Theme.layer2 : "transparent"
                    gradient: item.active ? activeGrad : null
                    border.width: item.active ? 1 : 0
                    border.color: Qt.rgba(1, 1, 1, 0.14)
                    Behavior on color { ColorAnimation { duration: Theme.fast } }

                    Gradient {
                        id: activeGrad
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.alpha(Theme.pink, 0.34) }
                        GradientStop { position: 0.6; color: Theme.alpha(Theme.violet, 0.28) }
                        GradientStop { position: 1; color: Theme.alpha(Theme.cyan, 0.18) }
                    }
                }

                MaterialIcon {
                    id: navIcon
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    icon: item.modelData.icon
                    size: 19
                    fill: item.active ? 1 : 0
                    color: item.active ? Theme.text : Theme.subtext
                }
                StyledText {
                    anchors.left: navIcon.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: item.modelData.label
                    font.pixelSize: Theme.fontMd
                    font.weight: item.active ? 650 : 500
                    color: item.active ? Theme.text : Theme.subtext
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Ui.settingsPage = item.modelData.id
                }
            }
        }
    }

    Rectangle {
        id: divider
        anchors.left: sidebar.right
        y: 18
        width: 1
        height: parent.height - 36
        color: Theme.rim
    }

    // ---- page ---------------------------------------------------------------------------
    Item {
        id: pageArea
        anchors.left: divider.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Loader {
            id: loader
            anchors.fill: parent
            sourceComponent: {
                switch (win.current) {
                case "appearance": return appearance;
                case "bar": return bar;
                case "wallpaper": return wallpaper;
                case "notifications": return notifications;
                case "sound": return sound;
                case "network": return network;
                case "bluetooth": return bluetooth;
                case "power": return power;
                case "launcher": return launcher;
                case "keybinds": return keybinds;
                case "about": return about;
                default: return general;
                }
            }
            onLoaded: {
                fade.restart();
            }
        }

        NumberAnimation {
            id: fade
            target: loader
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: Theme.normal
            easing.type: Easing.OutCubic
        }

        IconButton {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            icon: "close"
            onClicked: Ui.settingsOpen = false
        }
    }

    Component { id: general; GeneralPage {} }
    Component { id: appearance; AppearancePage {} }
    Component { id: bar; BarPage {} }
    Component { id: wallpaper; WallpaperPage {} }
    Component { id: notifications; NotificationsPage {} }
    Component { id: sound; SoundPage {} }
    Component { id: network; NetworkPage {} }
    Component { id: bluetooth; BluetoothSettingsPage {} }
    Component { id: power; PowerPage {} }
    Component { id: launcher; LauncherPage {} }
    Component { id: keybinds; KeybindsPage {} }
    Component { id: about; AboutPage {} }

    Shortcut {
        sequences: ["Ctrl+W", "Ctrl+Q"]
        onActivated: Ui.settingsOpen = false
    }
}
