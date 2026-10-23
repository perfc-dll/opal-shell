import QtQuick
import qs.config

// Slim slider with a value readout. Emits `moved` with a value snapped to `step`.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real step: 0.01
    property real value: 0
    property var format: v => v.toFixed(2)
    signal moved(real value)

    implicitWidth: 260
    implicitHeight: 28

    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))

    function snap(f) {
        const raw = from + Math.max(0, Math.min(1, f)) * (to - from);
        const v = Math.round(raw / step) * step;
        return Math.max(from, Math.min(to, Number(v.toFixed(4))));
    }

    StyledText {
        id: readout
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 58
        horizontalAlignment: Text.AlignRight
        text: root.format(root.value)
        font.pixelSize: Theme.fontSm
        font.weight: 650
        color: Theme.subtext
    }

    Item {
        id: track
        anchors.left: parent.left
        anchors.right: readout.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: 22

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.layer2

            Rectangle {
                width: parent.width * root.frac
                height: parent.height
                radius: 3
                gradient: AccentGradient {}
            }
        }

        Rectangle {
            x: root.frac * (track.width - width)
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: "white"
            border.width: 3
            border.color: Theme.violet
            scale: area.pressed ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: Theme.fast } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            function at(x) {
                return root.snap((x - 6) / (track.width));
            }
            onPressed: e => root.moved(at(e.x))
            onPositionChanged: e => {
                if (pressed)
                    root.moved(at(e.x));
            }
            onWheel: w => root.moved(root.snap(root.frac + (w.angleDelta.y > 0 ? 1 : -1) * Math.max(root.step / (root.to - root.from), 0.02)))
        }
    }
}
