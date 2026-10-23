import QtQuick
import qs.config
import qs.widgets

Item {
    id: root

    property string title: ""
    property bool toggleOn: false
    property bool busy: false
    signal back
    signal toggled

    implicitHeight: 40

    IconButton {
        id: backBtn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        icon: "arrow_back"
        onClicked: root.back()
    }
    StyledText {
        anchors.left: backBtn.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        font.pixelSize: Theme.fontXl - 2
        font.weight: 700
    }
    MaterialIcon {
        visible: root.busy
        anchors.right: sw.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        icon: "progress_activity"
        size: 18
        color: Theme.subtext
        RotationAnimation on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: root.busy }
    }

    // pill switch
    Rectangle {
        id: sw
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        height: 26
        radius: 13
        color: root.toggleOn ? "transparent" : Theme.layer2
        gradient: root.toggleOn ? grad : null
        border.width: 1
        border.color: Theme.rim
        AccentGradient { id: grad }

        Rectangle {
            width: 20
            height: 20
            radius: 10
            y: 3
            x: root.toggleOn ? parent.width - width - 3 : 3
            color: "white"
            Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }
}
