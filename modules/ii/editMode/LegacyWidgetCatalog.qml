pragma Singleton
import QtQuick
import Quickshell

// The original desktop widgets keep their existing singleton config entries.
Singleton {
    readonly property var widgets: [
        { id: "clock", name: qsTr("Clock"), icon: "schedule", category: "Legacy" },
        { id: "weather", name: qsTr("Weather"), icon: "cloud", category: "Legacy" },
        { id: "calendar", name: qsTr("Calendar"), icon: "calendar_month", category: "Legacy" },
        { id: "worldClock", name: qsTr("World clock"), icon: "public", category: "Legacy" },
        { id: "notes", name: qsTr("Notes"), icon: "note", category: "Legacy" },
        { id: "todo", name: qsTr("To-do"), icon: "checklist", category: "Legacy" },
        { id: "userCard", name: qsTr("User card"), icon: "person", category: "Legacy" },
        { id: "images", name: qsTr("Image converter"), icon: "image", category: "Legacy" },
        { id: "customImage", name: qsTr("Custom image"), icon: "photo", category: "Legacy" },
        { id: "resources", name: qsTr("Resources"), icon: "monitor_heart", category: "Legacy" },
        { id: "timers", name: qsTr("Timers"), icon: "timer", category: "Legacy" },
        { id: "media", name: qsTr("Media"), icon: "music_note", category: "Legacy" },
        { id: "visualizer", name: qsTr("Visualizer"), icon: "graphic_eq", category: "Legacy" },
        { id: "visualizer2", name: qsTr("Second visualizer"), icon: "graphic_eq", category: "Legacy" }
    ]
}
