import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.controlcenter

Item {
    StyledText {
        id: heading
        x: 32
        y: 28
        text: "Bluetooth"
        font.pixelSize: 26
        font.weight: 700
    }
    StyledText {
        id: sub
        x: 32
        anchors.top: heading.bottom
        anchors.topMargin: 4
        text: Bt.available ? "Click a device to connect or disconnect. New devices show up while this page is open." : "No Bluetooth adapter found."
        color: Theme.subtext
    }

    BluetoothPage {
        x: 32
        anchors.top: sub.bottom
        anchors.topMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: parent.width - 64
        showBack: false
        active: true
    }
}
