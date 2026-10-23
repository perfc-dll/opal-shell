import QtQuick
import qs.config
import qs.services
import qs.widgets

Column {
    id: root
    spacing: 10

    Column {
        width: parent.width
        spacing: 4
        OpalSlider {
            width: parent.width
            icon: Audio.icon
            value: Audio.volume
            muted: Audio.muted
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }
        StyledText {
            width: parent.width
            leftPadding: 12
            text: Audio.sinkName + (Audio.muted ? "  ·  muted" : "  ·  " + Math.round(Audio.volume * 100) + "%")
            font.pixelSize: Theme.fontXs
            color: Theme.dim
        }
    }

    OpalSlider {
        width: parent.width
        icon: Audio.micIcon
        value: Audio.micVolume
        muted: Audio.micMuted
        visible: Audio.source !== null
        onMoved: v => Audio.setMicVolume(v)
        onIconClicked: Audio.toggleMicMute()
    }

    OpalSlider {
        width: parent.width
        visible: Brightness.hasScreen
        icon: Brightness.icon
        value: Brightness.screen
        onMoved: v => Brightness.setScreen(v)
    }
}
