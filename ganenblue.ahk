; ============================================
; Ganenblue AHK - Main Script with Modern GUI v3.0
; ============================================

#NoEnv
#SingleInstance Force
#Persistent

#Include config.ahk
#Include actions.ahk

; -------------------- Initialize --------------------
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

; -------------------- Load Settings --------------------
if (!LoadSettings() or BotConfig.QuestURL = "") {
    ; Setup will be shown via GUI button if needed
}

; -------------------- Create GUI --------------------
Gui, +Resize +MinSize450x400 +AlwaysOnTop
Gui, Color, White
Gui, Font, s9 cBlack, Segoe UI

; === Controls Column (Left) ===
Gui, Add, GroupBox, x10 y10 w200 h175 cBlack, Commands
Gui, Add, Button, x25 y45 w170 h32 gBtnStart vBtnStartCtrl, Start
Gui, Add, Button, x25 y85 w80 h32 gBtnPause vBtnPauseCtrl Disabled, Pause
Gui, Add, Button, x115 y85 w80 h32 gBtnStop vBtnStopCtrl Disabled, Stop
Gui, Add, Button, x25 y125 w170 h32 gBtnReload, Reload Script

; === Settings Column (Right) ===
Gui, Add, GroupBox, x220 y10 w220 h175 cBlack, Configuration
Gui, Add, Button, x235 y45 w90 h32 gBtnEditQuest, Quest URL
Gui, Add, Button, x330 y45 w90 h32 gBtnEditReplicard, Repli. URL
Gui, Add, Button, x235 y85 w190 h32 gBtnResize, Resize Window

Gui, Font, s8
Gui, Add, Text, x235 y125 w60 h20, Battle:
Gui, Add, Radio, x280 y125 w70 h20 vRadioFullAuto gToggleBattleMode Checked, Full Auto
Gui, Add, Radio, x355 y125 w70 h20 vRadioSemiAuto gToggleBattleMode, Semi Auto

Gui, Add, Text, x235 y145 w40 h20, Mode:
Gui, Add, Radio, x275 y145 w55 h20 vRadioQuestMode gToggleBotMode Checked, Quest
Gui, Add, Radio, x330 y145 w45 h20 vRadioRaidMode gToggleBotMode, Raid
Gui, Add, Radio, x375 y145 w65 h20 vRadioReplicardMode gToggleBotMode, Replicard

; === Activity Log ===
Gui, Font, s9 cBlack
Gui, Add, GroupBox, x10 y200 w430 h360 cBlack, Activity Log
Gui, Font, s8
Gui, Add, ListView, x20 y225 w410 h325 vLogbox -Hdr Grid Background0xF0F0F0 cBlack, Time|Activity
LV_ModifyCol(1, 70)
LV_ModifyCol(2, 310)

; === Options (Bottom Row) ===
Gui, Font, s9
Gui, Add, Checkbox, x25 y572 w100 h20 vAlwaysOnTopCheck gToggleAlwaysOnTop Checked, Always On Top
Gui, Add, Checkbox, x135 y572 w100 h20 vDebugModeCheck gToggleDebugMode, Debug Mode

; === Quest & Replicard Info ===
Gui, Font, s8 c606060
Gui, Add, Text, x10 y590 w430 h15 vQuestInfo Center cGray, Quest: Not configured
Gui, Add, Text, x10 y605 w430 h15 vRepliInfo Center cGray, Repli: Not configured

Gui, Show, w450 h630, Ganenblue AHK v3.1

; Set ListView colors
Gui, ListView, Logbox

; Initial GUI Update
if (BotConfig.QuestURL != "")
    GuiControl,, QuestInfo, % "Quest: " . BotConfig.QuestURL

if (BotConfig.ReplicardURL != "")
    GuiControl,, RepliInfo, % "Repli: " . BotConfig.ReplicardURL

if (BotConfig.QuestURL = "" and BotConfig.ReplicardURL = "")
    Log("No URLs configured - click 'Quest URL' or 'Repli. URL'")

Log("Bot Ready - Click START to begin")

; Start main loop timer
SetTimer, MainLoop, 100
Return

; ============================================
; Main Loop - Timer Based (OPTIMIZED v3.2)
; ============================================

MainLoop:
    global lastCheckedURL

    ; Basic Guard
    if (!BotState.IsRunning or BotState.IsPaused)
        return

    ; Mode-specific Guard (ensure URL is set for Quest/Replicard)
    if (BotState.BotMode = "Quest" and BotConfig.QuestURL = "")
        return
    if (BotState.BotMode = "Replicard" and BotConfig.ReplicardURL = "")
        return

    ; Throttle URL Check (Every 5 ticks = 500ms)
    ; Throttle URL Check (Every 5 ticks = 500ms)
    ; This significantly reduces CPU usage from Accessibility calls
    BotState.LoopCount++

    if (Mod(BotState.LoopCount, 5) = 0 or BotState.LastURL = "") {
        url := GetChromeURL()
        BotState.LastURL := url

        ; DEBUG: Log URL every 5 seconds (50 ticks) to verify detection
        if (Mod(BotState.LoopCount, 50) = 0) {
            if (url != "")
                Log("DEBUG: Current URL: " . SubStr(url, 1, 50) . "...")
            else
                Log("DEBUG: No URL detected")
        }
    } else {
        url := BotState.LastURL
    }

    ; Skip if no URL
    if (url = "") {
        return
    }

    ; Route to appropriate handler (optimized order by frequency and specificity)
    if InStr(url, searchBattle) {
        HandleBattle()
    }
    else if InStr(url, searchResults) {
        HandleResults()
    }
    else if InStr(url, searchRaid) {
        HandleRaid()
    }
    else if InStr(url, searchSelectSummonRaid) or InStr(url, searchSelectSummon) {
        HandleSummon()
    }
    else if InStr(url, searchReplicard) {
        HandleReplicard()
    }
    else if InStr(url, searchScene) {
        HandleStory()
    }
    else if InStr(url, searchStage) {
        HandleStage()
    }
    else if InStr(url, searchQuest) {
        ReturnToBase()
    }
    else if InStr(url, searchCoop) or InStr(url, searchCoopJoin) or InStr(url, searchCoopRoom) {
        Log("Coop area - returning to base")
        ReturnToBase()
    }
    else {
        ; Only log unknown page if we actually just checked the URL (to avoid log spam)
        if (Mod(BotState.LoopCount, 5) = 0) {
            ; Optional: Enable this only if debugging to avoid spam
            ; Log("Unknown page - returning to base")
        }
        ReturnToBase()
    }
Return

; ============================================
; GUI Functions
; ============================================

UpdateGUI:
; Statistics updates removed
Return

BtnStart:
    ; Validate configuration based on mode
    if (BotState.BotMode = "Quest" and BotConfig.QuestURL = "") {
        MsgBox, 48, No Quest URL, Please configure a quest URL first!
        Gosub, ShowQuestURLSetup
        Return
    }
    if (BotState.BotMode = "Replicard" and BotConfig.ReplicardURL = "") {
        MsgBox, 48, No Replicard URL, Please configure a Replicard URL first!
        Gosub, ShowRepliURLSetup
        Return
    }

    BotState.IsRunning := true
    BotState.IsPaused := false

    Gui, Submit, NoHide

    GuiControl, Disable, BtnStartCtrl
    GuiControl, Enable, BtnPauseCtrl
    GuiControl, Enable, BtnStopCtrl
    GuiControl,, BtnPauseCtrl, Pause

    Log("Bot started")
    Log("Battle Mode: " . BotState.BattleMode)
    Log("Bot Mode: " . BotState.BotMode)
    Log("Target: " . (BotState.BotMode = "Raid" ? RAID_ASSIST_URL : BotConfig.QuestURL))
    Gosub, UpdateGUI
Return

BtnPause:
    BotState.IsPaused := !BotState.IsPaused
    if (BotState.IsPaused) {
        GuiControl,, BtnPauseCtrl, Resume
        Log("Paused")
    } else {
        GuiControl,, BtnPauseCtrl, Pause
        Log("Resumed")
    }
    Gosub, UpdateGUI
Return

BtnStop:
    BotState.IsRunning := false
    BotState.IsPaused := true

    GuiControl, Enable, BtnStartCtrl
    GuiControl, Disable, BtnPauseCtrl
    GuiControl, Disable, BtnStopCtrl
    GuiControl,, BtnPauseCtrl, Pause

    ; Unlock Configuration
    ; GuiControl, Enable, NoTimeoutCheck

    Log("Bot stopped")
    Log("Total battles: " . BotState.BattleCount . " | Errors: " . BotState.ErrorCount)
    ResetBattleState()
    Gosub, UpdateGUI
Return

BtnReload:
    Log("Reloading script...")
    Sleep, 500
    Reload
Return

BtnResize:
    ResizeWindow()
Return

; BtnResetStats removed

BtnEditQuest:
    Gosub, ShowQuestURLSetup
Return

BtnEditReplicard:
    Gosub, ShowRepliURLSetup
Return

ToggleBattleMode:
    Gui, Submit, NoHide
    if (RadioSemiAuto) {
        BotState.BattleMode := "SemiAuto"
        Log("Battle mode: SEMI AUTO (Attack button)")
    } else {
        BotState.BattleMode := "FullAuto"
        Log("Battle mode: FULL AUTO")
    }
Return

ToggleBotMode:
    Gui, Submit, NoHide
    if (RadioRaidMode) {
        BotState.BotMode := "Raid"
        Log("Bot mode: RAID MODE (returns to assist page)")
    } else if (RadioReplicardMode) {
        BotState.BotMode := "Replicard"
        Log("Bot mode: REPLICARD MODE")
    } else {
        BotState.BotMode := "Quest"
        Log("Bot mode: QUEST MODE (returns to quest URL)")
    }
Return

ToggleAlwaysOnTop:
    Gui, Submit, NoHide
    BotState.IsAlwaysOnTop := AlwaysOnTopCheck

    if (BotState.IsAlwaysOnTop) {
        Gui, +AlwaysOnTop
        Log("Always on top: ENABLED")
    } else {
        Gui, -AlwaysOnTop
        Log("Always on top: DISABLED")
    }
Return

ToggleDebugMode:
    Gui, Submit, NoHide
    BotState.DebugMode := DebugModeCheck

    if (BotState.DebugMode) {
        Log("Debug Mode: ENABLED (Verbose logging)")
    } else {
        Log("Debug Mode: DISABLED")
    }
Return

; ToggleTimeout removed

GuiSize:
    if (A_EventInfo = 1)  ; Minimized
        return

    ; Resize log to fit window
    newWidth := A_GuiWidth - 40
    newHeight := A_GuiHeight - 295 ; Adjusted for new layout (y225 start)

    if (newHeight < 100)
        newHeight := 100

    GuiControl, Move, Logbox, w%newWidth% h%newHeight%

    ; Move info and checkboxes to bottom
    repliY := A_GuiHeight - 20
    questY := A_GuiHeight - 35
    optY := A_GuiHeight - 58
    GuiControl, Move, RepliInfo, w%newWidth% y%repliY%
    GuiControl, Move, QuestInfo, w%newWidth% y%questY%
    GuiControl, Move, AlwaysOnTopCheck, y%optY%
    GuiControl, Move, DebugModeCheck, y%optY%
Return

; ============================================
; Quest URL Setup Dialog
; ============================================

ShowQuestURLSetup:
    Gui, 1:+Disabled

    Gui, 2:New, +Owner1 +ToolWindow
    Gui, 2:Color, White
    Gui, 2:Font, s10 cBlack, Segoe UI

    Gui, 2:Add, GroupBox, x10 y10 w460 h130 cBlack, Quest URL Configuration

    Gui, 2:Font, s9 cBlack
    Gui, 2:Add, Text, x20 y30 w440 h40 cBlack, Enter your Granblue Fantasy quest URL:`n(Example: https://game.granbluefantasy.jp/#quest/supporter/940311/3)

    ; We likely need a temporary variable for the Edit control to avoid conflicting with the object
    ; But we can preload it
    currentURL := BotConfig.QuestURL
    Gui, 2:Add, Edit, x20 y75 w440 h25 vQuestURLInput cBlack, %currentURL%

    Gui, 2:Add, Button, x20 y110 w100 h30 gSaveQuestURL Default, Save
    Gui, 2:Add, Button, x130 y110 w100 h30 gCancelQuestURL, Cancel

    Gui, 2:Add, Text, x20 y150 w440 h60 cGray, Tips:`n- The URL must start with https://game.granbluefantasy.jp/`n- You can get this URL from your browser address bar when on the quest page`n- The URL will be saved and loaded automatically on next start

    Gui, 2:Show, w480 h220, Quest URL Setup
Return

SaveQuestURL:
    Gui, 2:Submit, NoHide

    if (QuestURLInput = "") {
        MsgBox, 16, Error, Quest URL cannot be empty!
        Return
    }

    if (!InStr(QuestURLInput, "game.granbluefantasy.jp")) {
        MsgBox, 16, Error, Invalid quest URL!`n`nURL must contain: game.granbluefantasy.jp
        Return
    }

    BotConfig.QuestURL := QuestURLInput
    SaveSettings()

    GuiControl, 1:, QuestInfo, % "Quest: " . BotConfig.QuestURL
    Log("Quest URL updated: " . BotConfig.QuestURL)

    Gui, 2:Destroy
    Gui, 1:-Disabled
    WinActivate, Ganenblue AHK v3.0
Return

CancelQuestURL:
    if (BotConfig.QuestURL = "") {
        MsgBox, 48, Warning, No quest URL configured!`n`nThe bot cannot run without a quest URL.
    }

    Gui, 2:Destroy
    Gui, 1:-Disabled
    WinActivate, Ganenblue AHK v3.1
Return

; === Replicard URL Setup Dialog ===
ShowRepliURLSetup:
    Gui, 1:+Disabled

    Gui, 3:New, +Owner1 +ToolWindow
    Gui, 3:Color, White
    Gui, 3:Font, s10 cBlack, Segoe UI

    Gui, 3:Add, GroupBox, x10 y10 w460 h130 cBlack, Replicard URL Configuration

    Gui, 3:Font, s9 cBlack
    Gui, 3:Add, Text, x20 y30 w440 h40 cBlack, Enter your Replicard supporter selection URL:`n(Example: https://game.granbluefantasy.jp/#replicard/supporter/12345/1)

    currentRepli := BotConfig.ReplicardURL
    Gui, 3:Add, Edit, x20 y75 w440 h25 vRepliURLInput cBlack, %currentRepli%

    Gui, 3:Add, Button, x20 y110 w100 h30 gSaveRepliURL Default, Save
    Gui, 3:Add, Button, x130 y110 w100 h30 gCancelRepliURL, Cancel

    Gui, 3:Add, Text, x20 y150 w440 h60 cGray, Tips:`n- The URL must start with https://game.granbluefantasy.jp/`n- This should be the page where you select a support summon for Replicard.

    Gui, 3:Show, w480 h220, Replicard URL Setup
Return

SaveRepliURL:
    Gui, 3:Submit, NoHide

    if (RepliURLInput = "") {
        MsgBox, 16, Error, Replicard URL cannot be empty!
        Return
    }

    if (!InStr(RepliURLInput, "game.granbluefantasy.jp")) {
        MsgBox, 16, Error, Invalid Replicard URL!`n`nURL must contain: game.granbluefantasy.jp
        Return
    }

    BotConfig.ReplicardURL := RepliURLInput
    SaveSettings()

    GuiControl, 1:, RepliInfo, % "Repli: " . BotConfig.ReplicardURL
    Log("Replicard URL updated: " . BotConfig.ReplicardURL)

    Gui, 3:Destroy
    Gui, 1:-Disabled
    WinActivate, Ganenblue AHK v3.1
Return

CancelRepliURL:
    if (BotConfig.ReplicardURL = "") {
        MsgBox, 48, Warning, No Replicard URL configured!
    }

    Gui, 3:Destroy
    Gui, 1:-Disabled
    WinActivate, Ganenblue AHK v3.1
Return

3GuiClose:
    Gosub, CancelRepliURL
Return

2GuiClose:
    Gosub, CancelQuestURL
Return

; ============================================
; Hotkeys (Keyboard Shortcuts)
; ============================================

F1::
    ResizeWindow()
Return

F2::
    Log("Manual refresh triggered")
    RefreshPage()
    ResetBattleState()
Return

F10::
    Log("Battle timer: " . BotState.Timers.Main . "/" . BotConfig.Timeouts.Battle)
    Log("Result timer: " . BotState.Timers.Result . "/" . BotConfig.Timeouts.Result)
    Log("Status: " . (BotState.IsRunning ? (BotState.IsPaused ? "PAUSED" : "RUNNING") : "STOPPED"))
Return

; F11 removed (Reset Stats)

F12::
    if (BotState.IsRunning) {
        Gosub, BtnPause
    }
Return

^r::  ; Ctrl+R
    Gosub, BtnReload
Return

Esc::
    MsgBox, 4, Confirm Exit, Are you sure you want to exit the bot?
    IfMsgBox Yes
        Gosub, GuiClose
Return

GuiClose:
    if (BotState.IsRunning) {
        Log("=== Bot Stopped ===")
        Log("Total battles: " . BotState.BattleCount . " | Errors: " . BotState.ErrorCount)
    }
    Sleep, 500
ExitApp
Return
