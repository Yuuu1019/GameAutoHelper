;@Ahk2Exe-SetMainIcon res\raincloud.ico
;@Ahk2Exe-SetCompanyName 小雨
;@Ahk2Exe-SetProductName 冬雨游戏助手
;@Ahk2Exe-SetFileVersion 1.0.0.0
;@Ahk2Exe-SetProductVersion 1.0.0.0
;@Ahk2Exe-SetCopyright Copyright (C) 2025 小雨
;@Ahk2Exe-SetDescription 冬雨游戏助手 - 游戏环境切换器
;@Ahk2Exe-SetInternalName DongyuGameHelper
;@Ahk2Exe-SetOrigFilename 冬雨游戏助手.exe

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetWorkingDir(A_ScriptDir)

#Include utils\JSON.ahk
#Include utils\ActionDefs.ahk
#Include utils\ThemeManager.ahk
#Include core\Logger.ahk
#Include core\ConfigManager.ahk
#Include core\PathDetector.ahk
#Include core\Notifier.ahk
#Include core\ProfileManager.ahk
#Include core\UndoStack.ahk
#Include actions\Actions.ahk
#Include core\ActionExecutor.ahk
#Include core\Detector.ahk
#Include ui\EditDialog.ahk
#Include ui\ProcessPickerDialog.ahk
#Include ui\ProfileSettingsDialog.ahk
#Include ui\SettingsDialog.ahk
#Include ui\LogViewer.ahk
#Include ui\AboutDialog.ahk
#Include ui\MainWindow.ahk

if (!A_IsAdmin) {
    try {
        Run('*RunAs "' A_ScriptFullPath '"')
    } catch as e {
        MsgBox("必须管理员权限才能运行本程序。`n`n提权失败：" e.Message, "提示", "IconX")
    }
    ExitApp()
}

Logger.Init()
Logger.Info("========== 冬雨游戏助手 启动 ==========")

ConfigManager.Init()
ProfileManager.Init()
MainWindow.Show()