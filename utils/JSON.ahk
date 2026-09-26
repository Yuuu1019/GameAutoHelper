; utils\JSON.ahk
; 简易 JSON 序列化 / 反序列化

class JSON {
    static Stringify(obj) => this._S(obj)

    static _S(v) {
        switch Type(v) {
            case "String": return this._Esc(v)
            case "Integer", "Float": return String(v)
            case "Map":
                parts := []
                for k, val in v
                    parts.Push(this._Esc(k) ":" this._S(val))
                return "{" this._JoinArr(parts, ",") "}"
            case "Array":
                parts := []
                for _, val in v
                    parts.Push(this._S(val))
                return "[" this._JoinArr(parts, ",") "]"
            default:
                if IsObject(v) {
                    parts := []
                    for k, val in v.OwnProps()
                        parts.Push(this._Esc(k) ":" this._S(val))
                    return "{" this._JoinArr(parts, ",") "}"
                }
                return this._Esc(String(v))
        }
    }

    static _JoinArr(arr, sep) {
        result := ""
        for i, v in arr {
            if (i > 1)
                result .= sep
            result .= v
        }
        return result
    }

    static _Esc(s) {
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`t", "\t")
        return '"' s '"'
    }

    static Parse(text) {
        this._pos := 1
        this._text := text
        this._skipWs()
        return this._parseValue()
    }

    static _skipWs() {
        while (this._pos <= StrLen(this._text)) {
            c := SubStr(this._text, this._pos, 1)
            if (c == " " || c == "`t" || c == "`n" || c == "`r")
                this._pos++
            else
                break
        }
    }

    static _parseValue() {
        this._skipWs()
        c := SubStr(this._text, this._pos, 1)
        if (c == "{")
            return this._parseObject()
        if (c == "[")
            return this._parseArray()
        if (c == '"')
            return this._parseString()
        if (c == "t") {
            this._pos += 4
            return true
        }
        if (c == "f") {
            this._pos += 5
            return false
        }
        if (c == "n") {
            this._pos += 4
            return ""
        }
        return this._parseNumber()
    }

    static _parseObject() {
        obj := Map()
        this._pos++
        this._skipWs()
        if (SubStr(this._text, this._pos, 1) == "}") {
            this._pos++
            return obj
        }
        loop {
            this._skipWs()
            key := this._parseString()
            this._skipWs()
            this._pos++
            val := this._parseValue()
            obj[key] := val
            this._skipWs()
            c := SubStr(this._text, this._pos, 1)
            if (c == ",")
                this._pos++
            else if (c == "}") {
                this._pos++
                break
            } else
                throw Error("JSON: 期望 , 或 }，位置 " this._pos)
        }
        return obj
    }

    static _parseArray() {
        arr := []
        this._pos++
        this._skipWs()
        if (SubStr(this._text, this._pos, 1) == "]") {
            this._pos++
            return arr
        }
        loop {
            val := this._parseValue()
            arr.Push(val)
            this._skipWs()
            c := SubStr(this._text, this._pos, 1)
            if (c == ",")
                this._pos++
            else if (c == "]") {
                this._pos++
                break
            } else
                throw Error("JSON: 期望 , 或 ]，位置 " this._pos)
        }
        return arr
    }

    static _parseString() {
        this._pos++
        s := ""
        while (this._pos <= StrLen(this._text)) {
            c := SubStr(this._text, this._pos, 1)
            if (c == '"') {
                this._pos++
                return s
            }
            if (c == "\") {
                this._pos++
                e := SubStr(this._text, this._pos, 1)
                switch e {
                    case "n": s .= "`n"
                    case "r": s .= "`r"
                    case "t": s .= "`t"
                    case '"': s .= '"'
                    case "\": s .= "\"
                    case "/": s .= "/"
                    default:  s .= e
                }
                this._pos++
            } else {
                s .= c
                this._pos++
            }
        }
        throw Error("JSON: 字符串未闭合")
    }

    static _parseNumber() {
        start := this._pos
        while (this._pos <= StrLen(this._text)) {
            c := SubStr(this._text, this._pos, 1)
            if (c ~= "[-0-9.eE+]")
                this._pos++
            else
                break
        }
        numStr := SubStr(this._text, start, this._pos - start)
        if (numStr == "")
            throw Error("JSON: 期望数字，位置 " start)
        if InStr(numStr, ".") || InStr(numStr, "e") || InStr(numStr, "E")
            return Float(numStr)
        return Integer(numStr)
    }
}