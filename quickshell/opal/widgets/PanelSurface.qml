import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Overlay layer surface that slides in from an edge. niri blurs the whole
// surface (layer-rule on its namespace), so instead of fading a fixed glass
// rectangle in, the surface itself travels on/off screen via its margins.
PanelWindow {
    id: root

    required property string name          // matches Ui.panel
    property string edge: "right"          // right | top | bottom
    property int panelWidth: 400
    property int panelHeight: 600
    property int offset: Theme.barMargin + (Settings.barVisible ? Theme.barHeight : 0) + Theme.gap
    property int sideMargin: Theme.barSide
    property real progress: shown ? 1 : 0
    readonly property bool shown: Ui.panel === name
    readonly property real eased: progress
    default property alias content: body.data
    property alias body: body

    screen: Quickshell.screens.find(s => s.name === Ui.panelScreen) ?? Quickshell.screens[0]
    visible: shown || progress > 0.001
    color: "transparent"
    implicitWidth: panelWidth
    implicitHeight: panelHeight
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "opal-" + name
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors.top: edge === "right" || edge === "top"
    anchors.right: edge === "right"
    anchors.bottom: edge === "bottom"

    // A fully off-screen surface gets no frame callbacks from niri and Qt
    // stalls until it times out, so the hidden position keeps a 2px sliver
    // on screen and the slide renders from the very first frame.
    margins.top: edge === "top" ? Math.round(offset - (1 - progress) * (panelHeight + offset - 2)) : edge === "right" ? offset : 0
    margins.right: edge === "right" ? Math.round(sideMargin - (1 - progress) * (panelWidth + sideMargin - 2)) : 0
    margins.bottom: edge === "bottom" ? Math.round(40 - (1 - progress) * (panelHeight + 40 - 2)) : 0

    Behavior on progress {
        NumberAnimation {
            duration: root.shown ? Theme.slow : Theme.normal
            easing.type: root.shown ? Easing.OutExpo : Easing.InCubic
        }
    }

    Item {
        id: body
        anchors.fill: parent
        opacity: Math.min(1, root.progress * 1.6)
        focus: true
        Keys.onEscapePressed: Ui.close()
    }
}
