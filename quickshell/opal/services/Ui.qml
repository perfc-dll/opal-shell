pragma Singleton

import QtQuick
import Quickshell

// Which overlay is open, on which screen, plus the island's OSD state.
Singleton {
    id: root

    // "", "control", "dashboard", "launcher", "wallpaper", "session"
    property string panel: ""
    property string panelScreen: ""
    property string launcherMode: "apps"     // apps | clipboard

    readonly property bool anyOpen: panel !== ""

    // ---- island OSD ------------------------------------------------------------------
    property string osdKind: ""              // "", volume, brightness, mic, kbd
    property real osdValue: 0
    property string osdIcon: ""
    property string osdLabel: ""

    function focusedScreenName() {
        return Niri.focusedOutput || (Quickshell.screens[0]?.name ?? "");
    }

    function open(name, screenName) {
        panelScreen = screenName || focusedScreenName();
        panel = name;
    }

    function toggle(name, screenName) {
        if (panel === name)
            close();
        else
            open(name, screenName);
    }

    function close() {
        panel = "";
    }

    function openLauncher(mode) {
        launcherMode = mode || "apps";
        open("launcher");
    }

    function showOsd(kind, value, icon, label) {
        osdKind = kind;
        osdValue = value;
        osdIcon = icon;
        osdLabel = label;
        osdTimer.restart();
    }

    Timer {
        id: osdTimer
        interval: 1600
        onTriggered: root.osdKind = ""
    }

    Connections {
        target: Audio
        function onVolumeTouched() {
            root.showOsd("volume", Audio.muted ? 0 : Audio.volume, Audio.icon, Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%");
        }
    }

    Connections {
        target: Brightness
        function onScreenTouched() {
            root.showOsd("brightness", Brightness.screen, Brightness.icon, Math.round(Brightness.screen * 100) + "%");
        }
    }
}
