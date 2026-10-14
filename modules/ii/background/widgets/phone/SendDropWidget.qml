pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.background.widgets
import "FileTransferPaths.js" as UtilityFiles

/*
 * Send (2x1): files through the existing ADB bridge or KDE Connect. Drop files anywhere on the card, or choose them. The target
 * shape on the left is the state - a cookie waiting, a burst while a drag is
 * over it, a sunny check once sent; on the right, the way (a two-segment
 * group) and the device as chips, remembered between sessions.
 */
ExpressiveCardWidget {
    id: root

    configEntryName: "send_drop"
    designWidth: 492
    designHeight: 240

    readonly property real padding: 14
    readonly property real targetWidth: 176

    readonly property bool useAdb: (root.options?.backend ?? "adb") !== "kdeconnect"
    readonly property var kdeDevices: (KdeConnectService.devices ?? []).filter(device => device.paired)
    readonly property string kdeDeviceId: String(root.options?.kdeDevice ?? "") || KdeConnectService.activeDeviceId
    readonly property var kdeDevice: root.kdeDevices.find(device => device.id === root.kdeDeviceId) ?? null
    readonly property bool adbReady: PhoneFileBridgeService.adbReady || KdeConnectService.adbReachable
    readonly property bool ready: root.useAdb ? (root.adbReady || KdeConnectService.activeReachable) : (root.kdeDevice?.reachable === true)
    readonly property bool sending: PhoneFileBridgeService.isTransferring
    property string sendError: ""
    property bool queued: false
    property int lastSent: 0
    readonly property bool justSent: root.lastSent > 0 && !root.sending
    property bool dragOver: false

    function setBackend(backend) {
        if (root.actionsEnabled)
            root.options.backend = backend;
    }

    function completed(ok, count, error) {
        root.sendError = ok ? "" : (error || Translation.tr("Transfer failed"));
        root.lastSent = ok ? count : 0;
        sentTimer.restart();
    }

    function send(paths) {
        if (!root.actionsEnabled || paths.length === 0 || !root.ready || root.sending)
            return;
        root.sendError = "";
        root.lastSent = 0;
        root.queued = false;
        if (root.useAdb) {
            PhoneFileBridgeService.pushFiles(paths.map(path => UtilityFiles.fileUri(path)),
                String(root.options?.destination ?? "/sdcard/Download"),
                (ok, destination, error) => root.completed(ok, paths.length, error));
        } else {
            for (const path of paths)
                KdeConnectService.shareUrl(root.kdeDeviceId, UtilityFiles.fileUri(path));
            root.queued = true;
            root.completed(true, paths.length, "");
        }
    }

    Timer {
        id: sentTimer
        interval: 2600
        onTriggered: { root.lastSent = 0; root.sendError = ""; }
    }

    Process {
        id: picker
        command: ["bash", "-c",
            "if command -v kdialog >/dev/null 2>&1; then kdialog --getopenfilename \"$HOME\" --multiple 2>/dev/null | tr '\\n' '|'; "
            + "elif command -v zenity >/dev/null 2>&1; then zenity --file-selection --multiple --separator '|' 2>/dev/null; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = this.text.trim().split("|").map(s => s.trim()).filter(s => s.length > 0);
                root.send(UtilityFiles.dedupe(paths));
            }
        }
    }

    readonly property string targetName: root.useAdb
        ? (root.adbReady ? Translation.tr("ADB phone") : (KdeConnectService.activeDeviceDisplayName || Translation.tr("No phone")))
        : (root.kdeDevice?.name || Translation.tr("No phone paired"))
    readonly property string stateText: {
        if (root.dragOver)
            return root.ready ? Translation.tr("Release to send") : Translation.tr("Pick a device first");
        if (root.sending)
            return Translation.tr("Sending…");
        if (root.sendError)
            return root.sendError;
        if (root.justSent)
            return root.queued ? Translation.tr("Queued %1 files").arg(root.lastSent) : Translation.tr("Sent %1 files").arg(root.lastSent);
        return root.ready ? Translation.tr("Drop files here") : Translation.tr("No device ready");
    }

    DropArea {
        anchors.fill: parent
        enabled: root.actionsEnabled
        keys: ["text/uri-list"]
        onEntered: root.dragOver = true
        onExited: root.dragOver = false
        onDropped: drop => {
            root.dragOver = false;
            const paths = Array.from(drop.urls ?? []).map(url => UtilityFiles.pathFromUrl(url)).filter(p => p.length > 0);
            root.send(UtilityFiles.dedupe(paths));
            drop.accept();
        }
    }

    // ── Target ──
    Rectangle {
        id: target
        x: root.padding
        y: root.padding
        width: root.targetWidth
        height: root.designHeight - root.padding * 2
        radius: Appearance.rounding.normal
        color: root.dragOver ? ColorUtils.mix(WidgetColorScheme.accentColor, WidgetColorScheme.pillBgColor, 0.2) : WidgetColorScheme.pillBgColor

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Item {
            id: targetShape
            anchors.horizontalCenter: parent.horizontalCenter
            y: 28
            width: 108
            height: 108
            scale: root.dragOver ? 1.08 : 1

            Behavior on scale {
                enabled: !Appearance.reducedMotion
                animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
            }

            MaterialShape {
                anchors.fill: parent
                shape: root.justSent ? MaterialShape.Shape.Sunny
                    : root.sending ? MaterialShape.Shape.Flower
                    : root.dragOver ? MaterialShape.Shape.SoftBurst : MaterialShape.Shape.Cookie12Sided
                color: root.justSent || root.dragOver || root.sending ? WidgetColorScheme.accentColor : WidgetColorScheme.pillFillColor

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.justSent ? "done_all" : (root.useAdb ? "usb" : "phone_android")
                iconSize: 44
                fill: 1
                color: root.justSent || root.dragOver || root.sending ? WidgetColorScheme.onAccentColor : WidgetColorScheme.textColorOnPillFill
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            width: parent.width - 20
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.stateText
            color: WidgetColorScheme.textColorOnBg
            font.pixelSize: Appearance.font.pixelSize.normal
            font.variableAxes: ({ "wght": 620, "wdth": 92, "ROND": 100 })
        }
    }

    // ── Way ──
    Item {
        id: way
        anchors.left: target.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: root.padding
        y: root.padding
        height: 40

        Repeater {
            model: [
                { id: "adb", label: "Fast ADB", symbol: "usb" },
                { id: "kdeconnect", label: "KDE Connect", symbol: "smartphone" }
            ]

            delegate: WidgetButton {
                id: segment
                required property var modelData
                required property int index
                readonly property bool chosen: (segment.modelData.id === "adb") === root.useAdb
                readonly property real outerRadius: root.pill(height)
                property real joinRadius: segment.chosen || segment.down ? segment.outerRadius : Appearance.rounding.verysmall
                Behavior on joinRadius {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                x: segment.index === 0 ? 0 : (way.width + 3) / 2
                width: (way.width - 3) / 2
                height: way.height
                symbol: segment.chosen ? "check" : segment.modelData.symbol
                symbolSize: 16
                label: segment.modelData.label
                labelSize: Appearance.font.pixelSize.smaller
                colFill: segment.chosen ? WidgetColorScheme.accentColor : WidgetColorScheme.pillBgColor
                colContent: segment.chosen ? WidgetColorScheme.onAccentColor : WidgetColorScheme.textColorOnBg
                topLeftRadius: segment.index === 0 ? segment.outerRadius : segment.joinRadius
                bottomLeftRadius: segment.index === 0 ? segment.outerRadius : segment.joinRadius
                topRightRadius: segment.index === 1 ? segment.outerRadius : segment.joinRadius
                bottomRightRadius: segment.index === 1 ? segment.outerRadius : segment.joinRadius
                onClicked: root.setBackend(segment.modelData.id)
            }
        }
    }

    // ── Devices ──
    Flickable {
        id: devicesFlick
        anchors.left: way.left
        anchors.right: way.right
        anchors.top: way.bottom
        anchors.topMargin: 12
        anchors.bottom: chooseKey.top
        anchors.bottomMargin: 10
        clip: true
        contentWidth: width
        contentHeight: chips.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Flow {
            id: chips
            width: devicesFlick.width
            spacing: 6

            Repeater {
                model: root.useAdb ? [{ name: root.targetName, id: "adb", reachable: root.ready }] : root.kdeDevices

                delegate: WidgetButton {
                    id: chip
                    required property var modelData
                    readonly property string chipName: String(chip.modelData.name ?? "")
                    readonly property bool chosen: root.useAdb || chip.modelData.id === root.kdeDeviceId
                    readonly property bool online: chip.modelData.reachable === true
                    width: Math.min(chips.width, chipMeasure.implicitWidth + 50)
                    height: 34
                    symbol: chip.chosen ? "check" : (root.useAdb ? "usb" : (chip.online ? "smartphone" : "phonelink_off"))
                    symbolSize: 16
                    label: chip.chipName
                    labelSize: Appearance.font.pixelSize.smaller
                    colFill: chip.chosen ? WidgetColorScheme.pillFillColor : WidgetColorScheme.pillBgColor
                    colContent: chip.chosen ? WidgetColorScheme.textColorOnPillFill : WidgetColorScheme.textColorOnBg
                    restRadius: chip.chosen ? Appearance.rounding.small : root.pill(height)
                    onClicked: {
                        if (!root.useAdb)
                            root.options.kdeDevice = String(chip.modelData.id);
                    }

                    StyledText {
                        id: chipMeasure
                        visible: false
                        text: chip.chipName
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }


        }

        StyledText {
            visible: !root.useAdb && root.kdeDevices.length === 0
            width: parent.width
            wrapMode: Text.Wrap
            text: Translation.tr("No paired phones. Pair one in KDE Connect.")
            color: WidgetColorScheme.subtextColorOnBg
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }

    // ── Choose ──
    WidgetButton {
        id: chooseKey
        anchors.left: way.left
        anchors.right: way.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.padding
        height: 48
        enabled: root.ready && !root.sending
        symbol: "attach_file"
        label: Translation.tr("Choose files for %1").arg(root.targetName)
        labelAxes: ({ "wght": 620, "wdth": 92, "ROND": 100 })
        colFill: WidgetColorScheme.accentColor
        colContent: WidgetColorScheme.onAccentColor
        onClicked: picker.running = true
    }

}
