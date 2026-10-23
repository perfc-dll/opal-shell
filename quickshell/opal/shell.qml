//@ pragma UseQApplication
//@ pragma IconTheme Fluent-purple-dark
//@ pragma Env QS_NO_RELOAD_POPUP=1

// Opal — a liquid-glass desktop shell for niri.
// Run with `qs -c opal`. Talk to it with `qs -c opal ipc call <target> <fn>`
// (`qs -c opal ipc show` lists everything).

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.modules.bar
import qs.modules.controlcenter
import qs.modules.dashboard
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.wallpaper
import qs.modules.session
import qs.modules.visualizer
import qs.widgets

ShellRoot {
    id: shell

    // Touch the always-on services so they start with the shell.
    readonly property var _services: [Notifs, Niri, Audio, Brightness, Power, Wallpapers, Weather]

    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }

    Variants {
        model: Quickshell.screens
        EdgeVisualizer {}
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        Scrim {}
    }

    Toasts {}

    ControlCenter {}
    Dashboard {}
    Launcher {}
    WallpaperPicker {}
    SessionMenu {}

    // One-time hello with the important shortcuts.
    Timer {
        running: Settings.ready && !Settings.welcomed
        interval: 2500
        onTriggered: {
            Settings.welcomed = true;
            Quickshell.execDetached(["notify-send", "-a", "Opal", "-i", "preferences-desktop-theme", "-t", "20000", "Welcome to Opal ✨", "<b>Super+D</b> launcher  ·  <b>Super+A</b> control centre  ·  <b>Super+N</b> dashboard  ·  <b>Super+W</b> wallpapers  ·  <b>Super+V</b> clipboard  ·  <b>Super+Shift+E</b> power"]);
        }
    }

    // ---- IPC (used by the niri keybinds) ---------------------------------------------
    IpcHandler {
        target: "shell"

        function toggle(panel: string): void {
            Ui.toggle(panel);
        }
        function close(): void {
            Ui.close();
        }
        function launcher(): void {
            if (Ui.panel === "launcher" && Ui.launcherMode === "apps")
                Ui.close();
            else
                Ui.openLauncher("apps");
        }
        function clipboard(): void {
            if (Ui.panel === "launcher" && Ui.launcherMode === "clipboard")
                Ui.close();
            else
                Ui.openLauncher("clipboard");
        }
        function bar(): void {
            Settings.barVisible = !Settings.barVisible;
        }
        function dnd(): void {
            Settings.dnd = !Settings.dnd;
        }
        function caffeine(): void {
            Power.caffeine = !Power.caffeine;
        }
        function reload(): void {
            Quickshell.reload(true);
        }
    }

    IpcHandler {
        target: "brightness"

        function refresh(): void {
            Brightness.externalChange();
        }
        function up(): void {
            Brightness.stepScreen(0.05);
        }
        function down(): void {
            Brightness.stepScreen(-0.05);
        }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            Wallpapers.set(path);
        }
        function random(): void {
            Wallpapers.random();
        }
        function get(): string {
            return Wallpapers.current;
        }
    }

    IpcHandler {
        target: "media"

        function toggle(): void {
            Media.toggle();
        }
        function next(): void {
            Media.next();
        }
        function previous(): void {
            Media.previous();
        }
    }
}
