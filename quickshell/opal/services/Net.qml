pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Wi-Fi state from Quickshell.Networking (NetworkManager), plus nmcli for the
// bits it doesn't cover (wired status, connecting with a new password).
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property WifiDevice wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardware: Networking.wifiHardwareEnabled
    readonly property var networks: {
        if (!wifiDevice)
            return [];
        const seen = {};
        const list = [];
        for (const n of wifiDevice.networks.values) {
            if (!n.name || seen[n.name])
                continue;
            seen[n.name] = true;
            list.push(n);
        }
        return list.sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
    }
    readonly property WifiNetwork active: networks.find(n => n.connected) ?? null
    readonly property string ssid: active?.name ?? ""
    readonly property real strength: norm(active?.signalStrength ?? 0)

    property bool wired: false
    property string wiredName: ""

    readonly property bool online: active !== null || wired
    readonly property string icon: {
        if (wired && !active)
            return "lan";
        if (!wifiEnabled)
            return "wifi_off";
        if (!active)
            return "signal_wifi_statusbar_not_connected";
        return strengthIcon(strength);
    }
    readonly property string label: active ? ssid : wired ? (wiredName || "Ethernet") : wifiEnabled ? "Not connected" : "Off"

    property string connecting: ""
    property string lastError: ""

    function norm(v) {
        return v > 1 ? v / 100 : v;
    }

    function strengthIcon(s) {
        s = norm(s);
        return s > 0.75 ? "signal_wifi_4_bar" : s > 0.5 ? "network_wifi_3_bar" : s > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar";
    }

    function setWifi(on) {
        Networking.wifiEnabled = on;
    }

    function scan(on) {
        if (wifiDevice)
            wifiDevice.scannerEnabled = on;
    }

    function connectTo(network, password) {
        lastError = "";
        connecting = network.name;
        if (network.known && !password) {
            network.connect();
            connectingClear.restart();
            return;
        }
        const cmd = ["nmcli", "--wait", "20", "device", "wifi", "connect", network.name];
        if (password)
            cmd.push("password", password);
        nmConnect.command = cmd;
        nmConnect.running = true;
    }

    function disconnectFrom(network) {
        network.disconnect();
    }

    function forget(network) {
        network.forget();
    }

    Timer {
        id: connectingClear
        interval: 8000
        onTriggered: root.connecting = ""
    }

    Process {
        id: nmConnect
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.lastError = text.trim().replace(/^Error: /, "")
        }
        onExited: code => {
            root.connecting = "";
            if (code === 0)
                root.lastError = "";
        }
    }

    // Wired status (NetworkManager's ethernet devices aren't exposed by the
    // Networking module yet).
    Process {
        id: wiredProbe
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                let found = false, name = "";
                for (const l of text.split("\n")) {
                    const f = l.split(":");
                    if (f[0] === "ethernet" && f[1] === "connected") {
                        found = true;
                        name = f.slice(2).join(":");
                        break;
                    }
                }
                root.wired = found;
                root.wiredName = name;
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wiredProbe.running = true
    }
}
