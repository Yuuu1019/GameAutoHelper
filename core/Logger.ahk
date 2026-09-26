; core\Logger.ahk
; 日志：按天一个文件，记录到 logs\yyyy-MM-dd.log

class Logger {
    static logDir := ""
    static currentFile := ""
    static currentDate := ""

    static Init() {
        scriptDir := A_ScriptDir
        if (this._IsWritable(scriptDir)) {
            this.logDir := scriptDir . "\logs"
        } else {
            this.logDir := EnvGet("APPDATA") . "\GameAutoHelper\logs"
        }
        if !DirExist(this.logDir)
            DirCreate(this.logDir)
        this._UpdateFile()
    }

    static Info(msg) {
        this._Write("INFO", msg)
    }

    static Warn(msg) {
        this._Write("WARN", msg)
    }

    static Error(msg) {
        this._Write("ERROR", msg)
    }

    static _Write(level, msg) {
        this._UpdateFile()
        ts := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        line := "[" ts "] [" level "] " msg . "`n"
        try FileAppend(line, this.currentFile, "UTF-8")
    }

    static _UpdateFile() {
        today := FormatTime(A_Now, "yyyy-MM-dd")
        if (today != this.currentDate) {
            this.currentDate := today
            this.currentFile := this.logDir . "\" today . ".log"
        }
    }

    static _IsWritable(dir) {
        testFile := dir . "\.write_test_"
        try {
            FileDelete(testFile)
            f := FileOpen(testFile, "w")
            f.Write("t")
            f.Close()
            FileDelete(testFile)
            return true
        } catch {
            return false
        }
    }

    static OpenLogFolder() {
        if (this.logDir != "")
            Run('explorer.exe "' . this.logDir . '"')
    }
}