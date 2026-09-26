; ui\MainWindow.ahk
; 固定尺寸版本：不可拉伸，所有控件位置写死，永不重叠

class MainWindow {
    static gui := ""
    static statusText := ""
    static statusDot := ""
    static monitorStatusText := ""
    static tabButtons := Map()
    static listView := ""
    static theme := ""

    static Show() {
        if IsObject(this.gui) {
            try this.gui.Destroy()
            this.gui := ""
        }
        this.tabButtons := Map()

        t := ThemeManager.Current()
        this.theme := t
        this._ApplyIcon()

        this.gui := Gui("-Resize -MaximizeBox", "冬雨游戏助手")
        this.gui.SetFont(t["fontSize"], t["fontName"])
        this.gui.BackColor := t["bg"]
        this.gui.OnEvent("Close", (*) => MainWindow._HideToTray())

        ; ── 顶部 ──
        title := this.gui.Add("Text", "x20 y15 w500 h30 c" t["text"] " Background" t["bg"], "冬雨游戏助手")
        title.SetFont(t["fontSizeTitle"] " Bold c" t["text"], t["fontName"])

        version := this.gui.Add("Text", "x710 y22 w100 h20 Right c" t["muted"] " Background" t["bg"], "v1.0")
        version.SetFont("s8 c" t["muted"], t["fontName"])

        this.gui.Add("Text", "x20 y52 w790 h1 Background" t["line"], "")

        ; ── 档案区 ──
        lblProfile := this.gui.Add("Text", "x20 y70 w80 h22 c" t["text"] " Background" t["bg"], "档案")
        lblProfile.SetFont(t["fontSize"] " Bold c" t["text"], t["fontName"])

        btnSettings := this.gui.Add("Button", "x20 y140 w110 h28", "档案设置…")
        btnSettings.OnEvent("Click", (*) => MainWindow.OnProfileSettings())

        btnRename := this.gui.Add("Button", "x138 y140 w100 h28", "重命名")
        btnRename.OnEvent("Click", (*) => MainWindow.OnRenameCurrent())

        btnDel := this.gui.Add("Button", "x246 y140 w110 h28", "删除档案")
        btnDel.OnEvent("Click", (*) => MainWindow.OnDeleteCurrent())

        hintTab := this.gui.Add("Text", "x480 y144 w330 h20 Right c" t["muted"] " Background" t["bg"], "提示：双击动作行可直接编辑")
        hintTab.SetFont("s8 c" t["muted"], t["fontName"])

        this.gui.Add("Text", "x20 y182 w790 h1 Background" t["line"], "")

        ; ── 动作列表 ──
        lblAction := this.gui.Add("Text", "x20 y192 w200 h22 c" t["text"] " Background" t["bg"], "动作列表")
        lblAction.SetFont(t["fontSize"] " Bold c" t["text"], t["fontName"])

        this.listView := this.gui.Add("ListView", "x20 y218 w790 h290 -Multi Background" t["listBg"], ["动作", "参数"])
        this.listView.ModifyCol(1, 220)
        this.listView.ModifyCol(2, 560)
        this.listView.SetFont(t["fontSize"] " c" t["listText"], t["fontName"])
        this.listView.OnEvent("DoubleClick", (lv, row) => MainWindow.OnEditAction())

        btnAddAction := this.gui.Add("Button", "x20 y518 w100 h30", "添加动作")
        btnAddAction.OnEvent("Click", (*) => MainWindow.OnAddAction())

        btnEditAction := this.gui.Add("Button", "x128 y518 w100 h30", "编辑动作")
        btnEditAction.OnEvent("Click", (*) => MainWindow.OnEditAction())

        btnDelAction := this.gui.Add("Button", "x236 y518 w100 h30", "删除动作")
        btnDelAction.OnEvent("Click", (*) => MainWindow.OnDeleteAction())

        btnUp := this.gui.Add("Button", "x360 y518 w80 h30", "↑ 上移")
        btnUp.OnEvent("Click", (*) => MainWindow.OnMoveAction(-1))

        btnDown := this.gui.Add("Button", "x448 y518 w80 h30", "↓ 下移")
        btnDown.OnEvent("Click", (*) => MainWindow.OnMoveAction(1))

        this.gui.Add("Text", "x20 y561 w790 h1 Background" t["line"], "")

        ; ── 执行控制 ──
        lblExec := this.gui.Add("Text", "x20 y571 w200 h22 c" t["text"] " Background" t["bg"], "执行控制")
        lblExec.SetFont(t["fontSize"] " Bold c" t["text"], t["fontName"])

        this.monitorStatusText := this.gui.Add("Text", "x590 y572 w220 h22 Right c" t["muted"] " Background" t["bg"], "● 监控未启动")
        this.monitorStatusText.SetFont(t["fontSize"] " c" t["muted"], t["fontName"])

        btnDetectStart := this.gui.Add("Button", "x20 y598 w170 h40", "▶  启动监控")
        btnDetectStart.SetFont("s11 Bold", t["fontName"])
        btnDetectStart.OnEvent("Click", (*) => MainWindow.OnDetectStart())

        btnDetectStop := this.gui.Add("Button", "x200 y598 w150 h40", "■  停止监控")
        btnDetectStop.SetFont("s11 Bold", t["fontName"])
        btnDetectStop.OnEvent("Click", (*) => MainWindow.OnDetectStop())

        btnRun := this.gui.Add("Button", "x570 y604 w110 h28", "测试执行")
        btnRun.OnEvent("Click", (*) => MainWindow.OnRun())

        btnStop := this.gui.Add("Button", "x690 y604 w110 h28", "停止测试")
        btnStop.OnEvent("Click", (*) => MainWindow.OnStop())

        this.gui.Add("Text", "x20 y646 w790 h1 Background" t["line"], "")

        ; ── 状态栏 ──
        this.statusDot := this.gui.Add("Text", "x20 y676 w10 h10 Background" t["success"], "")

        this.statusText := this.gui.Add("Text", "x40 y672 w230 h24 c" t["muted"] " Background" t["bg"], "就绪")
        this.statusText.SetFont(t["fontSize"] " c" t["muted"], t["fontName"])

        ; ── 底部按钮 ──
        btnLog := this.gui.Add("Button", "x284 y668 w112 h30", "查看日志")
        btnLog.OnEvent("Click", (*) => LogViewer.Show())

        btnUndo := this.gui.Add("Button", "x402 y668 w90 h30", "↶ 撤回")
        btnUndo.OnEvent("Click", (*) => MainWindow.OnUndo())

        btnGlobalSettings := this.gui.Add("Button", "x498 y668 w100 h30", "全局设置")
        btnGlobalSettings.OnEvent("Click", (*) => SettingsDialog.Show())

        btnSave := this.gui.Add("Button", "x604 y668 w100 h30", "保存配置")
        btnSave.OnEvent("Click", (*) => MainWindow.OnSave())

        btnAbout := this.gui.Add("Button", "x710 y668 w100 h30", "关于")
        btnAbout.OnEvent("Click", (*) => AboutDialog.Show())

        this.RefreshTabs()
        this.RefreshListView()
        this._SetupTray()
        this.SetMonitorStatus(false)

        this.gui.Show("w830 h720")
    }

    ; ★ 图标：优先外部文件 → 编译时从 exe 自身读 → 兜底
    static _ApplyIcon() {
        ; 1. 优先用外部 res\raincloud.ico
        customIcon := A_ScriptDir . "\res\raincloud.ico"
        if FileExist(customIcon) {
            try {
                TraySetIcon(customIcon)
                A_IconTip := "冬雨游戏助手"
                return
            }
        }
        ; 2. 编译后的 exe：从自身资源里读嵌入的主图标
        if (A_IsCompiled) {
            try {
                TraySetIcon(A_ScriptFullPath, 1)
                A_IconTip := "冬雨游戏助手"
                return
            }
        }
        ; 3. 兜底
        try {
            TraySetIcon("imageres.dll", 102)
        } catch {
            TraySetIcon("shell32.dll", 44)
        }
        A_IconTip := "冬雨游戏助手"
    }

    static RefreshTabs() {
        t := this.theme
        for _, btn in this.tabButtons
            this._KillCtrl(btn)
        this.tabButtons := Map()

        profiles := ProfileManager.GetAll()
        total := profiles.Length

        tabW := 120
        gap := 5
        tabY := 100
        tabH := 32
        maxSlots := 5

        showMore := (total > maxSlots)
        displayCount := showMore ? (maxSlots - 1) : total
        if (displayCount < 1)
            displayCount := 1

        x := 20
        for i, p in profiles {
            if (i > displayCount)
                break
            id := p["id"]
            name := p["displayName"]
            isCur := (id == ProfileManager.currentId)
            label := isCur ? "▶ " name : name
            if (StrLen(label) > 7)
                label := SubStr(label, 1, 6) . "…"
            btn := this.gui.Add("Button", Format("x{} y{} w{} h{}", x, tabY, tabW, tabH), label)
            if isCur
                btn.SetFont(t["fontSize"] " Bold", t["fontName"])
            else
                btn.SetFont(t["fontSize"], t["fontName"])
            btn.OnEvent("Click", this._MakeTabHandler(id))
            this.tabButtons[id] := btn
            x += tabW + gap
        }

        if (showMore) {
            moreLabel := Format("更多 ▾ ({})", total - displayCount)
            btnMore := this.gui.Add("Button", Format("x{} y{} w{} h{}", x, tabY, tabW, tabH), moreLabel)
            btnMore.OnEvent("Click", (*) => MainWindow.ShowMoreMenu(displayCount))
            this.tabButtons["__more__"] := btnMore
            x += tabW + gap
        }

        btnAdd := this.gui.Add("Button", Format("x{} y{} w80 h{}", x, tabY, tabH), "+ 新建")
        btnAdd.OnEvent("Click", (*) => MainWindow.OnAddProfile())
        this.tabButtons["__add__"] := btnAdd
    }

    static ShowMoreMenu(startIdx) {
        profiles := ProfileManager.GetAll()
        m := Menu()
        added := 0
        for i, p in profiles {
            if (i <= startIdx)
                continue
            name := p["displayName"]
            isCur := (p["id"] == ProfileManager.currentId)
            label := isCur ? "✓ " name : name
            m.Add(label, MainWindow._MakeMenuHandler(p["id"]))
            added++
        }
        if (added == 0) {
            this.SetStatus("没有更多档案")
            return
        }
        m.Show()
    }

    static _MakeMenuHandler(profileId) {
        return (*) => MainWindow.SwitchToProfile(profileId)
    }

    static SwitchToProfile(id) {
        p := ProfileManager.GetById(id)
        if (!IsObject(p))
            return
        ProfileManager.SetCurrent(id)
        this.RefreshTabs()
        this.RefreshListView()
        this.SetStatus("已切换到「" p["displayName"] "」")
    }

    static SetMonitorStatus(running) {
        t := this.theme
        if (running) {
            this.monitorStatusText.Value := "● 监控运行中"
            this.monitorStatusText.SetFont(t["fontSize"] " Bold c0x10B981", t["fontName"])
        } else {
            this.monitorStatusText.Value := "● 监控未启动"
            this.monitorStatusText.SetFont(t["fontSize"] " c" t["muted"], t["fontName"])
        }
    }

    static _HideToTray() {
        this.gui.Hide()
    }

    static _SetupTray() {
        try A_TrayMenu.Delete()

        A_TrayMenu.Add("显示主窗口", (*) => MainWindow.ShowFromTray())
        A_TrayMenu.Add()
        A_TrayMenu.Add("▶ 启动监控", (*) => MainWindow.OnDetectStart())
        A_TrayMenu.Add("■ 停止监控", (*) => MainWindow.OnDetectStop())
        A_TrayMenu.Add()
        A_TrayMenu.Add("测试执行", (*) => MainWindow.OnRun())
        A_TrayMenu.Add("停止测试", (*) => MainWindow.OnStop())
        A_TrayMenu.Add()
        A_TrayMenu.Add("查看日志", (*) => LogViewer.Show())
        A_TrayMenu.Add("打开日志文件夹", (*) => Logger.OpenLogFolder())
        A_TrayMenu.Add()
        A_TrayMenu.Add("关于", (*) => AboutDialog.Show())
        A_TrayMenu.Add()
        A_TrayMenu.Add("退出（彻底关闭）", (*) => ExitApp())

        A_TrayMenu.Default := "显示主窗口"
        A_TrayMenu.ClickCount := 1
    }

    static ShowFromTray() {
        this.gui.Show()
        try WinActivate("ahk_id " this.gui.Hwnd)
    }

    static _KillCtrl(ctrl) {
        if !IsObject(ctrl)
            return
        try {
            ctrl.Destroy()
            return
        } catch {
        }
        try {
            hwnd := ctrl.Hwnd
            if (hwnd)
                DllCall("DestroyWindow", "Ptr", hwnd)
        } catch {
        }
    }

    static _MakeTabHandler(profileId) {
        return (*) => MainWindow.OnTabClick(profileId)
    }

    static OnTabClick(id) {
        p := ProfileManager.GetById(id)
        if (!IsObject(p)) {
            this.RefreshTabs()
            return
        }
        ProfileManager.SetCurrent(id)
        this.RefreshTabs()
        this.RefreshListView()
        this.SetStatus("已切换到「" p["displayName"] "」")
    }

    static RefreshListView() {
        this.listView.Delete()
        p := ProfileManager.GetCurrent()
        if (!IsObject(p))
            return
        actions := p["actions"]
        for _, act in actions {
            this.listView.Add(, ActionDefs.DisplayName(act["type"]), ActionDefs.DisplayParam(act["type"], act["param"]))
        }
    }

    static OnRun() {
        p := ProfileManager.GetCurrent()
        if (!IsObject(p))
            return
        ActionExecutor.Start(p["id"])
    }

    static OnStop() {
        ActionExecutor.Stop("用户点击停止")
    }

    static OnDetectStart() {
        Detector.Start()
    }

    static OnDetectStop() {
        Detector.Stop()
    }

    static OnAddAction() {
        p := ProfileManager.GetCurrent()
        if (!IsObject(p))
            return
        EditDialog.Show(p["id"], 0)
    }

    static OnEditAction() {
        p := ProfileManager.GetCurrent()
        if (!IsObject(p))
            return
        row := this.listView.GetNext()
        if (row == 0) {
            this.SetStatus("请先选中一行", this.theme["danger"])
            return
        }
        EditDialog.Show(p["id"], row)
    }

    static OnDeleteAction() {
        p := ProfileManager.GetCurrent()
        if (!IsObject(p))
            return
        row := this.listView.GetNext()
        if (row == 0) {
            this.SetStatus("请先选中一行", this.theme["danger"])
            return
        }
        act := p["actions"][row]
        UndoStack.Push(Map("kind", "action", "profileId", p["id"], "actionIndex", row, "action", act))

        p["actions"].RemoveAt(row)
        ProfileManager.Save()
        Logger.Info("删除动作「" ActionDefs.DisplayName(act["type"]) "」从档案「" p["displayName"] "」")
        this.RefreshListView()
        this.SetStatus("已删除动作（可点「↶ 撤回」恢复）", this.theme["danger"])
    }

    static OnMoveAction(dir) {
        p := ProfileManager.GetCurrent()
        if (!IsObject(p))
            return
        row := this.listView.GetNext()
        if (row == 0) {
            this.SetStatus("请先选中一行", this.theme["danger"])
            return
        }
        actions := p["actions"]
        if (dir < 0 && row <= 1) {
            this.SetStatus("已经是最顶部")
            return
        }
        if (dir > 0 && row >= actions.Length) {
            this.SetStatus("已经是最底部")
            return
        }
        target := row + dir
        tmp := actions[row]
        actions[row] := actions[target]
        actions[target] := tmp
        ProfileManager.Save()
        this.RefreshListView()
        try this.listView.Modify(target, "Select Focus")
        this.SetStatus(dir < 0 ? "已上移" : "已下移", this.theme["primary"])
    }

    static OnProfileSettings() {
        p := ProfileManager.GetCurrent()
        if (!IsObject(p))
            return
        ProfileSettingsDialog.Show(p["id"])
    }

    static OnAddProfile() {
        ib := InputBox("请输入新档案的名称：", "新建档案", "w320 h140", "新档案")
        if (ib.Result != "OK")
            return
        name := Trim(ib.Value)
        if (name == "")
            return
        p := ProfileManager.Create(name)
        ProfileManager.SetCurrent(p["id"])
        ProfileManager.Save()
        Logger.Info("新建档案「" name "」")
        this.RefreshTabs()
        this.RefreshListView()
        this.SetStatus("已新建档案「" name "」")
    }

    static OnDeleteCurrent() {
        p := ProfileManager.GetCurrent()
        if (!IsObject(p))
            return
        if (ProfileManager.order.Length <= 1) {
            MsgBox("至少要保留一个档案。", "提示", "Icon!")
            return
        }
        result := MsgBox("确定删除档案「" p["displayName"] "」吗？", "确认删除", "YesNo Icon?")
        if (result != "Yes")
            return

        orderIndex := ProfileManager.GetOrderIndex(p["id"])
        UndoStack.Push(Map("kind", "profile", "profile", p, "orderIndex", orderIndex))

        ProfileManager.Delete(p["id"])
        ProfileManager.Save()
        Logger.Info("删除档案「" p["displayName"] "」")
        this.RefreshTabs()
        this.RefreshListView()
        this.SetStatus("已删除档案（可点「↶ 撤回」恢复）", this.theme["danger"])
    }

    static OnRenameCurrent() {
        p := ProfileManager.GetCurrent()
        if (!IsObject(p))
            return
        oldName := p["displayName"]
        ib := InputBox("输入新名称：", "重命名档案", "w320 h140", oldName)
        if (ib.Result != "OK")
            return
        name := Trim(ib.Value)
        if (name == "")
            return
        ProfileManager.Rename(p["id"], name)
        ProfileManager.Save()
        Logger.Info("重命名档案「" oldName "」→「" name "」")
        this.RefreshTabs()
        this.SetStatus("已重命名为「" name "」")
    }

    static OnUndo() {
        if (UndoStack.Count() == 0) {
            this.SetStatus("没有可撤回的操作")
            return
        }
        rec := UndoStack.Peek()
        kind := rec["kind"]
        desc := ""
        if (kind == "profile")
            desc := "删除档案「" rec["profile"]["displayName"] "」"
        else if (kind == "action")
            desc := "删除动作「" ActionDefs.DisplayName(rec["action"]["type"]) "」"

        r := MsgBox("是否撤回以下操作？`n`n" desc, "撤回确认", "Yesno Icon?")
        if (r != "Yes")
            return

        rec := UndoStack.Pop()

        if (kind == "profile") {
            ProfileManager.Restore(rec["profile"], rec["orderIndex"])
            ProfileManager.SetCurrent(rec["profile"]["id"])
            ProfileManager.Save()
            Logger.Info("撤回：" desc)
            this.RefreshTabs()
            this.RefreshListView()
            this.SetStatus("已撤回删除档案", this.theme["success"])
        } else if (kind == "action") {
            p := ProfileManager.GetById(rec["profileId"])
            if (!IsObject(p)) {
                this.SetStatus("撤回失败：原档案已不存在", this.theme["danger"])
                return
            }
            idx := rec["actionIndex"]
            if (idx >= 1 && idx <= p["actions"].Length + 1)
                p["actions"].InsertAt(idx, rec["action"])
            else
                p["actions"].Push(rec["action"])
            ProfileManager.Save()
            Logger.Info("撤回：" desc)
            if (rec["profileId"] == ProfileManager.currentId)
                this.RefreshListView()
            this.SetStatus("已撤回删除动作", this.theme["success"])
        }
    }

    static OnSave() {
        ProfileManager.Save()
        Logger.Info("保存配置")
        this.SetStatus("配置已保存", this.theme["success"])
    }

    static SetStatus(txt, color := "") {
        t := this.theme
        if (color == "")
            color := t["muted"]
        this.statusText.Value := txt
        this.statusText.SetFont(t["fontSize"] " c" color, t["fontName"])
    }
}