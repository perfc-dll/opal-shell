import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// ext-session-lock: niri shows only these surfaces until Lock.locked goes
// false, which only a successful password check does.
WlSessionLock {
    id: sessionLock

    locked: Lock.locked
    onSecureChanged: Lock.secure = secure

    WlSessionLockSurface {
        id: surface
        color: "black"

        LockContent {
            anchors.fill: parent
            primary: Quickshell.screens.length === 1 || surface.screen?.name === Lock.primaryScreen
        }
    }
}
