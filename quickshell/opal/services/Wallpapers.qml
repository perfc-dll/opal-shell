pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Current wallpaper + the picker's folder model + a thumbnail cache
// (~/.cache/opal/thumbs) generated in the background with ImageMagick.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string thumbDir: home + "/.cache/opal/thumbs"
    readonly property string folder: Settings.wallpaperDir
    property string current: Settings.wallpaper
    property var thumbReady: ({})
    property bool thumbsDone: false
    readonly property alias model: folderModel

    function set(path) {
        if (!path || path === current)
            return;
        Settings.wallpaper = path;
    }

    function random() {
        if (folderModel.count === 0)
            return;
        let p = current;
        for (let i = 0; i < 6 && p === current; i++)
            p = folderModel.get(Math.floor(Math.random() * folderModel.count), "filePath");
        set(p);
    }

    function thumbFor(path) {
        return thumbDir + "/" + Qt.md5(path) + ".jpg";
    }

    function generateThumbs() {
        if (thumbGen.running || folderModel.count === 0)
            return;
        const files = [];
        for (let i = 0; i < folderModel.count; i++)
            files.push(folderModel.get(i, "filePath"));
        thumbGen.command = ["nice", "-n", "15", "sh", Quickshell.shellPath("scripts/thumbs.sh"), thumbDir, ...files];
        thumbGen.running = true;
    }

    onCurrentChanged: if (current !== Settings.wallpaper) Settings.wallpaper = current

    function inheritIfUnset() {
        if (Settings.ready && Settings.wallpaper === "" && !waypaperProbe.running)
            waypaperProbe.running = true;
    }
    Component.onCompleted: inheritIfUnset()

    Connections {
        target: Settings
        function onWallpaperChanged() {
            root.current = Settings.wallpaper;
        }
        function onReadyChanged() {
            root.inheritIfUnset();
        }
    }

    // First run: inherit whatever waypaper had set in the regular niri session.
    Process {
        id: waypaperProbe
        command: ["sh", "-c", "sed -n 's/^wallpaper *= *//p' \"$HOME/.config/waypaper/config.ini\" 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = text.trim();
                if (p.startsWith("~"))
                    p = root.home + p.slice(1);
                if (p !== "")
                    root.set(p);
            }
        }
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + root.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Time
        onStatusChanged: if (status === FolderListModel.Ready) root.generateThumbs()
        onCountChanged: thumbDebounce.restart()
    }

    Timer {
        id: thumbDebounce
        interval: 1500
        onTriggered: root.generateThumbs()
    }

    Process {
        id: thumbGen
        onRunningChanged: if (running) root.thumbsDone = false
        onExited: root.thumbsDone = true
        stdout: SplitParser {
            onRead: line => {
                const m = Object.assign({}, root.thumbReady);
                m[line] = true;
                root.thumbReady = m;
            }
        }
    }
}
