pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen + keyboard backlight through brightnessctl (goes via logind, no root).
Singleton {
    id: root

    property string screenDevice: ""
    property real screen: 0          // 0..1
    property string kbdDevice: ""
    property int kbd: 0
    property int kbdMax: 0

    readonly property bool hasScreen: screenDevice !== ""
    readonly property bool hasKbd: kbdDevice !== ""
    readonly property real minScreen: 0.05
    readonly property string icon: screen < 0.34 ? "brightness_low" : screen < 0.67 ? "brightness_medium" : "brightness_high"

    signal screenTouched

    function refresh() {
        if (!probe.running)
            probe.running = true;
    }

    function setScreen(v) {
        const pct = Math.round(Math.max(minScreen, Math.min(1, v)) * 100);
        screen = pct / 100;
        Quickshell.execDetached(["brightnessctl", "-q", "-d", screenDevice, "set", pct + "%"]);
    }

    function stepScreen(delta) {
        setScreen(screen + delta);
        screenTouched();
    }

    function setKbd(v) {
        kbd = Math.max(0, Math.min(kbdMax, v));
        Quickshell.execDetached(["brightnessctl", "-q", "-d", kbdDevice, "set", String(kbd)]);
    }

    function toggleKbd() {
        setKbd(kbd > 0 ? 0 : kbdMax);
    }

    // Called from the niri brightness keybinds after brightnessctl ran.
    function externalChange() {
        _announce = true;
        refresh();
    }

    property bool _announce: false

    Process {
        id: probe
        command: ["sh", "-c", "brightnessctl -m -c backlight 2>/dev/null | head -n1; brightnessctl -m -d '*kbd_backlight' 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const f = line.split(",");
                    if (f.length < 5)
                        continue;
                    if (f[1] === "backlight") {
                        root.screenDevice = f[0];
                        root.screen = parseInt(f[2]) / Math.max(1, parseInt(f[4]));
                    } else if (f[0].indexOf("kbd_backlight") !== -1) {
                        root.kbdDevice = f[0];
                        root.kbd = parseInt(f[2]);
                        root.kbdMax = parseInt(f[4]);
                    }
                }
                if (root._announce) {
                    root._announce = false;
                    root.screenTouched();
                }
            }
        }
    }

    // Slow poll catches changes made by anything else (e.g. the ThinkPad Fn keys
    // toggling the keyboard light in firmware).
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
