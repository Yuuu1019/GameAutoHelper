; ui\ProcessPickerDialog.ahk
; 从当前运行的进程里选一个

class ProcessPickerDialog {
    static Show() {
        result := Map("ok", false, "name", "")

        dlg := Gui("+Owner" MainWindow.gui.Hwnd " +ToolWindow -MaximizeBox", "检测当前运行的进程")
        dlg.SetFont("s9", "Microsoft YaHei UI")
        dlg.BackColor := "0xFFFFFF"

        dlg.Add("Text", "x20 y18 w60 h22", "搜索")
        editSearch := dlg.Add("Edit", "x80 y15 w380", "")

        lv := dlg.Add("ListView", "x20 y50 w440 h280 -Multi", ["进程名"])
        lv.ModifyCol(1, 420)
        lv.SetFont("s9", "Consolas")

        allProcs := ProcessPickerDialog._GetAllProcesses()
        for _, name in allProcs
            lv.Add(, name)

        dlg.Add("Text", "x20 y342 w80 h22", "已选中")
        editSelected := dlg.Add("Edit", "x100 y339 w360 h24 ReadOnly", "")
        editSelected.SetFont("s9 c0x2563EB", "Consolas")

        ; ★ Click 事件签名：(ctrl, row)，row 直接是行号
        lv.OnEvent("Click", (ctrl, row) => ProcessPickerDialog._OnSelect(lv, row, editSelected))
        lv.OnEvent("DoubleClick", (ctrl, row) => ProcessPickerDialog._OnDoubleClick(lv, row, result, dlg))

        editSearch.OnEvent("Change", (*) => ProcessPickerDialog._Filter(lv, allProcs, editSearch.Value, editSelected))

        btnRefresh := dlg.Add("Button", "x20 y372 w90 h30", "刷新")
        btnRefresh.OnEvent("Click", (*) => ProcessPickerDialog._Refresh(lv, editSelected))

        statusText := dlg.Add("Text", "x120 y378 w160 h20 c0x6B7280", "共 " allProcs.Length " 个")
        statusText.SetFont("s8 c0x6B7280", "Microsoft YaHei UI")

        btnOK := dlg.Add("Button", "x290 y372 w80 h30 Default", "确定")
        btnOK.OnEvent("Click", (*) => ProcessPickerDialog._Confirm(result, editSelected, dlg))

        btnCancel := dlg.Add("Button", "x380 y372 w80 h30", "取消")
        btnCancel.OnEvent("Click", (*) => dlg.Destroy())

        dlg.Show("w480 h420")
        WinWaitClose("ahk_id " dlg.Hwnd)

        if (!result["ok"])
            return ""
        return result["name"]
    }

    static _GetAllProcesses() {
        names := Map()
        try {
            cmd := A_ComSpec ' /c tasklist /FO CSV /NH'
            shell := ComObject("WScript.Shell")
            exec := shell.Exec(cmd)
            output := exec.StdOut.ReadAll()

            for line in StrSplit(output, "`n", "`r") {
                line := Trim(line)
                if (line == "")
                    continue
                if (SubStr(line, 1, 1) != '"')
                    continue
                endPos := InStr(line, '"', , 2)
                if (endPos <= 1)
                    continue
                name := SubStr(line, 2, endPos - 2)
                if (name != "")
                    names[name] := true
            }
        } catch {
        }

        arr := []
        for n, _ in names
            arr.Push(n)
        return this._SortArray(arr)
    }

    static _SortArray(arr) {
        n := arr.Length
        if (n < 2)
            return arr
        loop n - 1 {
            i := 1
            while (i < n) {
                if (StrCompare(arr[i], arr[i+1]) > 0) {
                    tmp := arr[i]
                    arr[i] := arr[i+1]
                    arr[i+1] := tmp
                }
                i++
            }
            n--
        }
        return arr
    }

    ; ★ 单击选中 → 更新"已选中"
    static _OnSelect(lv, row, editSelected) {
        if (row > 0 && row <= lv.GetCount())
            editSelected.Value := lv.GetText(row, 1)
    }

    ; ★ 双击直接确定
    static _OnDoubleClick(lv, row, result, dlg) {
        if (row <= 0 || row > lv.GetCount())
            return
        name := lv.GetText(row, 1)
        if (name == "")
            return
        result["ok"] := true
        result["name"] := name
        dlg.Destroy()
    }

    static _Filter(lv, allProcs, keyword, editSelected) {
        lv.Delete()
        editSelected.Value := ""
        kw := StrLower(Trim(keyword))
        for _, name in allProcs {
            if (kw == "" || InStr(StrLower(name), kw))
                lv.Add(, name)
        }
    }

    static _Refresh(lv, editSelected) {
        newProcs := ProcessPickerDialog._GetAllProcesses()
        lv.Delete()
        editSelected.Value := ""
        for _, name in newProcs
            lv.Add(, name)
    }

    static _Confirm(result, editSelected, dlg) {
        name := Trim(editSelected.Value)
        if (name == "") {
            MsgBox("请先单击一行选择进程", "提示", "Icon!")
            return
        }
        result["ok"] := true
        result["name"] := name
        dlg.Destroy()
    }
}