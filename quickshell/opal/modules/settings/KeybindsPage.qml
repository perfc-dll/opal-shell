import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    id: page
    title: "Keybinds"
    subtitle: "The main shortcuts. They live in ~/.config/niri/opal.kdl; Super+Shift+/ shows niri's full list."

    component Keys: Row {
        id: keys
        property string combo
        spacing: 4
        Repeater {
            model: keys.combo.split("+")
            Rectangle {
                required property string modelData
                width: Math.max(28, cap.implicitWidth + 16)
                height: 26
                radius: 7
                color: Theme.layer2
                border.width: 1
                border.color: Theme.rimBright
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 4
                    height: 2
                    radius: 1
                    color: Qt.rgba(0, 0, 0, 0.25)
                }
                StyledText {
                    id: cap
                    anchors.centerIn: parent
                    text: modelData
                    font.family: Theme.monoFont
                    font.pixelSize: Theme.fontSm
                    font.weight: 600
                }
            }
        }
    }

    component Bind: SettingRow {
        id: bind
        property string combo
        Keys { combo: bind.combo }
    }

    SettingCard {
        width: parent.width
        title: "OPAL"
        Bind { icon: "search"; title: "Launcher"; combo: "Super+D" }
        Bind { icon: "content_paste"; title: "Clipboard history"; combo: "Super+V" }
        Bind { icon: "tune"; title: "Control centre"; combo: "Super+A" }
        Bind { icon: "notifications"; title: "Dashboard & notifications"; combo: "Super+N" }
        Bind { icon: "settings"; title: "Settings"; combo: "Super+I" }
        Bind { icon: "wallpaper"; title: "Wallpapers / random"; combo: "Super+W" }
        Bind { icon: "toolbar"; title: "Show or hide the bar"; combo: "Super+Shift+B" }
        Bind { icon: "power_settings_new"; title: "Power menu"; combo: "Super+Shift+E" }
        Bind { icon: "restart_alt"; title: "Restart the shell"; combo: "Super+Ctrl+R" }
    }

    SettingCard {
        width: parent.width
        title: "WINDOWS"
        Bind { icon: "terminal"; title: "Terminal"; combo: "Super+Enter" }
        Bind { icon: "close"; title: "Close window"; combo: "Super+Q" }
        Bind { icon: "view_column"; title: "Focus column left / right"; combo: "Super+←/→" }
        Bind { icon: "swap_horiz"; title: "Move column"; combo: "Super+Shift+←/→" }
        Bind { icon: "fullscreen"; title: "Maximize column / fullscreen"; combo: "Super+F" }
        Bind { icon: "aspect_ratio"; title: "Cycle column width"; combo: "Super+R" }
        Bind { icon: "grid_view"; title: "Overview"; combo: "Super+O" }
    }

    SettingCard {
        width: parent.width
        title: "SYSTEM"
        Bind { icon: "lock"; title: "Lock"; combo: "Super+Esc" }
        Bind { icon: "lock_reset"; title: "Lock with hyprlock (fallback)"; combo: "Super+Ctrl+Esc" }
        Bind { icon: "photo_camera"; title: "Screenshot"; combo: "Print" }
        Bind { icon: "keyboard"; title: "All niri shortcuts"; combo: "Super+Shift+/" }
    }

    Row {
        spacing: 8
        PillButton {
            text: "Edit opal.kdl"
            icon: "code"
            onClicked: Quickshell.execDetached([Settings.terminal, "-e", Quickshell.env("EDITOR") || "nano", Quickshell.env("HOME") + "/.config/niri/opal.kdl"])
        }
    }
}
