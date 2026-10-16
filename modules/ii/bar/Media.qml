pragma ComponentBehavior: Bound
import "." as Local
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import qs.modules.common.models
import qs
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root
    
    property bool vertical: false
    property bool borderless: Config.options.bar.borderless
    property bool isMaterial: Config.options.bar.cornerStyle === 3
    property bool mirrored: false

    readonly property MprisPlayer activePlayer: {
        const preferred = Config.options.bar.media.preferredPlayer.trim().toLowerCase()
        if (preferred.length === 0) return MprisController.activePlayer
        const _ = MprisController.players.count
        for (const p of MprisController.players) {
            if ((p.identity ?? "").toLowerCase().includes(preferred) ||
                (p.desktopEntry ?? "").toLowerCase().includes(preferred))
                return p
        }
        return MprisController.activePlayer
    }

    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")

    property var    artUrl:      activePlayer?.trackArtUrl ?? ""
    property string trackTitle:  activePlayer?.trackTitle  ?? ""
    property string trackArtist: activePlayer?.trackArtist ?? ""
    property bool   isPlaying:   activePlayer?.isPlaying   ?? false
    property bool   hasTrack:    trackTitle.length > 0

    property string artDownloadLocation: Directories.coverArt
    property string artFileName:         Qt.md5(artUrl)
    property string artFilePath:         `${artDownloadLocation}/${artFileName}`
    property bool   artDownloaded:       false

    property string displayedArtFilePath: {
        if (!root.artDownloaded) return ""
        if (root.artUrl.startsWith("file://")) return root.artUrl
        return Qt.resolvedUrl(artFilePath)
    }

    onArtFilePathChanged: {
        if (!root.artUrl || root.artUrl.length === 0) {
            root.artDownloaded = false
            return
        }
        if (root.artUrl.startsWith("file://")) {
            root.artDownloaded = true
            return
        }
        artDownloader.targetFile  = root.artUrl
        artDownloader.artFilePath = root.artFilePath
        root.artDownloaded = false
        artDownloader.running = true
    }

    Process {
        id: artDownloader
        property string targetFile:  root.artUrl
        property string artFilePath: root.artFilePath
        command: ["bash", "-c",
            `[ -f ${artFilePath} ] || curl -sSL '${targetFile}' -o '${artFilePath}'`]
        onExited: { root.artDownloaded = true }
    }

    Layout.fillHeight: true
    property real visualizerWidth: 105
    property real visualizerHeight: 30

    implicitWidth: vertical 
        ? Appearance.sizes.verticalBarWidth 
        : (isMaterial ? visualizerWidth + 20 : visualizerWidth)
    implicitHeight: vertical 
        ? (isMaterial ? visualizerWidth + 20 : visualizerWidth) 
        : Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    HoverHandler {
        id: mediaHoverHandler
        onHoveredChanged: {
            GlobalStates.mediaHovered = hovered;
            GlobalStates.checkMediaControlsHover();
        }
    }

    Component.onDestruction: {
        GlobalStates.mediaHovered = false;
        GlobalStates.checkMediaControlsHover();
    }

    MouseArea {
        anchors.fill: parent
        z: 100
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        hoverEnabled: true
        onEntered: {
            GlobalStates.mediaHovered = true;
            GlobalStates.checkMediaControlsHover();
        }
        onExited: {
            GlobalStates.mediaHovered = mediaHoverHandler.hovered;
            GlobalStates.checkMediaControlsHover();
        }
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton)      activePlayer?.togglePlaying()
            else if (event.button === Qt.BackButton)   activePlayer?.previous()
            else if (event.button === Qt.ForwardButton) activePlayer?.next()
            else if (event.button === Qt.RightButton)  GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            else if (event.button === Qt.LeftButton)   activePlayer?.togglePlaying()
        }
    }

    Local.Visualizer {
        id: tacetVisualizer
        anchors.centerIn: parent
        vertical: root.vertical
        isMaterial: root.isMaterial
        mirrored: root.mirrored
        visualizerWidth: root.visualizerWidth
        visualizerHeight: root.visualizerHeight
    }
}
