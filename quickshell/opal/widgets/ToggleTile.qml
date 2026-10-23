import QtQuick
import qs.config

// Quick-settings tile: icon bubble + title + subtitle, accent-filled when on.
// An optional chevron opens a detail page.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool hasDetails: false

    signal toggled
    signal details

    implicitHeight: 58
    implicitWidth: 180

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.tileRadius
        color: root.active ? "transparent" : hover.hovered ? Theme.layer2 : Theme.layer1
        border.width: 1
        border.color: root.active ? Qt.rgba(1, 1, 1, 0.22) : Theme.rim
        gradient: root.active ? grad : null
        scale: tap.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.fast } }

        AccentGradient { id: grad; strength: 0.92 }
    }

    Rectangle {
        id: bubble
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36
        radius: 18
        color: root.active ? Qt.rgba(1, 1, 1, 0.28) : Theme.layer2

        MaterialIcon {
            anchors.centerIn: parent
            icon: root.icon
            size: 19
            fill: root.active ? 1 : 0
            color: root.active ? Theme.accentInk : Theme.text
        }
    }

    Column {
        anchors.left: bubble.right
        anchors.leftMargin: 10
        anchors.right: chevron.visible ? chevron.left : parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        StyledText {
            width: parent.width
            text: root.title
            font.pixelSize: Theme.fontMd
            font.weight: 600
            color: root.active ? Theme.accentInk : Theme.text
        }
        StyledText {
            width: parent.width
            text: root.subtitle
            visible: text !== ""
            font.pixelSize: Theme.fontSm
            color: root.active ? Theme.alpha(Theme.accentInk, 0.75) : Theme.subtext
        }
    }

    MouseArea {
        id: tap
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    HoverHandler { id: hover }

    Rectangle {
        id: chevron
        visible: root.hasDetails
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 40
        radius: 12
        color: chevArea.containsMouse ? Qt.rgba(1, 1, 1, root.active ? 0.25 : 0.10) : "transparent"

        MaterialIcon {
            anchors.centerIn: parent
            icon: "chevron_right"
            size: 20
            color: root.active ? Theme.accentInk : Theme.subtext
        }

        MouseArea {
            id: chevArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.details()
        }
    }
}
