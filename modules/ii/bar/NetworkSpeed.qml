import QtQuick
import qs.modules.common
import "widgets/networkSpeed"

Item {
    id: root
    property bool vertical: false
    implicitWidth: content.item?.implicitWidth ?? 0
    implicitHeight: content.item?.implicitHeight ?? 0
    visible: content.item?.visible ?? false
    Loader {
        id: content
        sourceComponent: (Config.options?.bar?.styles?.networkSpeed ?? "default") === "expressive" ? expressive : plain
    }
    Component { id: plain; NetworkSpeedWidget { vertical: root.vertical } }
    Component { id: expressive; ExpressiveNetworkSpeed { vertical: root.vertical } }
}
