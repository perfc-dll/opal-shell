import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The lock screen without the lock: no PAM, nothing is secured. Opened from
// Settings so you can look at it; any password "works", Esc leaves.
PanelWindow {
    id: win

    screen: Quickshell.screens.find(s => s.name === Lock.primaryScreen) ?? Quickshell.screens[0]
    visible: Lock.previewing
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.namespace: "opal-lockpreview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Loader {
        anchors.fill: parent
        active: win.visible
        sourceComponent: LockContent {
            primary: true
        }
    }
}
