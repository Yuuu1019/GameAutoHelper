; core\ConfigManager.ahk

class ConfigManager {
    static configPath := ""
    static data := Map()

    static Init() {
        scriptDir := A_ScriptDir
        if this._IsWritable(scriptDir) {
            this.configPath := scriptDir . "\config.json"
        } else {
            appDataDir := EnvGet("APPDATA") . "\GameAutoHelper"
            if !DirExist(appDataDir)
                DirCreate(appDataDir)
            this.configPath := appDataDir . "\config.json"
        }
        this.Load()
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

    static Load() {
        if !FileExist(this.configPath) {
            this.data := this.Defaults()
            this.Save()
            return
        }
        try {
            text := FileRead(this.configPath, "UTF-8")
            this.data := JSON.Parse(text)
        } catch as e {
            MsgBox("配置文件读取失败，将使用默认配置：`n" e.Message, "警告", "Icon!")
            this.data := this.Defaults()
        }
    }

    static Save() {
        try {
            text := JSON.Stringify(this.data)
            f := FileOpen(this.configPath, "w", "UTF-8")
            f.Write(text)
            f.Close()
        } catch as e {
            MsgBox("保存配置失败：`n" e.Message, "错误", "IconX")
        }
    }

    static Defaults() {
        return Map(
            "theme", "simple",
            "profileOrder", [],
            "profiles", Map(),
            "nextProfileId", 1,
            "lastProfileId", "",
            "dispwinPath", "D:\工具箱\Argyll_V3.5.0\bin\dispwin.exe",
            "iccProfile", "C:\Windows\System32\spool\drivers\color\1_v2.icc",
            "notifyEachAction", true,
            "notifyOnComplete", true
        )
    }

    static Get(key, def := "") {
        return this.data.Has(key) ? this.data[key] : def
    }

    static Set(key, value) {
        this.data[key] := value
    }
}