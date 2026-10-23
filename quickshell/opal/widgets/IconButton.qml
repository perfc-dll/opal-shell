import QtQuick
import qs.config

// Round hover button holding a Material icon.
Item {
    id: root

    property string icon: ""
    property int size: 34
    property int iconSize: 18
    property bool active: false
    property bool danger: false
    property color iconColor: active ? Theme.accentInk : danger && hover.hovered ? Theme.bad : Theme.text
    property string tooltip: ""
    property real radius: size / 2
    readonly property bool hovered: hover.hovered

    signal clicked
    signal rightClicked
    signal scrolled(int delta)

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.active ? "transparent" : hover.hovered ? (area.pressed ? Theme.layer3 : Theme.layer2) : "transparent"
        gradient: root.active ? activeGrad : null
        scale: area.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.fast } }

        AccentGradient { id: activeGrad }
    }

    MaterialIcon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        fill: root.active || hover.hovered ? 1 : 0
        color: root.iconColor
        scale: area.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: Theme.fast } }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    MouseArea {
        id: area
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: w => root.scrolled(w.angleDelta.y)
    }
}
