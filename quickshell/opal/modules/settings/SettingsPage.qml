import QtQuick
import qs.config
import qs.widgets

// Scrollable page body: title, subtitle, then the page's cards.
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    default property alias content: column.data

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 4000
        maximumFlickVelocity: 3500

        Column {
            id: column
            x: 32
            y: 28
            width: flick.width - 64
            spacing: 22

            Column {
                width: parent.width
                spacing: 4
                StyledText {
                    text: root.title
                    font.pixelSize: 26
                    font.weight: 700
                }
                StyledText {
                    width: parent.width
                    visible: text !== ""
                    text: root.subtitle
                    color: Theme.subtext
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                }
            }
        }
    }

    // slim scroll indicator
    Rectangle {
        visible: flick.contentHeight > flick.height
        anchors.right: parent.right
        anchors.rightMargin: 6
        y: 8 + (flick.height - 16 - height) * (flick.contentY / Math.max(1, flick.contentHeight - flick.height))
        width: 4
        height: Math.max(40, (flick.height - 16) * flick.height / flick.contentHeight)
        radius: 2
        color: Theme.alpha(Theme.text, flick.moving ? 0.35 : 0.14)
        Behavior on color { ColorAnimation { duration: Theme.normal } }
    }
}
