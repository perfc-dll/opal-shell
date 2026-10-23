import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Month grid, Monday first. Scroll or use the arrows to change month.
Rectangle {
    id: root

    implicitHeight: 268
    radius: Theme.tileRadius + 2
    color: Theme.layer1
    border.width: 1
    border.color: Theme.rim

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    property int monthOffset: 0
    readonly property date today: clock.date
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property var cells: {
        const first = new Date(shown.getFullYear(), shown.getMonth(), 1);
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(shown.getFullYear(), shown.getMonth(), 1 - lead + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === shown.getMonth(),
                isToday: d.toDateString() === today.toDateString(),
                weekend: d.getDay() === 0 || d.getDay() === 6
            });
        }
        return out;
    }

    Connections {
        target: Ui
        function onPanelChanged() {
            if (Ui.panel === "dashboard")
                root.monthOffset = 0;
        }
    }

    Item {
        id: head
        x: 14
        y: 8
        width: parent.width - 28
        height: 32

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.shown.toLocaleDateString(Qt.locale(), "MMMM yyyy")
            font.pixelSize: Theme.fontMd + 1
            font.weight: 700
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            IconButton { icon: "chevron_left"; size: 28; iconSize: 18; onClicked: root.monthOffset-- }
            IconButton { icon: "today"; size: 28; iconSize: 16; visible: root.monthOffset !== 0; onClicked: root.monthOffset = 0 }
            IconButton { icon: "chevron_right"; size: 28; iconSize: 18; onClicked: root.monthOffset++ }
        }
    }

    Grid {
        id: grid
        anchors.top: head.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        columns: 7
        columnSpacing: 2
        rowSpacing: 1
        readonly property real cell: (root.width - 28 - 12) / 7

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
            StyledText {
                required property string modelData
                required property int index
                width: grid.cell
                height: 22
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pixelSize: Theme.fontXs
                font.weight: 700
                color: index >= 5 ? Theme.pink : Theme.dim
            }
        }

        Repeater {
            model: root.cells
            Item {
                required property var modelData
                width: grid.cell
                height: 29

                Rectangle {
                    anchors.centerIn: parent
                    width: 27
                    height: 27
                    radius: 13.5
                    visible: modelData.isToday
                    gradient: AccentGradient {}
                }
                StyledText {
                    anchors.centerIn: parent
                    text: modelData.day
                    font.pixelSize: Theme.fontSm
                    font.weight: modelData.isToday ? 800 : 500
                    color: modelData.isToday ? Theme.accentInk : !modelData.inMonth ? Theme.alpha(Theme.dim, 0.5) : modelData.weekend ? Theme.alpha(Theme.pink, 0.9) : Theme.text
                }
            }
        }
    }

    WheelHandler {
        onWheel: e => root.monthOffset += e.angleDelta.y > 0 ? -1 : 1
    }
}
