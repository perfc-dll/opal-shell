import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Thumbnail grid of ~/Pictures/wallpapers; rises from the bottom.
PanelSurface {
    id: root

    name: "wallpaper"
    edge: "bottom"
    panelWidth: Math.min(1080, (screen?.width ?? 1920) - 80)
    panelHeight: Math.min(660, (screen?.height ?? 1200) - 140)

    property string filter: ""

    FolderListModel {
        id: filtered
        folder: "file://" + Wallpapers.folder
        nameFilters: ["jpg", "jpeg", "png", "webp", "bmp"].map(e => "*" + root.filter + "*." + e)
        caseSensitive: false
        showDirs: false
        sortField: FolderListModel.Time
    }

    onShownChanged: {
        if (shown) {
            filter = "";
            search.text = "";
            search.forceActiveFocus();
            Wallpapers.generateThumbs();
        }
    }

    Glass {
        anchors.fill: parent
        radius: Theme.popRadius
        glow: true

        Item {
            id: head
            x: 20
            y: 16
            width: parent.width - 40
            height: 44

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "wallpaper"
                    size: 24
                    fill: 1
                    color: Theme.violet
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wallpapers"
                    font.pixelSize: Theme.fontXl
                    font.weight: 700
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Wallpapers.model.count + " images"
                    color: Theme.dim
                    font.pixelSize: Theme.fontSm
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: 240
                    height: 36
                    radius: 12
                    color: Theme.layer1
                    border.width: 1
                    border.color: search.activeFocus ? Theme.alpha(Theme.violet, 0.6) : Theme.rim
                    MaterialIcon {
                        id: si
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "search"
                        size: 18
                        color: Theme.subtext
                    }
                    TextInput {
                        id: search
                        anchors.left: si.right
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontMd
                        clip: true
                        onTextChanged: root.filter = text.replace(/[*?\[\]]/g, "")
                        Keys.onEscapePressed: Ui.close()
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            text: "Filter by name"
                            color: Theme.dim
                        }
                    }
                }
                IconButton {
                    icon: "shuffle"
                    onClicked: Wallpapers.random()
                }
                IconButton {
                    icon: "palette"
                    active: Settings.adaptiveColors
                    onClicked: Settings.adaptiveColors = !Settings.adaptiveColors
                }
                IconButton {
                    icon: "folder_open"
                    onClicked: {
                        Qt.openUrlExternally("file://" + Wallpapers.folder);
                        Ui.close();
                    }
                }
                IconButton {
                    icon: "close"
                    onClicked: Ui.close()
                }
            }
        }

        GridView {
            id: grid
            x: 14
            anchors.top: head.bottom
            anchors.topMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            width: parent.width - 28
            clip: true
            model: filtered
            cellWidth: Math.floor(width / 4)
            cellHeight: Math.round(cellWidth * 0.625) + 30
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 600

            delegate: Item {
                id: cell
                required property string filePath
                required property string fileName
                readonly property bool current: Wallpapers.current === filePath
                readonly property string thumb: Wallpapers.thumbReady[filePath] ? "file://" + Wallpapers.thumbFor(filePath) : ""

                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    id: frame
                    x: 6
                    y: 6
                    width: parent.width - 12
                    height: Math.round(width * 0.625)
                    radius: 16
                    color: "transparent"
                    border.width: cell.current ? 0 : 1
                    border.color: Theme.rim
                    scale: hover.hovered ? 1.035 : 1
                    z: hover.hovered ? 2 : 0
                    Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

                    // gradient ring around the current wallpaper
                    Rectangle {
                        visible: cell.current
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: 19
                        gradient: AccentGradient {}
                    }

                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: cell.current ? 1 : 0
                        radius: 16
                        color: Theme.layer1

                        Image {
                            id: thumbImg
                            anchors.fill: parent
                            // originals are only decoded if thumbnailing gave up on them
                            source: cell.thumb !== "" ? cell.thumb : Wallpapers.thumbsDone ? "file://" + cell.filePath : ""
                            sourceSize: Qt.size(512, 320)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.normal } }
                        }
                        MaterialIcon {
                            anchors.centerIn: parent
                            visible: thumbImg.status !== Image.Ready
                            icon: "image"
                            size: 28
                            color: Theme.dim
                        }
                    }

                    Rectangle {
                        visible: cell.current
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        width: 26
                        height: 26
                        radius: 13
                        gradient: AccentGradient {}
                        MaterialIcon {
                            anchors.centerIn: parent
                            icon: "check"
                            size: 17
                            weight: 700
                            color: Theme.accentInk
                        }
                    }
                }

                StyledText {
                    anchors.top: frame.bottom
                    anchors.topMargin: 6
                    x: 10
                    width: parent.width - 20
                    text: cell.fileName.replace(/\.[^.]+$/, "")
                    font.pixelSize: Theme.fontXs
                    color: cell.current ? Theme.text : Theme.dim
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: frame
                    onClicked: Wallpapers.set(cell.filePath)
                }
            }
        }
    }
}
