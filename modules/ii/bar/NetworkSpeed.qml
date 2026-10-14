import QtQuick
import qs.modules.common
import "widgets/networkSpeed"

Loader {
    id: root
    property bool vertical: false
    implicitWidth: item?.implicitWidth ?? 0
    implicitHeight: item?.implicitHeight ?? 0
    visible: item?.visible ?? false
    sourceComponent: (Config.options?.bar?.styles?.networkSpeed ?? "default") === "expressive" ? expressive : plain
    Component { id: plain; NetworkSpeedWidget { vertical: root.vertical } }
    Component { id: expressive; ExpressiveNetworkSpeed { vertical: root.vertical } }
}
