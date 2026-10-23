import QtQuick
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    title: "General"
    subtitle: "Who you are, the clock, weather and your terminal."

    SettingCard {
        width: parent.width
        title: "YOU"
        note: "For a profile picture, save a square image as ~/.face."

        SettingRow {
            icon: "badge"
            title: "Your name"
            subtitle: "Shown in the greeting, the control centre and the power menu"
            TextBox {
                text: Settings.displayName
                placeholder: Account.realName || "Your name"
                onCommitted: t => Settings.displayName = t.trim()
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "CLOCK"

        SettingRow {
            icon: "schedule"
            title: "24-hour clock"
            subtitle: Settings.use24h ? "21:30" : "9:30 PM"
            OpalSwitch {
                checked: Settings.use24h
                onToggled: Settings.use24h = !Settings.use24h
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "WEATHER"
        note: "Weather comes from wttr.in. With no location set, it's guessed from your IP address."

        SettingRow {
            icon: "partly_cloudy_day"
            title: "Show weather"
            subtitle: Weather.ready && Settings.weatherEnabled ? Weather.temp + " · " + Weather.description + " in " + Weather.location : "Island and dashboard"
            OpalSwitch {
                checked: Settings.weatherEnabled
                onToggled: Settings.weatherEnabled = !Settings.weatherEnabled
            }
        }
        SettingRow {
            icon: "travel_explore"
            title: "Location"
            subtitle: "A city name, e.g. Seoul or Paris"
            enabled: Settings.weatherEnabled
            TextBox {
                text: Settings.weatherLocation
                placeholder: "Automatic"
                onCommitted: t => Settings.weatherLocation = t.trim()
            }
        }
        SettingRow {
            icon: "device_thermostat"
            title: "Units"
            enabled: Settings.weatherEnabled
            Segmented {
                options: [{ value: false, label: "°C" }, { value: true, label: "°F" }]
                value: Settings.useFahrenheit
                onPicked: v => Settings.useFahrenheit = v
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "APPS"

        SettingRow {
            icon: "terminal"
            title: "Terminal"
            subtitle: "Used for \">command\" + Shift+Enter in the launcher and for terminal apps"
            TextBox {
                text: Settings.terminal
                mono: true
                placeholder: "kitty"
                onCommitted: t => Settings.terminal = t.trim() || "kitty"
            }
        }
    }
}
