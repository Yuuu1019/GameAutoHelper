; core\ProfileManager.ahk
; 档案管理

class ProfileManager {
    static profiles := Map()
    static order := []
    static currentId := ""

    static Init() {
        this.profiles := ConfigManager.Get("profiles", Map())
        this.order := ConfigManager.Get("profileOrder", [])

        if !(this.profiles is Map)
            this.profiles := Map()
        if !(this.order is Array)
            this.order := []

        ConfigManager.Set("profiles", this.profiles)
        ConfigManager.Set("profileOrder", this.order)

        if (this.order.Length == 0)
            this._CreateDefaults()

        lastId := ConfigManager.Get("lastProfileId", "")
        if (lastId != "" && this.profiles.Has(lastId))
            this.currentId := lastId
        else if (this.order.Length > 0)
            this.currentId := this.order[1]
    }

    static _CreateDefaults() {
        ; ★ 编译后的 exe（给用户分享）：只创建一个空白档案
        if (A_IsCompiled) {
            this.Create("新档案")
            return
        }

        ; ★ 源码运行（开发者）：保留 4 个测试档案
        d := this.Create("三角洲")
        d["launcherProcess"] := "delta_force_launcher.exe"
        d["gameProcess"] := "delta_force_client.exe"

        v := this.Create("无畏契约")
        v["launcherProcess"] := "AclosGameProxy.exe"
        v["gameProcess"] := "VALORANT.exe"

        n := this.Create("永劫无间")
        n["launcherProcess"] := "LootHoarder.exe"
        n["gameProcess"] := "NarakaBladepoint.exe"

        desk := this.Create("桌面")
        desk["extraProcesses"] := "delta_force_launcher.exe; delta_force_client.exe; AclosGameProxy.exe; VALORANT.exe; LootHoarder.exe; NarakaBladepoint.exe"
        desk["triggerMode"] := "close"
    }

    static Create(displayName := "新档案") {
        nextId := ConfigManager.Get("nextProfileId", 1)
        id := "P" . nextId
        ConfigManager.Set("nextProfileId", nextId + 1)

        profile := Map(
            "id", id,
            "displayName", displayName,
            "launcherProcess", "",
            "gameProcess", "",
            "extraProcesses", "",
            "triggerMode", "start",
            "actions", [],
            "actionDelay", 200,
            "exitAfterComplete", false,
            "allowParallel", false,
            "detectEnabled", true
        )
        this.profiles[id] := profile
        this.order.Push(id)
        return profile
    }

    static Delete(id) {
        if !this.profiles.Has(id)
            return false
        this.profiles.Delete(id)
        newOrder := []
        for _, v in this.order
            if (v != id)
                newOrder.Push(v)
        this.order := newOrder

        if (this.currentId == id)
            this.currentId := (this.order.Length > 0) ? this.order[1] : ""
        return true
    }

    static Restore(profile, orderIndex) {
        id := profile["id"]
        this.profiles[id] := profile
        if (orderIndex >= 1 && orderIndex <= this.order.Length + 1)
            this.order.InsertAt(orderIndex, id)
        else
            this.order.Push(id)
    }

    static Rename(id, newName) {
        if !this.profiles.Has(id)
            return false
        this.profiles[id]["displayName"] := newName
        return true
    }

    static SetCurrent(id) {
        if !this.profiles.Has(id)
            return false
        this.currentId := id
        ConfigManager.Set("lastProfileId", id)
        return true
    }

    static GetCurrent() {
        return this.profiles.Has(this.currentId) ? this.profiles[this.currentId] : ""
    }

    static GetAll() {
        result := []
        for _, id in this.order
            if this.profiles.Has(id)
                result.Push(this.profiles[id])
        return result
    }

    static GetById(id) {
        return this.profiles.Has(id) ? this.profiles[id] : ""
    }

    static GetOrderIndex(id) {
        for i, oid in this.order
            if (oid == id)
                return i
        return 0
    }

    static Save() {
        ConfigManager.Set("profiles", this.profiles)
        ConfigManager.Set("profileOrder", this.order)
        ConfigManager.Set("lastProfileId", this.currentId)
        ConfigManager.Save()
    }
}