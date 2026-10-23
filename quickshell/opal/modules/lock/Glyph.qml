import QtQuick
import QtQuick.Shapes
import qs.config

// One alien glyph. Its strokes come from a seeded random generator keyed on
// the lock's salt and the glyph's position, never on the character typed, so
// the glyphs reveal nothing about the password.
Item {
    id: root

    property int seed: 0
    property color ink: "#ece6f2"
    property real strokeWidth: 1.6
    property real k: 1.4          // drawn on a 16x26 grid, shown k times larger

    implicitWidth: 16 * k
    implicitHeight: 26 * k

    // mulberry32
    function rng(a) {
        return function () {
            a |= 0;
            a = a + 0x6D2B79F5 | 0;
            let t = Math.imul(a ^ a >>> 15, 1 | a);
            t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
            return ((t ^ t >>> 14) >>> 0) / 4294967296;
        };
    }

    // A glyph is built on a 3x5 grid of anchor points inside 16x26:
    // a spine, then two or three marks from a small vocabulary.
    readonly property string path: {
        const r = rng(seed);
        const X = [2, 8, 14], Y = [2, 7.5, 13, 18.5, 24];
        const pick = n => Math.floor(r() * n);
        let p = "";
        // spine: vertical, slanted or arched
        const spine = pick(3);
        if (spine === 0)
            p += `M8 ${Y[pick(2)]} L8 ${Y[3 + pick(2)]} `;
        else if (spine === 1)
            p += `M${X[pick(2) * 2]} 3 L${X[2 - pick(2) * 2]} 23 `;
        else
            p += `M2 20 Q8 ${-2 + pick(6)} 14 20 `;
        const marks = 2 + pick(2);
        for (let i = 0; i < marks; i++) {
            const kind = pick(6);
            const x = X[pick(3)], y = Y[pick(5)];
            switch (kind) {
            case 0: // short bar
                p += `M${Math.max(1, x - 5)} ${y} L${Math.min(15, x + 5)} ${y} `;
                break;
            case 1: // hook
                p += `M${x} ${y} l0 5 q0 3 ${x > 8 ? -4 : 4} 3 `;
                break;
            case 2: // small ring
                p += `M${x + 2.2} ${y} a2.2 2.2 0 1 0 -4.4 0 a2.2 2.2 0 1 0 4.4 0 `;
                break;
            case 3: // arc cap
                p += `M${Math.max(1, x - 5)} ${y + 2} Q${x} ${y - 4} ${Math.min(15, x + 5)} ${y + 2} `;
                break;
            case 4: // tick
                p += `M${x} ${y} l${x > 8 ? -4 : 4} -4 `;
                break;
            default: // dot
                p += `M${x + 0.9} ${y} a0.9 0.9 0 1 0 -1.8 0 a0.9 0.9 0 1 0 1.8 0 `;
            }
        }
        return p;
    }

    Shape {
        width: 16
        height: 26
        scale: root.k
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.ink
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: root.path }
        }
    }
}
