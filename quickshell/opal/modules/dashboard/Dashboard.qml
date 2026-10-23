import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Drops down from the island: time, weather, calendar | notifications.
PanelSurface {
    id: root

    name: "dashboard"
    edge: "top"
    panelWidth: 800
    panelHeight: 600

    onShownChanged: if (shown) Notifs.markRead()

    Glass {
        anchors.fill: parent
        radius: Theme.panelRadius
        glow: true

        Column {
            id: leftCol
            x: 18
            y: 18
            width: 340
            spacing: 12

            Greeting { width: parent.width }
            WeatherCard { width: parent.width }
            CalendarCard { width: parent.width }
        }

        Rectangle {
            id: divider
            anchors.left: leftCol.right
            anchors.leftMargin: 16
            y: 24
            width: 1
            height: parent.height - 48
            color: Theme.rim
        }

        NotificationList {
            anchors.left: divider.right
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 18
            height: parent.height - 36
        }
    }
}
