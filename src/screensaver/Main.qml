import QtQuick
import QtMultimedia
import org.kde.layershell as LayerShell

// One overlay window per screen, each running its own shuffled slideshow from a random
// starting point. Two slides per window take turns: the hidden one loads the next file,
// then they crossfade, and the one that faded out drops its file to free the memory.
QtObject {
    id: root

    required property var screens
    required property bool preview
    required property var media
    required property int slideSeconds
    required property bool panZoom
    required property int panZoomStrength

    readonly property int fadeMs: 3000
    // Movement is a fixed slow speed, not "cover this much ground per slide", so short slides
    // don't make it rush. Full strength zooms about 1.2% per second; the default half that.
    readonly property int moveMs: slideSeconds * 1000 + fadeMs * 2
    readonly property real minZoom: 1.04
    readonly property real zoomTravel: Math.min(0.012 * panZoomStrength / 100 * moveMs / 1000, 0.3)
    readonly property real maxZoom: minZoom + zoomTravel

    property Instantiator windows: Instantiator {
        model: root.screens

        delegate: Window {
            id: win
            required property var modelData

            property int position: Math.floor(Math.random() * root.media.length)
            property int front: 0

            function advance() {
                position = (position + 1) % root.media.length
                const _back = slides.itemAt(1 - front)
                _back.entry = root.media[position]
                front = 1 - front
            }

            color: "black"

            // Overlay layer sits above normal windows, fullscreen apps and panels - only the
            // lock screen goes above it. Exclusive keyboard so the key you press to wake the
            // screen doesn't land in whatever app was focused.
            LayerShell.Window.scope: "inno-screensaver"
            LayerShell.Window.layer: LayerShell.Window.LayerOverlay
            LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom
                                       | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
            LayerShell.Window.exclusionZone: -1
            LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityExclusive
            LayerShell.Window.screen: modelData

            // the layer shell settings above only stick if they're in place before the first show
            Component.onCompleted: visible = true

            HoverHandler {
                property point start: Qt.point(-1, -1)
                cursorShape: Qt.BlankCursor
                // the pointer "arriving" when the window appears isn't movement, so only quit
                // once it has actually travelled a bit from where it first showed up
                onPointChanged: {
                    if (!root.preview)
                        return
                    const _at = point.position
                    if (start.x < 0)
                        start = _at
                    else if (Math.abs(_at.x - start.x) + Math.abs(_at.y - start.y) > 20)
                        Qt.quit()
                }
            }

            TapHandler {
                enabled: root.preview
                onPressedChanged: Qt.quit()
            }

            Item {
                focus: true
                Keys.onPressed: if (root.preview) Qt.quit()
            }

            Timer {
                interval: root.slideSeconds * 1000
                repeat: true
                running: root.media.length > 1
                onTriggered: win.advance()
            }

            Repeater {
                id: slides
                model: 2

                delegate: Item {
                    id: slide
                    required property int index
                    property var entry: null
                    readonly property bool shown: win.front === index

                    width: win.width
                    height: win.height
                    clip: true
                    z: shown ? 1 : 0
                    opacity: shown && loader.item && loader.item.ready ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: root.fadeMs }
                    }
                    onOpacityChanged: {
                        if (opacity === 0 && !shown)
                            entry = null
                    }

                    Component.onCompleted: {
                        if (index === 0 && root.media.length > 0)
                            entry = root.media[win.position]
                    }

                    Loader {
                        id: loader
                        anchors.fill: parent
                        sourceComponent: !slide.entry ? null
                                         : slide.entry.kind === "video" ? videoSlide
                                         : slide.entry.kind === "gif" ? gifSlide
                                         : stillSlide
                    }

                    Component {
                        id: stillSlide
                        Image {
                            id: still
                            readonly property bool ready: status === Image.Ready

                            // Ken Burns: slowly zoom in or out (coin flip), drifting between two
                            // random offsets that never show an edge
                            readonly property bool zoomIn: Math.random() < 0.5
                            readonly property real fromScale: zoomIn ? root.minZoom : root.maxZoom
                            readonly property real toScale: zoomIn ? root.maxZoom : root.minZoom
                            readonly property real fromX: (Math.random() * 2 - 1) * (fromScale - 1) * width / 2
                            readonly property real fromY: (Math.random() * 2 - 1) * (fromScale - 1) * height / 2
                            readonly property real toX: (Math.random() * 2 - 1) * (toScale - 1) * width / 2
                            readonly property real toY: (Math.random() * 2 - 1) * (toScale - 1) * height / 2

                            width: slide.width
                            height: slide.height
                            source: slide.entry.source
                            sourceSize: Qt.size(slide.width * root.maxZoom, slide.height * root.maxZoom)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            smooth: true
                            transformOrigin: Item.Center

                            ParallelAnimation {
                                running: root.panZoom && still.ready
                                NumberAnimation { target: still; property: "scale"; from: still.fromScale; to: still.toScale; duration: root.moveMs; easing.type: Easing.InOutSine }
                                NumberAnimation { target: still; property: "x"; from: still.fromX; to: still.toX; duration: root.moveMs; easing.type: Easing.InOutSine }
                                NumberAnimation { target: still; property: "y"; from: still.fromY; to: still.toY; duration: root.moveMs; easing.type: Easing.InOutSine }
                            }
                        }
                    }

                    Component {
                        id: gifSlide
                        AnimatedImage {
                            readonly property bool ready: status === AnimatedImage.Ready
                            source: slide.entry.source
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                            playing: true
                        }
                    }

                    Component {
                        id: videoSlide
                        Video {
                            readonly property bool ready: playbackState === MediaPlayer.PlayingState
                            source: slide.entry.source
                            muted: true
                            loops: MediaPlayer.Infinite
                            fillMode: VideoOutput.PreserveAspectFit
                            autoPlay: true
                        }
                    }
                }
            }
        }
    }
}
