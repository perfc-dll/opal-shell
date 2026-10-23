import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.controlcenter

// Same Wi-Fi list as the control centre, with room to breathe.
Item {
    StyledText {
        id: heading
        x: 32
        y: 28
        text: "Wi-Fi"
        font.pixelSize: 26
        font.weight: 700
    }
    StyledText {
        id: sub
        x: 32
        anchors.top: heading.bottom
        anchors.topMargin: 4
        text: Net.wired ? "Wired: " + (Net.wiredName || "connected") : "Click a network to connect; saved ones connect straight away."
        color: Theme.subtext
    }

    WifiPage {
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
