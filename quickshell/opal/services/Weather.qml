pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Current conditions from wttr.in (location auto-detected unless
// `weatherLocation` is set in settings.json). Refreshes every 20 minutes.
Singleton {
    id: root

    property bool ready: false
    property real tempC: 0
    property real feelsC: 0
    property int humidity: 0
    property int windKmh: 0
    property int code: 113
    property string description: ""
    property string location: ""
    property bool isDay: true
    property var forecast: []       // [{ day, maxC, minC, code }]

    readonly property bool fahrenheit: Settings.useFahrenheit
    readonly property string temp: fmt(tempC)
    readonly property string feels: fmt(feelsC)
    readonly property string icon: iconFor(code, isDay)

    function fmt(c) {
        return Math.round(fahrenheit ? c * 9 / 5 + 32 : c) + "°";
    }

    function iconFor(c, day) {
        if (c === 113)
            return day ? "sunny" : "clear_night";
        if (c === 116)
            return day ? "partly_cloudy_day" : "partly_cloudy_night";
        if (c === 119 || c === 122)
            return "cloud";
        if ([143, 248, 260].includes(c))
            return "foggy";
        if ([200, 386, 389, 392, 395].includes(c))
            return "thunderstorm";
        if ([179, 182, 185, 281, 284, 311, 314, 317, 350, 362, 365, 374, 377].includes(c))
            return "rainy_snow";
        if ([227, 230, 323, 326, 329, 332, 335, 338, 368, 371].includes(c))
            return "weather_snowy";
        if ([299, 302, 305, 308, 356, 359].includes(c))
            return "rainy_heavy";
        return "rainy_light";
    }

    function refresh() {
        if (!fetcher.running)
            fetcher.running = true;
    }

    Process {
        id: fetcher
        command: ["curl", "-sf", "--max-time", "15", "https://wttr.in/" + encodeURIComponent(Settings.weatherLocation) + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    const cur = j.current_condition[0];
                    root.tempC = Number(cur.temp_C);
                    root.feelsC = Number(cur.FeelsLikeC);
                    root.humidity = Number(cur.humidity);
                    root.windKmh = Number(cur.windspeedKmph);
                    root.code = Number(cur.weatherCode);
                    root.description = cur.weatherDesc?.[0]?.value?.trim() ?? "";
                    const area = j.nearest_area?.[0];
                    root.location = Settings.weatherLocation || (area ? area.areaName[0].value : "");
                    const astro = j.weather?.[0]?.astronomy?.[0];
                    if (astro) {
                        const now = new Date();
                        const toMin = s => {
                            const m = s.match(/(\d+):(\d+)\s*(AM|PM)/);
                            if (!m)
                                return 0;
                            return (Number(m[1]) % 12 + (m[3] === "PM" ? 12 : 0)) * 60 + Number(m[2]);
                        };
                        const mins = now.getHours() * 60 + now.getMinutes();
                        root.isDay = mins >= toMin(astro.sunrise) && mins < toMin(astro.sunset);
                    }
                    root.forecast = (j.weather ?? []).slice(0, 3).map(d => ({
                        day: new Date(d.date + "T12:00:00").toLocaleDateString(Qt.locale(), "ddd"),
                        maxC: Number(d.maxtempC),
                        minC: Number(d.mintempC),
                        code: Number(d.hourly?.[4]?.weatherCode ?? 113)
                    }));
                    root.ready = true;
                } catch (e) {
                    // keep the last good reading
                }
            }
        }
    }

    // refetch soon after the location or the on/off switch changes
    Timer {
        id: changed
        interval: 1500
        onTriggered: if (Settings.weatherEnabled) root.refresh()
    }
    Connections {
        target: Settings
        function onWeatherLocationChanged() { changed.restart(); }
        function onWeatherEnabledChanged() { changed.restart(); }
    }

    Timer {
        interval: 20 * 60 * 1000
        running: Settings.weatherEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
