pragma Singleton

import QtQuick
import Quickshell

// Application search for the launcher: fuzzy-ish scoring + launch frequency.
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

    function score(app, q) {
        const name = app.name.toLowerCase();
        let s = 0;
        if (name === q)
            s = 1000;
        else if (name.startsWith(q))
            s = 800;
        else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            s = 600;
        else if (name.includes(q))
            s = 400;
        else if ((app.genericName || "").toLowerCase().includes(q))
            s = 250;
        else if (app.keywords.some(k => k.toLowerCase().startsWith(q)))
            s = 220;
        else if ((app.id || "").toLowerCase().includes(q))
            s = 200;
        else if ((app.comment || "").toLowerCase().includes(q))
            s = 120;
        else {
            // subsequence match ("ffx" -> firefox)
            let i = 0;
            for (const ch of name)
                if (ch === q[i])
                    i++;
            if (i === q.length)
                s = 80;
        }
        if (s > 0)
            s += Math.min(150, (Settings.launchCounts[app.id] ?? 0) * 10);
        return s;
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        if (q === "") {
            return all.slice().sort((a, b) => ((Settings.launchCounts[b.id] ?? 0) - (Settings.launchCounts[a.id] ?? 0)) || a.name.localeCompare(b.name));
        }
        return all.map(a => ({ a: a, s: score(a, q) })).filter(x => x.s > 0).sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name)).map(x => x.a);
    }

    function launch(app) {
        const counts = Object.assign({}, Settings.launchCounts);
        counts[app.id] = (counts[app.id] ?? 0) + 1;
        Settings.launchCounts = counts;
        if (app.runInTerminal)
            Quickshell.execDetached([Settings.terminal, "-e", ...app.command]);
        else
            app.execute();
    }

    function iconFor(app) {
        return Quickshell.iconPath(app?.icon ?? "", "application-x-executable");
    }

    // Best-effort icon for a niri window's app-id.
    property var _iconCache: ({})
    function iconForAppId(appId) {
        if (!appId)
            return Quickshell.iconPath("application-x-executable");
        if (_iconCache[appId] !== undefined)
            return _iconCache[appId];
        const entry = DesktopEntries.heuristicLookup(appId);
        const icon = entry?.icon ? Quickshell.iconPath(entry.icon, true) : "";
        const result = icon || Quickshell.iconPath(appId.toLowerCase(), true) || Quickshell.iconPath("application-x-executable");
        _iconCache[appId] = result;
        return result;
    }

    function nameForAppId(appId) {
        return DesktopEntries.heuristicLookup(appId)?.name || appId;
    }
}
