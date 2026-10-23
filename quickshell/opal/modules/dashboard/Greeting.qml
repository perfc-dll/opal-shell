import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

Item {
    id: root

    implicitHeight: 112


    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property int hour: clock.hours
    readonly property string greeting: hour < 5 ? "Up late" : hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"

    Row {
        id: timeRow
        spacing: 4
        StyledText {
            id: hm
            text: Qt.formatDateTime(clock.date, Settings.use24h ? "HH:mm" : "h:mm")
            font.pixelSize: 58
            font.weight: 250
            font.letterSpacing: -2
        }
        StyledText {
            anchors.baseline: hm.baseline
            text: Qt.formatDateTime(clock.date, "ss")
            font.pixelSize: 20
            font.weight: 400
            color: Theme.violet
        }
    }

    StyledText {
        anchors.top: timeRow.bottom
        anchors.topMargin: -4
        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
        font.pixelSize: Theme.fontLg
        font.weight: 600
    }

    // greeting painted with the accent sweep
    Item {
        anchors.bottom: parent.bottom
        width: greet.implicitWidth
        height: greet.implicitHeight

        StyledText {
            id: greet
            text: root.greeting + ", " + Account.firstName
            font.pixelSize: Theme.fontMd + 1
            font.weight: 600
            visible: false
        }
        Rectangle {
            id: sweep
            anchors.fill: greet
            gradient: AccentGradient {}
            visible: false
        }
        OpacityMask {
            anchors.fill: greet
            source: sweep
            maskSource: greet
        }
    }
}
