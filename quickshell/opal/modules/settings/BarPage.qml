import QtQuick
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    title: "Bar & island"
    subtitle: "Choose what the bar and the centre island show."

    component Toggle: SettingRow {
        id: row
        property string key
        OpalSwitch {
            checked: Settings[row.key]
            onToggled: Settings[row.key] = !Settings[row.key]
        }
    }

    SettingCard {
        width: parent.width
        title: "BAR"
        note: "Super+Shift+B hides and shows the bar too."

        Toggle { key: "barVisible"; icon: "toolbar"; title: "Show the bar" }
        Toggle { key: "barWorkspaces"; icon: "more_horiz"; title: "Workspace dots"; enabled: Settings.barVisible }
        Toggle { key: "barWindows"; icon: "view_column"; title: "Window icons"; subtitle: "One icon per window, in niri column order"; enabled: Settings.barVisible }
        Toggle { key: "barTitle"; icon: "title"; title: "Focused window title"; enabled: Settings.barVisible }
        Toggle { key: "barTray"; icon: "apps"; title: "System tray"; enabled: Settings.barVisible }
        Toggle { key: "barBatteryPercent"; icon: "battery_full"; title: "Battery percentage"; enabled: Settings.barVisible }
    }

    SettingCard {
        width: parent.width
        title: "ISLAND"

        Toggle { key: "islandDate"; icon: "calendar_today"; title: "Date next to the clock"; enabled: Settings.barVisible }
        Toggle { key: "islandWeather"; icon: "partly_cloudy_day"; title: "Weather"; subtitle: Settings.weatherEnabled ? "" : "Weather is off in General"; enabled: Settings.barVisible && Settings.weatherEnabled }
        Toggle { key: "islandMedia"; icon: "music_note"; title: "Now playing"; subtitle: "Cover, track and live bars while music plays"; enabled: Settings.barVisible }
    }
}
