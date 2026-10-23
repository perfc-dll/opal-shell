import QtQuick
import qs.config

// Row of mutually exclusive choices. options: [{ value, label }] or plain strings.
Rectangle {
    id: root

    property var options: []
    property var value
    signal picked(var value)

    implicitWidth: row.implicitWidth + 6
    implicitHeight: 32
    radius: 11
    color: Theme.layer2
    border.width: 1
    border.color: Theme.rim

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.options
            Rectangle {
                id: seg
                required property var modelData
                readonly property var val: typeof modelData === "object" ? modelData.value : modelData
                readonly property string label: typeof modelData === "object" ? modelData.label : String(modelData)
                readonly property bool on: root.value === val

                width: Math.max(44, txt.implicitWidth + 22)
                height: 26
                radius: 8
                color: on ? "transparent" : area.containsMouse ? Theme.layer2 : "transparent"
                gradient: on ? grad : null
                AccentGradient { id: grad; strength: 0.9 }

                StyledText {
                    id: txt
                    anchors.centerIn: parent
                    text: seg.label
                    font.pixelSize: Theme.fontSm
                    font.weight: seg.on ? 700 : 500
                    color: seg.on ? Theme.accentInk : Theme.subtext
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(seg.val)
                }
            }
        }
    }
}
