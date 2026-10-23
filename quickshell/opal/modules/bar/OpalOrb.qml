import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services

// The Opal mark: a slowly turning iridescent orb. Click = launcher,
// right click = niri overview.
Item {
    id: root

    implicitWidth: 32
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 11
        color: hover.hovered || Ui.panel === "launcher" ? Theme.layer2 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Shape {
        id: orb
        anchors.centerIn: parent
        width: 20
        height: 20
        preferredRendererType: Shape.CurveRenderer
        scale: tap.pressed ? 0.85 : hover.hovered ? 1.12 : 1
        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: ConicalGradient {
                centerX: 10; centerY: 10
                angle: rot.angle
                GradientStop { position: 0.0; color: Theme.pink }
                GradientStop { position: 0.33; color: Theme.violet }
                GradientStop { position: 0.66; color: Theme.cyan }
                GradientStop { position: 1.0; color: Theme.pink }
            }
            PathAngleArc { centerX: 10; centerY: 10; radiusX: 10; radiusY: 10; startAngle: 0; sweepAngle: 360 }
        }
    }

    // glossy highlight
    Rectangle {
        anchors.centerIn: orb
        anchors.horizontalCenterOffset: -3
        anchors.verticalCenterOffset: -3
        width: 7
        height: 5
        radius: 3
        rotation: -35
        color: Qt.rgba(1, 1, 1, 0.55)
        scale: orb.scale
    }

    QtObject {
        id: rot
        property real angle: 0
        NumberAnimation on angle {
            from: 0; to: 360
            duration: 2400
            loops: Animation.Infinite
            // Only while you're looking at it: a permanent animation would
            // keep the whole bar redrawing (and niri re-blurring it) at 60fps.
            running: Theme.motion && (hover.hovered || Ui.panel === "launcher")
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea {
        id: tap
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? Niri.toggleOverview() : Ui.openLauncher("apps")
    }
}
