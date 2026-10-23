pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The session's notification daemon (org.freedesktop.Notifications).
// `toasts` are what is on screen right now, `history` feeds the dashboard.
Singleton {
    id: root

    property var toasts: []
    property var history: []
    property int unread: 0
    property var toastHeights: ({})
    readonly property int maxToasts: 4
    readonly property int maxHistory: 60
    readonly property bool dnd: Settings.dnd

    property int _seq: 0

    function toastOffset(key) {
        let y = 0;
        for (const t of toasts) {
            if (t.key === key)
                return y;
            y += (toastHeights[t.key] ?? 96) + 10;
        }
        return y;
    }

    function setToastHeight(key, h) {
        if (toastHeights[key] === h)
            return;
        const m = Object.assign({}, toastHeights);
        m[key] = h;
        toastHeights = m;
    }

    function removeToast(key) {
        toasts = toasts.filter(t => t.key !== key);
        const m = Object.assign({}, toastHeights);
        delete m[key];
        toastHeights = m;
    }

    function dismiss(entry) {
        removeToast(entry.key);
        history = history.filter(h => h.key !== entry.key);
        if (entry.notification)
            entry.notification.dismiss();
    }

    function clearAll() {
        for (const h of history)
            h.notification?.dismiss();
        history = [];
        toasts = [];
        toastHeights = {};
    }

    function invoke(entry, action) {
        action.invoke();
        if (entry.notification && !entry.notification.resident)
            dismiss(entry);
    }

    function defaultAction(entry) {
        const n = entry.notification;
        if (!n)
            return false;
        const a = n.actions.find(a => a.identifier === "default") ?? null;
        if (a) {
            invoke(entry, a);
            return true;
        }
        return false;
    }

    function markRead() {
        unread = 0;
    }

    function timeAgo(ms) {
        const s = Math.floor((Date.now() - ms) / 1000);
        if (s < 45)
            return "now";
        if (s < 3600)
            return Math.floor(s / 60) + "m";
        if (s < 86400)
            return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false

        onNotification: n => {
            n.tracked = true;
            const entry = {
                key: "n" + (++root._seq),
                notification: n,
                id: n.id,
                appName: n.appName || "",
                appIcon: n.appIcon || "",
                desktopEntry: n.desktopEntry || "",
                summary: n.summary || "",
                body: n.body || "",
                image: n.image || "",
                urgency: n.urgency,
                time: Date.now(),
                timeout: n.urgency === NotificationUrgency.Critical ? 0 : (n.expireTimeout > 0 ? (n.expireTimeout > 100 ? n.expireTimeout : n.expireTimeout * 1000) : 6000)
            };

            n.closed.connect(() => {
                root.removeToast(entry.key);
                root.history = root.history.filter(h => h.key !== entry.key);
            });

            let hist = [entry, ...root.history];
            if (hist.length > root.maxHistory) {
                for (const old of hist.slice(root.maxHistory))
                    old.notification?.dismiss();
                hist = hist.slice(0, root.maxHistory);
            }
            root.history = hist;
            root.unread++;

            if (n.transient && root.dnd)
                return;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical) {
                let t = [...root.toasts, entry];
                if (t.length > root.maxToasts)
                    t = t.slice(t.length - root.maxToasts);
                root.toasts = t;
            }
        }
    }
}
