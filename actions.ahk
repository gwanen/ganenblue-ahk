; ============================================
; Ganenblue AHK - Action Handlers v3.1 (OPTIMIZED)
; ============================================

; ============================================
; Screen Handlers
; ============================================

HandleStage() {
    Log("Stage screen")
}

HandleStory() {
    Log("Story - skipping")
    RandomClick(story_skip_X + 300, story_skip_Y + 40, clickVariance)
    Sleep, 150
    RandomClick(story_skip_ok_X + 300, story_skip_ok_Y + 40, clickVariance)
    Sleep, 150
}

HandleBattle() {
    global BotState, BotConfig, ImageConfig

    BotState.Timers.Main++
    region := BotConfig.Regions.Game

    ; Check for salute button (party wiped)
    if (ImageSearch(x, y, ImageConfig.Battle.SaluteBtn, region)) {
        Log(">>> PARTY WIPED DETECTED <<<")

        if (BotState.BotMode = "Raid") {
            Log("RAID MODE: Party wiped - returning to assist page")
            ResetBattleState()
            ReturnToBase()
        } else {
            Log("QUEST MODE: Party wiped - reviving with elixir")
            ReviveCharacterWithElixir(x, y)
            ResetBattleState()
        }
        return
    }

    ; Check for rejoin button
    if (ImageSearch(x, y, ImageConfig.Battle.Rejoin, region)) {
        Log("Disconnected - Rejoining battle")
        RejoinBattle()
        ResetBattleState()
        return
    }

    ; Check for attack button
    if (ImageSearch(attackX, attackY, ImageConfig.Battle.Attack, region)) {
        ; Check for Full Auto button
        if (ImageSearch(faX, faY, ImageConfig.Battle.FullAuto, region)) {
            if (BotState.BattleMode = "SemiAuto") {
                ExecuteSemiAuto(attackX, attackY)
            } else {
                ExecuteFullAuto(faX, faY)
            }
        } else {
            ; Attack button exists but FA button doesn't - might be loading
            if (BotState.Timers.Main >= BotConfig.Timeouts.Battle) {
                Log("Attack visible but no FA button - timeout")
                RefreshPage()
                ResetBattleState()
                BotState.ErrorCount++
            }
        }
        return
    }

    ; No buttons found - battle might be in progress or loading
    if (BotState.Timers.Main >= BotConfig.Timeouts.Battle) {
        Log("Battle timeout - refreshing")
        RefreshPage()
        ResetBattleState()
        BotState.ErrorCount++
    }
}

; Full Auto Attack Logic
ExecuteFullAuto(faX, faY) {
    global BotState, BotConfig, ImageConfig

    Log("Executing Full Auto")
    RandomClick(faX, faY)
    Sleep, 100
    BotState.Timers.Sub := 0
    region := BotConfig.Regions.Game

    ; Wait for attack to complete
    Loop {
        Sleep, 100
        BotState.Timers.Sub++

        ; Check if buttons are still visible
        attackStillVisible := IsImageVisible(ImageConfig.Battle.Attack, region)
        cancelStillVisible := IsImageVisible(ImageConfig.Battle.Cancel, region)

        if (BotState.Timers.Sub >= BotConfig.Timeouts.Attack) {
            Log("Attack confirmation timeout - refreshing")
            RefreshPage()
            ResetBattleState()
            BotState.ErrorCount++
            return
        }

        if (!attackStillVisible and !cancelStillVisible) {
            Log("Attack confirmed")
            BotState.BattleCount++
            RefreshPage()
            ResetBattleState()
            return
        }
    }
}

; Semi Auto Attack Logic
ExecuteSemiAuto(attackX, attackY) {
    global BotState, BotConfig, ImageConfig

    Log("Executing Semi Auto (Attack)")
    RandomClick(attackX, attackY)
    Sleep, 100
    BotState.Timers.Sub := 0
    region := BotConfig.Regions.Game

    Loop {
        Sleep, 100
        BotState.Timers.Sub++

        attackStillVisible := IsImageVisible(ImageConfig.Battle.Attack, region)
        cancelStillVisible := IsImageVisible(ImageConfig.Battle.Cancel, region)

        if (BotState.Timers.Sub >= BotConfig.Timeouts.Attack) {
            Log("Attack confirmation timeout - refreshing")
            RefreshPage()
            ResetBattleState()
            BotState.ErrorCount++
            return
        }

        if (!attackStillVisible and !cancelStillVisible) {
            Log("Attack confirmed")
            BotState.BattleCount++
            RefreshPage()
            ResetBattleState()
            return
        }
    }
}

ResetBattleState() {
    global BotState
    BotState.Timers.Main := 0
    BotState.Timers.Sub := 0
}

ReviveCharacterWithElixir(saluteX, saluteY) {
    Log("Clicking Salute button to revive with elixir")
    RandomClick(saluteX, saluteY)
    Sleep, 500
    RandomClick(165, 380)
    Sleep, 300
    RandomClick(227, 343)
    Sleep, 300
    Log("Party revival completed")
    return true
}

HandleResults() {
    global BotState, BotConfig

    BotState.Timers.Result += 10
    Log("Results screen")

    if (BotState.Timers.Result >= BotConfig.Timeouts.Result) {
        Log("Results timeout - returning to base")
        BotState.Timers.Result := 0
        BotState.Timers.Main := 0
        ReturnToBase()
    }
}

HandleSummon() {
    global BotState, BotConfig, ImageConfig

    Sleep, 150
    region := BotConfig.Regions.Game

    ; Check for party OK button
    if ImageSearch(x, y, ImageConfig.Battle.Ok, region) {
        Log("Party confirmed - clicking OK")
        RandomClick(x, y)
        Sleep, 500
        BotState.SummonScrolls := 0
        return
    }

    ; Auto-select summon
    if ImageSearch(x, y, ImageConfig.Summon.AutoSelect, region) {
        Log("Auto-selecting summon")
        RandomClick(x, y)
        Sleep, 200
        return
    }

    ; Battle Pending
    if ImageSearch(x, y, ImageConfig.Battle.OkPending, region) {
        Log("Battle Pending - clicking OK")
        RandomClick(x, y)
        Sleep, 500
        return
    }

    ; Battle ended
    if ImageSearch(x, y, ImageConfig.Battle.OkEnded, region) {
        Log("Battle ended - clicking OK")
        RandomClick(x, y)
        Sleep, 500
        return
    }

    ; Fallback: scroll and retry
    if (!BotState.SummonScrolls)
        BotState.SummonScrolls := 0

    BotState.SummonScrolls++
    if (BotState.SummonScrolls < BotConfig.SummonScrollMax) {
        Log("Scrolling summon list")
        MouseMove, 400, 400
        Sleep, 50
        Click, WheelDown, 3
        Sleep, 150
    } else {
        Log("Max scrolls reached - refreshing")
        RefreshPage()
        BotState.SummonScrolls := 0
    }
}

HandleRaid() {
    global BotConfig, ImageConfig
    Sleep, 300
    region := BotConfig.Regions.Game

    if ImageSearch(x, y, ImageConfig.Battle.OkPending, region) {
        RandomClick(x, y)
        Sleep, 500
        return
    }

    if ImageSearch(x, y, ImageConfig.Battle.Ok, region) {
        RandomClick(x, y)
        Sleep, 500
        return
    }

    if ImageSearch(x, y, ImageConfig.Battle.OkGeneric, region) {
        RandomClick(x, y)
        Sleep, 500
        return
    }

    if ImageSearch(x, y, ImageConfig.Battle.Raid, region) {
        RandomClick(x, y)
        Sleep, 500
        return
    }
}
