; core\ActionExecutor.ahk
; 异步动作执行器（统一发通知 + 日志）

class ActionExecutor {
    static state := "idle"
    static profileId := ""
    static profileName := ""
    static actions := []
    static index := 0
    static waitUntil := 0
    static _timerRef := ""
    static triggerReason := ""

    static IsRunning() {
        return this.state != "idle"
    }

    static _GetTimerRef() {
        if (!this._timerRef)
            this._timerRef := this._Tick.Bind(this)
        return this._timerRef
    }

    static _StartTimer(ms) {
        SetTimer(this._GetTimerRef(), ms)
    }

    static _StopTimer() {
        SetTimer(this._GetTimerRef(), 0)
    }

    static Start(profileId, reason := "") {
        if (this.IsRunning()) {
            MsgBox("已有序列正在执行，请先停止。", "提示", "Icon!")
            return
        }
        p := ProfileManager.GetById(profileId)
        if (!IsObject(p)) {
            MainWindow.SetStatus("找不到档案", "0xEF4444")
            Logger.Error("找不到档案 id=" profileId)
            return
        }
        this.profileId := profileId
        this.profileName := p["displayName"]
        this.actions := p["actions"]
        this.index := 0
        this.waitUntil := 0
        this.state := "running"
        this.triggerReason := reason

        if (reason != "") {
            MainWindow.SetStatus(Format("检测到「{}」{}，开始执行…", this.profileName, reason), "0x2563EB")
            Logger.Info("==== 开始执行「" this.profileName "」（触发：" reason "） ====")
        } else {
            MainWindow.SetStatus("开始执行「" this.profileName "」…", "0x2563EB")
            Logger.Info("==== 开始执行「" this.profileName "」（手动） ====")
        }

        this._StartTimer(100)
    }

    static Stop(reason := "用户停止") {
        if (this.state == "idle")
            return
        this._StopTimer()
        this.state := "idle"
        MainWindow.SetStatus("已停止：" reason, "0xEF4444")
        Logger.Warn("「" this.profileName "」已停止：" reason)
        if (ConfigManager.Get("notifyOnComplete", true))
            Notifier.Notify("■ 「" this.profileName "」已停止：" reason)
    }

    static _Tick() {
        if (this.state == "idle") {
            this._StopTimer()
            return
        }

        if (this.state == "waiting") {
            if (A_TickCount >= this.waitUntil)
                this.state := "running"
            else
                return
        }

        if (this.state == "dialog")
            return

        this.index++

        if (this.index > this.actions.Length) {
            this._Finish()
            return
        }

        act := this.actions[this.index]
        type := act["type"]
        param := act["param"]
        dispName := ActionDefs.DisplayName(type)

        MainWindow.SetStatus(Format("执行中 ({}/{})：{}", this.index, this.actions.Length, dispName), "0x2563EB")

        ctx := Map("config", ConfigManager.data, "profileId", this.profileId)
        result := this._Dispatch(type, param, ctx)

        if (!result["ok"]) {
            Logger.Error(Format("  [{}/{}] {} 失败：{}", this.index, this.actions.Length, dispName, result["msg"]))
            if (ConfigManager.Get("notifyEachAction", true))
                Notifier.Notify("✗ " dispName "：" result["msg"])

            this.state := "dialog"
            msg := Format("第 {} 步执行失败：`n`n动作：{}`n参数：{}`n`n原因：{}`n`n「是」= 跳过此动作，继续执行`n「否」= 停止整个序列",
                this.index, dispName, param, result["msg"])
            r := MsgBox(msg, "执行失败", "YesNo Icon!")
            if (r == "Yes") {
                this.state := "running"
                MainWindow.SetStatus("已跳过第 " this.index " 步", "0xEF4444")
                Logger.Warn("  跳过第 " this.index " 步，继续")
                this._StartTimer(100)
            } else {
                this.Stop("动作执行失败")
            }
            return
        }

        Logger.Info(Format("  [{}/{}] {}：{}", this.index, this.actions.Length, dispName, result["msg"]))
        if (ConfigManager.Get("notifyEachAction", true))
            Notifier.Notify("✓ " dispName "：" result["msg"])

        special := result.Has("special") ? result["special"] : ""

        if (special == "sleep") {
            this.waitUntil := A_TickCount + result["ms"]
            this.state := "waiting"
            MainWindow.SetStatus(Format("等待 {} 秒…", Round(result["ms"] / 1000, 1)), "0x2563EB")
            this._StartTimer(100)
            return
        }

        if (special == "exit") {
            this._StopTimer()
            this.state := "idle"
            MainWindow.SetStatus("序列要求退出脚本", "0x10B981")
            Logger.Info("  序列要求退出脚本，正在退出")
            if (ConfigManager.Get("notifyOnComplete", true))
                Notifier.Notify("▶ 「" this.profileName "」要求退出脚本")
            Sleep(400)
            ExitApp()
        }

        this._StartTimer(100)
    }

    static _Dispatch(type, param, ctx) {
        switch type {
            case "resolution": return ResolutionAction.Execute(param, ctx)
            case "monitor":    return MonitorAction.Execute(param, ctx)
            case "icc":        return ICCAction.Execute(param, ctx)
            case "cleanmem":   return CleanMemoryAction.Execute(param, ctx)
            case "run":        return RunProgramAction.Execute(param, ctx)
            case "openurl":    return OpenUrlAction.Execute(param, ctx)
            case "kill":       return KillProcessAction.Execute(param, ctx)
            case "sleep":      return SleepAction.Execute(param, ctx)
            case "exit":       return ExitScriptAction.Execute(param, ctx)
        }
        return Map("ok", false, "msg", "未知动作类型: " type, "special", "")
    }

    static _Finish() {
        this._StopTimer()
        p := ProfileManager.GetById(this.profileId)
        exitAfter := (IsObject(p) && p.Has("exitAfterComplete")) ? p["exitAfterComplete"] : false
        totalCount := this.actions.Length
        pName := this.profileName
        reason := this.triggerReason
        this.state := "idle"

        if (exitAfter) {
            MainWindow.SetStatus("序列完成，按要求退出脚本", "0x10B981")
            Logger.Info("==== 完成「" pName "」（共 " totalCount " 步），按要求退出 ====")
            if (ConfigManager.Get("notifyOnComplete", true))
                Notifier.Notify(Format("▶ 「{}」执行完成（共 {} 步），即将退出", pName, totalCount))
            Sleep(500)
            ExitApp()
        }

        if (reason != "")
            MainWindow.SetStatus(Format("「{}」（{} 触发）执行完成", pName, reason), "0x10B981")
        else
            MainWindow.SetStatus("「" pName "」执行完成", "0x10B981")

        Logger.Info("==== 完成「" pName "」（共 " totalCount " 步） ====")

        if (ConfigManager.Get("notifyOnComplete", true))
            Notifier.Notify(Format("✓ 「{}」执行完成（共 {} 步）", pName, totalCount))
    }
}