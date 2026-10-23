import QtQuick
import qs.config

// Single-line text field. Commits on Enter or when it loses focus.
Rectangle {
    id: root

    property string text: ""
    property string placeholder: ""
    property bool mono: false
    signal committed(string text)

    implicitWidth: 260
    implicitHeight: 34
    radius: 11
    color: Theme.layer2
    border.width: 1
    border.color: input.activeFocus ? Theme.alpha(Theme.violet, 0.7) : Theme.rim
    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        text: root.text
        color: Theme.text
        font.family: root.mono ? Theme.monoFont : Theme.font
        font.pixelSize: Theme.fontMd
        selectionColor: Theme.alpha(Theme.violet, 0.6)
        selectByMouse: true
        clip: true
        onAccepted: {
            root.committed(text);
            focus = false;
        }
        onActiveFocusChanged: if (!activeFocus && text !== root.text) root.committed(text)
        Keys.onEscapePressed: {
            text = root.text;
            focus = false;
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === "" && !input.activeFocus
            text: root.placeholder
            color: Theme.dim
            font.pixelSize: Theme.fontMd
        }
    }
}
