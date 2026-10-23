import QtQuick
import qs.config
import qs.services
import qs.widgets

// niri workspaces on this output as dots; the active one stretches into an
// accent pill. Scroll to move between workspaces.
Rectangle {
    id: root

    required property string screenName
    readonly property var list: Niri.workspacesOn(screenName)

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28
    radius: 14
    color: Theme.layer1
    visible: list.length > 0

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: root.list
            Rectangle {
                id: dot
                required property var modelData
                readonly property bool active: modelData.is_active
                readonly property bool occupied: Niri.workspaceHasWindows(modelData.id)

                anchors.verticalCenter: parent.verticalCenter
                width: active ? 22 : 8
                height: 8
                radius: 4
                color: modelData.is_urgent ? Theme.bad : occupied ? Theme.alpha(Theme.text, 0.75) : Theme.alpha(Theme.text, 0.22)
                gradient: active ? grad : null
                Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack; easing.overshoot: 2 } }

                AccentGradient { id: grad }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Niri.focusWorkspace(dot.modelData.idx)
                }
            }
        }
    }

    WheelHandler {
        onWheel: e => e.angleDelta.y > 0 ? Niri.focusWorkspaceUp() : Niri.focusWorkspaceDown()
    }
}
