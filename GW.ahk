; ============================================
; GBF Bot - Main Script with Modern GUI v3.0
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
Gui, +Resize +MinSize400x300
Gui, Color, White
Gui, Font, s9 cBlack, Segoe UI

; === Control Panel ===
Gui, Add, GroupBox, x10 y10 w380 h180 cBlack, Control Panel

; Buttons Row 1 - Start/Stop/Pause
Gui, Add, Button, x20 y30 w80 h35 gBtnStart vBtnStartCtrl, Start
Gui, Add, Button, x110 y30 w80 h35 gBtnPause vBtnPauseCtrl Disabled, Pause
Gui, Add, Button, x200 y30 w80 h35 gBtnStop vBtnStopCtrl Disabled, Stop

; Buttons Row 2 - Utilities
Gui, Add, Button, x20 y75 w80 h30 gBtnReload, Reload
Gui, Add, Button, x110 y75 w80 h30 gBtnResize, Resize Win
Gui, Add, Button, x200 y75 w170 h30 gBtnEditQuest, Edit Quest URL

; Row 3 - Battle Mode Selection
Gui, Font, s8 cBlack
Gui, Add, Text, x20 y115 w80 h20 cBlack, Battle Mode:
Gui, Add, Radio, x20 y130 w90 h20 vRadioFullAuto gToggleBattleMode Checked, Full Auto
Gui, Add, Radio, x120 y130 w90 h20 vRadioSemiAuto gToggleBattleMode, Semi Auto

; Row 4 - Bot Mode Selection (Quest/Raid)
Gui, Font, s8 cBlack
Gui, Add, Text, x20 y155 w80 h20 cBlack, Bot Mode:
Gui, Add, Radio, x20 y170 w90 h20 vRadioQuestMode gToggleBotMode Checked, Quest Mode
Gui, Add, Radio, x120 y170 w90 h20 vRadioRaidMode gToggleBotMode, Raid Mode

; Checkbox
Gui, Font, s9 cBlack
Gui, Add, Checkbox, x240 y130 w130 h20 vAlwaysOnTopCheck gToggleAlwaysOnTop cBlack, Always On Top

; === Statistics ===
Gui, Add, GroupBox, x10 y200 w380 h100 cBlack, Statistics

Gui, Font, s8 cBlack
Gui, Add, Text, x20 y220 w170 h20 cBlack, Battles Completed:
Gui, Add, Text, x200 y220 w170 h20 vStatBattles Right cBlack, 0

Gui, Add, Text, x20 y240 w170 h20 cBlack, Errors:
Gui, Add, Text, x200 y240 w170 h20 vStatErrors Right cBlack, 0

Gui, Add, Text, x20 y260 w170 h20 cBlack, Status:
Gui, Add, Text, x200 y260 w170 h20 vStatStatus Right cRed, STOPPED

Gui, Add, Button, x20 y275 w80 h20 gBtnResetStats, Reset Stats

; === Activity Log ===
Gui, Font, s9 cBlack
Gui, Add, GroupBox, x10 y310 w380 h250 cBlack, Activity Log

Gui, Font, s8
Gui, Add, ListView, x20 y330 w360 h220 vLogbox -Hdr Grid Background0xF0F0F0 cBlack, Time|Activity
LV_ModifyCol(1, 70)
LV_ModifyCol(2, 280)

; === Quest Info ===
Gui, Font, s8 c606060
Gui, Add, Text, x10 y570 w380 h40 vQuestInfo Center cGray, Quest: Not configured

Gui, Show, w400 h620, GBF Bot v3.0

; Set ListView colors
Gui, ListView, Logbox

; Initial GUI Update
if (BotConfig.QuestURL != "") {
    GuiControl,, QuestInfo, % "Quest: " . BotConfig.QuestURL
} else {
    Log("No quest URL configured - click 'Edit Quest URL'")
}

Log("=== Bot Ready - Click START to begin ===")

; Start main loop timer
SetTimer, MainLoop, 100
Return

; ============================================
; Main Loop - Timer Based (OPTIMIZED v3.2)
; ============================================

MainLoop:
    global lastCheckedURL

    if (!BotState.IsRunning or BotState.IsPaused or BotConfig.QuestURL = "") {
        return
    }

    ; Throttle URL Check (Every 5 ticks = 500ms)
    ; This significantly reduces CPU usage from Accessibility calls
    BotState.LoopCount++
    if (Mod(BotState.LoopCount, 5) = 0 or BotState.LastURL = "") {
        url := GetChromeURL()
        BotState.LastURL := url
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
    GuiControl,, StatBattles, % BotState.BattleCount
    GuiControl,, StatErrors, % BotState.ErrorCount

    if (!BotState.IsRunning) {
        GuiControl, +cRed, StatStatus
        GuiControl,, StatStatus, STOPPED
    } else if (BotState.IsPaused) {
        GuiControl, +cFF8C00, StatStatus
        GuiControl,, StatStatus, PAUSED
    } else {
        GuiControl, +c008000, StatStatus
        GuiControl,, StatStatus, RUNNING
    }
Return

BtnStart:
    if (BotConfig.QuestURL = "") {
        MsgBox, 48, No Quest URL, Please configure a quest URL first!
        Gosub, ShowQuestURLSetup
        Return
    }

    BotState.IsRunning := true
    BotState.IsPaused := false

    GuiControl, Disable, BtnStartCtrl
    GuiControl, Enable, BtnPauseCtrl
    GuiControl, Enable, BtnStopCtrl
    GuiControl,, BtnPauseCtrl, ⏸ Pause

    Log("=== BOT STARTED ===")
    Log("Battle Mode: " . BotState.BattleMode)
    Log("Bot Mode: " . BotState.BotMode)
    Log("Target: " . (BotState.BotMode = "Raid" ? RAID_ASSIST_URL : BotConfig.QuestURL))
    Gosub, UpdateGUI
Return

BtnPause:
    BotState.IsPaused := !BotState.IsPaused
    if (BotState.IsPaused) {
        GuiControl,, BtnPauseCtrl, Resume
        Log("=== PAUSED ===")
    } else {
        GuiControl,, BtnPauseCtrl, Pause
        Log("=== RESUMED ===")
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

    Log("=== BOT STOPPED ===")
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

BtnResetStats:
    BotState.BattleCount := 0
    BotState.ErrorCount := 0
    ResetBattleState()
    Log("Statistics reset")
    Gosub, UpdateGUI
Return

BtnEditQuest:
    Gosub, ShowQuestURLSetup
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

GuiSize:
    if (A_EventInfo = 1)  ; Minimized
        return

    ; Resize log to fit window
    newWidth := A_GuiWidth - 40
    newHeight := A_GuiHeight - 360

    if (newHeight < 100)
        newHeight := 100

    GuiControl, Move, Logbox, w%newWidth% h%newHeight%

    ; Move quest info to bottom
    questY := A_GuiHeight - 50
    GuiControl, Move, QuestInfo, w%newWidth% y%questY%
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

    Gui, 2:Font, s8 c606060
    Gui, 2:Add, Text, x20 y150 w440 h60 cGray, Tips:`n• The URL must start with https://game.granbluefantasy.jp/`n• You can get this URL from your browser address bar when on the quest page`n• The URL will be saved and loaded automatically on next start

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
    WinActivate, GBF Bot v3.0
Return

CancelQuestURL:
    if (BotConfig.QuestURL = "") {
        MsgBox, 48, Warning, No quest URL configured!`n`nThe bot cannot run without a quest URL.
    }

    Gui, 2:Destroy
    Gui, 1:-Disabled
    WinActivate, GBF Bot v3.0
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
    MsgBox, % "=== Bot Statistics ===`n"
        . "Battles Completed: " . BotState.BattleCount . "`n"
        . "Errors: " . BotState.ErrorCount . "`n"
        . "Battle Timer: " . BotState.Timers.Main . "/" . BotConfig.Timeouts.Battle . "`n"
        . "Result Timer: " . BotState.Timers.Result . "/" . BotConfig.Timeouts.Result . "`n`n"
        . "Mode: " . BotState.BattleMode . "`n"
        . "Status: " . (BotState.IsRunning ? (BotState.IsPaused ? "PAUSED" : "RUNNING") : "STOPPED")
Return

F11::
    Gosub, BtnResetStats
Return

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
