import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    id: page
    title: "About"

    property string opalVersion: "…"
    property string qsVersion: "…"
    property string niriVersion: "…"
    property bool confirmReset: false

    Process {
        running: true
        command: ["sh", "-c", "git -C \"$1\" describe --tags --always --dirty 2>/dev/null || echo unknown; qs --version 2>/dev/null | head -n1 | cut -d, -f1; niri --version 2>/dev/null", "sh", Quickshell.shellDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                page.opalVersion = l[0] ?? "unknown";
                page.qsVersion = (l[1] ?? "").replace(/^quickshell\s*/i, "") || "unknown";
                page.niriVersion = (l[2] ?? "").replace(/^niri\s*/i, "") || "unknown";
            }
        }
    }

    // hero
    Item {
        width: parent.width
        height: 150

        Rectangle {
            id: orb
            width: 96
            height: 96
            radius: 48
            anchors.verticalCenter: parent.verticalCenter
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.pink }
                GradientStop { position: 0.55; color: Theme.violet }
                GradientStop { position: 1; color: Theme.cyan }
            }
            Rectangle {
                x: 22; y: 18; width: 28; height: 18; radius: 10; rotation: -35
                color: Qt.rgba(1, 1, 1, 0.5)
            }
        }
        Column {
            anchors.left: orb.right
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            StyledText {
                text: "Opal"
                font.pixelSize: 34
                font.weight: 750
            }
            StyledText {
                text: "A liquid-glass desktop shell for niri"
                color: Theme.subtext
                font.pixelSize: Theme.fontLg
            }
            Rectangle {
                width: vibe.implicitWidth + 20
                height: 24
                radius: 12
                gradient: AccentGradient {}
                StyledText {
                    id: vibe
                    anchors.centerIn: parent
                    text: "✨ vibe-coded"
                    font.pixelSize: Theme.fontSm
                    font.weight: 700
                    color: Theme.accentInk
                }
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "VERSIONS"
        note: "Opal was built by describing it to an AI coding agent (Claude Code) and testing it in a nested niri session. It wasn't audited line by line."

        SettingRow { icon: "auto_awesome"; title: "Opal"; StyledText { text: page.opalVersion; font.family: Theme.monoFont; color: Theme.subtext } }
        SettingRow { icon: "code"; title: "Quickshell"; StyledText { text: page.qsVersion; font.family: Theme.monoFont; color: Theme.subtext } }
        SettingRow { icon: "view_column"; title: "niri"; StyledText { text: page.niriVersion; font.family: Theme.monoFont; color: Theme.subtext } }
        SettingRow { icon: "computer"; title: "System"; StyledText { text: Account.distro; color: Theme.subtext } }
    }

    SettingCard {
        width: parent.width
        title: "FILES & SHELL"

        SettingRow {
            icon: "description"
            title: "Settings file"
            subtitle: Settings.file
            PillButton {
                text: "Open"
                icon: "open_in_new"
                onClicked: Qt.openUrlExternally("file://" + Settings.file)
            }
        }
        SettingRow {
            icon: "folder_open"
            title: "Shell folder"
            subtitle: Quickshell.shellDir
            PillButton {
                text: "Open"
                icon: "open_in_new"
                onClicked: Qt.openUrlExternally("file://" + Quickshell.shellDir)
            }
        }
        SettingRow {
            icon: "restart_alt"
            title: "Restart the shell"
            subtitle: "Same as Super+Ctrl+R"
            PillButton {
                text: "Restart"
                icon: "restart_alt"
                onClicked: Quickshell.execDetached(["systemctl", "--user", "restart", "opal-shell.service"])
            }
        }
        SettingRow {
            icon: "public"
            title: "Source code"
            subtitle: "github.com/perfc-dll/opal-shell"
            PillButton {
                text: "GitHub"
                icon: "open_in_new"
                onClicked: Qt.openUrlExternally("https://github.com/perfc-dll/opal-shell")
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "RESET"

        SettingRow {
            icon: "settings_backup_restore"
            title: page.confirmReset ? "Really reset everything?" : "Reset to defaults"
            subtitle: "All settings go back to how Opal ships. Your wallpaper, name and app ranking stay."
            Row {
                spacing: 8
                PillButton {
                    visible: page.confirmReset
                    text: "Cancel"
                    onClicked: page.confirmReset = false
                }
                PillButton {
                    text: page.confirmReset ? "Yes, reset" : "Reset…"
                    icon: "settings_backup_restore"
                    danger: true
                    onClicked: {
                        if (page.confirmReset) {
                            Settings.resetDefaults();
                            page.confirmReset = false;
                        } else {
                            page.confirmReset = true;
                        }
                    }
                }
            }
        }
    }
}
