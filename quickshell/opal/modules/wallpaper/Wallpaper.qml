import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Wallpaper on the background layer. New images cross-fade in with a slow
// "settle" zoom. niri puts this surface in the overview backdrop
// (place-within-backdrop layer rule).
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    color: "black"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.namespace: "opal-wallpaper"
    WlrLayershell.layer: WlrLayer.Background

    property int front: 0
    readonly property var layers: [a, b]

    function show(path) {
        if (!path)
            return;
        const next = layers[1 - front];
        if (next.source.toString() === "file://" + path && next.opacity === 1)
            return;
        next.source = "file://" + path;
    }

    Connections {
        target: Wallpapers
        function onCurrentChanged() {
            root.show(Wallpapers.current);
        }
    }
    Component.onCompleted: show(Wallpapers.current)

    component Layer: Image {
        id: img
        anchors.fill: parent
        fillMode: Settings.wallpaperFill === "fit" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
        sourceSize: Qt.size(root.screen.width * 1.0, root.screen.height * 1.0)
        opacity: 0
        scale: 1
        property int myIndex: 0

        onStatusChanged: {
            if (status === Image.Ready && source.toString() !== "") {
                if (root.layers[root.front] !== img || opacity < 1) {
                    root.front = myIndex;
                    img.z = 1;
                    root.layers[1 - myIndex].z = 0;
                    fadeIn.restart();
                }
            }
        }

        ParallelAnimation {
            id: fadeIn
            NumberAnimation { target: img; property: "opacity"; from: 0; to: 1; duration: Math.max(1, Settings.wallpaperTransition); easing.type: Easing.OutCubic }
            NumberAnimation { target: img; property: "scale"; from: Theme.motion ? 1.06 : 1.0; to: 1.0; duration: Math.max(1, Settings.wallpaperTransition * 1.8); easing.type: Easing.OutExpo }
            onFinished: {
                const other = root.layers[1 - img.myIndex];
                other.opacity = 0;
                other.source = "";
            }
        }
    }

    Layer { id: a; myIndex: 0 }
    Layer { id: b; myIndex: 1 }
}
