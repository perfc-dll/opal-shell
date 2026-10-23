import QtQuick
import qs.config

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontMd
    font.features: ({ "tnum": 1, "cv11": 1 })
    renderType: Text.QtRendering
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorAnimation { duration: Theme.normal }
    }
}
