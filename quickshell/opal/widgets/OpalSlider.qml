import QtQuick
import qs.config

// Thick rounded slider with the accent sweep as its fill. Emits `moved`
// continuously while dragging / scrolling.
Item {
    id: root

    property real value: 0          // 0..1 (display)
    property real maximum: 1.0
    property string icon: ""
    property bool muted: false
    property bool dragging: area.pressed
    property real step: 0.05

    signal moved(real v)
    signal iconClicked

    implicitHeight: 36
    implicitWidth: 240

    readonly property real shown: dragging ? _drag : Math.max(0, Math.min(1, value / maximum))
    property real _drag: 0

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.layer1
        border.width: 1
        border.color: Theme.rim

        Rectangle {
            id: fill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(height, parent.width * root.shown)
            radius: height / 2
            opacity: root.muted ? 0.35 : 1
            gradient: AccentGradient {}
            Behavior on width {
                enabled: !root.dragging
                NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic }
            }

            // knob highlight
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 5
                width: 4
                height: parent.height * 0.45
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.85)
                visible: root.shown > 0.08
            }
        }

        MaterialIcon {
            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            size: 18
            fill: 1
            color: root.shown > 0.12 && !root.muted ? Theme.accentInk : Theme.text
            visible: root.icon !== ""

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.iconClicked()
                z: 2
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.leftMargin: root.icon !== "" ? 36 : 0
        cursorShape: Qt.PointingHandCursor
        function valueAt(x) {
            const full = x + anchors.leftMargin;
            return Math.max(0, Math.min(1, full / root.width));
        }
        onPressed: e => {
            root._drag = valueAt(e.x);
            root.moved(root._drag * root.maximum);
        }
        onPositionChanged: e => {
            if (pressed) {
                root._drag = valueAt(e.x);
                root.moved(root._drag * root.maximum);
            }
        }
        onWheel: w => {
            const v = Math.max(0, Math.min(1, root.value / root.maximum + (w.angleDelta.y > 0 ? root.step : -root.step)));
            root.moved(v * root.maximum);
        }
    }
}
