import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root

    property string imageSource: ""
    property string title: ""
    property string description: ""
    property bool inUse: Presets.activePreset === root.title
    property var onApply: () => {}
    property var onRemove: () => {}
    property var onOverwrite: () => {}
    property var onExportZip: () => {}

    implicitWidth: 293 
    implicitHeight: contentColumn.implicitHeight + 14
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    border.width: root.inUse ? 2 : 1
    border.color: root.inUse ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border

    Behavior on border.color {
        ColorAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
        }
    }

    ColumnLayout {
        id: contentColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 0
        }
        spacing: 6

        // Header
        RowLayout {
            Layout.leftMargin: 10
            Layout.rightMargin: 8
            Layout.topMargin: 8
            spacing: 10

            MaterialShapeWrappedMaterialSymbol {
                id: avatarShape
                shape: MaterialShape.Shape.Circle 
                text: root.title.length > 0 ? root.title.charAt(0).toUpperCase() : "?"
                iconSize: Appearance.font.pixelSize.normal
                implicitSize: 36
                font: Appearance.font.family.main
                color: root.inUse ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer
                colSymbol: root.inUse ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: -2
                Layout.fillWidth: true

                RowLayout {
                    spacing: 6
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: root.title
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }

                    Rectangle {
                        visible: root.inUse
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimaryContainer
                        implicitHeight: 20
                        implicitWidth: activeRow.implicitWidth + 10
                        Layout.alignment: Qt.AlignVCenter

                        RowLayout {
                            id: activeRow
                            anchors.centerIn: parent
                            spacing: 3
                            MaterialSymbol {
                                text: "check"
                                iconSize: 12
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                            StyledText {
                                text: Translation.tr("Active")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                        }
                    }
                }

                // Description
                StyledText {
                    Layout.fillWidth: true
                    visible: root.description.length > 0
                    text: root.description
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }

            Item {
                Layout.alignment: Qt.AlignRight
                implicitWidth: 32
                implicitHeight: 32
                RippleButton {
                    id: menuBtn
                    anchors.centerIn: parent
                    implicitWidth: 32
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: menuPopup.visible = !menuPopup.visible
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "more_vert"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnLayer1
                    }
                }
                PresetPopup {
                    id: menuPopup
                    y: menuBtn.height + 4
                    x: menuBtn.width - width + 8
                    onOverwrite: root.onOverwrite
                    onExportZip: root.onExportZip
                }
            }
        }

        // Wallpaper preview
        Rectangle {
            id: imageRect
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            implicitHeight: 130
            radius: 0
            color: Appearance.colors.colLayer2
            clip: true

            StyledImage {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: root.imageSource
                cache: false
                antialiasing: true
                sourceSize.width: imageRect.width * 2
                sourceSize.height: imageRect.height * 2
                visible: root.imageSource !== ""
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: imageRect.width
                        height: imageRect.height
                        radius: imageRect.radius
                    }
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.imageSource === ""
                text: "wallpaper"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colSubtext
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.onApply()
            }
        }

        // Buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 8
            Layout.bottomMargin: 4
            spacing: 8

            Item { Layout.fillWidth: true }

            GroupButton {
                id: removeBtn
                bounce: false
                toggled: false
                leftRadius: height / 2
                rightRadius: height / 2
                Layout.fillWidth: false
                Layout.fillHeight: false
                implicitHeight: 36
                horizontalPadding: 14
                verticalPadding: 8
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.8)
                colBackgroundActive: Appearance.colors.colErrorActive
                contentItem: StyledText {
                    text: Translation.tr("Remove")
                    color: Appearance.colors.colError
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.onRemove()
            }

            GroupButton {
                id: applyBtn
                bounce: false
                toggled: false
                leftRadius: height / 2
                rightRadius: height / 2
                Layout.fillWidth: false
                Layout.fillHeight: false
                implicitHeight: 36
                horizontalPadding: 14
                verticalPadding: 8
                colBackground: root.inUse ? Appearance.colors.colSecondaryContainer : Appearance.colors.colPrimaryContainer
                colBackgroundHover: root.inUse ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colPrimaryContainerHover
                colBackgroundActive: root.inUse ? Appearance.colors.colSecondaryContainerActive : Appearance.colors.colPrimaryContainerActive
                contentItem: StyledText {
                    text: root.inUse ? Translation.tr("Applied") : Translation.tr("Apply")
                    color: root.inUse ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnPrimaryContainer
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.onApply()
            }
        }
    }
}