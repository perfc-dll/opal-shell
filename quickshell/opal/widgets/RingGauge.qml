import QtQuick
import QtQuick.Shapes
import qs.config

// Circular gauge with the accent sweep, used for system stats.
Item {
    id: root

    property real value: 0      // 0..1
    property string icon: ""
    property string label: ""
    property string caption: ""
    property real thickness: 6

    implicitWidth: 72
    implicitHeight: 92

    Item {
        id: ring
        width: 64
        height: 64
        anchors.horizontalCenter: parent.horizontalCenter

        property real shownValue: root.value
        Behavior on shownValue { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: Theme.layer2
                strokeWidth: root.thickness
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 32; centerY: 32
                    radiusX: 32 - root.thickness / 2; radiusY: 32 - root.thickness / 2
                    startAngle: 135; sweepAngle: 270
                }
            }

            ShapePath {
                strokeWidth: root.thickness
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                strokeColor: root.value > 0.9 ? Theme.bad : root.value > 0.75 ? Theme.warn : Theme.mix(Theme.cyan, Theme.pink, Math.min(1, ring.shownValue * 1.2))
                PathAngleArc {
                    centerX: 32; centerY: 32
                    radiusX: 32 - root.thickness / 2; radiusY: 32 - root.thickness / 2
                    startAngle: 135; sweepAngle: Math.max(0.1, 270 * Math.min(1, ring.shownValue))
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: -2
            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                icon: root.icon
                size: 16
                fill: 1
                color: Theme.subtext
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.label
                font.pixelSize: Theme.fontSm
                font.weight: 650
            }
        }
    }

    StyledText {
        anchors.top: ring.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.caption
        font.pixelSize: Theme.fontXs
        color: Theme.dim
    }
}
