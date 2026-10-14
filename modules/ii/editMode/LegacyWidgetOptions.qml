import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    property string configName: ""
    readonly property var config: Config.options.background.widgets[root.configName]
    forceWidth: false
    readonly property var fieldNames: [
        "style", "styleLocked", "sizeMode", "path", "shape", "size", "color", "vertical", "expanded", "clockCount", "timezones",
        "height", "ringSize", "customWidth", "colorSource", "sensitivity", "showControls", "showLyrics", "showTitles", "backgroundShape",
        "showOnlyWhenLocked", "showDate", "showSeconds", "showWeather", "showBattery", "temperatureUnit", "content", "fontFamily", "fontSize",
        "digital.adaptiveAlignment", "digital.showDate", "digital.animateChange", "digital.vertical", "digital.font.family", "digital.font.size",
        "cookie.sides", "cookie.dialNumberStyle", "cookie.hourHandStyle", "cookie.minuteHandStyle", "cookie.secondHandStyle", "cookie.dateStyle",
        "cookie.timeIndicators", "cookie.hourMarks", "cookie.dateInClock", "cookie.constantlyRotate", "quote.enable", "quote.text"
    ]
    function value(path) {
        let target = root.config;
        for (const key of path.split(".")) target = target?.[key];
        return target;
    }
    function put(path, value) {
        let target = root.config;
        const keys = path.split(".");
        for (let i = 0; i < keys.length - 1; i++) target = target?.[keys[i]];
        if (target) target[keys[keys.length - 1]] = value;
    }
    function label(path) {
        return path.replace(/\./g, " · ").replace(/([a-z])([A-Z])/g, "$1 $2").replace(/^./, c => c.toUpperCase());
    }
    function choices(path) {
        if (path === "style" || path === "styleLocked") {
            if (root.configName === "clock") return ["digital", "cookie", "pixel"];
            if (root.configName.startsWith("visualizer")) return ["bars", "mirror", "aurora", "ring", "dots", "wuwa"];
        }
        if (path === "colorSource") return ["theme", "cover"];
        if (path === "sizeMode") return ["1x1", "1x2", "1x3", "2x2", "2x3"];
        if (path === "shape" || path === "backgroundShape") return ["Circle", "Square", "Cookie4Sided", "Cookie12Sided", "Clover4Leaf", "Pill", "Heart"];
        if (path === "cookie.dialNumberStyle") return ["full", "dots", "numbers", "none"];
        if (path === "cookie.hourHandStyle") return ["fill", "classic", "hollow", "hide"];
        if (path === "cookie.minuteHandStyle") return ["medium", "thin", "bold", "hide"];
        if (path === "cookie.secondHandStyle") return ["dot", "line", "classic", "hide"];
        if (path === "cookie.dateStyle") return ["bubble", "border", "rect", "hide"];
        return [];
    }
    readonly property var fields: root.fieldNames.filter(path => root.value(path) !== undefined)
    NoticeBox {
        Layout.fillWidth: true
        materialIcon: "tune"
        text: qsTr("Options apply immediately. Widgets of the same type share their appearance options.")
    }
    Repeater {
        model: root.fields
        delegate: Loader {
            id: field
            required property string modelData
            readonly property var current: root.value(modelData)
            Layout.fillWidth: true
            sourceComponent: root.choices(modelData).length ? choiceField : typeof current === "boolean" ? booleanField : typeof current === "number" ? numberField : textField
            Component {
                id: choiceField
                ConfigComboBox {
                    text: root.label(field.modelData)
                    fieldWidth: 175
                    model: root.choices(field.modelData).map(value => ({ value: value, displayName: value }))
                    currentValue: field.current
                    onSelected: value => root.put(field.modelData, value)
                }
            }
            Component {
                id: booleanField
                ConfigSwitch {
                    text: root.label(field.modelData); buttonIcon: "tune"
                    checked: !!field.current
                    onCheckedChanged: if (checked !== field.current) root.put(field.modelData, checked)
                }
            }
            Component {
                id: numberField
                ConfigSlider {
                    text: root.label(field.modelData); buttonIcon: "tune"
                    from: field.modelData === "clockCount" ? 1 : 0; to: field.modelData === "sensitivity" ? 5 : field.modelData === "clockCount" ? 12 : field.modelData === "cookie.sides" ? 32 : field.modelData.includes("font.size") ? 240 : 2000
                    stepSize: field.modelData === "sensitivity" ? 0.1 : 1
                    value: Number(field.current)
                    onValueChanged: if (value !== field.current) root.put(field.modelData, value)
                }
            }
            Component {
                id: textField
                ConfigTextField {
                    text: root.label(field.modelData); icon: "edit"
                    inputText: Array.isArray(field.current) ? field.current.join(", ") : String(field.current)
                    textField.onEditingFinished: root.put(field.modelData, Array.isArray(field.current) ? inputText.split(",").map(s => s.trim()).filter(Boolean) : inputText)
                }
            }
        }
    }
}
