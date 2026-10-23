import QtQuick
import qs.config

// A Material Symbols Rounded glyph; `fill` animates between outline and filled.
Text {
    id: root

    property string icon: ""
    property real fill: 0
    property int size: 18
    property int weight: 450

    text: icon
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": root.fill,
            "wght": root.weight,
            "GRAD": 0,
            "opsz": Math.max(20, Math.min(48, root.size))
        })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.QtRendering

    Behavior on fill {
        NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic }
    }
    Behavior on color {
        ColorAnimation { duration: Theme.normal }
    }
}
