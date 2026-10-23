import QtQuick
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    title: "Sound"
    subtitle: "Output and input devices and their volume."

    component DeviceRow: Item {
        id: dev
        required property var node
        property bool selected: false
        signal chosen

        width: parent ? parent.width : 400
        height: 46

        Rectangle {
            visible: dev.Positioner.index > 0
            anchors.top: parent.top
            x: 16
            width: parent.width - 32
            height: 1
            color: Theme.rim
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 12
            color: hover.hovered ? Theme.layer2 : "transparent"
        }
        MaterialIcon {
            id: radio
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            icon: dev.selected ? "radio_button_checked" : "radio_button_unchecked"
            size: 20
            fill: dev.selected ? 1 : 0
            color: dev.selected ? Theme.violet : Theme.subtext
        }
        StyledText {
            anchors.left: radio.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.nodeName(dev.node)
            font.weight: dev.selected ? 650 : 450
            color: dev.selected ? Theme.text : Theme.subtext
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            onClicked: dev.chosen()
        }
    }

    SettingCard {
        width: parent.width
        title: "OUTPUT"

        SettingRow {
            icon: Audio.icon
            title: "Volume"
            subtitle: Audio.muted ? "Muted" : ""
            Row {
                spacing: 14
                SettingSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 1.5
                    step: 0.01
                    value: Audio.volume
                    format: v => Math.round(v * 100) + "%"
                    onMoved: v => Audio.setVolume(v)
                }
                OpalSwitch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: !Audio.muted
                    onToggled: Audio.toggleMute()
                }
            }
        }
        Repeater {
            model: Audio.sinks
            DeviceRow {
                required property var modelData
                node: modelData
                selected: Audio.sink === modelData
                onChosen: Audio.setSink(modelData)
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "INPUT"
        note: "Volumes above 100% amplify and can distort."

        SettingRow {
            icon: Audio.micIcon
            title: "Microphone"
            subtitle: Audio.micMuted ? "Muted" : ""
            enabled: Audio.source !== null
            Row {
                spacing: 14
                SettingSlider {
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 1.5
                    step: 0.01
                    value: Audio.micVolume
                    format: v => Math.round(v * 100) + "%"
                    onMoved: v => Audio.setMicVolume(v)
                }
                OpalSwitch {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: !Audio.micMuted
                    onToggled: Audio.toggleMicMute()
                }
            }
        }
        Repeater {
            model: Audio.sources
            DeviceRow {
                required property var modelData
                node: modelData
                selected: Audio.source === modelData
                onChosen: Audio.setSource(modelData)
            }
        }
    }
}
