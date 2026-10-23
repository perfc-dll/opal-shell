import QtQuick
import qs.config
import qs.services
import qs.widgets

Column {
    id: root
    spacing: 10

    Row {
        width: parent.width
        readonly property real cell: width / 4

        RingGauge {
            width: parent.cell
            value: SysInfo.cpu
            icon: "memory"
            label: Math.round(SysInfo.cpu * 100) + "%"
            caption: "CPU"
        }
        RingGauge {
            width: parent.cell
            value: SysInfo.mem
            icon: "memory_alt"
            label: SysInfo.fmtBytes(SysInfo.memUsed)
            caption: "Memory"
        }
        RingGauge {
            width: parent.cell
            value: Math.min(1, SysInfo.temp / 100)
            icon: "thermostat"
            label: Math.round(SysInfo.temp) + "°"
            caption: "CPU temp"
        }
        RingGauge {
            width: parent.cell
            value: SysInfo.disk
            icon: "hard_drive"
            label: Math.round(SysInfo.disk * 100) + "%"
            caption: "Disk /"
        }
    }

    // battery strip
    Rectangle {
        visible: Power.hasBattery
        width: parent.width
        height: 40
        radius: 14
        color: Theme.layer1
        border.width: 1
        border.color: Theme.rim

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 3
            width: Math.max(radius * 2, (parent.width - 6) * Power.percent)
            radius: 11
            opacity: 0.35
            color: Power.charging ? Theme.good : Power.percent < 0.15 ? Theme.bad : "transparent"
            gradient: Power.charging || Power.percent < 0.15 ? null : batGrad
            AccentGradient { id: batGrad }
            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: Power.batteryIcon
                rotation: 90
                size: 18
                fill: 1
                color: Power.charging ? Theme.good : Theme.text
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Power.percent * 100) + "%"
                font.weight: 700
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Power.timeText
                color: Theme.subtext
                font.pixelSize: Theme.fontSm
            }
        }
        StyledText {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: Power.watts > 0.1
            text: Power.watts.toFixed(1) + " W"
            color: Theme.subtext
            font.pixelSize: Theme.fontSm
        }
    }
}
