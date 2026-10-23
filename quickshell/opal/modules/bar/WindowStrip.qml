import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// A taskbar shaped like niri's scrolling strip: one icon per window in
// column order on the active workspace. Click focuses, middle-click closes,
// scrolling walks the columns. The focused window's title trails the icons.
Row {
    id: root

    required property string screenName
    property real maxWidth: 600

    readonly property var workspace: Niri.activeWorkspaceOn(screenName)
    readonly property var windows: workspace ? Niri.windowsOnWorkspace(workspace.id) : []
    readonly property var focused: windows.find(w => w.id === Niri.focusedWindowId) ?? windows.find(w => w.id === workspace?.active_window_id) ?? null
    property var hoveredWindow: null
    readonly property int maxIcons: Math.max(1, Math.floor((maxWidth - 140) / 32))

    spacing: 2
    visible: windows.length > 0

    Rectangle {
        id: iconsBox
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: icons.implicitWidth + 8
        implicitHeight: 32
        radius: 12
        color: Theme.layer1

        Row {
            id: icons
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: root.windows.slice(0, root.maxIcons)

                Item {
                    id: cell
                    required property var modelData
                    readonly property bool isFocused: root.focused?.id === modelData.id

                    width: 28
                    height: 28

                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        color: cell.isFocused ? Theme.layer3 : hover.hovered ? Theme.layer2 : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: cell.isFocused ? 20 : 18
                        source: Apps.iconForAppId(cell.modelData.app_id)
                        opacity: cell.isFocused || hover.hovered ? 1 : 0.62
                        Behavior on implicitSize { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
                        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                    }

                    // focus pip
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 1
                        width: cell.isFocused ? 12 : cell.modelData.is_urgent ? 6 : 0
                        height: 2
                        radius: 1
                        color: cell.modelData.is_urgent ? Theme.bad : "transparent"
                        gradient: cell.isFocused ? pip : null
                        Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                        AccentGradient { id: pip }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered)
                                root.hoveredWindow = cell.modelData;
                            else if (root.hoveredWindow?.id === cell.modelData.id)
                                root.hoveredWindow = null;
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: e => e.button === Qt.MiddleButton ? Niri.closeWindow(cell.modelData.id) : Niri.focusWindow(cell.modelData.id)
                    }
                }
            }

            StyledText {
                visible: root.windows.length > root.maxIcons
                anchors.verticalCenter: parent.verticalCenter
                text: "+" + (root.windows.length - root.maxIcons)
                color: Theme.subtext
                font.pixelSize: Theme.fontSm
                rightPadding: 4
            }
        }

        WheelHandler {
            onWheel: e => e.angleDelta.y > 0 ? Niri.focusColumnLeft() : Niri.focusColumnRight()
        }
    }

    StyledText {
        id: title
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: 8
        width: Math.min(implicitWidth, Math.max(0, root.maxWidth - iconsBox.width - 8), 340)
        readonly property var w: root.hoveredWindow ?? root.focused
        text: w ? (w.title || Apps.nameForAppId(w.app_id)) : ""
        color: root.hoveredWindow ? Theme.text : Theme.subtext
        font.italic: !root.hoveredWindow
        font.pixelSize: Theme.fontMd
    }
}
