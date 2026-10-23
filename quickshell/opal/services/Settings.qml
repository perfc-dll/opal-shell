pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent user settings: ~/.local/state/opal/settings.json
// (or $OPAL_STATE_DIR/settings.json). The Settings app edits these; hand
// edits to the file are picked up live too.
Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("OPAL_STATE_DIR") || Quickshell.env("HOME") + "/.local/state/opal"
    readonly property string file: stateDir + "/settings.json"

    // general
    property alias displayName: adapter.displayName
    property alias terminal: adapter.terminal
    property alias use24h: adapter.use24h
    property alias weatherEnabled: adapter.weatherEnabled
    property alias weatherLocation: adapter.weatherLocation
    property alias useFahrenheit: adapter.useFahrenheit

    // appearance
    property alias accentPreset: adapter.accentPreset
    property alias adaptiveColors: adapter.adaptiveColors
    property alias glassOpacity: adapter.glassOpacity
    property alias fontScale: adapter.fontScale
    property alias animationSpeed: adapter.animationSpeed
    property alias reduceMotion: adapter.reduceMotion
    property alias edgeVisualizer: adapter.edgeVisualizer

    // bar & island
    property alias barVisible: adapter.barVisible
    property alias barWorkspaces: adapter.barWorkspaces
    property alias barWindows: adapter.barWindows
    property alias barTitle: adapter.barTitle
    property alias barTray: adapter.barTray
    property alias barBatteryPercent: adapter.barBatteryPercent
    property alias islandDate: adapter.islandDate
    property alias islandWeather: adapter.islandWeather
    property alias islandMedia: adapter.islandMedia

    // wallpaper
    property alias wallpaper: adapter.wallpaper
    property alias wallpaperDir: adapter.wallpaperDir
    property alias wallpaperFill: adapter.wallpaperFill
    property alias wallpaperTransition: adapter.wallpaperTransition
    property alias slideshowMinutes: adapter.slideshowMinutes

    // notifications
    property alias dnd: adapter.dnd
    property alias toastSeconds: adapter.toastSeconds
    property alias maxToasts: adapter.maxToasts
    property alias historyLimit: adapter.historyLimit

    // power
    property alias idleLockMinutes: adapter.idleLockMinutes
    property alias idleScreenOffMinutes: adapter.idleScreenOffMinutes
    property alias idleSuspendMinutes: adapter.idleSuspendMinutes
    property alias lowBatteryWarn: adapter.lowBatteryWarn
    property alias lockMedia: adapter.lockMedia
    property alias lockOrbit: adapter.lockOrbit
    property alias nightLight: adapter.nightLight
    property alias nightLightTemp: adapter.nightLightTemp
    property alias nightLightMode: adapter.nightLightMode
    property alias nightLightFrom: adapter.nightLightFrom
    property alias nightLightTo: adapter.nightLightTo

    // launcher
    property alias searchEngine: adapter.searchEngine
    property alias launchCounts: adapter.launchCounts

    // internal
    property alias welcomed: adapter.welcomed

    property bool ready: false

    // Everything "Reset to defaults" puts back. Wallpaper, name, launch
    // history and the welcome flag are yours and are left alone.
    readonly property var defaults: ({
            terminal: "kitty",
            use24h: true,
            weatherEnabled: true,
            weatherLocation: "",
            useFahrenheit: false,
            accentPreset: "opal",
            adaptiveColors: false,
            glassOpacity: 0.52,
            fontScale: 1.0,
            animationSpeed: 1.0,
            reduceMotion: false,
            edgeVisualizer: true,
            barVisible: true,
            barWorkspaces: true,
            barWindows: true,
            barTitle: true,
            barTray: true,
            barBatteryPercent: true,
            islandDate: true,
            islandWeather: true,
            islandMedia: true,
            wallpaperFill: "crop",
            wallpaperTransition: 900,
            slideshowMinutes: 0,
            dnd: false,
            toastSeconds: 6,
            maxToasts: 4,
            historyLimit: 60,
            idleLockMinutes: 0,
            idleScreenOffMinutes: 0,
            idleSuspendMinutes: 0,
            lowBatteryWarn: 15,
            lockMedia: true,
            lockOrbit: true,
            nightLight: false,
            nightLightTemp: 4000,
            nightLightMode: "always",
            nightLightFrom: "20:00",
            nightLightTo: "07:00",
            searchEngine: "duckduckgo"
        })

    function resetDefaults() {
        for (const k in defaults)
            adapter[k] = defaults[k];
    }

    // Many changes arrive at once (sliders being dragged): write them out in
    // one go shortly after the last one.
    Timer {
        id: saveDebounce
        interval: 350
        onTriggered: fileView.writeAdapter()
    }

    FileView {
        id: fileView
        path: root.file
        watchChanges: true
        printErrors: false
        onFileChanged: if (!saveDebounce.running) reload()
        onAdapterUpdated: saveDebounce.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            // First run: write the defaults out so the file exists to edit.
            if (error === FileViewError.FileNotFound)
                writeAdapter();
            root.ready = true;
        }

        JsonAdapter {
            id: adapter

            property string displayName: ""
            property string terminal: "kitty"
            property bool use24h: true
            property bool weatherEnabled: true
            property string weatherLocation: ""
            property bool useFahrenheit: false

            property string accentPreset: "opal"
            property bool adaptiveColors: false
            property real glassOpacity: 0.52
            property real fontScale: 1.0
            property real animationSpeed: 1.0
            property bool reduceMotion: false
            property bool edgeVisualizer: true

            property bool barVisible: true
            property bool barWorkspaces: true
            property bool barWindows: true
            property bool barTitle: true
            property bool barTray: true
            property bool barBatteryPercent: true
            property bool islandDate: true
            property bool islandWeather: true
            property bool islandMedia: true

            property string wallpaper: ""
            property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
            property string wallpaperFill: "crop"
            property int wallpaperTransition: 900
            property int slideshowMinutes: 0

            property bool dnd: false
            property int toastSeconds: 6
            property int maxToasts: 4
            property int historyLimit: 60

            property int idleLockMinutes: 0
            property int idleScreenOffMinutes: 0
            property int idleSuspendMinutes: 0
            property int lowBatteryWarn: 15
            property bool lockMedia: true
            property bool lockOrbit: true
            property bool nightLight: false
            property int nightLightTemp: 4000
            property string nightLightMode: "always"
            property string nightLightFrom: "20:00"
            property string nightLightTo: "07:00"

            property string searchEngine: "duckduckgo"
            property var launchCounts: ({})

            property bool welcomed: false
        }
    }
}
