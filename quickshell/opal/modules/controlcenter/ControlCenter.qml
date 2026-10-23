import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Slides in from the right under the bar.
PanelSurface {
    id: root

    name: "control"
    edge: "right"
    panelWidth: 420
    panelHeight: Math.min(main.implicitHeight + 32, (screen?.height ?? 1200) - offset - Theme.gap)

    property string page: "main"     // main | wifi | bluetooth

    onShownChanged: {
        if (shown)
            SysInfo.watchers++;
        else {
            SysInfo.watchers = Math.max(0, SysInfo.watchers - 1);
            page = "main";
        }
    }

    Glass {
        anchors.fill: parent
        radius: Theme.panelRadius
        glow: true
        clip: true

        Column {
            id: main
            x: root.page === "main" ? 16 : -width - 40
            y: 16
            width: parent.width - 32
            spacing: 14
            opacity: root.page === "main" ? 1 : 0
            Behavior on x { NumberAnimation { duration: Theme.normal + 60; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.normal } }

            Header { width: parent.width }
            Toggles {
                width: parent.width
                onOpenPage: p => root.page = p
            }
            Sliders { width: parent.width }
            MediaCard {
                width: parent.width
                visible: Media.hasPlayer
            }
            Stats { width: parent.width }
        }

        WifiPage {
            x: root.page === "wifi" ? 16 : parent.width + 40
            y: 16
            width: parent.width - 32
            height: parent.height - 32
            active: root.page === "wifi" && root.shown
            opacity: root.page === "wifi" ? 1 : 0
            Behavior on x { NumberAnimation { duration: Theme.normal + 60; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.normal } }
            onBack: root.page = "main"
        }

        BluetoothPage {
            x: root.page === "bluetooth" ? 16 : parent.width + 40
            y: 16
            width: parent.width - 32
            height: parent.height - 32
            active: root.page === "bluetooth" && root.shown
            opacity: root.page === "bluetooth" ? 1 : 0
            Behavior on x { NumberAnimation { duration: Theme.normal + 60; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.normal } }
            onBack: root.page = "main"
        }
    }
}
