; core\PathDetector.ahk
; 自动搜索 dispwin.exe 和 ICC 文件

class PathDetector {
    static FindDispwin() {
        ; 常见位置
        candidates := [
            "D:\工具箱\Argyll_V3.5.0\bin\dispwin.exe",
            "C:\Program Files\ArgyllCMS\bin\dispwin.exe",
            "C:\Program Files (x86)\ArgyllCMS\bin\dispwin.exe",
            "D:\Argyll_V3.5.0\bin\dispwin.exe",
            "D:\工具箱\Argyll_V3.5.0\bin\dispwin.exe"
        ]
        for _, p in candidates
            if FileExist(p)
                return p

        ; 搜索 Program Files
        Loop Files, "C:\Program Files\*\bin\dispwin.exe", "F"
            return A_LoopFileFullPath
        Loop Files, "C:\Program Files (x86)\*\bin\dispwin.exe", "F"
            return A_LoopFileFullPath
        Loop Files, "D:\*\*\bin\dispwin.exe", "F"
            return A_LoopFileFullPath
        return ""
    }

    static FindICC() {
        colorDir := "C:\Windows\System32\spool\drivers\color"
        if !DirExist(colorDir)
            return ""

        ; 优先找带 v2 的
        Loop Files, colorDir "\*.icc", "F"
            if InStr(A_LoopFileName, "v2")
                return A_LoopFileFullPath
        Loop Files, colorDir "\*.icm", "F"
            if InStr(A_LoopFileName, "v2")
                return A_LoopFileFullPath

        ; 其次任意 icc
        Loop Files, colorDir "\*.icc", "F"
            return A_LoopFileFullPath
        Loop Files, colorDir "\*.icm", "F"
            return A_LoopFileFullPath
        return ""
    }
}