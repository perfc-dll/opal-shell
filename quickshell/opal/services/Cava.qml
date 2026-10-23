pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// One shared cava process; every visualizer in the shell reads `bars`.
Singleton {
    id: root

    readonly property int count: 48
    property var bars: new Array(count).fill(0)     // 0..1
    property real level: 0                           // smoothed overall energy
    property bool active: false                      // audio audible recently
    // Run only while audio is playing: an MPRIS player, or (for the edge
    // visualizer) any app with an open playback stream. cava's own capture
    // stream is an AudioInStream, so it doesn't keep itself alive.
    readonly property bool playbackActive: Pipewire.nodes.values.some(n => n.type === PwNodeType.AudioOutStream)
    readonly property bool wanted: Media.playing || (Settings.edgeVisualizer && playbackActive)

    property real _lastSound: 0

    Process {
        id: proc
        running: root.wanted
        command: ["cava", "-p", Quickshell.shellPath("scripts/cava.conf")]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = new Array(root.count);
                let peak = 0, sum = 0;
                for (let i = 0; i < root.count; i++) {
                    const v = (parseInt(parts[i]) || 0) / 100;
                    out[i] = v;
                    sum += v;
                    if (v > peak)
                        peak = v;
                }
                root.bars = out;
                root.level = root.level * 0.7 + (sum / root.count) * 0.3;
                if (peak > 0.03)
                    root._lastSound = Date.now();
            }
        }
        onRunningChanged: if (!running) {
            root.bars = new Array(root.count).fill(0);
            root.active = false;
        }
    }

    Timer {
        interval: 250
        running: proc.running
        repeat: true
        onTriggered: root.active = Date.now() - root._lastSound < 900
    }

    // Down-sample to n bars for small widgets.
    function sample(n) {
        const out = new Array(n);
        const step = count / n;
        for (let i = 0; i < n; i++) {
            let m = 0;
            for (let j = Math.floor(i * step); j < Math.floor((i + 1) * step); j++)
                m = Math.max(m, bars[j]);
            out[i] = m;
        }
        return out;
    }
}
