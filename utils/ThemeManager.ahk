; utils\ThemeManager.ahk

class ThemeManager {
    static _cached := ""

    static Current() {
        if (this._cached != "")
            return this._cached
        name := ConfigManager.Get("theme", "simple")
        this._cached := this.Get(name)
        return this._cached
    }

    static Reload() {
        this._cached := ""
        return this.Current()
    }

    static Get(name) {
        ; 美化暂时和简约一致（WebView2 版本出来后再做真美化）
        return this._Simple()
    }

    static _Simple() {
        return Map(
            "bg", "0xFFFFFF",
            "banner", "0xFFFFFF",
            "bannerText", "0x111827",
            "listBg", "0xFFFFFF",
            "listText", "0x111827",
            "primary", "0x2563EB",
            "success", "0x10B981",
            "danger", "0xEF4444",
            "text", "0x111827",
            "muted", "0x6B7280",
            "line", "0xE5E7EB",
            "fontName", "Microsoft YaHei UI",
            "fontSize", "s9",
            "fontSizeTitle", "s12",
            "winW", 800,
            "winH", 700
        )
    }
}