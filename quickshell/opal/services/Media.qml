pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Picks the "current" MPRIS player: whatever is playing, else the last one
// that was playing, else the first one around.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer manual: null
    property MprisPlayer lastPlaying: null

    readonly property MprisPlayer player: {
        if (manual && players.includes(manual))
            return manual;
        const playing = players.find(p => p.isPlaying);
        if (playing)
            return playing;
        if (lastPlaying && players.includes(lastPlaying))
            return lastPlaying;
        return players[0] ?? null;
    }

    readonly property bool hasPlayer: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || "Nothing playing"
    readonly property string artist: player?.trackArtist || player?.identity || ""
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property real length: player?.length ?? 0
    property real position: 0

    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property MprisPlayer modelData
            target: modelData
            function onIsPlayingChanged() {
                if (modelData.isPlaying) {
                    root.lastPlaying = modelData;
                    root.manual = null;
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.player.positionChanged();
            root.position = root.player.position;
        }
    }

    onPlayerChanged: position = player?.position ?? 0

    function cycle() {
        if (players.length < 2)
            return;
        const i = players.indexOf(player);
        manual = players[(i + 1) % players.length];
    }

    function toggle() { if (player?.canTogglePlaying) player.togglePlaying(); }
    function next() { if (player?.canGoNext) player.next(); }
    function previous() { if (player?.canGoPrevious) player.previous(); }
    function seek(fraction) {
        if (player?.canSeek && length > 0) {
            player.position = fraction * length;
            position = player.position;
        }
    }

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0)
            sec = 0;
        const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
}
