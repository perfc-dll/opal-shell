import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.widgets

// One notification. Used for on-screen toasts and in the dashboard history.
Item {
    id: root

    required property var entry
    property bool compact: false
    readonly property bool hovered: hover.hovered
    readonly property bool critical: entry.urgency === NotificationUrgency.Critical
    readonly property var actions: (entry.notification?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "")

    implicitHeight: card.implicitHeight

    function resolve(src) {
        if (!src)
            return "";
        if (src.startsWith("/"))
            return "file://" + src;
        if (src.includes("://"))
            return src;
        return Quickshell.iconPath(src, true);
    }

    readonly property string imageSource: resolve(entry.image)
    readonly property string iconSource: resolve(entry.appIcon) || (entry.desktopEntry ? Quickshell.iconPath(DesktopEntries.byId(entry.desktopEntry)?.icon ?? "", true) : "")

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: Math.max(64, content.implicitHeight + 24)
        radius: root.compact ? Theme.tileRadius : Theme.toastRadius
        color: root.compact ? (hover.hovered ? Theme.layer2 : Theme.layer1) : "transparent"
        border.width: root.compact ? 1 : 0
        border.color: root.critical ? Theme.alpha(Theme.bad, 0.6) : Theme.rim

        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: e => {
                if (e.button === Qt.MiddleButton)
                    Notifs.dismiss(root.entry);
                else if (!Notifs.defaultAction(root.entry) && !root.compact)
                    Notifs.removeToast(root.entry.key);
            }
        }

        // image / icon
        Item {
            id: pic
            x: 12
            y: 12
            width: 42
            height: 42

            ClippingRectangle {
                anchors.fill: parent
                radius: 12
                color: Theme.layer2
                visible: root.imageSource !== ""
                Image {
                    anchors.fill: parent
                    source: root.imageSource
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(96, 96)
                    asynchronous: true
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: 12
                visible: root.imageSource === ""
                color: Theme.layer2
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 26
                    source: root.iconSource
                    visible: root.iconSource !== ""
                }
                MaterialIcon {
                    anchors.centerIn: parent
                    visible: root.iconSource === ""
                    icon: root.critical ? "warning" : "notifications"
                    size: 22
                    fill: 1
                    color: root.critical ? Theme.bad : Theme.violet
                }
            }
            // small app badge over a big image
            IconImage {
                visible: root.imageSource !== "" && root.iconSource !== ""
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -4
                implicitSize: 18
                source: root.iconSource
            }
        }

        Column {
            id: content
            anchors.left: pic.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            y: 11
            spacing: 2

            Item {
                width: parent.width
                height: 16
                StyledText {
                    anchors.left: parent.left
                    anchors.right: when.left
                    anchors.rightMargin: 6
                    text: root.entry.appName || "Notification"
                    font.pixelSize: Theme.fontXs
                    font.weight: 650
                    color: root.critical ? Theme.bad : Theme.dim
                }
                StyledText {
                    id: when
                    anchors.right: parent.right
                    anchors.rightMargin: closeBtn.visible ? 26 : 0
                    text: Notifs.timeAgo(root.entry.time)
                    font.pixelSize: Theme.fontXs
                    color: Theme.dim
                    // re-evaluated every 30s
                    property int tick: ticker.tick
                }
            }
            StyledText {
                width: parent.width
                text: root.entry.summary
                font.pixelSize: Theme.fontMd
                font.weight: 650
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }
            StyledText {
                width: parent.width
                visible: text !== ""
                text: root.entry.body
                textFormat: Text.StyledText
                font.pixelSize: Theme.fontSm
                color: Theme.subtext
                wrapMode: Text.Wrap
                maximumLineCount: root.compact ? 4 : 3
                linkColor: Theme.cyan
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
            Flow {
                width: parent.width
                visible: root.actions.length > 0
                spacing: 6
                topPadding: 6
                Repeater {
                    model: root.actions
                    Rectangle {
                        required property var modelData
                        width: actText.implicitWidth + 22
                        height: 28
                        radius: 14
                        color: actArea.containsMouse ? Theme.layer3 : Theme.layer2
                        border.width: 1
                        border.color: Theme.rim
                        StyledText {
                            id: actText
                            anchors.centerIn: parent
                            text: modelData.text
                            font.pixelSize: Theme.fontSm
                            font.weight: 600
                        }
                        MouseArea {
                            id: actArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.invoke(root.entry, modelData)
                        }
                    }
                }
            }
        }

        IconButton {
            id: closeBtn
            visible: hover.hovered
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            size: 24
            iconSize: 15
            icon: "close"
            onClicked: Notifs.dismiss(root.entry)
        }
    }

    QtObject {
        id: ticker
        property int tick: 0
    }
    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: ticker.tick++
    }
}
