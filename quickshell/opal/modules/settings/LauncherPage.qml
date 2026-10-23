import QtQuick
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    title: "Launcher"
    subtitle: "Super+D or Super+Space. Type to search apps, or start with a prefix."

    SettingCard {
        width: parent.width
        title: "WEB SEARCH"

        SettingRow {
            icon: "travel_explore"
            title: "Search engine"
            subtitle: "Used by \"?words\""
            Segmented {
                options: Object.keys(Apps.engines).map(k => ({ value: k, label: Apps.engines[k].name.replace(" Search", "") }))
                value: Settings.searchEngine
                onPicked: v => Settings.searchEngine = v
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "PREFIXES"

        component Hint: SettingRow {
            id: hint
            property string keys
            StyledText {
                text: hint.keys
                font.family: Theme.monoFont
                font.pixelSize: Theme.fontMd
                color: Theme.violet
            }
        }

        Hint { icon: "calculate"; title: "Calculator"; subtitle: "Enter copies the result"; keys: "=2^10/3" }
        Hint { icon: "terminal"; title: "Run a command"; subtitle: "Shift+Enter runs it in " + Settings.terminal; keys: ">htop" }
        Hint { icon: "travel_explore"; title: "Search the web"; subtitle: "With " + Apps.engineName; keys: "?niri wiki" }
        Hint { icon: "content_paste"; title: "Clipboard history"; subtitle: Clipboard.available ? "Also Super+V" : "Needs cliphist"; keys: "Tab" }
    }

    SettingCard {
        width: parent.width
        title: "HISTORY"

        SettingRow {
            icon: "history"
            title: "App ranking"
            subtitle: "Apps you open often float to the top (" + Object.keys(Settings.launchCounts).length + " tracked)"
            PillButton {
                text: "Reset"
                icon: "restart_alt"
                onClicked: Apps.resetCounts()
            }
        }
        SettingRow {
            visible: Clipboard.available
            icon: "content_paste"
            title: "Clipboard history"
            subtitle: "Everything you've copied, stored by cliphist"
            PillButton {
                text: "Clear"
                icon: "delete_sweep"
                danger: true
                onClicked: Clipboard.wipe()
            }
        }
    }
}
