import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

GridLayout {
    id: root

    signal openPage(string page)

    columns: 2
    rowSpacing: 8
    columnSpacing: 8

    ToggleTile {
        Layout.fillWidth: true
        icon: Net.wifiEnabled ? (Net.active ? "wifi" : "wifi_find") : "wifi_off"
        title: "Wi-Fi"
        subtitle: Net.label
        active: Net.wifiEnabled
        hasDetails: true
        onToggled: Net.setWifi(!Net.wifiEnabled)
        onDetails: root.openPage("wifi")
    }
    ToggleTile {
        Layout.fillWidth: true
        icon: Bt.icon
        title: "Bluetooth"
        subtitle: Bt.label
        active: Bt.enabled
        hasDetails: Bt.available
        onToggled: Bt.toggle()
        onDetails: root.openPage("bluetooth")
    }
    ToggleTile {
        Layout.fillWidth: true
        icon: Settings.dnd ? "do_not_disturb_on" : "notifications_active"
        title: "Do not disturb"
        subtitle: Settings.dnd ? "Silenced" : "Off"
        active: Settings.dnd
        onToggled: Settings.dnd = !Settings.dnd
    }
    ToggleTile {
        Layout.fillWidth: true
        icon: "coffee"
        title: "Caffeine"
        subtitle: Power.caffeine ? "Staying awake" : "Off"
        active: Power.caffeine
        onToggled: Power.caffeine = !Power.caffeine
    }
    ToggleTile {
        Layout.fillWidth: true
        icon: Power.profileIcon
        title: "Power mode"
        subtitle: Power.profileLabel
        active: Power.profile === "performance"
        onToggled: Power.cycleProfile()
    }
    ToggleTile {
        Layout.fillWidth: true
        visible: Power.hasWlsunset
        icon: "nightlight"
        title: "Night light"
        subtitle: !Settings.nightLight ? "Off" : Settings.nightLightMode === "scheduled" ? Settings.nightLightFrom + "–" + Settings.nightLightTo : Settings.nightLightTemp + "K"
        active: Settings.nightLight
        onToggled: Settings.nightLight = !Settings.nightLight
    }
    ToggleTile {
        Layout.fillWidth: true
        visible: Brightness.hasKbd
        icon: "keyboard"
        title: "Key light"
        subtitle: Brightness.kbd > 0 ? Brightness.kbd + " / " + Brightness.kbdMax : "Off"
        active: Brightness.kbd > 0
        onToggled: Brightness.setKbd(Brightness.kbd >= Brightness.kbdMax ? 0 : Brightness.kbd + 1)
    }
    ToggleTile {
        Layout.fillWidth: true
        icon: "graphic_eq"
        title: "Visualizer"
        subtitle: Settings.edgeVisualizer ? "Edges glow with music" : "Off"
        active: Settings.edgeVisualizer
        onToggled: Settings.edgeVisualizer = !Settings.edgeVisualizer
    }
    ToggleTile {
        Layout.fillWidth: true
        icon: "palette"
        title: "Adaptive color"
        subtitle: Settings.adaptiveColors ? "From wallpaper" : "Opal signature"
        active: Settings.adaptiveColors
        onToggled: Settings.adaptiveColors = !Settings.adaptiveColors
    }
    ToggleTile {
        Layout.fillWidth: true
        icon: "blur_on"
        title: "Glass"
        subtitle: Math.round(Settings.glassOpacity * 100) + "% tint"
        active: Settings.glassOpacity < 0.45
        onToggled: {
            const steps = [0.32, 0.42, 0.52, 0.66];
            const i = steps.findIndex(s => Math.abs(s - Settings.glassOpacity) < 0.01);
            Settings.glassOpacity = steps[(i + 1) % steps.length];
        }
    }
}
