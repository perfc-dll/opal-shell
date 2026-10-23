import QtQuick
import Quickshell.Bluetooth
import qs.config
import qs.services
import qs.widgets

Item {
    id: root

    property bool active: false
    signal back

    onActiveChanged: Bt.scan(active)

    PageHeader {
        id: header
        width: parent.width
        title: "Bluetooth"
        toggleOn: Bt.enabled
        busy: Bt.adapter?.discovering ?? false
        onBack: root.back()
        onToggled: Bt.toggle()
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        spacing: 6
        model: Bt.enabled ? Bt.devices : []
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row
            required property BluetoothDevice modelData
            width: list.width
            height: 52
            radius: Theme.tileRadius
            color: modelData.connected ? Theme.alpha(Theme.cyan, 0.16) : hover.hovered ? Theme.layer2 : Theme.layer1
            border.width: 1
            border.color: modelData.connected ? Theme.alpha(Theme.cyan, 0.45) : Theme.rim

            HoverHandler { id: hover }

            MaterialIcon {
                id: ic
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                icon: Bt.deviceIcon(row.modelData)
                size: 20
                fill: row.modelData.connected ? 1 : 0
                color: row.modelData.connected ? Theme.cyan : Theme.text
            }
            Column {
                anchors.left: ic.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                StyledText {
                    width: parent.width
                    text: row.modelData.name || row.modelData.address
                    font.weight: 600
                }
                StyledText {
                    width: parent.width
                    text: (row.modelData.state === BluetoothDeviceState.Connecting ? "Connecting…" : row.modelData.connected ? "Connected" : row.modelData.pairing ? "Pairing…" : row.modelData.paired ? "Paired" : "Available") + (row.modelData.batteryAvailable ? "  ·  " + Math.round(row.modelData.battery * 100) + "% battery" : "")
                    font.pixelSize: Theme.fontXs
                    color: Theme.subtext
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Bt.toggleDevice(row.modelData)
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: !Bt.available ? "No Bluetooth adapter" : Bt.enabled ? "Looking for devices…" : "Bluetooth is off"
            color: Theme.dim
        }
    }
}
