import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    title: "Notifications"
    subtitle: "Opal is the notification daemon in this session."

    SettingCard {
        width: parent.width
        title: "POPUPS"
        note: "Critical notifications (like low battery) always show and stay until dismissed. Hovering a popup pauses its timer."

        SettingRow {
            icon: "do_not_disturb_on"
            title: "Do not disturb"
            subtitle: "Popups are silenced; everything still lands in the history"
            OpalSwitch {
                checked: Settings.dnd
                onToggled: Settings.dnd = !Settings.dnd
            }
        }
        SettingRow {
            icon: "timer"
            title: "Show popups for"
            subtitle: "When the app doesn't ask for a specific time"
            SettingSlider {
                from: 2
                to: 20
                step: 1
                value: Settings.toastSeconds
                format: v => v + " s"
                onMoved: v => Settings.toastSeconds = v
            }
        }
        SettingRow {
            icon: "view_agenda"
            title: "Popups on screen at once"
            SettingSlider {
                from: 1
                to: 6
                step: 1
                value: Settings.maxToasts
                format: v => String(v)
                onMoved: v => Settings.maxToasts = v
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "HISTORY"

        SettingRow {
            icon: "history"
            title: "Keep in history"
            subtitle: Notifs.history.length + " notifications right now"
            SettingSlider {
                from: 20
                to: 200
                step: 10
                value: Settings.historyLimit
                format: v => String(v)
                onMoved: v => Settings.historyLimit = v
            }
        }
        SettingRow {
            icon: "science"
            title: "Try it"
            Row {
                spacing: 8
                PillButton {
                    text: "Send a test"
                    icon: "send"
                    onClicked: Quickshell.execDetached(["notify-send", "-a", "Opal", "-i", "preferences-desktop-theme", "-A", "nice=Nice", "Hello from Opal ✨", "This is what a notification looks like."])
                }
                PillButton {
                    text: "Clear history"
                    icon: "delete_sweep"
                    danger: true
                    onClicked: Notifs.clearAll()
                }
            }
        }
    }
}
