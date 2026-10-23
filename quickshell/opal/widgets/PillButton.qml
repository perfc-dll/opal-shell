import QtQuick
import qs.config

// Text button. `accent` = filled with the accent sweep, `danger` = red hover.
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool accent: false
    property bool danger: false
    signal clicked

    implicitWidth: row.implicitWidth + 26
    implicitHeight: 34
    radius: 11
    color: accent ? "transparent" : area.containsMouse ? (danger ? Theme.alpha(Theme.bad, 0.2) : Theme.layer3) : Theme.layer2
    gradient: accent ? grad : null
    border.width: 1
    border.color: danger && area.containsMouse ? Theme.alpha(Theme.bad, 0.6) : Theme.rim
    scale: area.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: Theme.fast } }
    AccentGradient { id: grad }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        MaterialIcon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            size: 17
            fill: 1
            color: root.accent ? Theme.accentInk : root.danger && area.containsMouse ? Theme.bad : Theme.text
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: Theme.fontSm + 1
            font.weight: 600
            color: root.accent ? Theme.accentInk : root.danger && area.containsMouse ? Theme.bad : Theme.text
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
