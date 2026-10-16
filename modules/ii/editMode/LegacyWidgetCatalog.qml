pragma Singleton
import QtQuick
import Quickshell

// The original desktop widgets keep their existing singleton config entries.
Singleton {
    readonly property var widgets: [
        { id: "clock", name: qsTr("Clock"), icon: "schedule", category: "Clock" },
        { id: "weather", name: qsTr("Weather"), icon: "cloud", category: "Weather" },
        { id: "calendar", name: qsTr("Calendar"), icon: "calendar_month", category: "Productivity" },
        { id: "worldClock", name: qsTr("World clock"), icon: "public", category: "Clock" },
        { id: "notes", name: qsTr("Notes"), icon: "note", category: "Productivity" },
        { id: "todo", name: qsTr("To-do"), icon: "checklist", category: "Productivity" },
        { id: "userCard", name: qsTr("User card"), icon: "person", category: "System" },
        { id: "images", name: qsTr("Image converter"), icon: "image", category: "Images" },
        { id: "customImage", name: qsTr("Custom image"), icon: "photo", category: "Images" },
        { id: "resources", name: qsTr("Resources"), icon: "monitor_heart", category: "System" },
        { id: "timers", name: qsTr("Timers"), icon: "timer", category: "Clock" },
        { id: "media", name: qsTr("Media"), icon: "music_note", category: "Media" },
        { id: "visualizer", name: qsTr("Visualizer"), icon: "graphic_eq", category: "Media" },
        { id: "visualizer2", name: qsTr("Second visualizer"), icon: "graphic_eq", category: "Media" }
    ]
}
