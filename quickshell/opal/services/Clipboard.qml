pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// cliphist-backed clipboard history (the session runs `wl-paste --watch cliphist store`).
Singleton {
    id: root

    property bool available: false
    property var entries: []     // [{ id, text }]

    function refresh() {
        if (available && !lister.running)
            lister.running = true;
    }

    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entry.id + "\t" + entry.text]);
    }

    function remove(entry) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", entry.id + "\t" + entry.text]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        entries = [];
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v cliphist"]
        onExited: code => root.available = code === 0
    }

    Process {
        id: lister
        command: ["sh", "-c", "cliphist list | head -n 200"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l.length > 0).map(l => {
                    const tab = l.indexOf("\t");
                    return { id: l.slice(0, tab), text: l.slice(tab + 1) };
                });
            }
        }
    }
}
