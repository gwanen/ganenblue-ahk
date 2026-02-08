; ============================================
; GBF Bot - Configuration & Utilities (OPTIMIZED v3.1)
; ============================================

; -------------------- Performance --------------------
SetBatchLines, -1  ; Run at maximum speed
SetMouseDelay, -1  ; Fastest mouse speed
SetWinDelay, 0     ; Fastest window operations
Process, Priority,, High

; -------------------- Settings --------------------
; -------------------- Bot Configuration --------------------
global BotConfig := {}
BotConfig.SettingsFile := "bot_settings.ini"
BotConfig.AutoExitMinutes := 80
BotConfig.MainLoopDelay := 100
BotConfig.Timeouts := { Battle: 30, Attack: 100, Result: 60 }
BotConfig.SummonScrollMax := 5
BotConfig.Window := { Width: 1000, Height: 1799 }
BotConfig.QuestURL := "" ; Loaded dynamically

; -------------------- Bot State (Runtime) --------------------
global BotState := {}
BotState.IsRunning := false
BotState.IsPaused := true
BotState.IsAlwaysOnTop := false
BotState.BattleMode := "FullAuto" ; or "SemiAuto"
BotState.BotMode := "Quest" ; or "Raid"
BotState.BattleCount := 0
BotState.ErrorCount := 0
BotState.Timers := { Main: 0, Sub: 0, Result: 0 }
BotState.LastURL := ""
BotState.LoopCount := 0

; -------------------- Constants --------------------
global ChromeBrowsers := "Chrome_WidgetWin_1"

global searchBattle := "raid"
global searchResults := "result"
global searchRaid := "quest/assist"
global searchSelectSummon := "quest/supporter"
global searchSelectSummonRaid := "quest/supporter/raid"
global searchScene := "quest/scene"
global searchStage := "quest/stage"
global searchQuest := "quest/index"
global searchCoop := "coop"
global searchCoopJoin := "coop/offer"
global searchCoopRoom := "coop/room"

global RAID_ASSIST_URL := "https://game.granbluefantasy.jp/#quest/assist"

; -------------------- Image Resources --------------------
global ImageConfig := {}
ImageConfig.Path := "image/"
ImageConfig.Variance := 90
ImageConfig.ClickVariance := 5

; Image Filenames
ImageConfig.Battle := { Attack: "attack_button.png"
    , Cancel: "cancel_button.png"
    , FullAuto: "fa_button.png"
    , Ok: "ok_button.png"
    , OkPending: "ok_pending_button.png"
    , Salute: "salute.png"
    , OkGeneric: "ok.png"
    , Raid: "raid_button.png"
    , SaluteBtn: "salute_button.png"
    , Rejoin: "rejoin_button.png"
    , OkEnded: "ok_ended_button.png" }

ImageConfig.Summon := { Main: "summon.png"
    , Secondary: "summon_2.png"
    , AutoSelect: "select_party_auto_select.png" }

; -------------------- Search Regions --------------------
BotConfig.Regions := {}
BotConfig.Regions.Game := { x1: 0, y1: 0, x2: 1000, y2: 1799 }
BotConfig.Regions.Battle := { x1: 0, y1: 500, x2: 1000, y2: 1500 }
BotConfig.Regions.Result := { x1: 0, y1: 800, x2: 1000, y2: 1799 }
BotConfig.Regions.Summon := { x1: 0, y1: 400, x2: 1000, y2: 1600 }

; ============================================
; Battle Functions
; ============================================

FullAutoAttack() {
    global BattleCoords
    Click % BattleCoords.fullauto.x " " BattleCoords.fullauto.y
    Sleep, 150 ; Reduced sleep
    return true
}

ReviveCharacter() {
    global BattleCoords
    Click % BattleCoords.salute.x " " BattleCoords.salute.y
    Sleep, 300
    Click % BattleCoords.saluteOk.x " " BattleCoords.saluteOk.y
    Sleep, 300
    Click % BattleCoords.salutePotion.x " " BattleCoords.salutePotion.y
    Sleep, 300
    return true
}

RejoinBattle() {
    global BattleCoords
    Click % BattleCoords.attack.x " " BattleCoords.attack.y
    Sleep, 300
    Click % BattleCoords.salutePotion.x " " BattleCoords.salutePotion.y
    Sleep, 300
    return true
}

; ============================================
; Image Search Functions (Verified v3.3)
; ============================================

; Region-based image search (Defaults to full screen for reliability)
; NOW AUTO-ENTERS COORDINATES (Returns Center X/Y instead of Top-Left)
; Region-based image search (Defaults to full screen for reliability)
; NOW AUTO-ENTERS COORDINATES (Returns Center X/Y instead of Top-Left)
ImageSearch(byref coordX, byref coordY, imageName, region := "") {
    global ImageConfig
    coordX := 0
    coordY := 0

    path := ImageConfig.Path
    variance := ImageConfig.Variance

    ; Default to full screen if no region specified (SAFE MODE)
    if (IsObject(region)) {
        x1 := region.x1, y1 := region.y1, x2 := region.x2, y2 := region.y2
    } else {
        x1 := 0, y1 := 0, x2 := A_ScreenWidth, y2 := A_ScreenHeight
    }

    ImageSearch, foundX, foundY, x1, y1, x2, y2, *%variance% %path%%imageName%

    if (ErrorLevel = 0) {
        ; Calculate Center
        GetImageSize(path . imageName, w, h)
        coordX := foundX + (w // 2)
        coordY := foundY + (h // 2)
        return true
    }
    return false
}

; Quick visibility check
IsImageVisible(imageName, region := "") {
    global ImageConfig

    path := ImageConfig.Path
    variance := ImageConfig.Variance

    if (IsObject(region)) {
        x1 := region.x1, y1 := region.y1, x2 := region.x2, y2 := region.y2
    } else {
        x1 := 0, y1 := 0, x2 := A_ScreenWidth, y2 := A_ScreenHeight
    }

    ImageSearch, ix, iy, x1, y1, x2, y2, *%variance% %path%%imageName%
    return (ErrorLevel = 0)
}

; Search multiple images
SearchMultipleImages(byref coordX, byref coordY, imageArray, region := "") {
    coordX := 0
    coordY := 0

    for index, imageName in imageArray {
        if ImageSearch(foundX, foundY, imageName, region) {
            coordX := foundX
            coordY := foundY
            return imageName
        }
    }
    return ""
}

; Helper to read PNG dimensions (Cached for performance)
GetImageSize(path, ByRef w, ByRef h) {
    static cache := {}

    if (cache.HasKey(path)) {
        w := cache[path].w
        h := cache[path].h
        return
    }

    w := 0, h := 0
    f := FileOpen(path, "r")
    if IsObject(f) {
        ; PNG allows easy read: Bytes 16-24 contain Width/Height (Big Endian)
        f.Seek(16, 0)
        w := (f.ReadUChar() << 24) | (f.ReadUChar() << 16) | (f.ReadUChar() << 8) | f.ReadUChar()
        h := (f.ReadUChar() << 24) | (f.ReadUChar() << 16) | (f.ReadUChar() << 8) | f.ReadUChar()
        f.Close()
    }

    ; Fallback if failed reading
    if (w = 0)
        w := 20, h := 20

    cache[path] := {w: w, h: h}
}

; ============================================
; Utility Functions
; ============================================

LoadSettings() {
    global BotConfig
    file := BotConfig.SettingsFile
    IniRead, savedURL, %file%, Settings, QuestURL, %A_Space%
    if (savedURL != "" and savedURL != "ERROR") {
        BotConfig.QuestURL := savedURL
        return true
    }
    return false
}

SaveSettings() {
    global BotConfig
    file := BotConfig.SettingsFile
    url := BotConfig.QuestURL
    IniWrite, %url%, %file%, Settings, QuestURL
    return true
}

Log(message) {
    FormatTime, currentTime,, HH:mm:ss
    rowNum := LV_Add("", currentTime, message)
    LV_Modify(rowNum, "Vis")
}

GoToQuest(url) {
    Sleep, 300
    Send, ^l
    Sleep, 100
    Clipboard := url
    Sleep, 100
    Send, ^v
    Sleep, 200
    Send, {ENTER}
    Sleep, 500
}

ReturnToBase() {
    global BotState, RAID_ASSIST_URL, BotConfig

    if (BotState.BotMode = "Raid") {
        GoToQuest(RAID_ASSIST_URL)
    } else {
        GoToQuest(BotConfig.QuestURL)
    }
}

RandomClick(x, y, variance := 0) {
    global ImageConfig
    if (variance = 0)
        variance := ImageConfig.ClickVariance

    Random, randX, % -variance, variance
    Random, randY, % -variance, variance
    Click, % (x + randX) " " (y + randY)
}

ResizeWindow() {
    global BotConfig
    w := BotConfig.Window.Width
    h := BotConfig.Window.Height
    Log("Resizing game window to " . w . "x" . h)

    WinGetPos, X, Y,,, A
    WinMove, A,, X, 0, w, h
}

RefreshPage() {
    Send {F5}
    Sleep, 2000
}

; ============================================
; Browser Functions
; ============================================

GetChromeURL() {
    global ChromeBrowsers
    WinGetClass, class, A

    if class in %ChromeBrowsers%
        return GetBrowserURL(class)
    return ""
}

GetBrowserURL(class) {
    static nWindow := 0
    static accAddressBar := ""

    ; Cache window handle and address bar object
    if (nWindow != WinExist("ahk_class " class)) {
        nWindow := WinExist("ahk_class " class)
        accAddressBar := GetAddressBar(Acc_ObjectFromWindow(nWindow))
    }

    Try sURL := accAddressBar.accValue(0)

    ; Fallback for multiple windows
    if (sURL = "") {
        WinGet, nWindows, List, % "ahk_class " class
        if (nWindows > 1) {
            accAddressBar := GetAddressBar(Acc_ObjectFromWindow(nWindows2))
            Try sURL := accAddressBar.accValue(0)
        }
    }

    ; Ensure URL has protocol
    if ((sURL != "") and (SubStr(sURL, 1, 4) != "http"))
        sURL := "http://" sURL

    if (sURL = "")
        nWindow := -1

    return sURL
}

GetAddressBar(accObj) {
    Try if ((accObj.accRole(0) = 42) and IsURL(accObj.accValue(0)))
    return accObj

    Try if ((accObj.accRole(0) = 42) and IsURL("http://" accObj.accValue(0)))
    return accObj

    for nChild, accChild in Acc_Children(accObj)
        if IsObject(accAddressBar := GetAddressBar(accChild))
            return accAddressBar
}

IsURL(url) {
    return RegExMatch(url, "^(?<Protocol>https?|ftp)://(?<Domain>(?:[\w-]+\.)+\w\w+)(?::(?<Port>\d+))?/?(?<Path>(?:[^:/?# ]*/?)+)(?:\?(?<Query>[^#]+)?)?(?:\#(?<Hash>.+)?)?$")
}

; ============================================
; Accessibility Functions
; ============================================

Acc_Init() {
    static h
    if Not h
        h := DllCall("LoadLibrary", "Str", "oleacc", "Ptr")
}

Acc_ObjectFromWindow(hWnd, idObject := 0) {
    Acc_Init()
    if DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", hWnd, "UInt", idObject&=0xFFFFFFFF, "Ptr", -VarSetCapacity(IID,16)+NumPut(idObject=0xFFFFFFF0?0x46000000000000C0:0x719B3800AA000C81,NumPut(idObject=0xFFFFFFF0?0x0000000000020400:0x11CF3C3D618736E0,IID,"Int64"),"Int64"), "Ptr*", pacc)=0
        return ComObjEnwrap(9,pacc,1)
}

Acc_Query(Acc) {
    Try return ComObj(9, ComObjQuery(Acc,"{618736e0-3c3d-11cf-810c-00aa00389b71}"), 1)
}

Acc_Children(Acc) {
    if ComObjType(Acc,"Name") != "IAccessible" {
        ErrorLevel := "Invalid IAccessible Object"
        return
    }

    Acc_Init()
    cChildren := Acc.accChildCount
    Children := []

    if DllCall("oleacc\AccessibleChildren", "Ptr", ComObjValue(Acc), "Int", 0, "Int", cChildren, "Ptr", VarSetCapacity(varChildren, cChildren*(8+2*A_PtrSize), 0)*0+&varChildren, "Int*", cChildren)=0 {
        Loop %cChildren% {
            i := (A_Index-1)*(A_PtrSize*2+8)+8
            child := NumGet(varChildren, i)
            Children.Insert(NumGet(varChildren, i-8)=9 ? Acc_Query(child) : child)
            if (NumGet(varChildren, i-8)=9)
                ObjRelease(child)
        }
        return Children.MaxIndex() ? Children : ""
    }

    ErrorLevel := "AccessibleChildren DllCall Failed"
    return
}
