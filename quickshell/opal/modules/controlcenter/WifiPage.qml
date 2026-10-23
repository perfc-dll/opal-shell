import QtQuick
import Quickshell.Networking
import qs.config
import qs.services
import qs.widgets

Item {
    id: root

    property bool active: false
    property bool showBack: true
    property string askingFor: ""
    signal back

    onActiveChanged: Net.scan(active)
    Component.onCompleted: if (active) Net.scan(true)
    Component.onDestruction: if (active) Net.scan(false)

    PageHeader {
        id: header
        width: parent.width
        showBack: root.showBack
        title: root.showBack ? "Wi-Fi" : "Networks"
        toggleOn: Net.wifiEnabled
        busy: Net.connecting !== ""
        onBack: root.back()
        onToggled: Net.setWifi(!Net.wifiEnabled)
    }

    StyledText {
        id: error
        anchors.top: header.bottom
        anchors.topMargin: 6
        width: parent.width
        visible: Net.lastError !== ""
        text: Net.lastError
        color: Theme.bad
        font.pixelSize: Theme.fontSm
        wrapMode: Text.Wrap
        elide: Text.ElideNone
    }

    ListView {
        id: list
        anchors.top: error.visible ? error.bottom : header.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        spacing: 6
        model: Net.wifiEnabled ? Net.networks : []
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: row
            required property WifiNetwork modelData
            readonly property bool asking: root.askingFor === modelData.name
            readonly property bool secured: modelData.security !== WifiSecurityType.Open

            width: list.width
            height: asking ? 96 : 52
            radius: Theme.tileRadius
            color: modelData.connected ? Theme.alpha(Theme.violet, 0.22) : hover.hovered ? Theme.layer2 : Theme.layer1
            border.width: 1
            border.color: modelData.connected ? Theme.alpha(Theme.violet, 0.5) : Theme.rim
            clip: true
            Behavior on height { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

            HoverHandler { id: hover }

            MaterialIcon {
                id: sig
                x: 14
                y: 16
                icon: Net.strengthIcon(row.modelData.signalStrength)
                size: 20
                fill: 1
                color: row.modelData.connected ? Theme.pink : Theme.text
            }
            Column {
                anchors.left: sig.right
                anchors.leftMargin: 12
                anchors.right: actions.left
                anchors.rightMargin: 8
                y: 9
                StyledText {
                    width: parent.width
                    text: row.modelData.name
                    font.weight: 600
                }
                StyledText {
                    width: parent.width
                    text: (row.modelData.connected ? "Connected" : Net.connecting === row.modelData.name ? "Connecting…" : row.modelData.known ? "Saved" : row.secured ? "Secured" : "Open") + "  ·  " + Math.round(Net.norm(row.modelData.signalStrength) * 100) + "%"
                    font.pixelSize: Theme.fontXs
                    color: Theme.subtext
                }
            }
            Row {
                id: actions
                anchors.right: parent.right
                anchors.rightMargin: 8
                y: 9
                spacing: 2
                MaterialIcon {
                    visible: row.secured
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "lock"
                    size: 14
                    color: Theme.dim
                    rightPadding: 4
                }
                IconButton {
                    visible: row.modelData.known && !row.modelData.connected
                    icon: "delete"
                    size: 32
                    iconSize: 16
                    danger: true
                    onClicked: Net.forget(row.modelData)
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 48
                height: 52
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const n = row.modelData;
                    if (n.connected)
                        Net.disconnectFrom(n);
                    else if (n.known || !row.secured)
                        Net.connectTo(n, "");
                    else {
                        root.askingFor = row.asking ? "" : n.name;
                        pass.text = "";
                        pass.forceActiveFocus();
                    }
                }
            }

            // inline password prompt
            Rectangle {
                visible: row.asking
                x: 12
                y: 52
                width: parent.width - 24
                height: 34
                radius: 12
                color: Theme.layer2
                border.width: 1
                border.color: pass.activeFocus ? Theme.alpha(Theme.violet, 0.7) : Theme.rim

                TextInput {
                    id: pass
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 40
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontMd
                    selectionColor: Theme.violet
                    clip: true
                    onAccepted: {
                        Net.connectTo(row.modelData, text);
                        root.askingFor = "";
                    }
                    Keys.onEscapePressed: root.askingFor = ""

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pass.text === ""
                        text: "Password for " + row.modelData.name
                        color: Theme.dim
                    }
                }
                IconButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    size: 30
                    iconSize: 18
                    icon: "arrow_forward"
                    onClicked: pass.accepted()
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: Net.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
            color: Theme.dim
        }
    }
}
