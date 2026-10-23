import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import qs.modules.notifications

Item {
    id: root

    Item {
        id: head
        width: parent.width
        height: 36

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                font.pixelSize: Theme.fontLg + 1
                font.weight: 700
            }
            Rectangle {
                visible: Notifs.history.length > 0
                anchors.verticalCenter: parent.verticalCenter
                width: countText.implicitWidth + 12
                height: 20
                radius: 10
                color: Theme.layer2
                StyledText {
                    id: countText
                    anchors.centerIn: parent
                    text: Notifs.history.length
                    font.pixelSize: Theme.fontXs
                    font.weight: 700
                }
            }
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            IconButton {
                icon: Settings.dnd ? "notifications_off" : "notifications_active"
                active: Settings.dnd
                size: 32
                iconSize: 17
                onClicked: Settings.dnd = !Settings.dnd
            }
            IconButton {
                icon: "delete_sweep"
                size: 32
                iconSize: 18
                visible: Notifs.history.length > 0
                onClicked: Notifs.clearAll()
            }
        }
    }

    ListView {
        id: list
        anchors.top: head.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        spacing: 8
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: Notifs.history
            objectProp: "key"
        }

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.normal }
            NumberAnimation { property: "x"; from: 30; to: 0; duration: Theme.normal; easing.type: Easing.OutCubic }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: Theme.fast }
            NumberAnimation { property: "x"; to: 60; duration: Theme.fast }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Theme.normal; easing.type: Easing.OutCubic }
        }

        delegate: NotificationCard {
            required property var modelData
            entry: modelData
            width: list.width
            compact: true
        }
    }

    Column {
        anchors.centerIn: list
        visible: Notifs.history.length === 0
        spacing: 10
        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: "auto_awesome"
            size: 46
            fill: 1
            color: Theme.alpha(Theme.violet, 0.8)
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "All caught up"
            font.pixelSize: Theme.fontLg
            font.weight: 650
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Settings.dnd ? "Do not disturb is on" : "New notifications land here"
            color: Theme.dim
            font.pixelSize: Theme.fontSm
        }
    }
}
