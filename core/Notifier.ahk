; core\Notifier.ahk
; 通知管理器：防抖合并 + 队列，避免一瞬间弹出一堆

class Notifier {
    static queue := []
    static _timerRef := ""
    static debounceMs := 700

    static Notify(msg) {
        this.queue.Push(msg)
        if (!this._timerRef)
            this._timerRef := this._Flush.Bind(this)
        SetTimer(this._timerRef, 0)
        SetTimer(this._timerRef, -this.debounceMs)
    }

    static _Flush(*) {
        if (this.queue.Length == 0)
            return

        text := ""
        for i, m in this.queue {
            if (i > 1)
                text .= "`n"
            text .= m
        }
        this.queue := []

        if (StrLen(text) > 250)
            text := SubStr(text, 1, 247) . "..."

        TrayTip(text, "冬雨游戏助手", "Iconi Mute")
    }

    static Clear() {
        this.queue := []
        if (this._timerRef)
            SetTimer(this._timerRef, 0)
    }
}