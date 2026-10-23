import QtQuick
import qs.config

// A rounded group of settings rows with an optional title above it.
Column {
    id: root

    property string title: ""
    property string note: ""
    default property alias rows: list.data

    spacing: 8

    StyledText {
        visible: root.title !== ""
        leftPadding: 6
        text: root.title
        font.pixelSize: Theme.fontSm
        font.weight: 700
        font.letterSpacing: 0.6
        color: Theme.subtext
    }

    Rectangle {
        width: parent.width
        height: list.implicitHeight
        radius: 18
        color: Theme.layer1
        border.width: 1
        border.color: Theme.rim

        Column {
            id: list
            width: parent.width
        }
    }

    StyledText {
        visible: root.note !== ""
        width: parent.width
        leftPadding: 6
        rightPadding: 6
        text: root.note
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontXs
        color: Theme.dim
    }
}
