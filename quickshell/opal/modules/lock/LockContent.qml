import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

// Everything drawn on a lock surface. `primary` is the screen that takes the
// password; other screens only show the ring and the clock.
Item {
    id: root

    property bool primary: true

    readonly property real s: Math.min(width, height)
    readonly property real ringFrac: 0.245
    readonly property real ringR: s * ringFrac
    readonly property color bone: "#ece6f2"
    readonly property color pearlDim: "#a59eb4"
    readonly property color ember: "#e6a593"

    property real lastInput: Date.now()
    property real idleFor: 0
    property int frozenCount: -1
    readonly property int glyphCount: frozenCount >= 0 ? frozenCount : input.text.length
    readonly property bool unlocking: Lock.state === "success"

    // ---- backdrop texture: the wallpaper, small and blurred --------------------------
    Item {
        id: wallLayer
        width: 480
        height: Math.round(480 * root.height / Math.max(1, root.width))

        Image {
            id: wallImg
            anchors.fill: parent
            source: Wallpapers.current ? "file://" + Wallpapers.current : ""
            sourceSize: Qt.size(960, 600)
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wallImg
            blurEnabled: true
            blur: 1.0
            blurMax: 32
        }
    }
    ShaderEffectSource {
        id: wallTex
        sourceItem: wallLayer
        hideSource: true
        live: false
        recursive: false
        Component.onCompleted: scheduleUpdate()
        Connections {
            target: wallImg
            function onStatusChanged() {
                if (wallImg.status === Image.Ready)
                    wallTex.scheduleUpdate();
            }
        }
    }

    // ---- the field + ring (GPU) -------------------------------------------------------
    ShaderEffect {
        id: fx
        anchors.fill: parent
        fragmentShader: "file://" + Quickshell.shellPath("shaders/opal_core.frag.qsb")

        property real time: 0
        property real spin: 0
        property real energy: 0
        property real verify: Lock.state === "verifying" ? 1 : 0
        property real fail: 0
        property real success: 0
        property real birth: 0
        property real radius: root.ringFrac
        property vector2d resolution: Qt.vector2d(width, height)
        property color tintA: Theme.pink
        property color tintB: Theme.violet
        property color tintC: Theme.cyan
        property var backdrop: wallTex

        Behavior on verify {
            NumberAnimation { duration: Theme.slow; easing.type: Easing.InOutCubic }
        }
    }

    NumberAnimation {
        id: birthAnim
        target: fx
        property: "birth"
        from: 0
        to: 1
        duration: Theme.motion ? 1600 : 300
        easing.type: Easing.OutCubic
        running: true
    }

    NumberAnimation {
        id: successAnim
        target: fx
        property: "success"
        from: 0
        to: 1
        duration: Lock.unlockDuration
        easing.type: Easing.InCubic
    }

    Connections {
        target: Lock
        function onUnlockStarted() {
            successAnim.restart();
        }
        function onAttemptFailed() {
            fx.fail = 1;
            shake.restart();
        }
        function onStateChanged() {
            if (Lock.state === "idle") {
                root.frozenCount = -1;
                if (fx.success > 0 && !Lock.locked && !Lock.previewing)
                    fx.success = 0;
            }
        }
    }

    // ---- animation clock: full rate while active, slower when idle, then still --------
    function step(dt) {
        fx.time += dt;
        fx.spin += dt * (0.035 + fx.verify * 1.4);
        fx.energy *= Math.exp(-dt * 2.2);
        fx.fail *= Math.exp(-dt * 1.4);
        const now = new Date();
        orbit.secFrac = (now.getSeconds() + now.getMilliseconds() / 1000) / 60;
    }

    FrameAnimation {
        running: root.visible && (root.idleFor < 25 || Lock.state !== "idle" || fx.birth < 1)
        onTriggered: root.step(frameTime)
    }
    Timer {
        // idle: ~12 fps for a few minutes, then the picture holds still
        interval: 83
        repeat: true
        running: root.visible && root.idleFor >= 25 && root.idleFor < 240 && Lock.state === "idle" && fx.birth >= 1
        onTriggered: root.step(0.083)
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        onTriggered: {
            root.idleFor = (Date.now() - root.lastInput) / 1000;
            if (root.idleFor >= 240)
                root.step(0);      // keep the seconds pearl honest
        }
    }

    function poke() {
        lastInput = Date.now();
        idleFor = 0;
    }

    // ---- clock inside the ring ------------------------------------------------------------
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        id: clockBox
        anchors.centerIn: parent
        width: timeText.implicitWidth
        height: timeText.implicitHeight + dateText.implicitHeight + 6
        opacity: Math.min(1, fx.birth * 1.4) * (1 - Math.min(1, fx.success * 2.5)) * (1 - fx.verify * 0.35)
        scale: 1 - fx.verify * 0.04

        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, Settings.use24h ? "HH:mm" : "h:mm")
            font.family: Theme.font
            font.pixelSize: Math.round(root.s * 0.092)
            font.weight: 180
            font.letterSpacing: root.s * 0.004
            font.features: ({ "tnum": 1 })
            color: root.bone
            visible: false
        }
        Rectangle {
            id: timeFill
            anchors.fill: timeText
            visible: false
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#f7f3fc" }
                GradientStop { position: 1.0; color: Theme.mix(root.bone, Theme.violet, 0.28) }
            }
        }
        OpacityMask {
            anchors.fill: timeText
            source: timeFill
            maskSource: timeText
        }

        Text {
            id: dateText
            anchors.top: timeText.bottom
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd  ·  d MMMM").toUpperCase()
            font.family: Theme.font
            font.pixelSize: Math.max(11, Math.round(root.s * 0.0125))
            font.weight: 550
            font.letterSpacing: root.s * 0.0034
            color: root.pearlDim
        }
    }

    // ---- seconds orbit: a pearl travelling round just outside the ring ----------------
    Item {
        id: orbit
        anchors.centerIn: parent
        width: 1
        height: 1
        visible: Settings.lockOrbit
        opacity: Math.min(1, fx.birth * 1.2) * (1 - fx.verify) * (1 - Math.min(1, fx.success * 3))
        property real secFrac: 0
        readonly property real r: root.ringR + root.s * 0.048

        Repeater {
            model: 12
            Rectangle {
                required property int index
                readonly property real a: index / 12 * Math.PI * 2 - Math.PI / 2
                x: Math.cos(a) * orbit.r - width / 2
                y: Math.sin(a) * orbit.r - height / 2
                width: index % 3 === 0 ? 5 : 3
                height: width
                radius: width / 2
                color: root.bone
                opacity: index % 3 === 0 ? 0.28 : 0.13
            }
        }

        Rectangle {
            readonly property real a: orbit.secFrac * Math.PI * 2 - Math.PI / 2
            x: Math.cos(a) * orbit.r - width / 2
            y: Math.sin(a) * orbit.r - height / 2
            width: 7
            height: 7
            radius: 3.5
            color: "#f6f2fb"

            Rectangle {
                anchors.centerIn: parent
                width: 19
                height: 19
                radius: 9.5
                color: "transparent"
                border.width: 1
                border.color: Theme.alpha(root.bone, 0.25)
            }
        }
    }

    // ---- password glyphs ---------------------------------------------------------------------
    Item {
        id: glyphArea
        visible: root.primary
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + root.ringR + root.s * 0.1
        width: parent.width
        height: 40

        Row {
            id: glyphRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 9
            property real lift: Lock.state === "verifying" ? 1 : 0
            Behavior on lift { NumberAnimation { duration: Theme.slow; easing.type: Easing.InCubic } }
            transform: Translate {
                id: shakeT
                y: -glyphRow.lift * (root.ringR * 0.9)
            }
            property real failFade: 1
            opacity: (1 - glyphRow.lift) * (1 - Math.min(1, fx.success * 3)) * failFade
            scale: 1 - glyphRow.lift * 0.4

            Repeater {
                model: root.glyphCount
                Glyph {
                    id: g
                    required property int index
                    seed: Lock.salt ^ Math.imul(index + 1, 2654435761)
                    ink: Theme.mix(root.bone, index % 3 === 0 ? Theme.pink : index % 3 === 1 ? Theme.violet : Theme.cyan, 0.22)
                    opacity: 0
                    scale: 0.4
                    Component.onCompleted: appear.start()
                    ParallelAnimation {
                        id: appear
                        NumberAnimation { target: g; property: "opacity"; to: 0.92; duration: Theme.normal; easing.type: Easing.OutCubic }
                        NumberAnimation { target: g; property: "scale"; to: 1; duration: Theme.slow; easing.type: Theme.motion ? Easing.OutBack : Easing.OutCubic }
                    }
                }
            }
        }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: shakeT; property: "x"; to: -14; duration: 50 }
            NumberAnimation { target: shakeT; property: "x"; to: 12; duration: 70 }
            NumberAnimation { target: shakeT; property: "x"; to: -8; duration: 60 }
            NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 60 }
            PauseAnimation { duration: 260 }
            NumberAnimation { target: glyphRow; property: "failFade"; to: 0; duration: 220 }
            ScriptAction { script: root.frozenCount = -1 }
            PropertyAction { target: glyphRow; property: "failFade"; value: 1 }
        }

        // hint / status line
        Text {
            id: hint
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.glyphCount > 0 && Lock.state !== "failed" ? 44 : 8
            Behavior on anchors.topMargin { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
            text: {
                if (Lock.state === "failed" || Lock.message !== "")
                    return Lock.message.toUpperCase();
                if (Lock.state === "verifying")
                    return "VERIFYING";
                if (root.capsLock)
                    return "CAPS LOCK IS ON";
                if (root.glyphCount === 0)
                    return Lock.previewing ? "PREVIEW  ·  TYPE ANYTHING, ENTER TO UNLOCK, ESC TO LEAVE" : "TYPE TO UNLOCK";
                return "";
            }
            font.family: Theme.font
            font.pixelSize: Math.max(11, Math.round(root.s * 0.0105))
            font.weight: 600
            font.letterSpacing: root.s * 0.0036
            color: Lock.state === "failed" || Lock.message !== "" ? root.ember : root.capsLock && Lock.state !== "verifying" ? Theme.warn : root.pearlDim
            opacity: text === "" ? 0 : Lock.state === "verifying" ? 0.55 + 0.45 * Math.abs(Math.sin(fx.time * 2.5)) : root.glyphCount === 0 && root.idleFor < 1.5 && Lock.state === "idle" ? 0 : 0.85
            Behavior on opacity { NumberAnimation { duration: Theme.slow } }
        }
    }

    // ---- caps lock (from the keyboard LED) ----------------------------------------------------
    property bool capsLock: false
    property string capsPath: ""
    Process {
        running: root.primary
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.capsPath = text.trim()
        }
    }
    FileView {
        id: capsFile
        path: root.capsPath ? root.capsPath + "/brightness" : ""
        printErrors: false
        onLoaded: root.capsLock = text().trim() !== "0"
    }
    Timer {
        interval: 500
        repeat: true
        running: root.primary && root.visible && root.capsPath !== "" && root.idleFor < 60
        onTriggered: capsFile.reload()
    }

    // ---- the hidden password field ------------------------------------------------------------
    TextInput {
        id: input
        width: 1
        height: 1
        opacity: 0
        enabled: root.primary
        focus: root.primary
        echoMode: TextInput.Password
        maximumLength: 256
        readOnly: Lock.busy

        onTextChanged: {
            root.poke();
            if (text.length > 0) {
                fx.energy = Math.min(1, fx.energy + 0.32);
                if (Lock.state === "failed")
                    Lock.state = "idle";
                Lock.message = "";
            }
        }
        onAccepted: {
            if (text.length === 0)
                return;
            root.frozenCount = text.length;
            const accepted = Lock.submit(text);
            text = "";
            if (!accepted)
                root.frozenCount = -1;
        }
        Keys.onEscapePressed: {
            if (Lock.previewing && text.length === 0)
                Lock.endPreview();
            text = "";
        }
        Keys.onPressed: e => root.poke()
        Component.onCompleted: if (root.primary) forceActiveFocus()
    }

    MouseArea {
        anchors.fill: parent
        onPressed: {
            root.poke();
            input.forceActiveFocus();
        }
        onPositionChanged: root.poke()
        hoverEnabled: true
    }

    // ---- bottom strip: who, what's playing, battery -------------------------------------------
    Item {
        id: strip
        visible: root.primary
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(root.s * 0.04)
        height: 40
        opacity: Math.min(1, fx.birth * 1.3) * (1 - Math.min(1, fx.success * 3)) * (root.idleFor > 30 ? 0.45 : 1)
        Behavior on opacity { NumberAnimation { duration: 800 } }

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: "transparent"
                border.width: 1
                border.color: Theme.alpha(root.bone, 0.4)
                Text {
                    anchors.centerIn: parent
                    text: Account.fullName.charAt(0).toUpperCase()
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: 600
                    color: root.bone
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Account.fullName
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: 550
                font.letterSpacing: 1.5
                color: root.pearlDim
            }
        }

        Row {
            id: media
            visible: Settings.lockMedia && Media.hasPlayer
            anchors.centerIn: parent
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, root.width * 0.3)
                elide: Text.ElideRight
                text: Media.title + (Media.artist ? "  —  " + Media.artist : "")
                font.family: Theme.font
                font.pixelSize: 13
                font.letterSpacing: 0.6
                color: root.pearlDim
            }
            Repeater {
                model: [["skip_previous", () => Media.previous()], [Media.playing ? "pause" : "play_arrow", () => Media.toggle()], ["skip_next", () => Media.next()]]
                MaterialIcon {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    icon: modelData[0]
                    size: 20
                    color: mediaHover.hovered ? root.bone : root.pearlDim
                    HoverHandler { id: mediaHover }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: {
                            parent.modelData[1]();
                            input.forceActiveFocus();
                        }
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Text {
                visible: Niri.keyboardLayouts.length > 1
                anchors.verticalCenter: parent.verticalCenter
                text: Niri.keyboardLayout.slice(0, 2).toUpperCase()
                font.family: Theme.font
                font.pixelSize: 12
                font.weight: 650
                font.letterSpacing: 1.5
                color: root.pearlDim
            }
            Row {
                visible: Power.hasBattery
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Power.batteryIcon
                    rotation: 90
                    size: 18
                    color: Power.charging ? Theme.good : Power.percent < 0.15 ? root.ember : root.pearlDim
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Power.percent * 100) + "%"
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.weight: 550
                    font.letterSpacing: 1
                    color: root.pearlDim
                }
            }
        }
    }
}
