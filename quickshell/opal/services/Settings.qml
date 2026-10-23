pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent user settings: ~/.local/state/opal/settings.json
// Edits made by hand are picked up live (watchChanges).
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("OPAL_STATE_DIR") || Quickshell.env("HOME") + "/.local/state/opal"

    property alias wallpaper: adapter.wallpaper
    property alias wallpaperDir: adapter.wallpaperDir
    property alias adaptiveColors: adapter.adaptiveColors
    property alias glassOpacity: adapter.glassOpacity
    property alias edgeVisualizer: adapter.edgeVisualizer
    property alias barVisible: adapter.barVisible
    property alias dnd: adapter.dnd
    property alias weatherLocation: adapter.weatherLocation
    property alias useFahrenheit: adapter.useFahrenheit
    property alias use24h: adapter.use24h
    property alias nightLightTemp: adapter.nightLightTemp
    property alias launchCounts: adapter.launchCounts
    property alias terminal: adapter.terminal
    property alias welcomed: adapter.welcomed
    property alias displayName: adapter.displayName

    property bool ready: false

    FileView {
        id: file
        path: root.stateDir + "/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            // First run: write the defaults out so the file exists to edit.
            if (error === FileViewError.FileNotFound)
                writeAdapter();
            root.ready = true;
        }

        JsonAdapter {
            id: adapter

            property string wallpaper: ""
            property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
            property bool adaptiveColors: false
            property real glassOpacity: 0.52
            property bool edgeVisualizer: true
            property bool barVisible: true
            property bool dnd: false
            property string weatherLocation: ""
            property bool useFahrenheit: false
            property bool use24h: true
            property int nightLightTemp: 4000
            property var launchCounts: ({})
            property string terminal: "kitty"
            property bool welcomed: false
            property string displayName: ""
        }
    }
}
