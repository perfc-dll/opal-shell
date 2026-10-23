pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

// Opal design tokens. The signature palette is the same pink -> violet -> cyan
// as the niri focus borders in niri/opal.kdl; "adaptive" mode
// swaps the three accents for the most vivid colours in the wallpaper.
Singleton {
    id: root

    // ---- accents ------------------------------------------------------------------
    // Each preset is [start, middle, end] of the accent sweep. The property
    // names stay pink/violet/cyan after the signature palette.
    readonly property var presets: ({
            opal: { name: "Opal", colors: ["#f472b6", "#a855f7", "#65c8ff"] },
            sakura: { name: "Sakura", colors: ["#ffafcc", "#f472b6", "#ffd6a5"] },
            ocean: { name: "Ocean", colors: ["#38bdf8", "#6366f1", "#2dd4bf"] },
            aurora: { name: "Aurora", colors: ["#34d399", "#22d3ee", "#a78bfa"] },
            sunset: { name: "Sunset", colors: ["#fb923c", "#f43f5e", "#facc15"] },
            crimson: { name: "Crimson", colors: ["#f43f5e", "#be123c", "#fb7185"] },
            mint: { name: "Mint", colors: ["#a7f3d0", "#5eead4", "#bae6fd"] },
            mono: { name: "Mono", colors: ["#f4f4f5", "#a1a1aa", "#e4e4e7"] }
        })
    readonly property var presetOrder: ["opal", "sakura", "ocean", "aurora", "sunset", "crimson", "mint", "mono"]
    readonly property var preset: (presets[Settings.accentPreset] ?? presets.opal).colors

    readonly property bool adaptive: Settings.adaptiveColors && adaptivePalette.length >= 3
    property color pink: adaptive ? adaptivePalette[0] : preset[0]
    property color violet: adaptive ? adaptivePalette[1] : preset[1]
    property color cyan: adaptive ? adaptivePalette[2] : preset[2]
    readonly property color accent: Qt.tint(violet, Qt.rgba(pink.r, pink.g, pink.b, 0.35))

    Behavior on pink { ColorAnimation { duration: 600 } }
    Behavior on violet { ColorAnimation { duration: 600 } }
    Behavior on cyan { ColorAnimation { duration: 600 } }

    // ---- neutrals -------------------------------------------------------------
    readonly property color glass: Qt.rgba(0.075, 0.06, 0.105, Settings.glassOpacity)
    readonly property color glassStrong: Qt.rgba(0.075, 0.06, 0.105, Math.min(0.92, Settings.glassOpacity + 0.25))
    readonly property color layer1: Qt.rgba(1, 1, 1, 0.055)
    readonly property color layer2: Qt.rgba(1, 1, 1, 0.09)
    readonly property color layer3: Qt.rgba(1, 1, 1, 0.14)
    readonly property color rim: Qt.rgba(1, 1, 1, 0.10)
    readonly property color rimBright: Qt.rgba(1, 1, 1, 0.22)

    readonly property color text: "#f2eefb"
    readonly property color subtext: "#bcb5cc"
    readonly property color dim: "#7f7893"
    readonly property color accentInk: "#160f1f"

    readonly property color good: "#a6e3a1"
    readonly property color warn: "#f9e2af"
    readonly property color bad: "#f38ba8"

    // ---- type -------------------------------------------------------------------
    readonly property string font: "Inter Variable"
    readonly property string monoFont: "Hack Nerd Font Mono"
    readonly property string iconFont: "Material Symbols Rounded"

    readonly property real fontScale: Math.max(0.8, Math.min(1.4, Settings.fontScale))
    readonly property int fontXs: Math.round(10 * fontScale)
    readonly property int fontSm: Math.round(11 * fontScale)
    readonly property int fontMd: Math.round(13 * fontScale)
    readonly property int fontLg: Math.round(15 * fontScale)
    readonly property int fontXl: Math.round(20 * fontScale)

    // ---- geometry -----------------------------------------------------------------
    readonly property int barHeight: 42
    readonly property int barMargin: 8
    readonly property int barSide: 10
    readonly property int barRadius: 16
    readonly property int panelRadius: 24
    readonly property int popRadius: 26
    readonly property int toastRadius: 18
    readonly property int tileRadius: 16
    readonly property int chipRadius: 12
    readonly property int gap: 10

    // ---- motion ---------------------------------------------------------------------
    // `motion` is false with "Reduce motion": decorative loops stop and
    // transitions become quick fades.
    readonly property bool motion: !Settings.reduceMotion
    readonly property real timeScale: motion ? 1 / Math.max(0.25, Settings.animationSpeed) : 0.4
    readonly property int fast: Math.round(140 * timeScale)
    readonly property int normal: Math.round(240 * timeScale)
    readonly property int slow: Math.round(420 * timeScale)
    readonly property var emphasized: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]

    // ---- helpers ----------------------------------------------------------------------
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    // ---- adaptive palette from the wallpaper ----------------------------------------
    property var adaptivePalette: []

    ColorQuantizer {
        id: quantizer
        source: Settings.adaptiveColors && Wallpapers.current !== "" ? "file://" + Wallpapers.current : ""
        depth: 4
        rescaleSize: 96
        onColorsChanged: root.adaptivePalette = root.pickAccents(colors)
    }

    // Picks three vivid, mutually distinct hues and normalises them into the
    // same luminous pastel range as the signature palette, so text on top of
    // them stays readable whatever the wallpaper looks like.
    function pickAccents(colors) {
        const scored = [];
        for (const c of colors) {
            const s = c.hsvSaturation, v = c.hsvValue;
            if (v < 0.18)
                continue;
            scored.push({ c: c, score: s * 0.7 + v * 0.3, h: c.hsvHue });
        }
        scored.sort((a, b) => b.score - a.score);
        const picked = [];
        for (const s of scored) {
            if (picked.every(p => hueDistance(p.h, s.h) > 0.08))
                picked.push(s);
            if (picked.length === 3)
                break;
        }
        if (picked.length === 0)
            return [];
        while (picked.length < 3) {
            const base = picked[picked.length - 1];
            picked.push({ h: (base.h + 0.12) % 1.0 });
        }
        return picked.map(p => Qt.hsva(p.h < 0 ? 0 : p.h, 0.62, 0.98, 1.0));
    }

    function hueDistance(a, b) {
        if (a < 0 || b < 0)
            return 1;
        const d = Math.abs(a - b);
        return Math.min(d, 1 - d);
    }
}
