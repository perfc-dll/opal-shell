pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU / memory / temperature / disk / uptime. Polls only while something
// that shows the numbers is open (`watchers` > 0), plus a slow idle tick.
Singleton {
    id: root

    property int watchers: 0

    property real cpu: 0            // 0..1
    property real memUsed: 0        // bytes
    property real memTotal: 1
    readonly property real mem: memUsed / memTotal
    property real temp: 0           // °C
    property real diskUsed: 0
    property real diskTotal: 1
    readonly property real disk: diskUsed / diskTotal
    property real uptimeSec: 0
    property string tempPath: ""

    readonly property string uptimeText: {
        const s = Math.floor(uptimeSec);
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        if (d > 0)
            return `${d}d ${h}h`;
        if (h > 0)
            return `${h}h ${m}m`;
        return `${m}m`;
    }

    property var _lastCpu: null

    function fmtBytes(b) {
        const g = b / 1073741824;
        return g >= 100 ? g.toFixed(0) + "G" : g.toFixed(1) + "G";
    }

    Timer {
        interval: root.watchers > 0 ? 2000 : 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            uptime.reload();
            if (root.tempPath !== "")
                tempFile.reload();
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const line = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = line[3] + (line[4] ?? 0);
            const total = line.reduce((a, b) => a + b, 0);
            if (root._lastCpu) {
                const dt = total - root._lastCpu.total, di = idle - root._lastCpu.idle;
                if (dt > 0)
                    root.cpu = Math.max(0, Math.min(1, 1 - di / dt));
            }
            root._lastCpu = { total: total, idle: idle };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s+(\d+)/)?.[1] ?? 1) * 1024;
            const avail = Number(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0) * 1024;
            root.memTotal = total;
            root.memUsed = total - avail;
        }
    }

    FileView {
        id: uptime
        path: "/proc/uptime"
        onLoaded: root.uptimeSec = parseFloat(text().split(" ")[0])
    }

    FileView {
        id: tempFile
        path: root.tempPath
        onLoaded: root.temp = parseInt(text()) / 1000
    }

    Process {
        id: findTemp
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); case $n in coretemp|k10temp|zenpower) echo $h/temp1_input; exit;; esac; done; for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && echo $z/temp && exit; done"]
        stdout: StdioCollector {
            onStreamFinished: root.tempPath = text.trim()
        }
    }

    Process {
        id: df
        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n").pop().trim().split(/\s+/).map(Number);
                if (f.length === 2) {
                    root.diskUsed = f[0];
                    root.diskTotal = f[1];
                }
            }
        }
    }
}
