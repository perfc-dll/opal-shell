pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Session lock state + password check.
//
// Only a PAM success ever sets `locked` back to false. Authentication uses
// the shell's own pam/password config (pam_unix only), so an enrolled
// fingerprint can't stall the password prompt.
//
// Crash safety: while locked, a flag file sits in $XDG_RUNTIME_DIR. If the
// shell dies, niri keeps the screen locked, and when systemd restarts the
// shell it sees the flag and takes the lock over again.
Singleton {
    id: root

    property bool locked: false
    property bool secure: false             // niri has confirmed the lock (set by LockScreen)
    property string state: "idle"          // idle | verifying | failed | success
    property string message: ""
    property int failures: 0
    property real cooldownUntil: 0
    property string primaryScreen: ""
    property int salt: 0                    // reshuffles the password glyphs every lock

    // preview mode: the same screen without any locking or PAM
    property bool previewing: false

    readonly property bool busy: state === "verifying" || state === "success"
    readonly property string flagFile: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/opal-locked"
    readonly property int unlockDuration: Settings.reduceMotion ? 250 : 950

    property string _pending: ""

    signal attemptFailed
    signal unlockStarted

    function lock() {
        if (locked)
            return;
        prepare();
        locked = true;
        Quickshell.execDetached(["touch", flagFile]);
    }

    function preview() {
        if (locked)
            return;
        prepare();
        previewing = true;
    }

    function prepare() {
        salt = Math.floor(Math.random() * 1000000000);
        primaryScreen = Ui.focusedScreenName();
        state = "idle";
        message = "";
        _pending = "";
        Ui.close();
    }

    function submit(password) {
        if (busy || password.length === 0)
            return false;
        const wait = Math.ceil((cooldownUntil - Date.now()) / 1000);
        if (wait > 0) {
            message = "Wait " + wait + " s";
            return false;
        }
        state = "verifying";
        message = "";

        if (previewing) {
            // no real check in preview: pretend it worked after a moment
            previewTimer.restart();
            return true;
        }

        _pending = password;
        if (!pam.start()) {
            _pending = "";
            fail("Couldn't start the password check");
        }
        return true;
    }

    function fail(text) {
        failures++;
        if (failures >= 3)
            cooldownUntil = Date.now() + Math.min(30, 2 * (failures - 2)) * 1000;
        state = "failed";
        message = text;
        attemptFailed();
        failReset.restart();
    }

    function succeed() {
        failures = 0;
        cooldownUntil = 0;
        state = "success";
        message = "";
        unlockStarted();
        unlockTimer.restart();
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("pam")
        config: "password"

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root._pending);
                root._pending = "";
            }
        }
        onCompleted: result => {
            root._pending = "";
            if (result === PamResult.Success)
                root.succeed();
            else if (result === PamResult.MaxTries)
                root.fail("Too many tries");
            else
                root.fail("Not recognised");
        }
        onError: error => {
            root._pending = "";
            root.fail("Authentication error (" + PamError.toString(error) + ")");
        }
    }

    Timer {
        id: unlockTimer
        interval: root.unlockDuration
        onTriggered: {
            if (root.previewing) {
                root.previewing = false;
            } else {
                root.locked = false;
                Quickshell.execDetached(["rm", "-f", root.flagFile]);
            }
            root.state = "idle";
        }
    }

    Timer {
        id: failReset
        interval: 1600
        onTriggered: if (root.state === "failed") root.state = "idle"
    }

    Timer {
        id: previewTimer
        interval: 900
        onTriggered: root.succeed()
    }

    function endPreview() {
        if (previewing && state !== "success") {
            previewing = false;
            state = "idle";
        }
    }

    // take the lock back over after a crash/restart
    Process {
        running: true
        command: ["test", "-e", root.flagFile]
        onExited: code => {
            if (code === 0)
                root.lock();
        }
    }
}
