pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common.functions
import QtCore
import QtQuick
import Quickshell

Singleton {
    // XDG Dirs, with "file://"
    readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
    readonly property string genericCache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property string documents: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
    readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string music: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
    readonly property string videos: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]

    // Other dirs used by the shell, without "file://"
    property string assetsPath: Quickshell.shellPath("assets")
    property string scriptPath: Quickshell.shellPath("scripts")
    property string favicons: FileUtils.trimFileProtocol(`${Directories.cache}/media/favicons`)
    property string coverArt: FileUtils.trimFileProtocol(`${Directories.cache}/media/coverart`)
    property string tempImages: "/tmp/quickshell/media/images"
    property string booruPreviews: FileUtils.trimFileProtocol(`${Directories.cache}/media/boorus`)
    property string booruDownloads: FileUtils.trimFileProtocol(Directories.pictures  + "/homework")
    property string booruDownloadsNsfw: FileUtils.trimFileProtocol(Directories.pictures + "/homework/🌶️")
    property string latexOutput: FileUtils.trimFileProtocol(`${Directories.cache}/media/latex`)
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse`)
    property string shellConfigName: "config.json"
    property string shellConfigPath: `${Directories.shellConfig}/${Directories.shellConfigName}`
	property string todoPath: FileUtils.trimFileProtocol(`${Directories.state}/user/todo.json`)
	property string notesPath: FileUtils.trimFileProtocol(`${Directories.state}/user/notes.txt`)
    property string desktopNotesPath: FileUtils.trimFileProtocol(`${Directories.state}/user/desktopnotes.txt`)
	property string conflictCachePath: FileUtils.trimFileProtocol(`${Directories.cache}/conflict-killer`)
    property string notificationsPath: FileUtils.trimFileProtocol(`${Directories.cache}/notifications/notifications.json`)
    property string generatedMaterialThemePath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/colors.json`)
    property string wallpaperPreviewColorsPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/wallpaper_preview_colors.json`)
    property string defaultPreviewColorsDarkPath: FileUtils.trimFileProtocol(Quickshell.shellPath("assets/data/default_preview_colors_dark.json"))
    property string defaultPreviewColorsLightPath: FileUtils.trimFileProtocol(Quickshell.shellPath("assets/data/default_preview_colors_light.json"))
    property string defaultWallpaperImagePath: FileUtils.trimFileProtocol(Quickshell.shellPath("assets/images/default_wallpaper.png"))
    property string lockscreenColorsPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/lockscreen_colors.json`)
    property string generatedWallpaperCategoryPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/wallpaper/category.txt`)
    property string cliphistDecode: FileUtils.trimFileProtocol(`/tmp/quickshell/media/cliphist`)
    property string screenshotTemp: "/tmp/quickshell/media/screenshot"
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/switchwall.sh`)
    property string defaultAiPrompts: Quickshell.shellPath("defaults/ai/prompts")
    property string userAiPrompts: FileUtils.trimFileProtocol(`${Directories.shellConfig}/ai/prompts`)
    property string userActions: FileUtils.trimFileProtocol(`${Directories.shellConfig}/actions`)
    property string aiChats: FileUtils.trimFileProtocol(`${Directories.state}/user/ai/chats`)
    property string aiTranslationScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/gemini-translate.sh`)
    property string recordScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/videos/record.sh`)
    property string userAvatarPathAccountsService: FileUtils.trimFileProtocol(`/var/lib/AccountsService/icons/${SystemInfo.username}`)
    property string userAvatarPathRicersAndWeirdSystems: FileUtils.trimFileProtocol(`${Directories.home}.face`)
    property string userAvatarPathRicersAndWeirdSystems2: FileUtils.trimFileProtocol(`${Directories.home}.face.icon`)
    property string userProfileImagePath: FileUtils.trimFileProtocol(`${Directories.shellConfig}/profile.png`)
    property string userPresetsPath: FileUtils.trimFileProtocol(`${Directories.shellConfig}/presets`)
    property string presetsScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/presets.sh`)
    property string generatedLockMaterialThemePath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/colors-lock.json`)
    property string eqScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/eq/equalizer.sh`)
    property string eqStateDir: FileUtils.trimFileProtocol(`${Directories.state}/user/eq`)
    // Paths shared by migrated app services.
    readonly property string desktop: StandardPaths.standardLocations(StandardPaths.DesktopLocation)[0] || (Directories.home + "/Desktop")
    property string desktopPath: FileUtils.trimFileProtocol(Directories.desktop)
    readonly property string runtime: FileUtils.trimFileProtocol(StandardPaths.standardLocations(StandardPaths.RuntimeLocation)[0] || "/run/user/1000")
    property string rustHelpersScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/rust-helpers.sh`)
    property string localMediaCoverCache: FileUtils.trimFileProtocol(`${Directories.cache}/media/local-media/covers`)
    property string localMediaLyricsCache: FileUtils.trimFileProtocol(`${Directories.cache}/media/local-media/lyrics`)
    property string phoneShare: FileUtils.trimFileProtocol(`${Directories.cache}/phone-share`)
    property string localSendDownloadPath: `${Directories.downloads || (Directories.home + "/Downloads")}/localsend`
    property string localPreferencesName: "local-preferences.json"
    property string localPreferencesPath: `${Directories.shellConfig}/${Directories.localPreferencesName}`
    property string welcomeRequestPath: FileUtils.trimFileProtocol(`${Directories.state}/user/welcome_pending`)
    property string todoDoneHistoryPath: FileUtils.trimFileProtocol(`${Directories.state}/user/todo_done.json`)
    property string remindersPath: FileUtils.trimFileProtocol(`${Directories.state}/user/reminders.json`)
    property string reminderAttachmentsDir: FileUtils.trimFileProtocol(`${Directories.state}/user/reminder_attachments`)
    property string appUsagePath: FileUtils.trimFileProtocol(`${Directories.state}/user/app_usage.json`)
    property string appStats: FileUtils.trimFileProtocol(`${Directories.state}/user/app_stats`)
    property string commandsPath: FileUtils.trimFileProtocol(`${Directories.state}/user/commands.json`)
    property string keybindsPath: FileUtils.trimFileProtocol(`${Directories.state}/user/keybinds.json`)
    property string keybindTemplatesPath: FileUtils.trimFileProtocol(Quickshell.shellPath("defaults/keybinds/templates.json"))
    property string keybindImporterPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/keybinds/import_keybinds.py`)
    property string keybindAiCategorizerPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/keybinds/ai_categorize.py`)
    property string noteSketchesDir: FileUtils.trimFileProtocol(`${Directories.state}/user/note_sketches`)
    property string notesDir: FileUtils.trimFileProtocol(`${Directories.state}/user/notes`)
    property string notesIndexPath: `${Directories.notesDir}/index.json`
    property string notesDocsDir: `${Directories.notesDir}/docs`
    property string notesAssetsDir: `${Directories.notesDir}/assets`
    property string notesRevisionsDir: `${Directories.notesDir}/revisions`
    property string notesLegacyBackupPath: `${Directories.notesPath}.migrated`
    property string notesLinkPreviewsCacheDir: FileUtils.trimFileProtocol(`${Directories.cache}/media/link_previews`)
    property string lyricsPath: FileUtils.trimFileProtocol(`${Directories.cache}/lyrics/lyrics.json`)
    property string betterlyricsCachePath: FileUtils.trimFileProtocol(`${Directories.cache}/lyrics/betterlyrics.json`)
    property string customLyricsPath: FileUtils.trimFileProtocol(`${Directories.state}/user/custom-lyrics.json`)
    property string holidaysCachePath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/holidays.json`)
    property string shellUpdateSummaryPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/shell_update_summary.json`)
    property string sportsCachePath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/sports.json`)
    property string googleCalendarColorsPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/google_calendar_colors.json`)
    property string generateLockscreenColorsScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/generate-lockscreen-colors.sh`)
    property string gammaControlScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/brightness/ii-gamma-control`)
    property string displayColorFilterWriterPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/display/write_color_filter.py`)
    property string displayColorFilterGeneratedPath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/display-color-filter`)
    property string defaultThemes: Quickshell.shellPath("defaults/themes")
    property string customThemes: `${Directories.shellConfig}/themes`
    property string aiUsage: FileUtils.trimFileProtocol(`${Directories.state}/user/ai/usage.json`)
    property string aiDrafts: FileUtils.trimFileProtocol(`${Directories.state}/user/ai/drafts`)
    property string aiSessions: FileUtils.trimFileProtocol(`${Directories.state}/user/ai/sessions`)
    property string aiExports: FileUtils.trimFileProtocol(`${Directories.documents}/ai-chats`)
    property string aiSessionsScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/ai_sessions.py`)
    property string aiDraftsScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/ai_drafts.py`)
    property string aiAttachScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/ai_attach.py`)
    property string aiSettingsIndexPath: FileUtils.trimFileProtocol(`${Directories.state}/user/ai/settings_index.json`)
    property string aiLastAnswer: FileUtils.trimFileProtocol(`${Directories.state}/user/ai/last_answer.json`)
    property string aiSettingsIndexScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/ai_settings_index.py`)
    property string aiWebScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/ai_web.py`)
    property string aiRagScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/ai/ai_rag.py`)
    property string aiRagIndexDir: FileUtils.trimFileProtocol(`${Directories.state}/user/ai/rag_index`)
    property string processVideoScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/videos/compress_video.py`)
    property string extractColorsScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/wallpapers/extract-colors.sh`)
    property string colorCachePath: FileUtils.trimFileProtocol(`${Directories.cache}/wallpapers/colors.json`)
    property string screenshareStateScript: FileUtils.trimFileProtocol(`${Directories.scriptPath}/screenShare/screensharestate.sh`)
    property string screenshareStatePath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/screenshare/apps.txt`)
    property string geniusLyricsScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/lyrics/genius-lyrics.js`)
    property string ytmusicLyricsScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/lyrics/ytmusic-lyrics-wrapper.sh`)
    property string userWidgetsPath: FileUtils.trimFileProtocol(`${Directories.shellConfig}/user_widgets`)
    property string widgetExtensionsPath: `${Directories.shellConfig}/widget_extensions.json`
    property string widgetBackupsPath: FileUtils.trimFileProtocol(`${Directories.shellConfig}/user_widgets/.backups`)



    // Cleanup on init
    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", `${userPresetsPath}`])
        Quickshell.execDetached(["mkdir", "-p", `${shellConfig}`])
        Quickshell.execDetached(["mkdir", "-p", `${favicons}`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${coverArt}'; mkdir -p '${coverArt}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${booruPreviews}'; mkdir -p '${booruPreviews}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${latexOutput}'; mkdir -p '${latexOutput}'`])
        Quickshell.execDetached(["bash", "-c", `rm -rf '${cliphistDecode}'; mkdir -p '${cliphistDecode}'`])
        Quickshell.execDetached(["mkdir", "-p", `${aiChats}`])
        Quickshell.execDetached(["mkdir", "-p", `${userActions}`])
        Quickshell.execDetached(["mkdir", "-p", `${eqStateDir}`])
        Quickshell.execDetached(["rm", "-rf", `${tempImages}`])
    }
}
