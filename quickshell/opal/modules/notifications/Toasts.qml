import QtQuick
import Quickshell
import qs.config
import qs.services

// On-screen notification popups, each its own blurred layer surface stacked
// under the bar on the focused output.
Scope {
    Variants {
        model: Notifs.toasts
        delegate: Toast {}
    }
}
