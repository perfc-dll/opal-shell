import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// The centre "island". Resting: clock + weather. While music plays it grows a
// spinning cover + title + live cava bars. Volume / brightness changes morph
// it into an OSD for a moment. Click = dashboard, middle = play/pause,
// scroll = volume.
Item {
    id: root

    readonly property bool osd: Ui.osdKind !== ""
    readonly property bool media: Settings.islandMedia && Media.hasPlayer && (Media.playing || mediaLinger.running)
    readonly property real targetWidth: osd ? 300 : clockRow.implicitWidth + (media ? mediaRow.implicitWidth + 14 : 0) + 28

    implicitWidth: targetWidth
    implicitHeight: 32
    width: implicitWidth
    height: implicitHeight

    Behavior on implicitWidth {
        enabled: Theme.motion
        SpringAnimation { spring: 4.2; damping: 0.32; epsilon: 0.4 }
    }

    // keep the media chunk around for a bit after pausing
    Timer {
        id: mediaLinger
        interval: 8000
    }
    Connections {
        target: Media
        function onPlayingChanged() {
            if (!Media.playing)
                mediaLinger.restart();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: capsule
        anchors.fill: parent
        radius: height / 2
        color: hover.hovered ? Theme.layer2 : Theme.layer1
        border.width: 1
        border.color: root.osd || Ui.panel === "dashboard" ? Theme.alpha(Theme.violet, 0.55) : Theme.rim
        clip: true
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        Behavior on border.color { ColorAnimation { duration: Theme.normal } }

        // ---- resting content -------------------------------------------------------
        Row {
            id: content
            anchors.centerIn: parent
            spacing: 14
            opacity: root.osd ? 0 : 1
            scale: root.osd ? 0.85 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

            Row {
                id: clockRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, Settings.use24h ? "HH:mm" : "h:mm AP")
                    font.pixelSize: Theme.fontLg
                    font.weight: 700
                }
                StyledText {
                    visible: Settings.islandDate
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "ddd d MMM")
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSm
                    font.weight: 500
                }
                Row {
                    visible: Weather.ready && Settings.weatherEnabled && Settings.islandWeather
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Weather.icon
                        size: 16
                        fill: 1
                        color: Theme.warn
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Weather.temp
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSm
                    }
                }
            }

            Row {
                id: mediaRow
                visible: root.media
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    width: 1
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.rim
                }

                ClippingRectangle {
                    id: cover
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: Theme.layer2

                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(64, 64)
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: Media.art === ""
                        icon: "music_note"
                        size: 14
                        color: Theme.subtext
                    }

                    RotationAnimation on rotation {
                        from: 0; to: 360
                        duration: 9000
                        loops: Animation.Infinite
                        running: Media.playing && Theme.motion
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 260)
                    text: Media.title + (Media.artist ? "  ·  " + Media.artist : "")
                    font.pixelSize: Theme.fontSm
                    font.weight: 550
                    color: Media.playing ? Theme.text : Theme.subtext
                }

                MiniBars {
                    anchors.verticalCenter: parent.verticalCenter
                    count: 5
                    maxHeight: 14
                    live: Media.playing
                }
            }
        }

        // ---- OSD content ---------------------------------------------------------------
        Row {
            anchors.centerIn: parent
            spacing: 10
            opacity: root.osd ? 1 : 0
            scale: root.osd ? 1 : 1.15
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: Ui.osdIcon
                size: 18
                fill: 1
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 190
                height: 6
                radius: 3
                color: Theme.layer2
                Rectangle {
                    width: parent.width * Math.min(1, Ui.osdValue)
                    height: parent.height
                    radius: 3
                    gradient: AccentGradient {}
                    Behavior on width { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
                }
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                text: Ui.osdLabel
                font.pixelSize: Theme.fontSm
                font.weight: 650
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: e => {
            if (e.button === Qt.MiddleButton)
                Media.toggle();
            else if (e.button === Qt.RightButton)
                Media.next();
            else
                Ui.toggle("dashboard");
        }
        onWheel: w => Audio.setVolume(Audio.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
