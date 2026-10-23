pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live model of niri's state, fed by its JSON event stream on $NIRI_SOCKET.
// Actions are sent through `niri msg action ...` (one short-lived process each).
Singleton {
    id: root

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") ?? ""
    readonly property bool available: socketPath !== ""

    property var workspaces: []
    property var windows: []
    property var focusedWindowId: null
    property bool overviewOpen: false
    property var keyboardLayouts: []
    property int keyboardLayoutIndex: 0

    readonly property var focusedWindow: {
        for (const w of windows)
            if (w.id === focusedWindowId)
                return w;
        return null;
    }
    readonly property var focusedWorkspace: workspaces.find(w => w.is_focused) ?? null
    readonly property string focusedOutput: focusedWorkspace?.output ?? ""
    readonly property string keyboardLayout: keyboardLayouts[keyboardLayoutIndex] ?? ""

    // ---- queries ------------------------------------------------------------------
    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output).sort((a, b) => a.idx - b.idx);
    }

    function activeWorkspaceOn(output) {
        return workspaces.find(w => w.output === output && w.is_active) ?? null;
    }

    function windowsOnWorkspace(wsId) {
        return windows.filter(w => w.workspace_id === wsId).sort((a, b) => {
            if (a.is_floating !== b.is_floating)
                return a.is_floating ? 1 : -1;
            const pa = a.layout?.pos_in_scrolling_layout ?? [9999, 0];
            const pb = b.layout?.pos_in_scrolling_layout ?? [9999, 0];
            return pa[0] - pb[0] || pa[1] - pb[1] || a.id - b.id;
        });
    }

    function workspaceHasWindows(wsId) {
        return windows.some(w => w.workspace_id === wsId);
    }

    // ---- actions --------------------------------------------------------------------
    function action(...args) {
        Quickshell.execDetached(["niri", "msg", "action", ...args.map(a => String(a))]);
    }

    function focusWindow(id) { action("focus-window", "--id", id); }
    function closeWindow(id) { action("close-window", "--id", id); }
    function focusWorkspace(ref) { action("focus-workspace", ref); }
    function focusWorkspaceUp() { action("focus-workspace-up"); }
    function focusWorkspaceDown() { action("focus-workspace-down"); }
    function focusColumnLeft() { action("focus-column-left"); }
    function focusColumnRight() { action("focus-column-right"); }
    function toggleOverview() { action("toggle-overview"); }
    function quit() { action("quit", "--skip-confirmation"); }
    function powerOffMonitors() { action("power-off-monitors"); }
    function spawn(cmd) { action("spawn", "--", ...cmd); }

    // ---- event stream -----------------------------------------------------------------
    Socket {
        id: events
        path: root.socketPath
        connected: root.available

        onConnectedChanged: {
            if (connected) {
                write('"EventStream"\n');
                flush();
            } else if (root.available) {
                reconnect.restart();
            }
        }

        parser: SplitParser {
            onRead: line => root.handleLine(line)
        }
    }

    Timer {
        id: reconnect
        interval: 1500
        onTriggered: {
            events.connected = false;
            events.connected = true;
        }
    }

    function handleLine(line) {
        if (!line)
            return;
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;
        }
        if ("Ok" in ev || "Err" in ev)
            return;

        const kind = Object.keys(ev)[0];
        const d = ev[kind];

        switch (kind) {
        case "WorkspacesChanged":
            workspaces = d.workspaces;
            break;
        case "WorkspaceActivated":
            {
                const target = workspaces.find(w => w.id === d.id);
                if (!target)
                    break;
                workspaces = workspaces.map(w => {
                    const n = Object.assign({}, w);
                    if (w.output === target.output)
                        n.is_active = w.id === d.id;
                    if (d.focused)
                        n.is_focused = w.id === d.id;
                    return n;
                });
                break;
            }
        case "WorkspaceActiveWindowChanged":
            workspaces = workspaces.map(w => w.id === d.workspace_id ? Object.assign({}, w, { active_window_id: d.active_window_id }) : w);
            break;
        case "WorkspaceUrgencyChanged":
            workspaces = workspaces.map(w => w.id === d.id ? Object.assign({}, w, { is_urgent: d.urgent }) : w);
            break;
        case "WindowsChanged":
            windows = d.windows;
            focusedWindowId = windows.find(w => w.is_focused)?.id ?? null;
            break;
        case "WindowOpenedOrChanged":
            {
                const win = d.window;
                let list = windows.filter(w => w.id !== win.id);
                if (win.is_focused) {
                    list = list.map(w => w.is_focused ? Object.assign({}, w, { is_focused: false }) : w);
                    focusedWindowId = win.id;
                }
                list.push(win);
                windows = list;
                break;
            }
        case "WindowClosed":
            windows = windows.filter(w => w.id !== d.id);
            if (focusedWindowId === d.id)
                focusedWindowId = null;
            break;
        case "WindowFocusChanged":
            focusedWindowId = d.id;
            windows = windows.map(w => (w.is_focused !== (w.id === d.id)) ? Object.assign({}, w, { is_focused: w.id === d.id }) : w);
            break;
        case "WindowUrgencyChanged":
            windows = windows.map(w => w.id === d.id ? Object.assign({}, w, { is_urgent: d.urgent }) : w);
            break;
        case "WindowLayoutsChanged":
            {
                const changes = {};
                for (const [id, layout] of d.changes)
                    changes[id] = layout;
                windows = windows.map(w => w.id in changes ? Object.assign({}, w, { layout: changes[w.id] }) : w);
                break;
            }
        case "OverviewOpenedOrClosed":
            overviewOpen = d.is_open;
            break;
        case "KeyboardLayoutsChanged":
            keyboardLayouts = d.keyboard_layouts.names;
            keyboardLayoutIndex = d.keyboard_layouts.current_idx;
            break;
        case "KeyboardLayoutSwitched":
            keyboardLayoutIndex = d.idx;
            break;
        }
    }
}
