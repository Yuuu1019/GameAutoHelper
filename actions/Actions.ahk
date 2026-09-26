; actions\Actions.ahk

class ResolutionAction {
    static Execute(param, ctx) {
        parts := StrSplit(param, "x")
        if (parts.Length != 2)
            return Map("ok", false, "msg", "分辨率格式错误: " param, "special", "")
        try {
            w := Integer(parts[1])
            h := Integer(parts[2])
        } catch {
            return Map("ok", false, "msg", "分辨率不是数字: " param, "special", "")
        }
        ok := this._SetResolutionKeepHz(w, h)
        return ok
            ? Map("ok", true, "msg", Format("已切换到 {}x{}", w, h), "special", "")
            : Map("ok", false, "msg", "找不到分辨率 " param, "special", "")
    }

    static _SetResolutionKeepHz(targetW, targetH) {
        devMode := Buffer(220, 0)
        NumPut("UShort", 220, devMode, 68)
        DllCall("EnumDisplaySettingsW", "Ptr", 0, "UInt", -1, "Ptr", devMode)
        currentHz := NumGet(devMode, 184, "UInt")
        i := 0
        while DllCall("EnumDisplaySettingsW", "Ptr", 0, "UInt", i, "Ptr", devMode) {
            w := NumGet(devMode, 172, "UInt")
            h := NumGet(devMode, 176, "UInt")
            if (w == targetW && h == targetH) {
                fields := NumGet(devMode, 72, "UInt")
                fields |= 0x80000 | 0x100000 | 0x400000
                NumPut("UInt", fields, devMode, 72)
                NumPut("UInt", currentHz, devMode, 184)
                return DllCall("ChangeDisplaySettingsW", "Ptr", devMode, "UInt", 1) == 0
            }
            NumPut("UShort", 220, devMode, 68)
            i++
        }
        return false
    }
}

class MonitorAction {
    static Execute(param, ctx) {
        enable := (param == "enable")
        if (enable)
            psCmd := "Get-PnpDevice -Class Monitor | Enable-PnpDevice -Confirm:`$false"
        else
            psCmd := "Get-PnpDevice -Class Monitor | Disable-PnpDevice -Confirm:`$false"
        try {
            RunWait(Format('{1} /c powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "{2}"', A_ComSpec, psCmd), , "Hide")
            return Map("ok", true, "msg", enable ? "监视器已启用" : "监视器已禁用", "special", "")
        } catch as e {
            return Map("ok", false, "msg", "监视器操作失败: " e.Message, "special", "")
        }
    }
}

; ★ ICC 动作 + 真实生效检测
class ICCAction {
    static Execute(param, ctx) {
        dispwin := ctx["config"]["dispwinPath"]
        icc := ctx["config"]["iccProfile"]
        if (dispwin == "")
            return Map("ok", false, "msg", "未设置 dispwin.exe 路径", "special", "")
        if !FileExist(dispwin)
            return Map("ok", false, "msg", "dispwin.exe 不存在: " dispwin, "special", "")

        try {
            if (param == "on") {
                if (icc == "" || !FileExist(icc))
                    return Map("ok", false, "msg", "ICC 文件不存在: " icc, "special", "")

                code := RunWait(Format('"{1}" -d 1 "{2}"', dispwin, icc), , "Hide")
                if (code != 0)
                    return Map("ok", false, "msg", Format("dispwin 返回错误码 {}", code), "special", "")

                ; 等系统完成加载
                Sleep(600)

                ; ★ 验证是否真的生效
                current := this._GetCurrentICC()
                if (current == "")
                    return Map("ok", false, "msg", "dispwin 已执行，但无法读取系统当前 ICC（显示器可能未就绪）", "special", "")

                if (this._PathsEqual(current, icc))
                    return Map("ok", true, "msg", Format("ICC 已开启并生效（{}）", this._BaseName(current)), "special", "")
                else
                    return Map("ok", false, "msg", Format("dispwin 命令已执行，但系统当前 ICC 仍为「{}」，可能因监视器未启动导致未生效", this._BaseName(current)), "special", "")
            } else {
                code := RunWait(Format('"{1}" -d 1 -c', dispwin), , "Hide")
                if (code != 0)
                    return Map("ok", false, "msg", Format("dispwin 返回错误码 {}", code), "special", "")
                return Map("ok", true, "msg", "ICC 已关闭", "special", "")
            }
        } catch as e {
            return Map("ok", false, "msg", "ICC 操作失败: " e.Message, "special", "")
        }
    }

    static _GetCurrentICC() {
        hDC := DllCall("user32\GetDC", "Ptr", 0, "Ptr")
        if (!hDC)
            return ""

        sizeBuf := Buffer(4, 0)
        NumPut("UInt", 260, sizeBuf)
        nameBuf := Buffer(520, 0)

        ok := DllCall("gdi32\GetICMProfileW", "Ptr", hDC, "Ptr", sizeBuf, "Ptr", nameBuf)
        DllCall("user32\ReleaseDC", "Ptr", 0, "Ptr", hDC)

        if (!ok)
            return ""
        return StrGet(nameBuf, "UTF-16")
    }

    static _PathsEqual(a, b) {
        if (a == "" || b == "")
            return false
        SplitPath(a, &n1)
        SplitPath(b, &n2)
        return (StrLower(n1) == StrLower(n2))
    }

    static _BaseName(path) {
        SplitPath(path, &name)
        return name
    }
}

class CleanMemoryAction {
    static Execute(param, ctx) {
        this._EnablePrivilege("SeProfileSingleProcessPrivilege")
        this._EnablePrivilege("SeIncreaseQuotaPrivilege")
        beforeBytes := this._GetAvailPhysBytes()
        this._EmptyAllProcessWorkingSets()
        this._EmptySystemWorkingSet()
        this._FlushFileSystemCache()
        this._FlushModifiedPageList()
        this._PurgeStandbyList()
        afterBytes := this._GetAvailPhysBytes()
        freed := afterBytes - beforeBytes
        if (freed < 0)
            freed := 0
        freedGB := freed / 1073741824
        return Map("ok", true, "msg", Format("已释放 {:.2f} GB 内存", freedGB), "special", "")
    }

    static _GetAvailPhysBytes() {
        buf := Buffer(64, 0)
        NumPut("UInt", 64, buf, 0)
        if (!DllCall("kernel32\GlobalMemoryStatusEx", "Ptr", buf))
            return 0
        return NumGet(buf, 16, "Int64")
    }

    static _EmptyAllProcessWorkingSets() {
        accessRights := 0x0400 | 0x0100
        try {
            wmi := ComObject("winmgmts:")
            for proc in wmi.ExecQuery("SELECT ProcessId FROM Win32_Process") {
                pid := proc.ProcessId
                if (pid == 0)
                    continue
                hProc := DllCall("OpenProcess", "UInt", accessRights, "Int", 0, "UInt", pid, "Ptr")
                if (hProc) {
                    try DllCall("kernel32\SetProcessWorkingSetSizeEx", "Ptr", hProc, "UPtr", -1, "UPtr", -1, "UInt", 0)
                    catch
                        DllCall("psapi\EmptyWorkingSet", "Ptr", hProc)
                    DllCall("CloseHandle", "Ptr", hProc)
                }
            }
        }
    }

    static _EmptySystemWorkingSet() {
        try {
            cmd := Buffer(4, 0)
            NumPut("UInt", 2, cmd)
            DllCall("ntdll\NtSetSystemInformation", "UInt", 0x50, "Ptr", cmd, "UInt", 4)
        } catch {
        }
    }

    static _FlushFileSystemCache() {
        try DllCall("SetSystemFileCacheSize", "UPtr", -1, "UPtr", -1, "UInt", 0)
        catch {
        }
    }

    static _FlushModifiedPageList() {
        try {
            cmd := Buffer(4, 0)
            NumPut("UInt", 3, cmd)
            DllCall("ntdll\NtSetSystemInformation", "UInt", 0x50, "Ptr", cmd, "UInt", 4)
        } catch {
        }
    }

    static _PurgeStandbyList() {
        try {
            cmd := Buffer(4, 0)
            NumPut("UInt", 4, cmd)
            DllCall("ntdll\NtSetSystemInformation", "UInt", 0x50, "Ptr", cmd, "UInt", 4)
        } catch {
        }
    }

    static _EnablePrivilege(privName) {
        try {
            luid := Buffer(8, 0)
            if (!DllCall("advapi32\LookupPrivilegeValue", "Ptr", 0, "Str", privName, "Ptr", luid))
                return false
            hToken := 0
            if (!DllCall("advapi32\OpenProcessToken", "Ptr", DllCall("kernel32\GetCurrentProcess", "Ptr"), "UInt", 0x0020 | 0x0008, "Ptr*", &hToken))
                return false
            tp := Buffer(16, 0)
            NumPut("UInt", 1, tp, 0)
            NumPut("Int64", NumGet(luid, 0, "Int64"), tp, 4)
            NumPut("UInt", 0x00000002, tp, 12)
            res := DllCall("advapi32\AdjustTokenPrivileges", "Ptr", hToken, "Int", false, "Ptr", tp, "UInt", 0, "Ptr", 0, "Ptr", 0)
            err := A_LastError
            DllCall("kernel32\CloseHandle", "Ptr", hToken)
            return (res != 0 && err == 0)
        } catch {
            return false
        }
    }
}

class RunProgramAction {
    static Execute(param, ctx) {
        if (param == "")
            return Map("ok", false, "msg", "未指定程序路径", "special", "")
        if !FileExist(param)
            return Map("ok", false, "msg", "程序不存在: " param, "special", "")
        try {
            Run(Format('"{1}"', param))
            return Map("ok", true, "msg", "已启动: " param, "special", "")
        } catch as e {
            return Map("ok", false, "msg", "启动失败: " e.Message, "special", "")
        }
    }
}

class OpenUrlAction {
    static Execute(param, ctx) {
        url := Trim(param)
        if (url == "")
            return Map("ok", false, "msg", "未指定网址", "special", "")
        if !(SubStr(url, 1, 7) == "http://" || SubStr(url, 1, 8) == "https://")
            url := "https://" . url
        try {
            Run('explorer.exe "' . url . '"')
            return Map("ok", true, "msg", "已打开: " url, "special", "")
        } catch as e {
            return Map("ok", false, "msg", "打开失败: " e.Message, "special", "")
        }
    }
}

class KillProcessAction {
    static Execute(param, ctx) {
        if (param == "")
            return Map("ok", false, "msg", "未指定进程名", "special", "")
        try {
            RunWait(Format('{1} /c taskkill /F /IM "{2}"', A_ComSpec, param), , "Hide")
            return Map("ok", true, "msg", "已尝试结束: " param, "special", "")
        } catch as e {
            return Map("ok", false, "msg", "结束进程失败: " e.Message, "special", "")
        }
    }
}

class SleepAction {
    static Execute(param, ctx) {
        try {
            ms := Integer(param)
        } catch {
            return Map("ok", false, "msg", "等待时间不是数字: " param, "special", "")
        }
        return Map("ok", true, "msg", Format("等待 {} 毫秒", ms), "special", "sleep", "ms", ms)
    }
}

class ExitScriptAction {
    static Execute(param, ctx) {
        return Map("ok", true, "msg", "准备退出脚本", "special", "exit")
    }
}