; ui\AboutDialog.ahk
; 关于对话框

class AboutDialog {
    static Show() {
        t := ThemeManager.Current()

        dlg := Gui("+Owner" MainWindow.gui.Hwnd " +ToolWindow -MaximizeBox", "关于 冬雨游戏助手")
        dlg.SetFont(t["fontSize"], t["fontName"])
        dlg.BackColor := t["bg"]

        ; 软件名（中英）
        name1 := dlg.Add("Text", "x0 y30 w460 h32 Center c" t["text"], "冬雨游戏助手")
        name1.SetFont("s16 Bold c" t["text"], t["fontName"])

        name2 := dlg.Add("Text", "x0 y70 w460 h24 Center c" t["muted"], "WinterRain Game Assistant")
        name2.SetFont("s10 c" t["muted"], t["fontName"])

        ; 版本
        ver := dlg.Add("Text", "x0 y105 w460 h22 Center c" t["text"], "版本 v1.0.0")
        ver.SetFont("s9 c" t["text"], t["fontName"])

        ; 分隔线
        dlg.Add("Text", "x40 y140 w380 h1 Background" t["line"], "")

        ; 作者
        author := dlg.Add("Text", "x0 y155 w460 h22 Center c" t["text"], "作者：小雨")
        author.SetFont("s9 c" t["text"], t["fontName"])

        ; GitHub
        dlg.Add("Text", "x100 y185 w80 h22 Right c" t["text"], "GitHub：")
        editGH := dlg.Add("Edit", "x184 y182 w200 h24 ReadOnly -E0x200", "https://github.com/Yuuu1019")
        editGH.SetFont("s9 c0x2563EB", "Consolas")

        btnGH := dlg.Add("Button", "x392 y182 w60 h24", "打开")
        btnGH.OnEvent("Click", (*) => Run("https://github.com/Yuuu1019"))

        ; 简介
        desc := dlg.Add("Text", "x40 y225 w380 h50 Center c" t["muted"],
            "一个帮助玩家自动切换游戏环境的工具`n检测游戏进程，自动执行预设动作")
        desc.SetFont("s8 c" t["muted"], t["fontName"])

        ; 分隔线
        dlg.Add("Text", "x40 y290 w380 h1 Background" t["line"], "")

        ; 版权
        copyright := dlg.Add("Text", "x0 y300 w460 h20 Center c" t["muted"], "Copyright (C) 2025 小雨. All rights reserved.")
        copyright.SetFont("s8 c" t["muted"], t["fontName"])

        ; 关闭按钮
        btnClose := dlg.Add("Button", "x180 y338 w100 h32 Default", "关闭")
        btnClose.OnEvent("Click", (*) => dlg.Destroy())

        ; 打开图标
        dlg.Show("w460 h390")
    }
}