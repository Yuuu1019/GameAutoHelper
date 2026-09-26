; ui\ProfileSettingsDialog.ahk
; 档案设置：启动器进程、本体进程、附加进程、触发时机

class ProfileSettingsDialog {
    static Show(profileId) {
        profile := ProfileManager.GetById(profileId)
        if (!IsObject(profile))
            return

        if !profile.Has("triggerMode")
            profile["triggerMode"] := "start"
        if !profile.Has("launcherProcess")
            profile["launcherProcess"] := ""
        if !profile.Has("gameProcess")
            profile["gameProcess"] := ""
        if !profile.Has("extraProcesses")
            profile["extraProcesses"] := ""
        if !profile.Has("exitAfterComplete")
            profile["exitAfterComplete"] := false

        result := Map("ok", false)

        dlg := Gui("+Owner" MainWindow.gui.Hwnd " +ToolWindow -MaximizeBox", "档案设置")
        dlg.SetFont("s9", "Microsoft YaHei UI")
        dlg.BackColor := "0xFFFFFF"

        ; ── 启动器进程 ──
        dlg.Add("Text", "x20 y22 w100 h22", "启动器进程")
        editLauncher := dlg.Add("Edit", "x130 y18 w300", profile["launcherProcess"])
        btnDetectL := dlg.Add("Button", "x438 y17 w80 h26", "检测…")
        btnBrowseL := dlg.Add("Button", "x524 y17 w80 h26", "浏览…")

        ; ── 本体进程 ──
        dlg.Add("Text", "x20 y55 w100 h22", "本体进程")
        editGame := dlg.Add("Edit", "x130 y51 w300", profile["gameProcess"])
        btnDetectG := dlg.Add("Button", "x438 y50 w80 h26", "检测…")
        btnBrowseG := dlg.Add("Button", "x524 y50 w80 h26", "浏览…")

        ; ── 附加进程 ──
        dlg.Add("Text", "x20 y88 w110 h22", "附加进程")
        editExtra := dlg.Add("Edit", "x130 y84 w474", profile["extraProcesses"])

        hintExtra := dlg.Add("Text", "x130 y110 w474 h18 c0x6B7280", "多个进程用英文分号分隔，可留空")
        hintExtra.SetFont("s8 c0x6B7280", "Microsoft YaHei UI")

        ; ── 触发时机 ──
        dlg.Add("Text", "x20 y140 w110 h22", "触发时机")
        ddTrigger := dlg.Add("DropDownList", "x130 y136 w474",
            ["进程启动时", "进程全部关闭时", "仅手动"])
        triggerValues := ["start", "close", "manual"]
        cur := profile["triggerMode"]
        if (cur == "anyClose" || cur == "allClose")
            cur := "close"
        chosen := 3
        for i, v in triggerValues
            if (v == cur) {
                chosen := i
                break
            }
        ddTrigger.Choose(chosen)

        cbExit := dlg.Add("CheckBox", "x130 y172 w474", "序列执行完成后退出本脚本")
        cbExit.Value := profile["exitAfterComplete"] ? 1 : 0

        hint := dlg.Add("Text", "x20 y206 w590 h60 c0x6B7280",
            "操作说明：`n【检测…】列出当前正在运行的进程，从里面选一个`n【浏览…】手动选择 exe 文件（只取文件名作为进程名）")
        hint.SetFont("s8 c0x6B7280", "Microsoft YaHei UI")

        btnOK := dlg.Add("Button", "x410 y280 w90 h30 Default", "确定")
        btnCancel := dlg.Add("Button", "x510 y280 w90 h30", "取消")

        btnDetectL.OnEvent("Click", (*) => ProfileSettingsDialog._Detect(editLauncher))
        btnBrowseL.OnEvent("Click", (*) => ProfileSettingsDialog._Browse(editLauncher))

        btnDetectG.OnEvent("Click", (*) => ProfileSettingsDialog._Detect(editGame))
        btnBrowseG.OnEvent("Click", (*) => ProfileSettingsDialog._Browse(editGame))

        btnOK.OnEvent("Click", (*) => ProfileSettingsDialog._Save(result, editLauncher, editGame, editExtra, ddTrigger, cbExit, triggerValues, dlg))
        btnCancel.OnEvent("Click", (*) => dlg.Destroy())

        dlg.Show("w630 h340")
        WinWaitClose("ahk_id " dlg.Hwnd)

        if (!result["ok"])
            return

        profile["launcherProcess"] := result["launcher"]
        profile["gameProcess"] := result["game"]
        profile["extraProcesses"] := result["extra"]
        profile["triggerMode"] := result["trigger"]
        profile["exitAfterComplete"] := result["exit"]
        ProfileManager.Save()
        Logger.Info(Format("修改档案「{}」设置：启动器={} 本体={} 附加={} 触发={}", profile["displayName"], result["launcher"], result["game"], result["extra"], result["trigger"]))
        MainWindow.RefreshTabs()
        MainWindow.RefreshListView()
        MainWindow.SetStatus("档案设置已保存", "0x10B981")
    }

    ; 检测：从当前运行的进程里选
    static _Detect(editCtrl) {
        picked := ProcessPickerDialog.Show()
        if (picked != "")
            editCtrl.Value := picked
    }

    ; 浏览：手动选文件，只取文件名
    static _Browse(editCtrl) {
        file := FileSelect(3, , "选择程序", "可执行文件 (*.exe)")
        if (file != "") {
            SplitPath(file, &fname)
            editCtrl.Value := fname
        }
    }

    static _Save(result, editLauncher, editGame, editExtra, ddTrigger, cbExit, triggerValues, dlg) {
        result["ok"] := true
        result["launcher"] := Trim(editLauncher.Value)
        result["game"] := Trim(editGame.Value)
        result["extra"] := Trim(editExtra.Value)
        result["trigger"] := triggerValues[ddTrigger.Value]
        result["exit"] := cbExit.Value ? true : false
        dlg.Destroy()
    }
}