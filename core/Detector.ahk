; core\Detector.ahk
; 后台检测 + 日志

class Detector {
    static timerRef := ""
    static lastState := Map()
    static stableCount := Map()
    static active := false
    static interval := 2000
    static debounceCount := 2

    static Start() {
        if (this.active)
            return
        this.active := true
        this.timerRef := this._Tick.Bind(this)
        this.lastState := Map()
        this.stableCount := Map()

        for _, p in ProfileManager.GetAll() {
            id := p["id"]
            this.lastState[id] := this._IsRunning(p) ? "running" : "stopped"
        }

        SetTimer(this.timerRef, this.interval)
        MainWindow.SetStatus("监控已启动", "0x10B981")
        MainWindow.SetMonitorStatus(true)
        Logger.Info("监控启动")
    }

    static Stop() {
        if (!this.active)
            return
        this.active := false
        try SetTimer(this.timerRef, 0)
        MainWindow.SetStatus("监控已停止")
        MainWindow.SetMonitorStatus(false)
        Logger.Info("监控停止")
    }

    static IsActive() {
        return this.active
    }

    static _CollectProcesses(p) {
        procs := []
        if (p.Has("launcherProcess") && p["launcherProcess"] != "")
            procs.Push(p["launcherProcess"])
        if (p.Has("gameProcess") && p["gameProcess"] != "")
            procs.Push(p["gameProcess"])
        if (p.Has("extraProcesses") && p["extraProcesses"] != "") {
            for _, name in StrSplit(p["extraProcesses"], ";") {
                t := Trim(name)
                if (t != "")
                    procs.Push(t)
            }
        }
        return procs
    }

    static _IsRunning(p) {
        for _, name in this._CollectProcesses(p)
            if (ProcessExist(name))
                return true
        return false
    }

    static _Tick() {
        if (!this.active)
            return

        for _, p in ProfileManager.GetAll() {
            id := p["id"]
            mode := p.Has("triggerMode") ? p["triggerMode"] : "manual"
            procs := this._CollectProcesses(p)

            if (mode == "manual" || procs.Length == 0) {
                this.lastState[id] := this._IsRunning(p) ? "running" : "stopped"
                continue
            }

            nowState := this._IsRunning(p) ? "running" : "stopped"
            prevState := this.lastState.Has(id) ? this.lastState[id] : nowState

            if (nowState == prevState) {
                this.stableCount[id] := 0
                continue
            }

            cnt := (this.stableCount.Has(id) ? this.stableCount[id] : 0) + 1
            this.stableCount[id] := cnt
            if (cnt < this.debounceCount)
                continue

            this.stableCount[id] := 0
            this.lastState[id] := nowState

            if (ActionExecutor.IsRunning()) {
                MainWindow.SetStatus(Format("检测到「{}」变化，但执行器正忙，跳过本次", p["displayName"]), "0xEF4444")
                Logger.Warn("检测到「" p["displayName"] "」变化，但执行器忙，跳过")
                continue
            }

            if (mode == "start" && nowState == "running")
                this._Trigger(p, "已启动")
            else if ((mode == "close" || mode == "allClose") && nowState == "stopped")
                this._Trigger(p, "已关闭")
        }
    }

    static _Trigger(p, reason) {
        Logger.Info("检测到「" p["displayName"] "」" reason)
        ActionExecutor.Start(p["id"], reason)
    }
}