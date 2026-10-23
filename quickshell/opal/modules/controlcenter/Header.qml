import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

Item {
    id: root

    implicitHeight: 52
    readonly property string face: Quickshell.env("HOME") + "/.face"
    property bool hasFace: false

    Process {
        running: true
        command: ["test", "-s", root.face]
        onExited: code => root.hasFace = code === 0
    }

    // avatar: accent ring + photo (~/.face) or initial
    Rectangle {
        id: avatar
        width: 48
        height: 48
        radius: 24
        anchors.verticalCenter: parent.verticalCenter
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.pink }
            GradientStop { position: 0.5; color: Theme.violet }
            GradientStop { position: 1; color: Theme.cyan }
        }
        RotationAnimation on rotation {
            from: 0; to: 360; duration: 12000; loops: Animation.Infinite; running: Ui.panel === "control"
        }

        ClippingRectangle {
            anchors.centerIn: parent
            width: 42
            height: 42
            radius: 21
            color: Theme.glassStrong
            rotation: -avatar.rotation

            Image {
                id: faceImg
                anchors.fill: parent
                source: root.hasFace ? "file://" + root.face : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(96, 96)
                visible: status === Image.Ready
            }
            StyledText {
                anchors.centerIn: parent
                visible: faceImg.status !== Image.Ready
                text: Account.fullName.charAt(0).toUpperCase()
                font.pixelSize: 20
                font.weight: 750
            }
        }
    }

    Column {
        anchors.left: avatar.right
        anchors.leftMargin: 12
        anchors.right: buttons.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        StyledText {
            width: parent.width
            text: Account.fullName
            font.pixelSize: Theme.fontLg + 1
            font.weight: 700
        }
        StyledText {
            width: parent.width
            text: "up " + SysInfo.uptimeText + (Account.distro ? "  ·  " + Account.distro : "")
            font.pixelSize: Theme.fontSm
            color: Theme.subtext
        }
    }

    Row {
        id: buttons
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        IconButton {
            icon: "wallpaper"
            onClicked: Ui.open("wallpaper")
        }
        IconButton {
            icon: "lock"
            onClicked: {
                Ui.close();
                Power.lock();
            }
        }
        IconButton {
            icon: "power_settings_new"
            danger: true
            onClicked: Ui.open("session")
        }
    }
}
