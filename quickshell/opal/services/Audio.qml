pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property string sinkName: sink?.description || sink?.nickname || sink?.name || "No output"
    readonly property string sourceName: source?.description || source?.nickname || source?.name || "No input"

    // hardware outputs / inputs (not app streams)
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)

    function nodeName(n) {
        return n?.description || n?.nickname || n?.name || "Unknown device";
    }
    function setSink(n) {
        Pipewire.preferredDefaultAudioSink = n;
    }
    function setSource(n) {
        Pipewire.preferredDefaultAudioSource = n;
    }

    readonly property string icon: muted || volume <= 0.001 ? "volume_off" : volume < 0.34 ? "volume_mute" : volume < 0.67 ? "volume_down" : "volume_up"
    readonly property string micIcon: micMuted ? "mic_off" : "mic"

    // Emitted only for changes that did not come from our own sliders' drag,
    // so the island OSD reacts to keys / other apps.
    signal volumeTouched

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    property bool _primed: false
    Timer {
        // Ignore the burst of property changes while pipewire binds on start.
        running: root.ready
        interval: 1200
        onTriggered: root._primed = true
    }
    onVolumeChanged: if (_primed) volumeTouched()
    onMutedChanged: if (_primed) volumeTouched()

    function setVolume(v) {
        if (sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1.5, v));
        }
    }
    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }
    function setMicVolume(v) {
        if (source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(1.5, v));
        }
    }
    function toggleMicMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }
}
