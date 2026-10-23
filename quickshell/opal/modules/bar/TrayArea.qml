import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// StatusNotifier tray. Left click activates, right click opens the app's menu.
Row {
    id: root

    required property var barWindow

    spacing: 2
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        Item {
            id: cell
            required property SystemTrayItem modelData
            width: 28
            height: 28

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: hover.hovered ? Theme.layer2 : "transparent"
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: {
                    const icon = cell.modelData.icon;
                    // Some apps hand over "name?path=/dir" theme-path icons.
                    if (icon.includes("?path=")) {
                        const [name, path] = icon.split("?path=");
                        return "file://" + path + "/" + name.slice(name.lastIndexOf("/") + 1);
                    }
                    return icon;
                }
                opacity: cell.modelData.status === Status.Passive ? 0.55 : 1
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: e => {
                    const item = cell.modelData;
                    if (e.button === Qt.RightButton || (e.button === Qt.LeftButton && item.onlyMenu)) {
                        if (item.hasMenu) {
                            const p = root.barWindow.itemPosition(cell);
                            item.display(root.barWindow, p.x, p.y + cell.height + 10);
                        }
                    } else if (e.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else {
                        item.activate();
                    }
                }
                onWheel: w => cell.modelData.scroll(w.angleDelta.y, false)
            }
        }
    }

    Rectangle {
        visible: root.visible
        width: 1
        height: 16
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.rim
    }
}
