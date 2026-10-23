import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Music-reactive glow along the bottom (and mirrored at the top) of the
// screen, under windows, driven by the shared cava process.
// Click-through; fades away after a second of silence.
Scope {
    id: scope

    required property var modelData

    component Strip: PanelWindow {
        id: strip
        property bool mirrored: false

        screen: scope.modelData
        visible: Settings.edgeVisualizer && body.opacity > 0.01
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors.left: true
        anchors.right: true
        anchors.bottom: !mirrored
        anchors.top: mirrored
        implicitHeight: mirrored ? 90 : 150
        mask: Region {}

        WlrLayershell.namespace: "opal-visualizer"
        WlrLayershell.layer: WlrLayer.Bottom

        Item {
            id: body
            anchors.fill: parent
            opacity: Settings.edgeVisualizer && Cava.active ? (strip.mirrored ? 0.45 : 0.8) : 0
            Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

            Row {
                anchors.fill: parent
                spacing: 3
                readonly property real barW: (width - (Cava.count - 1) * spacing) / Cava.count

                Repeater {
                    model: Cava.count
                    Rectangle {
                        required property int index
                        readonly property real v: strip.visible ? (Cava.bars[index] ?? 0) : 0
                        width: parent.barW
                        height: Math.max(0, strip.height * Math.min(1, v * 1.1))
                        y: strip.mirrored ? 0 : strip.height - height
                        radius: Math.min(width / 2, 6)
                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: strip.mirrored ? Theme.alpha(Theme.mix(Theme.pink, Theme.cyan, index / (Cava.count - 1)), 0.9) : Theme.alpha(Theme.mix(Theme.pink, Theme.cyan, index / (Cava.count - 1)), 0.0)
                            }
                            GradientStop {
                                position: 1.0
                                color: strip.mirrored ? Theme.alpha(Theme.mix(Theme.pink, Theme.cyan, index / (Cava.count - 1)), 0.0) : Theme.alpha(Theme.mix(Theme.pink, Theme.cyan, index / (Cava.count - 1)), 0.9)
                            }
                        }
                    }
                }
            }
        }
    }

    Strip { mirrored: false }
    Strip { mirrored: true }
}
