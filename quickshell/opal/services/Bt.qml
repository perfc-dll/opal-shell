pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: {
        if (!adapter)
            return [];
        return adapter.devices.values.filter(d => d.paired || d.connected || d.name).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
    }
    readonly property var connected: devices.filter(d => d.connected)
    readonly property string icon: !enabled ? "bluetooth_disabled" : connected.length > 0 ? "bluetooth_connected" : "bluetooth"
    readonly property string label: !available ? "Unavailable" : !enabled ? "Off" : connected.length === 1 ? connected[0].name : connected.length > 1 ? connected.length + " devices" : "On"

    function toggle() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function scan(on) {
        if (adapter && adapter.enabled)
            adapter.discovering = on;
    }

    function toggleDevice(d) {
        if (d.connected)
            d.disconnect();
        else if (d.paired)
            d.connect();
        else {
            d.trusted = true;
            d.pair();
        }
    }

    function deviceIcon(d) {
        const i = d.icon || "";
        if (i.indexOf("audio-headset") !== -1 || i.indexOf("headphone") !== -1)
            return "headphones";
        if (i.indexOf("audio") !== -1)
            return "speaker";
        if (i.indexOf("input-mouse") !== -1)
            return "mouse";
        if (i.indexOf("input-keyboard") !== -1)
            return "keyboard";
        if (i.indexOf("phone") !== -1)
            return "smartphone";
        if (i.indexOf("input-gaming") !== -1)
            return "sports_esports";
        if (i.indexOf("computer") !== -1)
            return "computer";
        return "bluetooth";
    }
}
