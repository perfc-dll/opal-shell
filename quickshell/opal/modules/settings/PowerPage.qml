import QtQuick
import qs.config
import qs.services
import qs.widgets

SettingsPage {
    title: "Power & idle"
    subtitle: "Battery, power mode, what happens when you step away, and night light."

    SettingCard {
        width: parent.width
        title: "BATTERY"
        visible: Power.hasBattery

        SettingRow {
            icon: Power.batteryIcon
            title: Math.round(Power.percent * 100) + "%" + (Power.charging ? " · charging" : Power.full ? " · full" : "")
            subtitle: Power.timeText + (Power.watts > 0.1 ? "  ·  " + Power.watts.toFixed(1) + " W" : "")
        }
        SettingRow {
            icon: "battery_alert"
            title: "Low battery warning"
            subtitle: "A critical notification when the battery drops this low"
            SettingSlider {
                from: 0
                to: 40
                step: 5
                value: Settings.lowBatteryWarn
                format: v => v === 0 ? "Off" : v + "%"
                onMoved: v => Settings.lowBatteryWarn = v
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "POWER MODE"
        note: Power.profile === "" ? "Needs the small root helper from extras/power-profile in the repo." : ""

        SettingRow {
            icon: Power.profileIcon
            title: "Platform profile"
            subtitle: "Trades battery life for speed"
            enabled: Power.profile !== ""
            Segmented {
                options: [{ value: "low-power", label: "Saver" }, { value: "balanced", label: "Balanced" }, { value: "performance", label: "Performance" }]
                value: Power.profile
                onPicked: v => Power.setProfile(v)
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "WHEN IDLE"
        note: "Caffeine and apps that inhibit idle (like a playing video) pause these timers. The screen still locks before suspend either way."

        SettingRow {
            icon: "lock_clock"
            title: "Lock the screen after"
            Segmented {
                options: [{ value: 0, label: "Never" }, { value: 2, label: "2m" }, { value: 5, label: "5m" }, { value: 10, label: "10m" }, { value: 30, label: "30m" }]
                value: Settings.idleLockMinutes
                onPicked: v => Settings.idleLockMinutes = v
            }
        }
        SettingRow {
            icon: "desktop_access_disabled"
            title: "Turn the screen off after"
            Segmented {
                options: [{ value: 0, label: "Never" }, { value: 5, label: "5m" }, { value: 10, label: "10m" }, { value: 15, label: "15m" }, { value: 30, label: "30m" }]
                value: Settings.idleScreenOffMinutes
                onPicked: v => Settings.idleScreenOffMinutes = v
            }
        }
        SettingRow {
            icon: "bedtime"
            title: "Suspend after"
            Segmented {
                options: [{ value: 0, label: "Never" }, { value: 15, label: "15m" }, { value: 30, label: "30m" }, { value: 60, label: "1h" }]
                value: Settings.idleSuspendMinutes
                onPicked: v => Settings.idleSuspendMinutes = v
            }
        }
        SettingRow {
            icon: "coffee"
            title: "Caffeine"
            subtitle: "Stay awake until you turn it off (not kept after a restart)"
            OpalSwitch {
                checked: Power.caffeine
                onToggled: Power.caffeine = !Power.caffeine
            }
        }
    }

    SettingCard {
        width: parent.width
        title: "NIGHT LIGHT"
        note: Power.hasWlsunset ? "" : "Needs wlsunset (sudo dnf install wlsunset)."

        SettingRow {
            icon: "nightlight"
            title: "Night light"
            subtitle: "Warmer colours that are easier on the eyes at night"
            enabled: Power.hasWlsunset
            OpalSwitch {
                checked: Settings.nightLight
                onToggled: Settings.nightLight = !Settings.nightLight
            }
        }
        SettingRow {
            icon: "device_thermostat"
            title: "Warmth"
            enabled: Power.hasWlsunset
            SettingSlider {
                from: 2500
                to: 6000
                step: 100
                value: Settings.nightLightTemp
                format: v => v + " K"
                onMoved: v => Settings.nightLightTemp = v
            }
        }
        SettingRow {
            icon: "schedule"
            title: "When"
            subtitle: Settings.nightLightMode === "scheduled" ? "Fades in and out over 30 minutes" : "As long as night light is on"
            enabled: Power.hasWlsunset
            Segmented {
                options: [{ value: "always", label: "Always" }, { value: "scheduled", label: "Scheduled" }]
                value: Settings.nightLightMode
                onPicked: v => Settings.nightLightMode = v
            }
        }
        SettingRow {
            visible: Settings.nightLightMode === "scheduled"
            icon: "dark_mode"
            title: "From – to"
            subtitle: "24-hour times, e.g. 20:00 and 07:00"
            enabled: Power.hasWlsunset
            Row {
                spacing: 8
                function valid(t) {
                    const m = t.trim().match(/^(\d{1,2}):(\d{2})$/);
                    return m && Number(m[1]) < 24 && Number(m[2]) < 60 ? (m[1].padStart(2, "0") + ":" + m[2]) : "";
                }
                TextBox {
                    width: 90
                    text: Settings.nightLightFrom
                    mono: true
                    onCommitted: t => {
                        const v = parent.valid(t);
                        if (v)
                            Settings.nightLightFrom = v;
                        else
                            text = Settings.nightLightFrom;
                    }
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "→"
                    color: Theme.subtext
                }
                TextBox {
                    width: 90
                    text: Settings.nightLightTo
                    mono: true
                    onCommitted: t => {
                        const v = parent.valid(t);
                        if (v)
                            Settings.nightLightTo = v;
                        else
                            text = Settings.nightLightTo;
                    }
                }
            }
        }
    }
}
