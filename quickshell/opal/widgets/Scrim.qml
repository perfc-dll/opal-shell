import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Invisible full-screen click catcher under an open panel: clicking anywhere
// outside the panel closes it. The bar stays clickable through a hole in the
// input mask so you can hop straight from one panel to another.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    visible: Ui.anyOpen && Ui.panel !== "session" && Ui.panelScreen === modelData.name
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.namespace: "opal-scrim"
    WlrLayershell.layer: WlrLayer.Top

    mask: Region {
        item: full
        Region {
            item: barHole
            intersection: Intersection.Subtract
        }
    }

    Item { id: full; anchors.fill: parent }
    Item {
        id: barHole
        visible: Settings.barVisible
        x: Theme.barSide
        y: Theme.barMargin
        width: parent.width - Theme.barSide * 2
        height: Settings.barVisible ? Theme.barHeight : 0
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: Ui.close()
    }
}
