import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.configs.widgets

ContentPage {
    id: root
    forceWidth: false

    signal goBack

    RowLayout {
        spacing: 12

        RippleButton {
            implicitWidth: implicitHeight
            implicitHeight: 40
            topLeftRadius: Appearance.rounding.full
            topRightRadius: Appearance.rounding.full
            bottomLeftRadius: Appearance.rounding.full
            bottomRightRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            colRipple: Appearance.colors.colSecondaryContainerActive

            MaterialSymbol {
                anchors.centerIn: parent
                text: "arrow_back"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSecondaryContainer
            }

            onClicked: root.goBack()
        }

        StyledText {
            text: Translation.tr("Desktop Visualizer Options")
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer0
        }
    }

    // ── Visualizer 1 ──
    ContentSection {
        id: settingsVisualizer1
        icon: "graphic_eq"
        shape: MaterialShape.Shape.Burst
        title: Translation.tr("Visualizer 1")

        readonly property var entry: Config.options.background.widgets.visualizer
        readonly property bool bandStyle: ["bars", "mirror", "aurora", "dots", "wuwa"].includes(entry?.style ?? "bars")

        GroupedList {
            ConfigSwitch {
                Layout.fillWidth: true
                buttonIcon: "check"
                text: Translation.tr("Enable Visualizer 1")
                checked: settingsVisualizer1.entry?.enable ?? false
                onCheckedChanged: {
                    if (settingsVisualizer1.entry)
                        settingsVisualizer1.entry.enable = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Style")

            ConfigSelectionArray {
                currentValue: settingsVisualizer1.entry?.style ?? "bars"
                onSelected: newValue => {
                    if (settingsVisualizer1.entry)
                        settingsVisualizer1.entry.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "bar_chart",
                        value: "bars"
                    },
                    {
                        displayName: Translation.tr("Mirror"),
                        icon: "equalizer",
                        value: "mirror"
                    },
                    {
                        displayName: Translation.tr("Aurora"),
                        icon: "waves",
                        value: "aurora"
                    },
                    {
                        displayName: Translation.tr("Ring"),
                        icon: "album",
                        value: "ring"
                    },
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "grid_on",
                        value: "dots"
                    },
                    {
                        displayName: Translation.tr("Tacet Mark (WuWa)"),
                        icon: "graphic_eq",
                        value: "wuwa"
                    }
                ]
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            visible: settingsVisualizer1.entry?.style === "ring" || settingsVisualizer1.entry?.style === "wuwa"
            materialIcon: "touch_app"
            text: settingsVisualizer1.entry?.style === "ring"
                ? Translation.tr("Drag the ring on your desktop to move it, drag its corner to resize it.")
                : Translation.tr("Drag the Tacet Mark on your desktop to move it, drag its edge to resize it.")
        }

        ConfigSelectionArray {
            text: Translation.tr("Colors")
            icon: "palette"
            currentValue: settingsVisualizer1.entry?.colorSource ?? "theme"
            onSelected: newValue => {
                if (settingsVisualizer1.entry)
                    settingsVisualizer1.entry.colorSource = newValue;
            }
            options: [
                {
                    displayName: Translation.tr("Theme"),
                    icon: "palette",
                    value: "theme"
                },
                {
                    displayName: Translation.tr("Album cover"),
                    icon: "album",
                    value: "cover"
                }
            ]
        }

        GroupedList {
            ConfigSlider {
                text: Translation.tr("Sensitivity (%)")
                buttonIcon: "tune"
                usePercentTooltip: false
                value: (settingsVisualizer1.entry?.sensitivity ?? 1) * 100
                from: 50
                to: 300
                stopIndicatorValues: [100]
                onValueChanged: {
                    if (settingsVisualizer1.entry)
                        settingsVisualizer1.entry.sensitivity = Math.round(value) / 100;
                }
            }
            ConfigSlider {
                visible: settingsVisualizer1.bandStyle
                text: Translation.tr("Height")
                buttonIcon: "height"
                usePercentTooltip: false
                value: settingsVisualizer1.entry?.height ?? 260
                from: 80
                to: 600
                stopIndicatorValues: [260]
                onValueChanged: {
                    if (settingsVisualizer1.entry)
                        settingsVisualizer1.entry.height = Math.round(value);
                }
            }
            ConfigSlider {
                visible: settingsVisualizer1.entry?.style === "wuwa"
                text: Translation.tr("Width")
                buttonIcon: "aspect_ratio"
                usePercentTooltip: false
                value: settingsVisualizer1.entry?.customWidth ?? 860
                from: 300
                to: 1920
                stopIndicatorValues: [860]
                onValueChanged: {
                    if (settingsVisualizer1.entry)
                        settingsVisualizer1.entry.customWidth = Math.round(value);
                }
            }
            ConfigSlider {
                visible: settingsVisualizer1.entry?.style === "ring"
                text: Translation.tr("Ring Size")
                buttonIcon: "aspect_ratio"
                usePercentTooltip: false
                value: settingsVisualizer1.entry?.ringSize ?? 380
                from: 150
                to: 900
                stopIndicatorValues: [380]
                onValueChanged: {
                    if (settingsVisualizer1.entry)
                        settingsVisualizer1.entry.ringSize = Math.round(value);
                }
            }
        }
    }

    // ── Visualizer 2 ──
    ContentSection {
        id: settingsVisualizer2
        icon: "album"
        shape: MaterialShape.Shape.Burst
        title: Translation.tr("Visualizer 2")

        readonly property var entry: Config.options.background.widgets.visualizer2
        readonly property bool bandStyle: ["bars", "mirror", "aurora", "dots", "wuwa"].includes(entry?.style ?? "ring")

        GroupedList {
            ConfigSwitch {
                Layout.fillWidth: true
                buttonIcon: "check"
                text: Translation.tr("Enable Visualizer 2")
                checked: settingsVisualizer2.entry?.enable ?? false
                onCheckedChanged: {
                    if (settingsVisualizer2.entry)
                        settingsVisualizer2.entry.enable = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Style")

            ConfigSelectionArray {
                currentValue: settingsVisualizer2.entry?.style ?? "ring"
                onSelected: newValue => {
                    if (settingsVisualizer2.entry)
                        settingsVisualizer2.entry.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "bar_chart",
                        value: "bars"
                    },
                    {
                        displayName: Translation.tr("Mirror"),
                        icon: "equalizer",
                        value: "mirror"
                    },
                    {
                        displayName: Translation.tr("Aurora"),
                        icon: "waves",
                        value: "aurora"
                    },
                    {
                        displayName: Translation.tr("Ring"),
                        icon: "album",
                        value: "ring"
                    },
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "grid_on",
                        value: "dots"
                    },
                    {
                        displayName: Translation.tr("Tacet Mark (WuWa)"),
                        icon: "graphic_eq",
                        value: "wuwa"
                    }
                ]
            }
        }

        NoticeBox {
            Layout.fillWidth: true
            visible: settingsVisualizer2.entry?.style === "ring" || settingsVisualizer2.entry?.style === "wuwa"
            materialIcon: "touch_app"
            text: settingsVisualizer2.entry?.style === "ring"
                ? Translation.tr("Drag the ring on your desktop to move it, drag its corner to resize it.")
                : Translation.tr("Drag the Tacet Mark on your desktop to move it, drag its edge to resize it.")
        }

        ConfigSelectionArray {
            text: Translation.tr("Colors")
            icon: "palette"
            currentValue: settingsVisualizer2.entry?.colorSource ?? "theme"
            onSelected: newValue => {
                if (settingsVisualizer2.entry)
                    settingsVisualizer2.entry.colorSource = newValue;
            }
            options: [
                {
                    displayName: Translation.tr("Theme"),
                    icon: "palette",
                    value: "theme"
                },
                {
                    displayName: Translation.tr("Album cover"),
                    icon: "album",
                    value: "cover"
                }
            ]
        }

        GroupedList {
            ConfigSlider {
                text: Translation.tr("Sensitivity (%)")
                buttonIcon: "tune"
                usePercentTooltip: false
                value: (settingsVisualizer2.entry?.sensitivity ?? 1) * 100
                from: 50
                to: 300
                stopIndicatorValues: [100]
                onValueChanged: {
                    if (settingsVisualizer2.entry)
                        settingsVisualizer2.entry.sensitivity = Math.round(value) / 100;
                }
            }
            ConfigSlider {
                visible: settingsVisualizer2.bandStyle
                text: Translation.tr("Height")
                buttonIcon: "height"
                usePercentTooltip: false
                value: settingsVisualizer2.entry?.height ?? 260
                from: 80
                to: 600
                stopIndicatorValues: [260]
                onValueChanged: {
                    if (settingsVisualizer2.entry)
                        settingsVisualizer2.entry.height = Math.round(value);
                }
            }
            ConfigSlider {
                visible: settingsVisualizer2.entry?.style === "wuwa"
                text: Translation.tr("Width")
                buttonIcon: "aspect_ratio"
                usePercentTooltip: false
                value: settingsVisualizer2.entry?.customWidth ?? 860
                from: 300
                to: 1920
                stopIndicatorValues: [860]
                onValueChanged: {
                    if (settingsVisualizer2.entry)
                        settingsVisualizer2.entry.customWidth = Math.round(value);
                }
            }
            ConfigSlider {
                visible: settingsVisualizer2.entry?.style === "ring"
                text: Translation.tr("Ring Size")
                buttonIcon: "aspect_ratio"
                usePercentTooltip: false
                value: settingsVisualizer2.entry?.ringSize ?? 380
                from: 150
                to: 900
                stopIndicatorValues: [380]
                onValueChanged: {
                    if (settingsVisualizer2.entry)
                        settingsVisualizer2.entry.ringSize = Math.round(value);
                }
            }
        }
    }
}
