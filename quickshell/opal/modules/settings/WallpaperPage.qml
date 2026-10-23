import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    title: "Wallpaper"
    subtitle: "Opal draws the wallpaper itself, so it can cross-fade and sit behind the niri overview."

    // current wallpaper preview
    ClippingRectangle {
        width: parent.width
        height: Math.round(width * 0.36)
        radius: 20
        color: Theme.layer1
        border.width: 1
        border.color: Theme.rim

        Image {
            anchors.fill: parent
            source: Wallpapers.current ? "file://" + Wallpapers.current : ""
            sourceSize: Qt.size(1280, 720)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 64
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.6) }
            }
        }
        StyledText {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 16
            width: parent.width - buttons.width - 48
            text: Wallpapers.current.split("/").pop()
            font.weight: 600
        }
        Row {
            id: buttons
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            spacing: 8
            PillButton {
                text: "Shuffle"
                icon: "shuffle"
                onClicked: Wallpapers.random()
            }
            PillButton {
                text: "Choose…"
                icon: "wallpaper"
                accent: true
                onClicked: {
                    Ui.settingsOpen = false;
                    Ui.open("wallpaper");
                }
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "WALLPAPER"

        SettingRow {
            icon: "folder_open"
            title: "Folder"
            subtitle: Wallpapers.model.count + " images"
            TextBox {
                width: 320
                text: Settings.wallpaperDir
                mono: true
                onCommitted: t => Settings.wallpaperDir = t.trim().replace(/\/$/, "")
            }
        }
        SettingRow {
            icon: "aspect_ratio"
            title: "Fit"
            subtitle: "Fill crops to cover the screen; Fit shows the whole image"
            Segmented {
                options: [{ value: "crop", label: "Fill" }, { value: "fit", label: "Fit" }]
                value: Settings.wallpaperFill
                onPicked: v => Settings.wallpaperFill = v
            }
        }
        SettingRow {
            icon: "animation"
            title: "Transition"
            subtitle: "Cross-fade length when the wallpaper changes"
            SettingSlider {
                from: 0
                to: 3000
                step: 100
                value: Settings.wallpaperTransition
                format: v => v === 0 ? "Instant" : (v / 1000).toFixed(1) + " s"
                onMoved: v => Settings.wallpaperTransition = v
            }
        }
        SettingRow {
            icon: "slideshow"
            title: "Slideshow"
            subtitle: "Switch to a random wallpaper from the folder"
            Segmented {
                options: [{ value: 0, label: "Off" }, { value: 10, label: "10m" }, { value: 30, label: "30m" }, { value: 60, label: "1h" }, { value: 180, label: "3h" }]
                value: Settings.slideshowMinutes
                onPicked: v => Settings.slideshowMinutes = v
            }
        }
    }
}
