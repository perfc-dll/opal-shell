pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Who's logged in and what we're running on. `displayName` in settings.json
// overrides the real name from the passwd entry.
Singleton {
    id: root

    property string realName: Quickshell.env("USER") ?? ""
    property string distro: ""

    readonly property string fullName: Settings.displayName || realName
    readonly property string firstName: fullName.split(" ")[0]

    Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.realName = text.trim()
        }
    }

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const t = text();
            const name = t.match(/^NAME="?([^"\n]*)"?/m)?.[1] ?? "Linux";
            const ver = t.match(/^VERSION_ID="?([^"\n]*)"?/m)?.[1] ?? "";
            root.distro = (name + " " + ver).trim();
        }
    }
}
