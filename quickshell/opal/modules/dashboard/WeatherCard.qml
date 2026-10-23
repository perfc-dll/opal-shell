import QtQuick
import qs.config
import qs.services
import qs.widgets

Rectangle {
    id: root

    implicitHeight: Weather.ready ? 124 : 56
    radius: Theme.tileRadius + 2
    color: Theme.layer1
    border.width: 1
    border.color: Theme.rim
    clip: true

    // warm/cool wash depending on day/night
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        opacity: 0.18
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Weather.isDay ? Theme.warn : Theme.violet }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    StyledText {
        visible: !Weather.ready
        anchors.centerIn: parent
        text: "Fetching weather…"
        color: Theme.dim
    }

    Item {
        visible: Weather.ready
        anchors.fill: parent
        anchors.margins: 14

        MaterialIcon {
            id: big
            icon: Weather.icon
            size: 44
            fill: 1
            color: Weather.isDay ? Theme.warn : Theme.cyan
        }
        Column {
            anchors.left: big.right
            anchors.leftMargin: 12
            anchors.top: parent.top
            anchors.topMargin: -2
            StyledText {
                text: Weather.temp
                font.pixelSize: 30
                font.weight: 300
            }
            StyledText {
                text: Weather.description
                font.pixelSize: Theme.fontSm
                color: Theme.subtext
            }
        }
        Column {
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 3
            StyledText {
                anchors.right: parent.right
                text: Weather.location
                font.pixelSize: Theme.fontSm
                font.weight: 650
            }
            StyledText {
                anchors.right: parent.right
                text: "Feels " + Weather.feels + "  ·  " + Weather.humidity + "%"
                font.pixelSize: Theme.fontXs
                color: Theme.subtext
            }
            StyledText {
                anchors.right: parent.right
                text: "Wind " + Weather.windKmh + " km/h"
                font.pixelSize: Theme.fontXs
                color: Theme.subtext
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 6
            Repeater {
                model: Weather.forecast
                Rectangle {
                    required property var modelData
                    width: (parent.width - 12) / 3
                    height: 30
                    radius: 10
                    color: Theme.layer1
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.day
                            font.pixelSize: Theme.fontXs
                            font.weight: 650
                        }
                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: Weather.iconFor(modelData.code, true)
                            size: 15
                            fill: 1
                            color: Theme.subtext
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.fmt(modelData.maxC) + " " + Weather.fmt(modelData.minC)
                            font.pixelSize: Theme.fontXs
                            color: Theme.subtext
                        }
                    }
                }
            }
        }
    }
}
