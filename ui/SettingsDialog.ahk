; ui\SettingsDialog.ahk

class SettingsDialog {
    static Show() {
        t := ThemeManager.Current()
        result := Map("ok", false)

        dlg := Gui("+Owner" MainWindow.gui.Hwnd " +ToolWindow -MaximizeBox", "全局设置")
        dlg.SetFont(t["fontSize"], t["fontName"])
        dlg.BackColor := t["bg"]

        dlg.Add("Text", "x20 y22 w120", "dispwin.exe")
        editDispwin := dlg.Add("Edit", "x140 y18 w400", ConfigManager.Get("dispwinPath", ""))
        btnBrowseDispwin := dlg.Add("Button", "x548 y17 w80 h26", "浏览…")

        dlg.Add("Text", "x20 y60 w120", "ICC 文件")
        editICC := dlg.Add("Edit", "x140 y56 w400", ConfigManager.Get("iccProfile", ""))
        btnBrowseICC := dlg.Add("Button", "x548 y55 w80 h26", "浏览…")

        btnAuto := dlg.Add("Button", "x140 y90 w120 h26", "自动检测路径")

        dlg.Add("Text", "x20 y132 w120", "界面主题")
        ddTheme := dlg.Add("DropDownList", "x140 y128 w200", ["简约", "美化"])
        themeValues := ["simple", "beautiful"]
        curTheme := ConfigManager.Get("theme", "simple")
        for i, v in themeValues
            if (v == curTheme) {
                ddTheme.Choose(i)
                break
            }

        ; ★ 通知设置
        dlg.Add("Text", "x20 y170 w120", "通知设置")
        cbNotifyEach := dlg.Add("CheckBox", "x140 y168 w400", "每个动作完成后通知")
        cbNotifyEach.Value := ConfigManager.Get("notifyEachAction", true) ? 1 : 0

        cbNotifyComplete := dlg.Add("CheckBox", "x140 y196 w400", "整个序列完成/停止时通知")
        cbNotifyComplete.Value := ConfigManager.Get("notifyOnComplete", true) ? 1 : 0

        ; 开机自启
        cbAuto := dlg.Add("CheckBox", "x140 y228 w300", "开机自动启动")
        cbAuto.Value := SettingsDialog._IsAutoStartEnabled() ? 1 : 0

        hint := dlg.Add("Text", "x20 y260 w610 h44 c" t["muted"],
            "提示：切换主题后脚本会自动重启。窗口点 X 隐藏到托盘，右键托盘图标可退出。")
        hint.SetFont("s8 c" t["muted"], t["fontName"])

        btnOK := dlg.Add("Button", "x440 y318 w90 h30 Default", "确定")
        btnCancel := dlg.Add("Button", "x540 y318 w90 h30", "取消")

        btnBrowseDispwin.OnEvent("Click", (*) => SettingsDialog._BrowseInto(editDispwin, "exe"))
        btnBrowseICC.OnEvent("Click", (*) => SettingsDialog._BrowseInto(editICC, "icc"))
        btnAuto.OnEvent("Click", (*) => SettingsDialog._AutoDetect(editDispwin, editICC))
        btnOK.OnEvent("Click", (*) => SettingsDialog._Save(result, editDispwin, editICC, ddTheme, themeValues, cbNotifyEach, cbNotifyComplete, cbAuto, dlg))
        btnCancel.OnEvent("Click", (*) => dlg.Destroy())

        dlg.Show("w640 h368")
        WinWaitClose("ahk_id " dlg.Hwnd)

        if (!result["ok"])
            return

        ConfigManager.Set("dispwinPath", result["dispwin"])
        ConfigManager.Set("iccProfile", result["icc"])
        ConfigManager.Set("theme", result["theme"])
        ConfigManager.Set("notifyEachAction", result["notifyEach"])
        ConfigManager.Set("notifyOnComplete", result["notifyComplete"])
        ConfigManager.Save()

        SettingsDialog._SetAutoStart(result["autostart"])

        if (result["theme"] != curTheme) {
            r := MsgBox("主题已切换，需要重启脚本生效。`n`n现在重启吗？", "重启脚本", "YesNo Icon!")
            if (r == "Yes") {
                try Run('*RunAs "' A_ScriptFullPath '"')
                ExitApp()
            }
        } else {
            MainWindow.SetStatus("设置已保存", "0x10B981")
        }
    }

    static _BrowseInto(editCtrl, kind) {
        if (kind == "exe")
            file := FileSelect(3, , "选择 dispwin.exe", "可执行文件 (*.exe)")
        else
            file := FileSelect(3, , "选择 ICC 文件", "色彩配置文件 (*.icc; *.icm)")
        if (file != "")
            editCtrl.Value := file
    }

    static _AutoDetect(editDispwin, editICC) {
        found := 0
        d := PathDetector.FindDispwin()
        if (d != "") {
            editDispwin.Value := d
            found++
        }
        i := PathDetector.FindICC()
        if (i != "") {
            editICC.Value := i
            found++
        }
        if (found == 0)
            MsgBox("未找到 dispwin.exe 或 ICC 文件，请手动选择。", "自动检测", "Icon!")
        else
            MsgBox(Format("已找到 {} 项，请确认后点确定。", found), "自动检测", "Icon!")
    }

    static _Save(result, editDispwin, editICC, ddTheme, themeValues, cbNotifyEach, cbNotifyComplete, cbAuto, dlg) {
        result["ok"] := true
        result["dispwin"] := Trim(editDispwin.Value)
        result["icc"] := Trim(editICC.Value)
        result["theme"] := themeValues[ddTheme.Value]
        result["notifyEach"] := cbNotifyEach.Value ? true : false
        result["notifyComplete"] := cbNotifyComplete.Value ? true : false
        result["autostart"] := cbAuto.Value ? true : false
        dlg.Destroy()
    }

    static _RunKey() {
        return "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    }

    static _IsAutoStartEnabled() {
        try {
            v := RegRead(this._RunKey(), "GameAutoHelper", "")
            return (v != "")
        } catch {
            return false
        }
    }

    static _SetAutoStart(enable) {
        try {
            if (enable) {
                if (A_IsCompiled)
                    cmd := '"' A_ScriptFullPath '"'
                else
                    cmd := '"' A_AhkPath '" "' A_ScriptFullPath '"'
                RegWrite(cmd, "REG_SZ", this._RunKey(), "GameAutoHelper")
            } else {
                try RegDelete(this._RunKey(), "GameAutoHelper")
            }
        } catch as e {
            MsgBox("设置开机自启失败：`n" e.Message, "错误", "IconX")
        }
    }
}