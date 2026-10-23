import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Full-screen frosted power menu. Lock and suspend act at once; log out,
// reboot and power off arm a 3 s countdown (click again = now, Esc = cancel).
// Keys: arrows + Enter, or L S E R P.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Ui.panelScreen) ?? Quickshell.screens[0]
    readonly property bool shown: Ui.panel === "session"
    property real progress: shown ? 1 : 0
    property int selected: 0
    property string armed: ""
    property real armProgress: 0

    visible: shown || progress > 0.001
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.namespace: "opal-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var actions: [
        { id: "lock", icon: "lock", label: "Lock", key: Qt.Key_L, confirm: false },
        { id: "suspend", icon: "bedtime", label: "Suspend", key: Qt.Key_S, confirm: false },
        { id: "logout", icon: "logout", label: "Log out", key: Qt.Key_E, confirm: true },
        { id: "reboot", icon: "restart_alt", label: "Reboot", key: Qt.Key_R, confirm: true },
        { id: "poweroff", icon: "power_settings_new", label: "Power off", key: Qt.Key_P, confirm: true }
    ]


    onShownChanged: {
        armed = "";
        if (shown) {
            selected = 0;
            keys.forceActiveFocus();
        }
    }

    Behavior on progress { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    function run(id) {
        Ui.close();
        armed = "";
        // let the menu fade before the action grabs the screen
        Qt.callLater(() => actionTimer.start());
        actionTimer.action = id;
    }

    function activate(i) {
        const a = actions[i];
        selected = i;
        if (!a.confirm || armed === a.id) {
            run(a.id);
            return;
        }
        armed = a.id;
        armAnim.restart();
    }

    Timer {
        id: actionTimer
        property string action: ""
        interval: 260
        onTriggered: {
            switch (action) {
            case "lock": Power.lock(); break;
            case "suspend": Power.suspend(); break;
            case "logout": Power.logout(); break;
            case "reboot": Power.reboot(); break;
            case "poweroff": Power.poweroff(); break;
            }
        }
    }

    NumberAnimation {
        id: armAnim
        target: root
        property: "armProgress"
        from: 0
        to: 1
        duration: 3000
        onFinished: if (root.armed !== "") root.run(root.armed)
    }

    // tint over niri's blur of the whole screen
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.035, 0.02, 0.06, 0.5)
        opacity: root.progress
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.armed !== "" ? root.armed = "" : Ui.close()
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                if (root.armed !== "")
                    root.armed = "";
                else
                    Ui.close();
            } else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) {
                root.selected = (root.selected + root.actions.length - 1) % root.actions.length;
            } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) {
                root.selected = (root.selected + 1) % root.actions.length;
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                root.activate(root.selected);
            } else {
                const i = root.actions.findIndex(a => a.key === e.key);
                if (i >= 0)
                    root.activate(i);
            }
            e.accepted = true;
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 34
        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.armed !== "" ? root.actions.find(a => a.id === root.armed).label + " in " + Math.ceil(3 - root.armProgress * 3) + "…" : "See you soon, " + Account.firstName
                font.pixelSize: 30
                font.weight: 300
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.armed !== "" ? "Click again to do it now · Esc to cancel" : "up " + SysInfo.uptimeText
                color: Theme.subtext
                font.pixelSize: Theme.fontMd
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 22

            Repeater {
                model: root.actions

                Column {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool isSel: root.selected === index
                    readonly property bool isArmed: root.armed === modelData.id
                    spacing: 12

                    scale: root.shown ? 1 : 0.6
                    Behavior on scale { NumberAnimation { duration: Theme.slow + btn.index * 40; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }

                    Item {
                        width: 104
                        height: 104
                        anchors.horizontalCenter: parent.horizontalCenter

                        Glass {
                            anchors.fill: parent
                            radius: 34
                            tint: btn.isArmed ? Theme.alpha(Theme.bad, 0.28) : btn.isSel || hover.hovered ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
                            border.color: btn.isSel ? Theme.alpha(Theme.violet, 0.8) : Theme.rim
                            scale: tap.pressed ? 0.93 : hover.hovered ? 1.05 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
                            Behavior on tint { ColorAnimation { duration: Theme.fast } }
                        }

                        // countdown ring for armed actions
                        Rectangle {
                            visible: btn.isArmed
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 12
                            width: 56 * (1 - root.armProgress)
                            height: 3
                            radius: 1.5
                            color: Theme.bad
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: btn.modelData.icon
                            size: 40
                            fill: btn.isSel || hover.hovered ? 1 : 0
                            color: btn.isArmed ? Theme.bad : btn.isSel ? Theme.text : Theme.subtext
                        }

                        HoverHandler {
                            id: hover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: if (hovered) root.selected = btn.index
                        }
                        MouseArea {
                            id: tap
                            anchors.fill: parent
                            onClicked: root.activate(btn.index)
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: btn.modelData.label
                        font.pixelSize: Theme.fontMd
                        font.weight: btn.isSel ? 650 : 450
                        color: btn.isSel ? Theme.text : Theme.subtext
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String.fromCharCode(btn.modelData.key)
                        font.family: Theme.monoFont
                        font.pixelSize: Theme.fontXs
                        color: Theme.dim
                    }
                }
            }
        }
    }
}
