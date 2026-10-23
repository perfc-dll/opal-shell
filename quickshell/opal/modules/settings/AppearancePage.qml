import QtQuick
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    title: "Appearance"
    subtitle: "Accent colours, glass, text size and motion. Everything applies as you change it."

    SettingCard {
        width: parent.width
        title: "ACCENT"
        note: Settings.adaptiveColors ? "Adaptive: the three accents are picked from the current wallpaper and follow it when it changes." : ""

        Item {
            width: parent.width
            height: grid.implicitHeight + 28

            Grid {
                id: grid
                x: 14
                y: 14
                columns: 3
                columnSpacing: 10
                rowSpacing: 10
                readonly property real cellW: (parent.width - 28 - 20) / 3

                Repeater {
                    model: [...Theme.presetOrder, "adaptive"]

                    Rectangle {
                        id: card
                        required property string modelData
                        readonly property bool isAdaptive: modelData === "adaptive"
                        readonly property var colors: isAdaptive ? (Theme.adaptivePalette.length >= 3 ? Theme.adaptivePalette : ["#888", "#aaa", "#ccc"]) : Theme.presets[modelData].colors
                        readonly property bool selected: isAdaptive ? Settings.adaptiveColors : !Settings.adaptiveColors && Settings.accentPreset === modelData

                        width: grid.cellW
                        height: 64
                        radius: 16
                        color: hover.hovered ? Theme.layer2 : Theme.layer1
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.violet : Theme.rim

                        Rectangle {
                            id: swatch
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            height: 40
                            radius: 20
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: card.colors[0] }
                                GradientStop { position: 0.55; color: card.colors[1] }
                                GradientStop { position: 1; color: card.colors[2] }
                            }
                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: card.isAdaptive
                                icon: "auto_awesome"
                                size: 18
                                fill: 1
                                color: "white"
                            }
                        }
                        Column {
                            anchors.left: swatch.right
                            anchors.leftMargin: 12
                            anchors.right: check.left
                            anchors.verticalCenter: parent.verticalCenter
                            StyledText {
                                text: card.isAdaptive ? "Adaptive" : Theme.presets[card.modelData].name
                                font.weight: 650
                            }
                            StyledText {
                                text: card.isAdaptive ? "From your wallpaper" : card.modelData === "opal" ? "Signature" : "Preset"
                                font.pixelSize: Theme.fontXs + 1
                                color: Theme.dim
                            }
                        }
                        MaterialIcon {
                            id: check
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            visible: card.selected
                            icon: "check_circle"
                            size: 20
                            fill: 1
                            color: Theme.violet
                        }

                        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (card.isAdaptive) {
                                    Settings.adaptiveColors = true;
                                } else {
                                    Settings.adaptiveColors = false;
                                    Settings.accentPreset = card.modelData;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "GLASS & TEXT"

        SettingRow {
            icon: "blur_on"
            title: "Glass tint"
            subtitle: "Lower is clearer, higher is darker and easier to read"
            SettingSlider {
                from: 0.25
                to: 0.85
                step: 0.01
                value: Settings.glassOpacity
                format: v => Math.round(v * 100) + "%"
                onMoved: v => Settings.glassOpacity = v
            }
        }
        SettingRow {
            icon: "text_fields"
            title: "Text size"
            subtitle: "Scales the shell's text (the bar keeps its height)"
            SettingSlider {
                from: 0.85
                to: 1.25
                step: 0.05
                value: Settings.fontScale
                format: v => Math.round(v * 100) + "%"
                onMoved: v => Settings.fontScale = v
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "MOTION"

        SettingRow {
            icon: "animation"
            title: "Animation speed"
            enabled: !Settings.reduceMotion
            Segmented {
                options: [{ value: 0.7, label: "Relaxed" }, { value: 1.0, label: "Normal" }, { value: 1.5, label: "Snappy" }]
                value: Settings.animationSpeed
                onPicked: v => Settings.animationSpeed = v
            }
        }
        SettingRow {
            icon: "motion_mode"
            title: "Reduce motion"
            subtitle: "Quick fades instead of slides, no spinning cover, orb or springy island"
            OpalSwitch {
                checked: Settings.reduceMotion
                onToggled: Settings.reduceMotion = !Settings.reduceMotion
            }
        }
        SettingRow {
            icon: "graphic_eq"
            title: "Edge visualizer"
            subtitle: "Music-reactive bars along the screen edges, under your windows"
            OpalSwitch {
                checked: Settings.edgeVisualizer
                onToggled: Settings.edgeVisualizer = !Settings.edgeVisualizer
            }
        }
    }
}
