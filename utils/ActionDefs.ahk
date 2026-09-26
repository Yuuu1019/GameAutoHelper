; utils\ActionDefs.ahk

class ActionDefs {
    static Types() {
        return [
            {type: "resolution", name: "改分辨率", editor: "resolution",
             options: ["1440x1080", "1920x1080", "1920x1440", "2088x1440", "2560x1440"],
             hint: "从左下拉选常用分辨率，或直接在右框输入（格式：宽x高，如 1920x1080）",
             default: "1920x1080"},
            {type: "monitor", name: "监视器", editor: "dropdown",
             options: ["启用", "禁用"], values: ["enable", "disable"],
             hint: "启用或禁用所有监视器", default: "enable"},
            {type: "icc", name: "ICC 滤镜", editor: "dropdown",
             options: ["开启", "关闭"], values: ["on", "off"],
             hint: "开启或关闭 ICC 色彩滤镜", default: "on"},
            {type: "cleanmem", name: "清理内存", editor: "none",
             hint: "释放所有进程的工作集和系统缓存", default: ""},
            {type: "run", name: "启动程序", editor: "file",
             hint: "程序的完整路径", default: ""},
            {type: "openurl", name: "打开网页", editor: "text",
             hint: "输入网址，例如 https://www.bilibili.com", default: ""},
            {type: "kill", name: "结束进程", editor: "text",
             hint: "进程名，例如 HwMonitor64.exe", default: ""},
            {type: "sleep", name: "等待", editor: "sleep",
             hint: "秒数，例如 5 表示等待 5 秒", default: "5"},
            {type: "exit", name: "结束本脚本", editor: "none",
             hint: "立即退出本工具，后续动作不会再执行", default: ""}
        ]
    }

    static Find(type) {
        for _, t in this.Types()
            if (t.type == type)
                return t
        return ""
    }

    static DisplayName(type) {
        t := this.Find(type)
        return t ? t.name : type
    }

    static DisplayParam(type, param) {
        switch type {
            case "monitor":
                return (param == "enable") ? "启用" : "禁用"
            case "icc":
                return (param == "on") ? "开启" : "关闭"
            case "cleanmem":
                return "—"
            case "sleep":
                try {
                    sec := Integer(param) / 1000
                    return (sec == Floor(sec) ? Integer(sec) : sec) . " 秒"
                } catch {
                    return param . " 毫秒"
                }
            case "run":
                SplitPath(param, &name)
                return name
            case "openurl":
                return (StrLen(param) > 50) ? SubStr(param, 1, 47) . "..." : param
            case "exit":
                return "—"
        }
        return param
    }
}