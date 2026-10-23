import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

PanelWindow {
    id: root

    required property var modelData
    readonly property var entry: modelData
    readonly property int stackY: Notifs.toastOffset(entry.key)
    property real slide: 0          // 0 = off screen, 1 = in place
    property real shownY: stackY
    property bool leaving: false

    screen: Quickshell.screens.find(s => s.name === Ui.focusedScreenName()) ?? Quickshell.screens[0]
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true }
    implicitWidth: 390
    implicitHeight: card.implicitHeight
    margins.top: Math.round(Theme.barMargin + (Settings.barVisible ? Theme.barHeight : 0) + Theme.gap + shownY)
    // keep a 2px sliver on screen so frames keep flowing (see PanelSurface)
    margins.right: Math.round(Theme.barSide - (1 - slide) * (implicitWidth + Theme.barSide - 2))

    WlrLayershell.namespace: "opal-toast"
    WlrLayershell.layer: WlrLayer.Overlay

    Behavior on shownY { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    onStackYChanged: shownY = stackY

    Component.onCompleted: enter.start()
    onImplicitHeightChanged: Notifs.setToastHeight(entry.key, implicitHeight)

    NumberAnimation {
        id: enter
        target: root
        property: "slide"
        from: 0
        to: 1
        duration: Theme.slow
        easing.type: Easing.OutExpo
    }

    NumberAnimation {
        id: leaveAnim
        target: root
        property: "slide"
        to: 0
        duration: Theme.normal
        easing.type: Easing.InCubic
        onFinished: Notifs.removeToast(root.entry.key)
    }

    Glass {
        anchors.fill: parent
        radius: Theme.toastRadius
        tint: card.critical ? Qt.rgba(0.2, 0.05, 0.09, Settings.glassOpacity + 0.1) : Theme.glass
        border.color: card.critical ? Theme.alpha(Theme.bad, 0.55) : Theme.rim

        // countdown hairline
        Rectangle {
            visible: root.entry.timeout > 0
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: Theme.toastRadius
            anchors.bottomMargin: 1
            height: 2
            radius: 1
            width: (parent.width - Theme.toastRadius * 2) * life.remaining
            gradient: AccentGradient {}
            opacity: 0.8
        }
    }

    NotificationCard {
        id: card
        width: parent.width
        entry: root.entry
    }

    // life timer that pauses while hovered
    QtObject {
        id: life
        property real remaining: 1
    }
    Timer {
        interval: 50
        repeat: true
        running: root.entry.timeout > 0 && !card.hovered
        onTriggered: {
            life.remaining -= 50 / root.entry.timeout;
            if (life.remaining <= 0) {
                running = false;
                leaveAnim.start();
            }
        }
    }
}
