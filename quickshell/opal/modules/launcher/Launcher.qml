import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Spotlight-style launcher that drops from the top.
//   plain text  -> apps (ranked by match + how often you launch them)
//   = or math   -> calculator (Enter copies the result)
//   >cmd        -> run a shell command (Shift+Enter: in the terminal)
//   ?words      -> web search
//   Tab         -> switch to clipboard history (also Mod+V)
PanelSurface {
    id: root

    name: "launcher"
    edge: "top"
    panelWidth: 660
    panelHeight: 540
    offset: Math.round((screen?.height ?? 1200) * 0.14)

    property string query: ""
    readonly property string mode: Ui.launcherMode
    readonly property string prefix: mode === "apps" ? query.charAt(0) : ""
    readonly property bool isRun: prefix === ">"
    readonly property bool isWeb: prefix === "?"
    readonly property string calcResult: mode === "apps" ? calculate(query) : ""

    readonly property var results: {
        if (mode === "clipboard") {
            const q = query.toLowerCase();
            return Clipboard.entries.filter(e => q === "" || e.text.toLowerCase().includes(q)).slice(0, 80);
        }
        if (isRun || isWeb)
            return [];
        return Apps.search(query).slice(0, 60);
    }

    onShownChanged: {
        if (shown) {
            query = "";
            input.text = "";
            list.currentIndex = 0;
            input.forceActiveFocus();
            if (mode === "clipboard")
                Clipboard.refresh();
        }
    }
    onModeChanged: {
        list.currentIndex = 0;
        if (mode === "clipboard")
            Clipboard.refresh();
    }

    function calculate(q) {
        let expr = q.trim();
        const forced = expr.startsWith("=");
        if (forced)
            expr = expr.slice(1);
        if (expr === "")
            return "";
        if (!forced && !(/\d/.test(expr) && /[+\-*/^%()]/.test(expr) && /^[\d\s+\-*/().,^%a-z]+$/i.test(expr)))
            return "";
        const fns = { sqrt: "Math.sqrt", sin: "Math.sin", cos: "Math.cos", tan: "Math.tan", abs: "Math.abs", ln: "Math.log", log: "Math.log10", round: "Math.round", floor: "Math.floor", ceil: "Math.ceil", pow: "Math.pow", min: "Math.min", max: "Math.max", pi: "Math.PI", e: "Math.E" };
        let ok = true;
        const js = expr.replace(/,/g, ".").replace(/\^/g, "**").replace(/[a-z]+/gi, w => {
            const f = fns[w.toLowerCase()];
            if (!f)
                ok = false;
            return f ?? w;
        });
        if (!ok || /[^\d\s+\-*/().%A-Za-z0-9_]/.test(js.replace(/\*\*/g, "*")))
            return "";
        try {
            const v = Function('"use strict"; return (' + js + ");")();
            if (typeof v !== "number" || !isFinite(v))
                return "";
            return String(Math.round(v * 1e10) / 1e10);
        } catch (e) {
            return "";
        }
    }

    function accept(shift) {
        if (calcResult !== "" && (list.currentIndex <= 0 || results.length === 0)) {
            Quickshell.execDetached(["wl-copy", calcResult]);
            Ui.close();
            return;
        }
        if (isRun) {
            const cmd = query.slice(1).trim();
            if (cmd !== "") {
                if (shift)
                    Quickshell.execDetached([Settings.terminal, "-e", "sh", "-c", cmd + "; exec $SHELL"]);
                else
                    Quickshell.execDetached(["sh", "-c", cmd]);
            }
            Ui.close();
            return;
        }
        if (isWeb) {
            Qt.openUrlExternally(Apps.searchUrl(query.slice(1).trim()));
            Ui.close();
            return;
        }
        const item = results[list.currentIndex];
        if (!item)
            return;
        if (mode === "clipboard")
            Clipboard.copy(item);
        else
            Apps.launch(item);
        Ui.close();
    }

    Glass {
        anchors.fill: parent
        radius: Theme.popRadius
        glow: true

        // ---- search field ------------------------------------------------------------
        Rectangle {
            id: field
            x: 16
            y: 16
            width: parent.width - 32
            height: 54
            radius: 18
            color: Theme.layer1
            border.width: 1
            border.color: input.activeFocus ? Theme.alpha(Theme.violet, 0.6) : Theme.rim
            Behavior on border.color { ColorAnimation { duration: Theme.fast } }

            MaterialIcon {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                icon: root.mode === "clipboard" ? "content_paste" : root.isRun ? "terminal" : root.isWeb ? "travel_explore" : root.calcResult !== "" ? "calculate" : "search"
                size: 22
                color: Theme.violet
                fill: 1
            }

            TextInput {
                id: input
                anchors.left: searchIcon.right
                anchors.leftMargin: 12
                anchors.right: modeChips.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 18
                font.weight: 450
                selectionColor: Theme.alpha(Theme.violet, 0.6)
                selectedTextColor: Theme.text
                clip: true
                focus: true
                onTextChanged: {
                    root.query = text;
                    list.currentIndex = 0;
                }

                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Down || (e.key === Qt.Key_J && e.modifiers & Qt.ControlModifier) || (e.key === Qt.Key_N && e.modifiers & Qt.ControlModifier)) {
                        list.incrementCurrentIndex();
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Up || (e.key === Qt.Key_K && e.modifiers & Qt.ControlModifier) || (e.key === Qt.Key_P && e.modifiers & Qt.ControlModifier)) {
                        list.decrementCurrentIndex();
                        e.accepted = true;
                    } else if (e.key === Qt.Key_PageDown) {
                        list.currentIndex = Math.min(list.count - 1, list.currentIndex + 7);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_PageUp) {
                        list.currentIndex = Math.max(0, list.currentIndex - 7);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        root.accept(e.modifiers & Qt.ShiftModifier);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
                        Ui.launcherMode = root.mode === "apps" && Clipboard.available ? "clipboard" : "apps";
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Delete && root.mode === "clipboard" && root.results[list.currentIndex]) {
                        Clipboard.remove(root.results[list.currentIndex]);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Escape) {
                        Ui.close();
                        e.accepted = true;
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text === ""
                    text: root.mode === "clipboard" ? "Search clipboard history…" : "Search apps, = math, > command, ? web"
                    color: Theme.dim
                    font.pixelSize: 17
                }
            }

            Row {
                id: modeChips
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Repeater {
                    model: Clipboard.available ? [["apps", "apps"], ["clipboard", "content_paste"]] : []
                    Rectangle {
                        required property var modelData
                        readonly property bool on: root.mode === modelData[0]
                        width: 34
                        height: 30
                        radius: 10
                        color: on ? "transparent" : chipArea.containsMouse ? Theme.layer2 : "transparent"
                        gradient: on ? chipGrad : null
                        AccentGradient { id: chipGrad; strength: 0.85 }
                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: modelData[1]
                            size: 17
                            fill: parent.on ? 1 : 0
                            color: parent.on ? Theme.accentInk : Theme.subtext
                        }
                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Ui.launcherMode = modelData[0];
                                input.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // ---- calculator / run / web banner ----------------------------------------------
        Rectangle {
            id: banner
            x: 16
            anchors.top: field.bottom
            anchors.topMargin: 10
            width: parent.width - 32
            height: visible ? 58 : 0
            radius: 16
            visible: root.calcResult !== "" || root.isRun || root.isWeb
            color: Theme.alpha(Theme.violet, 0.16)
            border.width: 1
            border.color: Theme.alpha(Theme.violet, 0.4)

            MaterialIcon {
                id: bannerIcon
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                icon: root.isRun ? "terminal" : root.isWeb ? "travel_explore" : "equal"
                size: 22
                fill: 1
                color: Theme.pink
            }
            Column {
                anchors.left: bannerIcon.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                StyledText {
                    width: parent.width
                    text: root.isRun ? root.query.slice(1).trim() || "Type a command" : root.isWeb ? root.query.slice(1).trim() || "Type to search the web" : root.calcResult
                    font.pixelSize: root.calcResult !== "" && !root.isRun && !root.isWeb ? 22 : Theme.fontLg
                    font.weight: 650
                    font.family: root.isRun ? Theme.monoFont : Theme.font
                }
                StyledText {
                    width: parent.width
                    text: root.isRun ? "Enter: run  ·  Shift+Enter: run in " + Settings.terminal : root.isWeb ? "Enter: search " + Apps.engineName : "Enter: copy result"
                    font.pixelSize: Theme.fontXs
                    color: Theme.subtext
                }
            }
        }

        // ---- results ------------------------------------------------------------------------
        ListView {
            id: list
            x: 12
            anchors.top: banner.visible ? banner.bottom : field.bottom
            anchors.topMargin: 10
            anchors.bottom: footer.top
            anchors.bottomMargin: 6
            width: parent.width - 24
            clip: true
            spacing: 2
            model: root.results
            currentIndex: 0
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 140
            highlightResizeDuration: 0
            keyNavigationEnabled: false

            highlight: Rectangle {
                radius: 14
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.alpha(Theme.pink, 0.34) }
                    GradientStop { position: 0.6; color: Theme.alpha(Theme.violet, 0.30) }
                    GradientStop { position: 1; color: Theme.alpha(Theme.cyan, 0.26) }
                }
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool selected: ListView.isCurrentItem
                readonly property bool isClip: root.mode === "clipboard"

                width: list.width
                height: isClip ? 44 : 54

                Item {
                    id: iconBox
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: row.isClip ? 26 : 36
                    height: width

                    IconImage {
                        anchors.fill: parent
                        visible: !row.isClip
                        source: row.isClip ? "" : Apps.iconFor(row.modelData)
                        asynchronous: true
                    }
                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: row.isClip
                        icon: row.isClip && row.modelData.text.startsWith("[[ binary") ? "image" : "content_paste"
                        size: 18
                        color: row.selected ? Theme.text : Theme.subtext
                    }
                }

                Column {
                    anchors.left: iconBox.right
                    anchors.leftMargin: 12
                    anchors.right: hint.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    StyledText {
                        width: parent.width
                        text: row.isClip ? row.modelData.text.replace(/\s+/g, " ") : row.modelData.name
                        font.pixelSize: row.isClip ? Theme.fontMd : Theme.fontLg - 1
                        font.weight: row.isClip ? 450 : 600
                    }
                    StyledText {
                        width: parent.width
                        visible: !row.isClip && text !== ""
                        text: row.isClip ? "" : (row.modelData.comment || row.modelData.genericName || "")
                        font.pixelSize: Theme.fontSm
                        color: row.selected ? Theme.subtext : Theme.dim
                    }
                }

                StyledText {
                    id: hint
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↵"
                    opacity: row.selected ? 0.8 : 0
                    font.pixelSize: Theme.fontLg
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: list.currentIndex = row.index
                    onClicked: {
                        list.currentIndex = row.index;
                        root.accept(false);
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: list.count === 0 && !banner.visible
                text: root.mode === "clipboard" ? (Clipboard.entries.length === 0 ? "Clipboard history is empty" : "No matches") : "No apps match “" + root.query + "”"
                color: Theme.dim
            }
        }

        // ---- footer -----------------------------------------------------------------------
        Item {
            id: footer
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            x: 20
            width: parent.width - 40
            height: 18

            StyledText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.mode === "clipboard" ? root.results.length + " entries" : root.results.length + " apps"
                font.pixelSize: Theme.fontXs
                color: Theme.dim
            }
            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.mode === "clipboard" ? "↵ copy   del remove   ⇥ apps   esc close" : "↵ open   ↑↓ move   ⇥ clipboard   esc close"
                font.pixelSize: Theme.fontXs
                color: Theme.dim
            }
        }
    }
}
