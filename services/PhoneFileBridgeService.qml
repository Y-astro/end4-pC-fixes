pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import qs.services
import ".."
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * PhoneFileBridgeService
 * Singleton managing file transfers to the phone via high-speed ADB push
 * or KDE Connect fallback, directory navigation on /sdcard, and media scanning.
 */
Singleton {
    id: root

    readonly property string helperScript: FileUtils.trimFileProtocol(Directories.scriptPath + "/phone/phone_file_bridge.py")

    property bool adbReady: false
    property bool isTransferring: false
    property int transferIndex: 0
    property int transferTotal: 0
    property string currentFileName: ""
    property string targetPath: ""
    property string lastToast: ""

    signal transferCompleted(int count, string destination)
    signal transferFailed(string error)

    Component.onCompleted: {
        root.checkAdbReady()
    }

    Timer {
        interval: 8000
        repeat: true
        running: true
        onTriggered: root.checkAdbReady()
    }

    function checkAdbReady(): void {
        checkProc.running = true
    }

    Process {
        id: checkProc
        command: ["python3", root.helperScript, "is-ready"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res = JSON.parse(text.trim())
                    root.adbReady = res.ready ?? false
                } catch (e) {
                    root.adbReady = false
                }
            }
        }
    }

    /**
     * Lists subdirectories for a given path on the phone.
     * callback: function(array of folder names)
     */
    function listDirectory(remotePath: string, callback): void {
        const proc = listProcComponent.createObject(root, {
            "remotePath": remotePath,
            "callback": callback
        })
        proc.running = true
    }

    Component {
        id: listProcComponent
        Process {
            id: proc
            property string remotePath: "/sdcard"
            property var callback: null

            command: ["python3", root.helperScript, "list", remotePath]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const res = JSON.parse(text.trim())
                        if (proc.callback) {
                            proc.callback(res.folders || [])
                        }
                    } catch (e) {
                        if (proc.callback) proc.callback([])
                    }
                    proc.destroy()
                }
            }
        }
    }

    /**
     * Creates a new directory on the phone.
     */
    function createDirectory(remotePath: string, callback): void {
        const proc = mkdirProcComponent.createObject(root, {
            "remotePath": remotePath,
            "callback": callback
        })
        proc.running = true
    }

    Component {
        id: mkdirProcComponent
        Process {
            id: proc
            property string remotePath: ""
            property var callback: null

            command: ["python3", root.helperScript, "mkdir", remotePath]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const res = JSON.parse(text.trim())
                        if (proc.callback) proc.callback(res.status === "ok")
                    } catch (e) {
                        if (proc.callback) proc.callback(false)
                    }
                    proc.destroy()
                }
            }
        }
    }

    /**
     * Pushes an array of file URLs to the specified remote destination.
     */
    function pushFiles(fileUrls: var, destination: string, onComplete): void {
        if (!fileUrls || fileUrls.length === 0) return

        root.isTransferring = true
        root.transferIndex = 0
        root.transferTotal = fileUrls.length
        root.targetPath = destination
        root.currentFileName = ""

        // Convert URLs to file paths
        let paths = []
        for (let i = 0; i < fileUrls.length; i++) {
            let p = fileUrls[i].toString()
            if (p.startsWith("file://")) p = decodeURIComponent(p.substring(7))
            paths.push(p)
        }

        // Check if ADB is available for high-speed direct transfer
        if (root.adbReady || KdeConnectService.adbReachable) {
            const pushProc = pushProcComponent.createObject(root, {
                "destination": destination,
                "filePaths": paths,
                "onComplete": onComplete
            })
            pushProc.running = true
        } else {
            // Fallback to KDE Connect if ADB is unavailable
            root._fallbackKdeConnectSend(paths, destination, onComplete)
        }
    }

    Component {
        id: pushProcComponent
        Process {
            id: proc
            property string destination: "/sdcard/Download"
            property var filePaths: []
            property var onComplete: null
            property bool completedHandled: false

            command: ["python3", root.helperScript, "push", destination, ...filePaths]
            stdout: SplitParser {
                splitMarker: "\n"
                onRead: data => {
                    const line = String(data).trim()
                    if (!line) return
                    try {
                        const ev = JSON.parse(line)
                        if (ev.event === "progress") {
                            root.transferIndex = ev.index
                            root.transferTotal = ev.total
                            root.currentFileName = ev.file
                        } else if (ev.event === "complete") {
                            proc.completedHandled = true
                            root.isTransferring = false

                            if (ev.failed > 0 && ev.success === 0) {
                                const errMsg = (ev.failed_files && ev.failed_files.length > 0)
                                               ? ev.failed_files[0].message
                                               : "All file transfers failed"
                                root.transferFailed(errMsg)
                                if (proc.onComplete) proc.onComplete(false, ev.destination, errMsg)
                            } else {
                                root.transferCompleted(ev.success || ev.total, ev.destination)
                                if (proc.onComplete) proc.onComplete(true, ev.destination, "")
                            }
                        } else if (ev.event === "error") {
                            proc.completedHandled = true
                            root.isTransferring = false
                            root.transferFailed(ev.message || "Transfer error")
                            if (proc.onComplete) proc.onComplete(false, proc.destination, ev.message || "Transfer error")
                        } else if (ev.event === "file_error") {
                            root.lastError = ev.message || "File error"
                        }
                    } catch (e) {
                        // Ignore non-json lines
                    }
                }
            }
            onExited: (code, status) => {
                root.isTransferring = false
                if (!proc.completedHandled) {
                    proc.completedHandled = true
                    root.transferFailed("Transfer process exited prematurely")
                    if (proc.onComplete) proc.onComplete(false, proc.destination, "Transfer process exited prematurely")
                }
                proc.destroy()
            }
        }
    }

    function _fallbackKdeConnectSend(paths: var, destination: string, onComplete): void {
        let sent = 0
        for (let i = 0; i < paths.length; i++) {
            KdeConnectService.shareUrl(KdeConnectService.activeDeviceId, "file://" + paths[i])
            sent++
        }
        root.isTransferring = false
        root.transferCompleted(sent, "/sdcard/Download (KDE Connect)")
        if (onComplete) onComplete(true, "/sdcard/Download (KDE Connect)", "kdeconnect")
    }
}
