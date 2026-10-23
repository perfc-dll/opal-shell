import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Now-playing card: blurred cover backdrop, cover art, scrubber, controls and
// a cava strip along the bottom.
ClippingRectangle {
    id: root

    implicitHeight: 148
    radius: Theme.tileRadius + 2
    color: Theme.layer1
    border.width: 1
    border.color: Theme.rim

    // blurred cover backdrop
    Image {
        id: backdropSrc
        anchors.fill: parent
        source: Media.art
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(256, 256)
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: backdropSrc
        visible: backdropSrc.status === Image.Ready
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: 0.25
        brightness: -0.18
        opacity: 0.55
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(0.05, 0.03, 0.08, 0.55) }
            GradientStop { position: 1; color: Qt.rgba(0.05, 0.03, 0.08, 0.15) }
        }
    }

    // cava strip
    Row {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 38
        spacing: 2
        opacity: 0.45
        readonly property var vals: Media.playing && Ui.panel === "control" ? Cava.sample(32) : []
        Repeater {
            model: 32
            Rectangle {
                required property int index
                width: (root.width - 31 * 2) / 32
                height: Math.max(2, 38 * (parent.vals[index] ?? 0))
                anchors.bottom: parent.bottom
                radius: 2
                color: Theme.mix(Theme.pink, Theme.cyan, index / 31)
                Behavior on height { NumberAnimation { duration: 90 } }
            }
        }
    }

    ClippingRectangle {
        id: cover
        x: 14
        y: 14
        width: 82
        height: 82
        radius: 14
        color: Theme.layer2

        Image {
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(192, 192)
            asynchronous: true
        }
        MaterialIcon {
            anchors.centerIn: parent
            visible: Media.art === ""
            icon: "music_note"
            size: 34
            color: Theme.subtext
        }
    }

    Column {
        anchors.left: cover.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: 16
        spacing: 2

        StyledText {
            width: parent.width
            text: Media.title
            font.pixelSize: Theme.fontLg
            font.weight: 700
        }
        StyledText {
            width: parent.width
            text: Media.artist
            font.pixelSize: Theme.fontSm
            color: Theme.subtext
        }

        Row {
            spacing: 4
            topPadding: 6
            IconButton { icon: "skip_previous"; size: 34; iconSize: 22; onClicked: Media.previous() }
            IconButton {
                icon: Media.playing ? "pause" : "play_arrow"
                size: 38
                iconSize: 24
                active: true
                onClicked: Media.toggle()
            }
            IconButton { icon: "skip_next"; size: 34; iconSize: 22; onClicked: Media.next() }
            IconButton {
                visible: Media.players.length > 1
                icon: "swap_horiz"
                size: 34
                iconSize: 18
                onClicked: Media.cycle()
            }
        }
    }

    // scrubber
    Item {
        x: 14
        y: cover.y + cover.height + 12
        width: parent.width - 28
        height: 14
        visible: Media.length > 0

        StyledText {
            id: posText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: Media.fmt(Media.position)
            font.pixelSize: Theme.fontXs
            color: Theme.subtext
        }
        StyledText {
            id: lenText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Media.fmt(Media.length)
            font.pixelSize: Theme.fontXs
            color: Theme.subtext
        }
        Rectangle {
            id: track
            anchors.left: posText.right
            anchors.right: lenText.left
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Theme.layer2
            Rectangle {
                width: parent.width * Math.min(1, Media.position / Math.max(1, Media.length))
                height: parent.height
                radius: 2
                gradient: AccentGradient {}
                Behavior on width { NumberAnimation { duration: 900 } }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: e => Media.seek(Math.max(0, Math.min(1, (e.x - 6) / track.width)))
            }
        }
    }
}
