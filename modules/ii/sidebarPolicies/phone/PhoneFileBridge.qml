import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

/**
 * PhoneFileBridge.qml
 * In-sidebar Drag-to-Send Phone File Bridge.
 * Displays 4 main zones (Downloads, Documents, Pictures, Audio) with hover sub-zones
 * (Direct Copy and + New Folder), and Zone 5 (Internal Storage Explorer) with
 * single-click selection, double-click traversal, and 'Use' action button.
 */
Item {
    id: root

    property var stagedFiles: []
    readonly property bool hasStagedFiles: stagedFiles && stagedFiles.length > 0
    property bool activeMode: false

    signal cancelRequested()
    signal completed()

    // Internal state
    // "zones", "explorer", "new_folder", "transferring"
    property string currentView: "zones"
    property string activeHoveredZone: ""
    property string targetBaseFolder: "/sdcard/Download"
    property string selectedExplorerPath: "/sdcard"
    property string currentExplorerPath: "/sdcard"
    property var currentFolderList: []
    property bool isLoadingFolders: false

    // Track last single click time and folder for double-click detection
    property string lastClickedFolder: ""
    property real lastClickTime: 0

    function activateWithFiles(urls) {
        root.stagedFiles = urls
        root.currentView = "zones"
        root.activeHoveredZone = ""
        root.activeMode = true
    }

    function reset() {
        root.currentView = "zones"
        root.activeHoveredZone = ""
        root.stagedFiles = []
        root.activeMode = false
        root.cancelRequested()
    }

    function openExplorer() {
        root.currentView = "explorer"
        root.currentExplorerPath = "/sdcard"
        root.selectedExplorerPath = "/sdcard"
        root.refreshExplorerFolders()
    }

    function refreshExplorerFolders() {
        root.isLoadingFolders = true
        PhoneFileBridgeService.listDirectory(root.currentExplorerPath, function(folders) {
            root.isLoadingFolders = false
            root.currentFolderList = folders || []
        })
    }

    function handleFolderClick(folderName) {
        const fullPath = root.currentExplorerPath.replace(/\/+$/, "") + "/" + folderName
        const now = Date.now()

        // Double click detection (under 380ms on same item)
        if (root.lastClickedFolder === folderName && (now - root.lastClickTime) < 380) {
            // Navigate inside
            root.currentExplorerPath = fullPath
            root.selectedExplorerPath = fullPath
            root.lastClickedFolder = ""
            root.lastClickTime = 0
            root.refreshExplorerFolders()
            return
        }

        // Single click: select folder
        root.lastClickedFolder = folderName
        root.lastClickTime = now
        root.selectedExplorerPath = fullPath
    }

    function navigateUp() {
        if (root.currentExplorerPath === "/sdcard") return
        const parts = root.currentExplorerPath.split("/")
        parts.pop()
        root.currentExplorerPath = parts.join("/") || "/sdcard"
        root.selectedExplorerPath = root.currentExplorerPath
        root.refreshExplorerFolders()
    }

    function executePush(destination) {
        root.currentView = "transferring"
        PhoneFileBridgeService.pushFiles(root.stagedFiles, destination, (success, dest) => {
            if (success) {
                completionTimer.restart()
            } else {
                root.currentView = "zones"
            }
        })
    }

    Timer {
        id: completionTimer
        interval: 1400
        repeat: false
        onTriggered: {
            root.completed()
            root.reset()
        }
    }

    // Main background card
    Rectangle {
        id: bgCard
        anchors.fill: parent
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.large
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        // ═════════════════════════════════════════════════════════
        // VIEW 1: 4 MAIN ZONES + ZONE 5 TRAVERSAL
        // ═════════════════════════════════════════════════════════
        ColumnLayout {
            id: zonesLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            visible: root.currentView === "zones"

            // Header info with staged file preview
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 38
                    height: 38
                    radius: 12
                    color: Appearance.colors.colPrimaryContainer

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "upload_file"
                        iconSize: 22
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: root.stagedFiles.length > 1
                              ? Translation.tr("%1 files ready to transfer").arg(String(root.stagedFiles.length))
                              : (root.stagedFiles.length === 1
                                 ? decodeURIComponent(String(root.stagedFiles[0]).split("/").pop())
                                 : Translation.tr("Ready to transfer"))
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer2
                        elide: Text.ElideMiddle
                    }

                    StyledText {
                        text: Translation.tr("Drop onto a destination or hover for sub-zones")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }

                // Cancel button
                Rectangle {
                    width: 32
                    height: 32
                    radius: Appearance.rounding.normal
                    color: cancelMouse.containsMouse ? Appearance.colors.colLayer2 : "transparent"
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 18
                        color: Appearance.colors.colSubtext
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.reset()
                    }
                }
            }

            // 2×2 Main Zones Grid
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                // ZONE 1: DOWNLOADS
                ZoneCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    zoneKey: "download"
                    title: Translation.tr("Downloads")
                    remotePath: "/sdcard/Download"
                    iconName: "download"
                    hoveredKey: root.activeHoveredZone
                    onHoverEntered: root.activeHoveredZone = "download"
                    onHoverExited: if (root.activeHoveredZone === "download") root.activeHoveredZone = ""
                    onDirectCopy: root.executePush("/sdcard/Download")
                    onNewFolder: {
                        root.targetBaseFolder = "/sdcard/Download"
                        root.currentView = "new_folder"
                    }
                }

                // ZONE 2: DOCUMENTS
                ZoneCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    zoneKey: "documents"
                    title: Translation.tr("Documents")
                    remotePath: "/sdcard/Documents"
                    iconName: "description"
                    hoveredKey: root.activeHoveredZone
                    onHoverEntered: root.activeHoveredZone = "documents"
                    onHoverExited: if (root.activeHoveredZone === "documents") root.activeHoveredZone = ""
                    onDirectCopy: root.executePush("/sdcard/Documents")
                    onNewFolder: {
                        root.targetBaseFolder = "/sdcard/Documents"
                        root.currentView = "new_folder"
                    }
                }

                // ZONE 3: PICTURES
                ZoneCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    zoneKey: "pictures"
                    title: Translation.tr("Pictures")
                    remotePath: "/sdcard/Pictures"
                    iconName: "image"
                    hoveredKey: root.activeHoveredZone
                    onHoverEntered: root.activeHoveredZone = "pictures"
                    onHoverExited: if (root.activeHoveredZone === "pictures") root.activeHoveredZone = ""
                    onDirectCopy: root.executePush("/sdcard/Pictures")
                    onNewFolder: {
                        root.targetBaseFolder = "/sdcard/Pictures"
                        root.currentView = "new_folder"
                    }
                }

                // ZONE 4: AUDIO / MUSIC
                ZoneCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    zoneKey: "audio"
                    title: Translation.tr("Audio / Music")
                    remotePath: "/sdcard/Music"
                    iconName: "music_note"
                    hoveredKey: root.activeHoveredZone
                    onHoverEntered: root.activeHoveredZone = "audio"
                    onHoverExited: if (root.activeHoveredZone === "audio") root.activeHoveredZone = ""
                    onDirectCopy: root.executePush("/sdcard/Music")
                    onNewFolder: {
                        root.targetBaseFolder = "/sdcard/Music"
                        root.currentView = "new_folder"
                    }
                }
            }

            // ZONE 5: INTERNAL STORAGE EXPLORER
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                radius: Appearance.rounding.normal
                color: zone5Mouse.containsMouse ? Appearance.colors.colLayer2 : Appearance.colors.colLayer2
                border.width: 1.5
                border.color: zone5Mouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                scale: zone5Mouse.pressed ? 0.98 : (zone5Mouse.containsMouse ? 1.01 : 1.0)

                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 12
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85)

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "folder_open"
                            iconSize: 24
                            color: Appearance.colors.colPrimary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: Translation.tr("Internal Storage Explorer")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer2
                        }

                        StyledText {
                            text: Translation.tr("Browse custom folders & pick destination")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    MaterialSymbol {
                        text: "chevron_right"
                        iconSize: 20
                        color: Appearance.colors.colSubtext
                    }
                }

                MouseArea {
                    id: zone5Mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openExplorer()
                }
            }
        }

        // ═════════════════════════════════════════════════════════
        // VIEW 2: INTERNAL STORAGE EXPLORER (ZONE 5 EXPANDED)
        // ═════════════════════════════════════════════════════════
        ColumnLayout {
            id: explorerLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            visible: root.currentView === "explorer"

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Phone Internal Storage")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer2
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: Appearance.rounding.normal
                    color: closeExpMouse.containsMouse ? Appearance.colors.colLayer2 : "transparent"

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: 18
                        color: Appearance.colors.colSubtext
                    }

                    MouseArea {
                        id: closeExpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentView = "zones"
                    }
                }
            }

            // Breadcrumb bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    MaterialSymbol {
                        text: "smartphone"
                        iconSize: 16
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.currentExplorerPath
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.family: "monospace"
                        color: Appearance.colors.colPrimary
                        elide: Text.ElideLeft
                    }
                }
            }

            // Folder list view
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                clip: true

                ListView {
                    id: folderListView
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4
                    model: {
                        let list = []
                        if (root.currentExplorerPath !== "/sdcard") {
                            list.push({ isParent: true, name: ".. (Go back up)" })
                        }
                        for (let i = 0; i < root.currentFolderList.length; i++) {
                            list.push({ isParent: false, name: root.currentFolderList[i] })
                        }
                        return list
                    }

                    delegate: Rectangle {
                        id: folderDelegate
                        width: folderListView.width
                        height: 38
                        radius: Appearance.rounding.small
                        readonly property bool isSelected: !modelData.isParent && (root.selectedExplorerPath === (root.currentExplorerPath.replace(/\/+$/, "") + "/" + modelData.name))
                        color: isSelected
                               ? Appearance.colors.colPrimaryContainer
                               : (itemMouse.containsMouse ? Appearance.colors.colLayer2 : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            MaterialSymbol {
                                text: modelData.isParent ? "arrow_upward" : "folder"
                                iconSize: 18
                                color: folderDelegate.isSelected
                                       ? Appearance.colors.colOnPrimaryContainer
                                       : (modelData.isParent ? Appearance.colors.colSubtext : Appearance.colors.colPrimary)
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: folderDelegate.isSelected ? Font.Bold : Font.Normal
                                color: folderDelegate.isSelected
                                       ? Appearance.colors.colOnPrimaryContainer
                                       : Appearance.colors.colOnLayer2
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: modelData.isParent ? "" : Translation.tr("dbl-click open")
                                font.pixelSize: 10
                                color: Appearance.colors.colSubtext
                                opacity: 0.6
                                visible: itemMouse.containsMouse && !folderDelegate.isSelected
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.isParent) {
                                    root.navigateUp()
                                } else {
                                    root.handleFolderClick(modelData.name)
                                }
                            }
                        }
                    }
                }

                // Loading indicator
                BusyIndicator {
                    anchors.centerIn: parent
                    running: root.isLoadingFolders
                    visible: root.isLoadingFolders
                }
            }

            // Tip note
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("💡 Single click to select · Double click to open folder")
                font.pixelSize: 11
                color: Appearance.colors.colSubtext
                opacity: 0.8
            }

            // Footer action bar: Target path & "Use" button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        StyledText {
                            text: Translation.tr("Destination:")
                            font.pixelSize: 10
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.selectedExplorerPath
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            font.family: "monospace"
                            color: Appearance.colors.colPrimary
                            elide: Text.ElideLeft
                        }
                    }

                    // "Use" button
                    Rectangle {
                        Layout.preferredWidth: 84
                        Layout.fillHeight: true
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colPrimary
                        scale: useMouse.pressed ? 0.96 : (useMouse.containsMouse ? 1.02 : 1.0)

                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: "check"
                                iconSize: 16
                                color: Appearance.colors.colOnPrimary
                            }

                            StyledText {
                                text: Translation.tr("Use")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: Appearance.colors.colOnPrimary
                            }
                        }

                        MouseArea {
                            id: useMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.executePush(root.selectedExplorerPath)
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════
        // VIEW 3: INLINE NEW FOLDER INPUT
        // ═════════════════════════════════════════════════════════
        ColumnLayout {
            id: newFolderLayout
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 14
            visible: root.currentView === "new_folder"

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 52
                height: 52
                radius: 16
                color: Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "create_new_folder"
                    iconSize: 30
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Create Subfolder & Copy")
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer2
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("In: %1").arg(root.targetBaseFolder)
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: "monospace"
                color: Appearance.colors.colSubtext
            }

            TextField {
                id: folderNameField
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                placeholderText: Translation.tr("Folder name...")
                text: "New_Folder"
                color: Appearance.colors.colOnLayer2
                background: Rectangle {
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer0
                    border.width: 1.5
                    border.color: folderNameField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: Appearance.rounding.normal
                    color: "transparent"
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Cancel")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentView = "zones"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colPrimary

                    StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Create & Copy")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const folderName = folderNameField.text.trim() || "New_Folder"
                            const finalDest = root.targetBaseFolder.replace(/\/+$/, "") + "/" + folderName
                            PhoneFileBridgeService.createDirectory(finalDest, ok => {
                                root.executePush(finalDest)
                            })
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════
        // VIEW 4: TRANSFERRING & PROGRESS STATE
        // ═════════════════════════════════════════════════════════
        ColumnLayout {
            id: transferringLayout
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 16
            visible: root.currentView === "transferring"

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 60
                height: 60
                radius: 20
                color: Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: PhoneFileBridgeService.isTransferring ? "bolt" : "check_circle"
                    iconSize: 34
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: PhoneFileBridgeService.isTransferring
                      ? Translation.tr("Pushing via ADB...")
                      : Translation.tr("Transfer Complete!")
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer2
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: parent.width
                text: PhoneFileBridgeService.currentFileName || (root.stagedFiles.length > 0 ? String(root.stagedFiles[0]).split("/").pop() : "")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                elide: Text.ElideMiddle
            }

            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: 4
                color: Appearance.colors.colLayer2

                Rectangle {
                    height: parent.height
                    width: PhoneFileBridgeService.transferTotal > 0
                           ? parent.width * (PhoneFileBridgeService.transferIndex / PhoneFileBridgeService.transferTotal)
                           : (PhoneFileBridgeService.isTransferring ? parent.width * 0.75 : parent.width)
                    radius: 4
                    color: Appearance.colors.colPrimary

                    Behavior on width {
                        NumberAnimation { duration: 200 }
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Saving to: %1").arg(PhoneFileBridgeService.targetPath || root.selectedExplorerPath)
                font.pixelSize: 11
                font.family: "monospace"
                color: Appearance.colors.colPrimary
            }
        }
    }

    // ═════════════════════════════════════════════════════════════
    // COMPONENT: ZoneCard (One of the 4 Main Zones with Hover Split)
    // ═════════════════════════════════════════════════════════════
    component ZoneCard: Rectangle {
        id: zoneRoot
        required property string zoneKey
        required property string title
        required property string remotePath
        required property string iconName
        required property string hoveredKey

        signal hoverEntered()
        signal hoverExited()
        signal directCopy()
        signal newFolder()

        readonly property bool isHovered: zoneRoot.hoveredKey === zoneRoot.zoneKey
        radius: Appearance.rounding.normal
        color: zoneRoot.isHovered ? Appearance.colors.colLayer2 : Appearance.colors.colLayer2
        border.width: 1.5
        border.color: zoneRoot.isHovered ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
        scale: zoneRoot.isHovered ? 1.02 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
        }
        Behavior on border.color {
            ColorAnimation { duration: 160 }
        }

        // DEFAULT VIEW: ICON, TITLE, PATH
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6
            opacity: zoneRoot.isHovered ? 0.0 : 1.0
            visible: opacity > 0.0

            Behavior on opacity {
                NumberAnimation { duration: 140 }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 42
                height: 42
                radius: 14
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.88)

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: zoneRoot.iconName
                    iconSize: 22
                    color: Appearance.colors.colPrimary
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: zoneRoot.title
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer2
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: zoneRoot.remotePath
                font.pixelSize: 10
                font.family: "monospace"
                color: Appearance.colors.colSubtext
                opacity: 0.7
            }
        }

        // HOVER VIEW: 2 SUB-ZONE PILLS
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6
            opacity: zoneRoot.isHovered ? 1.0 : 0.0
            visible: opacity > 0.0

            Behavior on opacity {
                NumberAnimation { duration: 140 }
            }

            // Sub-Zone 1: Direct Copy
            Rectangle {
                id: directPill
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.small
                color: directMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
                border.width: 1
                border.color: directMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol {
                        text: "file_download"
                        iconSize: 16
                        color: directMouse.containsMouse ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: Translation.tr("Direct Copy")
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: directMouse.containsMouse ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                    }
                }

                MouseArea {
                    id: directMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: zoneRoot.directCopy()
                }
            }

            // Sub-Zone 2: + New Folder
            Rectangle {
                id: newFolderPill
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.small
                color: newFolderMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
                border.width: 1
                border.color: newFolderMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    MaterialSymbol {
                        text: "create_new_folder"
                        iconSize: 16
                        color: newFolderMouse.containsMouse ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: Translation.tr("+ New Folder")
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: newFolderMouse.containsMouse ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                    }
                }

                MouseArea {
                    id: newFolderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: zoneRoot.newFolder()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: zoneRoot.hoverEntered()
            onExited: zoneRoot.hoverExited()
        }
    }
}
