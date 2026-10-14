import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: presetsViewRoot
    property string text: ""
    spacing: 16
    Layout.fillWidth: true

    signal publishRequested(string name)
    signal updateRequested(string name)

    Process {
        id: filePickerProc
        stdout: StdioCollector {
            onStreamFinished: {
                let path = text.trim();
                if (path.length > 0) {
                    Presets.importZip(path);
                }
            }
        }
    }

    function openImportDialog() {
        filePickerProc.running = false;
        filePickerProc.command = [
            "bash", "-c",
            "if command -v zenity >/dev/null 2>&1; then zenity --file-selection --file-filter='Presets (*.zip *.json) | *.zip *.json' 2>/dev/null; else kdialog --getopenfilename ~ '*.zip *.json' 2>/dev/null; fi"
        ];
        filePickerProc.running = true;
    }

    // Top action bar: Save new preset & Import
    ConfigRow {
        Layout.fillWidth: true
        Layout.preferredHeight: 48

        ToolbarTextField {
            id: presetNameInput
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: Translation.tr("Preset name, description (optional)...")
            font.pixelSize: Appearance.font.pixelSize.normal
            onAccepted: {
                if (presetNameInput.text.trim().length > 0) {
                    Presets.save(presetNameInput.text);
                    presetNameInput.text = "";
                }
            }
        }

        RippleButtonWithIcon {
            materialIcon: "save"
            mainText: Translation.tr("Save")
            topLeftRadius: Appearance.rounding.full
            topRightRadius: Appearance.rounding.small
            bottomLeftRadius: Appearance.rounding.full
            bottomRightRadius: Appearance.rounding.small
            Layout.fillHeight: true
            enabled: presetNameInput.text.trim().length > 0
            onClicked: {
                Presets.save(presetNameInput.text);
                presetNameInput.text = "";
            }
        }

        RippleButtonWithIcon {
            materialIcon: "file_upload"
            mainText: Translation.tr("Import")
            topLeftRadius: Appearance.rounding.small
            topRightRadius: Appearance.rounding.full
            bottomLeftRadius: Appearance.rounding.small
            bottomRightRadius: Appearance.rounding.full
            Layout.fillHeight: true
            onClicked: presetsViewRoot.openImportDialog()
        }
    }

    // Empty state
    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 30
        Layout.bottomMargin: 30
        visible: Presets.folderModel.count === 0
        horizontalAlignment: Text.AlignHCenter
        text: Translation.tr("No presets saved yet. Type a name above to save your current configuration!")
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.normal
    }

    // Presets Flow
    Flow {
        id: presetsFlow
        Layout.fillWidth: true
        Layout.topMargin: 10
        spacing: 14
        visible: Presets.folderModel.count > 0

        Repeater {
            model: Presets.folderModel

            delegate: PresetsCard {
                id: presetDelegate
                required property string fileName
                required property string filePath

                property string presetName: fileName.replace(".json", "")
                property string presetWallpaper: ""
                property string presetDescription: ""

                FileView {
                    path: presetDelegate.filePath
                    onLoaded: {
                        try {
                            const data = JSON.parse(text());
                            let rawWall = data?.background?.wallpaperPath ?? "";
                            const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWall);
                            let resolved = isVideo ? (data?.background?.thumbnailPath ?? "") : rawWall;
                            if (resolved.startsWith("$HOME")) {
                                resolved = resolved.replace("$HOME", Directories.home);
                            }
                            presetDelegate.presetWallpaper = resolved;
                            presetDelegate.presetDescription = data?._presetMeta?.description ?? "";
                        } catch (e) {
                            console.log("Failed to parse preset JSON:", e);
                        }
                    }
                }

                title: presetDelegate.presetName
                imageSource: presetDelegate.presetWallpaper !== "" 
                    ? presetDelegate.presetWallpaper 
                    : `${Directories.assetsPath}/images/default_wallpaper.png`
                description: presetDelegate.presetDescription !== "" 
                    ? presetDelegate.presetDescription 
                    : Translation.tr("Saved preset")

                onApply: () => Presets.apply(presetDelegate.presetName)
                onRemove: () => Presets.remove(presetDelegate.presetName)
                onOverwrite: () => Presets.overwrite(presetDelegate.presetName)
                onExportZip: () => Presets.exportZip(presetDelegate.presetName)
            }
        }
    }

    // Imported Presets Section
    ContentSubsection {
        title: Translation.tr("Imported")
        visible: Presets.importedFolderModel.count > 0
        Layout.fillWidth: true
        Layout.topMargin: 20

        Flow {
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: Presets.importedFolderModel

                delegate: PresetsCard {
                    id: importedDelegate
                    required property string fileName
                    required property string filePath

                    property string presetName: fileName.replace(".json", "")
                    property string presetWallpaper: ""
                    property string presetDescription: ""

                    FileView {
                        path: importedDelegate.filePath
                        onLoaded: {
                            try {
                                const data = JSON.parse(text());
                                let rawWall = data?.background?.wallpaperPath ?? "";
                                const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWall);
                                let resolved = isVideo ? (data?.background?.thumbnailPath ?? "") : rawWall;
                                if (resolved.startsWith("$HOME")) {
                                    resolved = resolved.replace("$HOME", Directories.home);
                                }
                                importedDelegate.presetWallpaper = resolved;
                                importedDelegate.presetDescription = data?._presetMeta?.description ?? "";
                            } catch (e) {
                                console.log("Failed to parse imported preset:", e);
                            }
                        }
                    }

                    title: importedDelegate.presetName
                    imageSource: importedDelegate.presetWallpaper !== "" 
                        ? importedDelegate.presetWallpaper 
                        : `${Directories.assetsPath}/images/default_wallpaper.png`
                    description: importedDelegate.presetDescription !== "" 
                        ? importedDelegate.presetDescription 
                        : Translation.tr("Imported preset")

                    onApply: () => Presets.applyImported(importedDelegate.presetName)
                    onRemove: () => Presets.removeImported(importedDelegate.presetName)
                    onOverwrite: () => Presets.overwrite(importedDelegate.presetName)
                    onExportZip: () => Presets.exportZip(importedDelegate.presetName)
                }
            }
        }
    }

    // Downloaded Presets Section
    ContentSubsection {
        title: Translation.tr("Downloaded")
        visible: Presets.onlineFolderModel.count > 0
        Layout.fillWidth: true
        Layout.topMargin: 20

        Flow {
            Layout.fillWidth: true
            spacing: 14

            Repeater {
                model: Presets.onlineFolderModel

                delegate: PresetsCard {
                    id: onlineDelegate
                    required property string fileName
                    required property string filePath

                    property string presetName: fileName.replace(".json", "")
                    property string presetWallpaper: ""
                    property string presetDescription: ""

                    FileView {
                        path: onlineDelegate.filePath
                        onLoaded: {
                            try {
                                const data = JSON.parse(text());
                                let rawWall = data?.background?.wallpaperPath ?? "";
                                const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWall);
                                let resolved = isVideo ? (data?.background?.thumbnailPath ?? "") : rawWall;
                                if (resolved.startsWith("$HOME")) {
                                    resolved = resolved.replace("$HOME", Directories.home);
                                }
                                onlineDelegate.presetWallpaper = resolved;
                                onlineDelegate.presetDescription = data?._presetMeta?.description ?? "";
                            } catch (e) {
                                console.log("Failed to parse downloaded preset:", e);
                            }
                        }
                    }

                    title: onlineDelegate.presetName
                    imageSource: onlineDelegate.presetWallpaper !== "" 
                        ? onlineDelegate.presetWallpaper 
                        : `${Directories.assetsPath}/images/default_wallpaper.png`
                    description: onlineDelegate.presetDescription !== "" 
                        ? onlineDelegate.presetDescription 
                        : Translation.tr("Downloaded preset")

                    onApply: () => Presets.applyOnline(onlineDelegate.presetName)
                    onRemove: () => Presets.removeOnline(onlineDelegate.presetName)
                    onOverwrite: () => Presets.overwrite(onlineDelegate.presetName)
                    onExportZip: () => Presets.exportZip(onlineDelegate.presetName)
                }
            }
        }
    }
}
