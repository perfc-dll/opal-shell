import QtQuick
import qs.config

// Pill switch with the accent sweep when on.
Item {
    id: root

    property bool checked: false
    property bool enabled: true
    signal toggled

    implicitWidth: 46
    implicitHeight: 26
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? "transparent" : Theme.layer2
        gradient: root.checked ? grad : null
        border.width: 1
        border.color: root.checked ? Qt.rgba(1, 1, 1, 0.2) : Theme.rim
        AccentGradient { id: grad }

        Rectangle {
            width: 20
            height: 20
            radius: 10
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? "white" : Theme.subtext
            Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Theme.motion ? Easing.OutBack : Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
