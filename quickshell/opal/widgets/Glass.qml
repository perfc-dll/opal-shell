import QtQuick
import qs.config

// The Opal glass pane: translucent plum tint (niri blurs what's behind the
// layer surface), a hairline rim, and a specular highlight along the top edge
// like the "glass rim" border on the niri kitty rule.
Rectangle {
    id: root

    property color tint: Theme.glass
    property bool rimLight: true
    property bool glow: false

    color: tint
    radius: Theme.panelRadius
    border.width: 1
    border.color: Theme.rim

    // top-left specular rim
    Rectangle {
        visible: root.rimLight
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: 1
        border.color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.075) }
            GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }

    Rectangle {
        visible: root.rimLight
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 1
        width: parent.width - parent.radius * 2
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.32) }
            GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.12) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }

    // accent underglow along the bottom edge
    Rectangle {
        visible: root.glow
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 1
        width: parent.width * 0.6
        height: 1
        opacity: 0.8
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.alpha(Theme.pink, 0) }
            GradientStop { position: 0.35; color: Theme.alpha(Theme.pink, 0.7) }
            GradientStop { position: 0.65; color: Theme.alpha(Theme.cyan, 0.7) }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.cyan, 0) }
        }
    }
}
