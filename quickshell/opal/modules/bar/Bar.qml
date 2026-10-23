import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// One floating glass bar per screen.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    visible: Settings.barVisible
    color: "transparent"
    anchors { top: true; left: true; right: true }
    margins { top: Theme.barMargin; left: Theme.barSide; right: Theme.barSide }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight

    WlrLayershell.namespace: "opal-bar"
    WlrLayershell.layer: WlrLayer.Top

    // Caffeine lives on the first screen's bar (an inhibitor needs a surface).
    IdleInhibitor {
        window: bar
        enabled: Power.caffeine && bar.screen === Quickshell.screens[0]
    }

    Glass {
        id: glass
        anchors.fill: parent
        radius: Theme.barRadius
        glow: Media.playing

        Row {
            id: left
            anchors.left: parent.left
            anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            OpalOrb {}
            Workspaces { screenName: bar.screen.name }
            WindowStrip {
                id: strip
                screenName: bar.screen.name
                maxWidth: Math.max(0, island.x - left.x - 160)
            }
        }

        Island {
            id: island
            anchors.centerIn: parent
        }

        Row {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            TrayArea { barWindow: bar }
            StatusCluster { screenName: bar.screen.name }
            IconButton {
                icon: Settings.dnd ? "notifications_off" : "notifications"
                size: 32
                iconSize: 18
                active: Ui.panel === "dashboard"
                onClicked: Ui.toggle("dashboard", bar.screen.name)

                Rectangle {
                    visible: Notifs.unread > 0 && !parent.active
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 3
                    anchors.topMargin: 3
                    width: Math.max(15, badge.implicitWidth + 7)
                    height: 15
                    radius: 7.5
                    gradient: AccentGradient {}
                    StyledText {
                        id: badge
                        anchors.centerIn: parent
                        text: Notifs.unread > 9 ? "9+" : Notifs.unread
                        font.pixelSize: 9
                        font.weight: 800
                        color: Theme.accentInk
                    }
                }
            }
            IconButton {
                icon: "power_settings_new"
                size: 32
                iconSize: 18
                danger: true
                onClicked: Ui.toggle("session", bar.screen.name)
            }
        }
    }
}
