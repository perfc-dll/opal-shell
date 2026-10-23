pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland

// Battery (UPower), ACPI platform profile (through an optional root helper +
// scoped sudo rule, see extras/power-profile), caffeine, night light and
// session actions.
Singleton {
    id: root

    // ---- battery ------------------------------------------------------------------
    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property real percent: battery?.percentage ?? 0     // 0..1
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: battery?.state === UPowerDeviceState.FullyCharged
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property real watts: Math.abs(battery?.changeRate ?? 0)
    readonly property string batteryIcon: {
        if (charging)
            return "battery_charging_full";
        if (full || percent > 0.95)
            return "battery_full";
        const steps = ["battery_0_bar", "battery_1_bar", "battery_2_bar", "battery_3_bar", "battery_4_bar", "battery_5_bar", "battery_6_bar"];
        return steps[Math.min(6, Math.floor(percent * 7))];
    }
    readonly property string timeText: {
        const s = charging ? battery?.timeToFull : battery?.timeToEmpty;
        if (!s || s <= 0)
            return full ? "Fully charged" : pluggedIn ? "Plugged in" : "";
        const h = Math.floor(s / 3600), m = Math.round(s % 3600 / 60);
        return (h > 0 ? h + "h " : "") + m + "m " + (charging ? "to full" : "left");
    }

    // ---- platform profile -----------------------------------------------------------
    readonly property var profiles: ["low-power", "balanced", "performance"]
    property string profile: ""
    readonly property string profileLabel: profile === "performance" ? "Performance" : profile === "low-power" ? "Power saver" : profile === "balanced" ? "Balanced" : "Unavailable"
    readonly property string profileIcon: profile === "performance" ? "speed" : profile === "low-power" ? "eco" : "balance"

    function cycleProfile() {
        const order = ["performance", "balanced", "low-power"];
        const next = order[(order.indexOf(profile) + 1) % order.length];
        setProfile(next);
    }

    function setProfile(p) {
        setter.command = ["sudo", "-n", "/usr/local/sbin/set-platform-profile", p];
        setter.running = true;
    }

    FileView {
        id: profileFile
        path: "/sys/firmware/acpi/platform_profile"
        printErrors: false
        onLoaded: root.profile = text().trim()
    }

    Process {
        id: setter
        onExited: profileFile.reload()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: profileFile.reload()
    }

    // ---- caffeine (the bar owns the actual IdleInhibitor) ---------------------------
    property bool caffeine: false

    // ---- night light (wlsunset) -----------------------------------------------------
    readonly property bool nightLight: Settings.nightLight
    property bool hasWlsunset: false

    Process {
        running: true
        command: ["sh", "-c", "command -v wlsunset"]
        onExited: code => root.hasWlsunset = code === 0
    }

    Process {
        id: sunset
        running: root.nightLight && root.hasWlsunset
        // "always": day and night temperatures 1K apart = a constant warm tint.
        // "scheduled": warm from nightLightFrom until nightLightTo, with a
        // 30-minute fade either side.
        command: Settings.nightLightMode === "scheduled"
            ? ["wlsunset", "-T", "6500", "-t", String(Settings.nightLightTemp), "-s", Settings.nightLightFrom, "-S", Settings.nightLightTo, "-d", "1800"]
            : ["wlsunset", "-T", String(Settings.nightLightTemp + 1), "-t", String(Settings.nightLightTemp), "-S", "06:00", "-s", "18:00", "-d", "60"]
        // restart with the new arguments when a setting changes
        onCommandChanged: if (running) {
            running = false;
            running = Qt.binding(() => root.nightLight && root.hasWlsunset);
        }
    }

    // ---- idle (ext-idle-notify; caffeine and video players' inhibitors count) -------
    IdleMonitor {
        enabled: Settings.idleLockMinutes > 0
        timeout: Settings.idleLockMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lock()
    }
    IdleMonitor {
        enabled: Settings.idleScreenOffMinutes > 0
        timeout: Settings.idleScreenOffMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Niri.powerOffMonitors()
    }
    IdleMonitor {
        enabled: Settings.idleSuspendMinutes > 0
        timeout: Settings.idleSuspendMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.suspend()
    }

    // ---- low battery warning -----------------------------------------------------------
    property bool _warned: false
    function checkBattery() {
        const t = Settings.lowBatteryWarn / 100;
        if (!hasBattery || t <= 0)
            return;
        if (charging || pluggedIn || percent > t + 0.05) {
            _warned = false;
        } else if (percent <= t && !_warned) {
            _warned = true;
            Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Battery", "-i", "battery-caution", "Battery low", Math.round(percent * 100) + "% left" + (timeText ? "  ·  " + timeText : "")]);
        }
    }
    onPercentChanged: checkBattery()
    onChargingChanged: checkBattery()

    // ---- session ------------------------------------------------------------------------
    function lock() {
        Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock"]);
    }
    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }
    function logout() {
        Niri.quit();
    }
    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }
    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
