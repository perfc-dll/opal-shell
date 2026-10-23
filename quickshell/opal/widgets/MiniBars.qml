import QtQuick
import qs.config
import qs.services

// Small cava visualizer: `count` rounded bars with the accent sweep.
Row {
    id: root

    property int count: 6
    property real barWidth: 3
    property real maxHeight: 16
    property real minHeight: 3
    property bool live: true

    spacing: 2
    height: maxHeight

    readonly property var values: live ? Cava.sample(count) : new Array(count).fill(0)


    Repeater {
        model: root.count
        Rectangle {
            required property int index
            width: root.barWidth
            height: Math.max(root.minHeight, root.maxHeight * Math.min(1, (root.values[index] ?? 0) * 1.15))
            anchors.verticalCenter: parent.verticalCenter
            radius: width / 2
            color: Theme.mix(Theme.pink, Theme.cyan, index / Math.max(1, root.count - 1))
            Behavior on height { NumberAnimation { duration: 90 } }
        }
    }
}
