; ui\LogViewer.ahk
; 应用内日志查看器（实时刷新）

class LogViewer {
    static gui := ""
    static editCtrl := ""
    static statusText := ""
    static autoScrollCtrl := ""
    static timerRef := ""
    static _lastContent := ""
    static _active := false

    static Show() {
        t := ThemeManager.Current()

        if (IsObject(this.gui)) {
            try {
                this.gui.Show()
                WinActivate("ahk_id " this.gui.Hwnd)
                this._Refresh()
                this._StartTimer()
                return
            } catch {
            }
        }

        this.gui := Gui("+Resize +MaximizeBox", "日志 - 冬雨游戏助手")
        this.gui.SetFont(t["fontSize"], t["fontName"])
        this.gui.BackColor := t["bg"]
        this.gui.OnEvent("Close", (*) => this._OnClose())
        this.gui.OnEvent("Size", (g, mm, w, h) => this._OnSize(g, mm, w, h))

        this.editCtrl := this.gui.Add("Edit", "x10 y10 w760 h480 ReadOnly -Wrap +VScroll Background" t["listBg"] " c" t["listText"], "")
        this.editCtrl.SetFont("s9", "Consolas")

        btnRefresh := this.gui.Add("Button", "x10 y500 w100 h30", "立即刷新")
        btnRefresh.OnEvent("Click", (*) => LogViewer._Refresh(true))

        btnFolder := this.gui.Add("Button", "x120 y500 w130 h30", "打开日志文件夹")
        btnFolder.OnEvent("Click", (*) => Logger.OpenLogFolder())

        btnCopy := this.gui.Add("Button", "x260 y500 w90 h30", "复制全部")
        btnCopy.OnEvent("Click", (*) => LogViewer._CopyAll())

        btnClear := this.gui.Add("Button", "x360 y500 w90 h30", "清空日志")
        btnClear.OnEvent("Click", (*) => LogViewer._ClearToday())

        cbAuto := this.gui.Add("CheckBox", "x470 y505 w120 h24", "自动滚动")
        cbAuto.Value := 1
        this.autoScrollCtrl := cbAuto

        this.statusText := this.gui.Add("Text", "x600 y505 w170 h24 Right c" t["muted"], "")
        this.statusText.SetFont(t["fontSize"] " c" t["muted"], t["fontName"])

        this.gui.Show("w790 h550")

        this._Refresh()
        this._StartTimer()
    }

    static _StartTimer() {
        if (!this.timerRef)
            this.timerRef := this._AutoRefresh.Bind(this)
        this._active := true
        SetTimer(this.timerRef, 2000)
        this.statusText.Value := "自动刷新中…"
    }

    static _StopTimer() {
        this._active := false
        if (this.timerRef)
            SetTimer(this.timerRef, 0)
    }

    static _OnClose() {
        this._StopTimer()
        try this.gui.Destroy()
        this.gui := ""
        this.editCtrl := ""
        this._lastContent := ""
    }

    static _OnSize(g, minMax, w, h) {
        if (!IsObject(this.editCtrl))
            return
        try this.editCtrl.Move(10, 10, w - 30, h - 80)
    }

    static _AutoRefresh(*) {
        if (!this._active)
            return
        this._Refresh()
    }

    static _Refresh(force := false) {
        if (!IsObject(this.editCtrl))
            return

        today := FormatTime(A_Now, "yyyy-MM-dd")
        filePath := Logger.logDir . "\" today . ".log"

        content := ""
        if FileExist(filePath) {
            try content := FileRead(filePath, "UTF-8")
        }
        if (content == "")
            content := "（今天暂无日志）"

        if (!force && content == this._lastContent)
            return
        this._lastContent := content

        this.editCtrl.Value := content

        if (this.autoScrollCtrl.Value) {
            hwnd := this.editCtrl.Hwnd
            SendMessage(0x00B1, -1, -1, hwnd)
            SendMessage(0x00B7, 0, 0, hwnd)
        }

        lineCount := 0
        if (content != "")
            lineCount := StrSplit(content, "`n").Length
        this.statusText.Value := Format("共 {} 行 · {}", lineCount, FormatTime(A_Now, "HH:mm:ss"))
    }

    static _CopyAll() {
        if (!IsObject(this.editCtrl))
            return
        A_Clipboard := this.editCtrl.Value
        MainWindow.SetStatus("日志已复制到剪贴板", "0x10B981")
    }

    static _ClearToday() {
        today := FormatTime(A_Now, "yyyy-MM-dd")
        filePath := Logger.logDir . "\" today . ".log"
        r := MsgBox("确定清空今天的日志吗？", "确认清空", "YesNo Icon?")
        if (r != "Yes")
            return
        try FileDelete(filePath)
        this._lastContent := ""
        this._Refresh(true)
        Logger.Info("（日志已被用户清空）")
        this._Refresh(true)
    }
}