import QtQuick
import qs.config

// One line in a SettingCard: icon, title, description, control on the right.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool enabled: true
    default property alias control: slot.data
    property real controlWidth: slot.childrenRect.width

    width: parent ? parent.width : 400
    implicitHeight: Math.max(58, texts.implicitHeight + 22)
    opacity: enabled ? 1 : 0.45

    // hairline between rows
    Rectangle {
        visible: root.Positioner.index > 0
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: Theme.rim
    }

    Rectangle {
        id: bubble
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        radius: 11
        color: Theme.layer2

        MaterialIcon {
            anchors.centerIn: parent
            icon: root.icon
            size: 18
            fill: 1
            color: Theme.text
        }
    }

    Column {
        id: texts
        anchors.left: bubble.visible ? bubble.right : parent.left
        anchors.leftMargin: bubble.visible ? 12 : 16
        anchors.right: slot.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        StyledText {
            width: parent.width
            text: root.title
            font.pixelSize: Theme.fontMd
            font.weight: 600
            elide: Text.ElideRight
        }
        StyledText {
            width: parent.width
            visible: text !== ""
            text: root.subtitle
            font.pixelSize: Theme.fontXs + 1
            color: Theme.dim
            wrapMode: Text.Wrap
            elide: Text.ElideNone
        }
    }

    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
        enabled: root.enabled
    }
}
