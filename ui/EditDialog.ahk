; ui\EditDialog.ahk
; 添加 / 编辑动作的对话框

class EditDialog {
    static Show(profileId, rowNum) {
        profile := ProfileManager.GetById(profileId)
        if (!IsObject(profile))
            return

        types := ActionDefs.Types()
        typeNames := []
        for _, t in types
            typeNames.Push(t.name)

        actions := profile["actions"]
        curType := "resolution"
        curParam := ""
        if (rowNum > 0 && rowNum <= actions.Length) {
            curType := actions[rowNum]["type"]
            curParam := actions[rowNum]["param"]
        }

        ui := Map()
        result := Map("ok", false, "type", "", "param", "")

        dlg := Gui("+Owner" MainWindow.gui.Hwnd " +ToolWindow -MaximizeBox", rowNum > 0 ? "编辑动作" : "添加动作")
        dlg.SetFont("s9", "Microsoft YaHei UI")
        dlg.BackColor := "0xFFFFFF"

        dlg.Add("Text", "x20 y22 w120", "动作类型")
        ddType := dlg.Add("DropDownList", "x140 y18 w300", typeNames)
        ui["ddType"] := ddType

        dlg.Add("Text", "x20 y62 w120", "参数")
        editParam := dlg.Add("Edit", "x140 y58 w220", "")
        ui["editParam"] := editParam

        suffixText := dlg.Add("Text", "x370 y62 w60 c0x6B7280", "")
        ui["suffixText"] := suffixText

        ddParam := dlg.Add("DropDownList", "x140 y58 w300", [""])
        ui["ddParam"] := ddParam

        btnBrowse := dlg.Add("Button", "x370 y57 w70 h26", "浏览…")
        ui["btnBrowse"] := btnBrowse

        hintText := dlg.Add("Text", "x20 y100 w440 h50 c0x6B7280", "")
        hintText.SetFont("s8 c0x6B7280", "Microsoft YaHei UI")
        ui["hintText"] := hintText

        ui["types"] := types
        ui["originalType"] := curType
        ui["originalParam"] := curParam

        for i, t in types
            if (t.type == curType) {
                ddType.Choose(i)
                break
            }

        ddType.OnEvent("Change", (*) => EditDialog._UpdateUI(ui))
        ddParam.OnEvent("Change", (*) => EditDialog._OnParamChange(ui))
        btnBrowse.OnEvent("Click", (*) => EditDialog._Browse(ui))

        btnOK := dlg.Add("Button", "x250 y160 w90 h30 Default", "确定")
        btnCancel := dlg.Add("Button", "x350 y160 w90 h30", "取消")
        btnOK.OnEvent("Click", (*) => EditDialog._Confirm(ui, result, dlg))
        btnCancel.OnEvent("Click", (*) => dlg.Destroy())

        dlg.Show("w480 h210")

        EditDialog._UpdateUI(ui)

        WinWaitClose("ahk_id " dlg.Hwnd)

        if (!result["ok"])
            return

        pName := profile["displayName"]
        dispName := ActionDefs.DisplayName(result["type"])
        newAct := Map("type", result["type"], "param", result["param"])

        if (rowNum > 0 && rowNum <= actions.Length) {
            oldType := actions[rowNum]["type"]
            oldName := ActionDefs.DisplayName(oldType)
            actions[rowNum] := newAct
            Logger.Info(Format("编辑动作：档案「{}」第 {} 步：{} → {}", pName, rowNum, oldName, dispName))
        } else {
            actions.Push(newAct)
            Logger.Info(Format("添加动作：「{}」到档案「{}」", dispName, pName))
        }

        ProfileManager.Save()
        MainWindow.RefreshListView()
        MainWindow.SetStatus("动作已保存", "0x10B981")
    }

    static _ResetLayout(ui) {
        ui["editParam"].Move(140, 58, 220, 24)
        ui["editParam"].Visible := true
        ui["ddParam"].Move(140, 58, 300, 24)
        ui["ddParam"].Visible := false
        ui["btnBrowse"].Move(370, 57, 70, 26)
        ui["btnBrowse"].Visible := false
        ui["suffixText"].Move(370, 62, 60, 24)
        ui["suffixText"].Visible := false
        ui["suffixText"].Value := ""
    }

    static _UpdateUI(ui) {
        idx := ui["ddType"].Value
        types := ui["types"]
        if (idx < 1 || idx > types.Length)
            return
        t := types[idx]
        ui["hintText"].Value := t.hint

        EditDialog._ResetLayout(ui)

        isOriginal := (t.type == ui["originalType"])

        switch t.editor {
            case "text":
                ui["editParam"].Value := isOriginal ? ui["originalParam"] : t.default
            case "sleep":
                ui["suffixText"].Visible := true
                ui["suffixText"].Value := "秒"
                val := t.default
                if (isOriginal) {
                    try val := String(Integer(ui["originalParam"]) / 1000)
                }
                ui["editParam"].Value := val
            case "dropdown":
                ui["editParam"].Visible := false
                ui["ddParam"].Visible := true
                ui["ddParam"].Delete()
                ui["ddParam"].Add(t.options)
                chosen := 1
                if (isOriginal) {
                    for i, v in t.values
                        if (v == ui["originalParam"]) {
                            chosen := i
                            break
                        }
                }
                ui["ddParam"].Choose(chosen)
            case "file":
                ui["btnBrowse"].Visible := true
                ui["editParam"].Value := isOriginal ? ui["originalParam"] : ""
            case "resolution":
                ui["ddParam"].Move(140, 58, 150, 24)
                ui["ddParam"].Visible := true
                ui["editParam"].Move(296, 58, 144, 24)
                ui["editParam"].Visible := true

                presets := t.options
                ui["ddParam"].Delete()
                ui["ddParam"].Add(presets)
                ui["ddParam"].Add(["自定义"])

                curVal := isOriginal ? ui["originalParam"] : t.default
                ui["editParam"].Value := curVal

                foundIdx := 0
                for i, p in presets
                    if (p == curVal) {
                        foundIdx := i
                        break
                    }
                if (foundIdx > 0)
                    ui["ddParam"].Choose(foundIdx)
                else
                    ui["ddParam"].Choose(presets.Length + 1)
            case "none":
                ui["editParam"].Visible := false
        }
    }

    static _OnParamChange(ui) {
        idx := ui["ddType"].Value
        types := ui["types"]
        if (idx < 1 || idx > types.Length)
            return
        t := types[idx]
        if (t.editor != "resolution")
            return
        dv := ui["ddParam"].Value
        presets := t.options
        if (dv >= 1 && dv <= presets.Length)
            ui["editParam"].Value := presets[dv]
    }

    static _Browse(ui) {
        file := FileSelect(3, , "选择程序", "可执行文件 (*.exe)")
        if (file != "")
            ui["editParam"].Value := file
    }

    static _Confirm(ui, result, dlg) {
        idx := ui["ddType"].Value
        types := ui["types"]
        if (idx < 1 || idx > types.Length)
            return
        t := types[idx]

        param := ""
        switch t.editor {
            case "text", "file":
                param := Trim(ui["editParam"].Value)
            case "sleep":
                try {
                    sec := Float(Trim(ui["editParam"].Value))
                    param := String(Round(sec * 1000))
                } catch {
                    MsgBox("请输入有效数字", "错误", "IconX")
                    return
                }
            case "dropdown":
                dv := ui["ddParam"].Value
                param := (dv >= 1 && dv <= t.values.Length) ? t.values[dv] : t.values[1]
            case "resolution":
                param := Trim(ui["editParam"].Value)
                parts := StrSplit(param, "x")
                if (parts.Length != 2) {
                    MsgBox("分辨率格式应为 宽x高，例如 1920x1080", "错误", "IconX")
                    return
                }
                try {
                    Integer(parts[1])
                    Integer(parts[2])
                } catch {
                    MsgBox("分辨率的宽和高必须是数字", "错误", "IconX")
                    return
                }
            case "none":
                param := ""
        }

        result["ok"] := true
        result["type"] := t.type
        result["param"] := param
        dlg.Destroy()
    }
}