; core\UndoStack.ahk
; 撤回栈：删除操作前保存记录，可撤回

class UndoStack {
    static items := []
    static maxSize := 20

    static Push(record) {
        this.items.Push(record)
        if (this.items.Length > this.maxSize)
            this.items.RemoveAt(1)
    }

    static Pop() {
        if (this.items.Length == 0)
            return ""
        return this.items.Pop()
    }

    static Peek() {
        if (this.items.Length == 0)
            return ""
        return this.items[this.items.Length]
    }

    static Count() {
        return this.items.Length
    }

    static Clear() {
        this.items := []
    }
}