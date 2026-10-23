import QtQuick
import qs.config
import qs.services
import qs.widgets

// Compact status icons; the whole pill opens the control centre.
Rectangle {
    id: root

    required property string screenName
    readonly property bool open: Ui.panel === "control"

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 32
    radius: 12
    color: open ? "transparent" : hover.hovered ? Theme.layer2 : Theme.layer1
    gradient: open ? grad : null
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    AccentGradient { id: grad; strength: 0.9 }

    readonly property color fg: open ? Theme.accentInk : Theme.text

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 9

        StyledText {
            visible: Niri.keyboardLayouts.length > 1
            anchors.verticalCenter: parent.verticalCenter
            text: Niri.keyboardLayout.slice(0, 2).toUpperCase()
            font.pixelSize: Theme.fontSm
            font.weight: 700
            color: root.fg
        }
        MaterialIcon {
            visible: Power.caffeine
            anchors.verticalCenter: parent.verticalCenter
            icon: "coffee"; size: 17; fill: 1
            color: root.open ? root.fg : Theme.warn
        }
        MaterialIcon {
            visible: Power.nightLight
            anchors.verticalCenter: parent.verticalCenter
            icon: "nightlight"; size: 17; fill: 1
            color: root.open ? root.fg : Theme.warn
        }
        MaterialIcon {
            visible: Settings.dnd
            anchors.verticalCenter: parent.verticalCenter
            icon: "do_not_disturb_on"; size: 17; fill: 1
            color: root.open ? root.fg : Theme.pink
        }
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: Net.icon; size: 17; fill: 1
            color: root.fg
            opacity: Net.online ? 1 : 0.5
        }
        MaterialIcon {
            visible: Bt.enabled
            anchors.verticalCenter: parent.verticalCenter
            icon: Bt.icon; size: 17; fill: 1
            color: Bt.connected.length > 0 && !root.open ? Theme.cyan : root.fg
        }
        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: Audio.icon; size: 17; fill: 1
            color: root.fg
            opacity: Audio.muted ? 0.5 : 1
        }
        Row {
            visible: Power.hasBattery
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: Power.batteryIcon; size: 17; fill: 1
                rotation: 90
                color: root.open ? root.fg : Power.charging ? Theme.good : Power.percent < 0.15 ? Theme.bad : Power.percent < 0.3 ? Theme.warn : root.fg
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Power.percent * 100) + "%"
                font.pixelSize: Theme.fontSm
                font.weight: 600
                color: root.fg
            }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea {
        anchors.fill: parent
        onClicked: Ui.toggle("control", root.screenName)
        onWheel: w => Audio.setVolume(Audio.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
