; ============================================
; Flexible Image Detection Test Tool
; ============================================
; Tests any image file with multiple variance levels

#NoEnv
#SingleInstance Force

global image_path := "image/"
global imageToTest := ""
global imageFileName := ""

CoordMode, Pixel, Relative
CoordMode, Mouse, Relative

; Ask user for image file name
InputBox, userInput, Image Detection Tool, Enter the image file name to test:`n`n(Examples: ok_button salute_button attack_button)`n`nDo NOT include .png extension, w300 h150

if (ErrorLevel) {
    MsgBox, Cancelled. Exiting...
    ExitApp
}

if (userInput = "") {
    MsgBox, No image name provided. Exiting...
    ExitApp
}

; Set the image file name
imageToTest := userInput
imageFileName := userInput . ".png"

; Verify file exists
filePath := image_path . imageFileName
if !FileExist(filePath) {
    MsgBox, 16, File Not Found, ERROR: Image file not found!`n`nLooking for: %filePath%`n`nCurrent directory: %A_WorkingDir%`n`nPlease make sure:`n1. The 'image' folder exists`n2. The file '%imageFileName%' is in the image folder
    ExitApp
}

FileGetSize, fileSize, %filePath%
MsgBox, 64, Ready!, Image Detection Tool Ready!`n`nTesting: %imageFileName%`nFile size: %fileSize% bytes`nPath: %filePath%`n`nHotkeys:`n• F9 - Test detection (multiple variance levels)`n• F10 - Quick test (single detection)`n• F11 - Continuous monitoring mode`n• ESC - Exit`n`nPosition your game window and press F9!

Return

; ============================================
; F9 - Full Test with Multiple Variance Levels
; ============================================
F9::
    testResults := ""
    foundAny := false
    bestX := 0
    bestY := 0
    bestVariance := 0
    
    ; Test different variance levels
    variances := [30, 50, 80, 120, 150]
    
    for index, variance in variances {
        ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *%variance% %image_path%%imageFileName%
        
        if (ErrorLevel = 0) {
            testResults .= "✓ Variance " . variance . ": FOUND at (" . foundX . ", " . foundY . ")`n"
            
            if (!foundAny) {
                bestX := foundX
                bestY := foundY
                bestVariance := variance
                foundAny := true
            }
        } else {
            testResults .= "✗ Variance " . variance . ": NOT FOUND`n"
        }
    }
    
    if (foundAny) {
        MsgBox, 64, SUCCESS!, Image: %imageFileName%`n`n%testResults%`n`nRecommended variance: %bestVariance%`n`nBest location: (%bestX%, %bestY%)`n`nA red box will mark the location for 3 seconds...
        
        ; Draw box at detected location
        Gui, Marker:Destroy
        Gui, Marker:+LastFound +AlwaysOnTop -Caption +ToolWindow
        Gui, Marker:Color, Red
        Gui, Marker:Show, x%bestX% y%bestY% w80 h40 NoActivate
        Sleep, 3000
        Gui, Marker:Destroy
    } else {
        MsgBox, 48, FAILED!, Image: %imageFileName%`n`n%testResults%`n`nPossible issues:`n`n1. Image doesn't match screen appearance`n   → Recapture the image from your game`n`n2. Game window not visible/active`n   → Make sure game is in foreground`n`n3. Image is in a different state`n   → Try hovering/clicking away from target`n`n4. Screen resolution mismatch`n   → Recapture at your current resolution`n`n5. Image variance too strict`n   → Try variance 150+
    }
Return

; ============================================
; F10 - Quick Single Detection Test
; ============================================
F10::
    variance := 80  ; Default variance
    
    ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *%variance% %image_path%%imageFileName%
    
    if (ErrorLevel = 0) {
        MsgBox, 64, Quick Test - FOUND!, Image: %imageFileName%`nVariance: %variance%`n`nFound at:`nX: %foundX%`nY: %foundY%`n`nMarking location...
        
        ; Draw box
        Gui, Quick:Destroy
        Gui, Quick:+LastFound +AlwaysOnTop -Caption +ToolWindow
        Gui, Quick:Color, Lime
        Gui, Quick:Show, x%foundX% y%foundY% w80 h40 NoActivate
        Sleep, 2000
        Gui, Quick:Destroy
    } else {
        MsgBox, 48, Quick Test - NOT FOUND, Image: %imageFileName%`nVariance: %variance%`n`nNot detected on screen.`n`nTry:`n• Press F9 for full variance test`n• Make sure target is visible`n• Recapture the image
    }
Return

; ============================================
; F11 - Continuous Monitoring Mode
; ============================================
F11::
    if (A_IsSuspended) {
        Suspend, Off
        SetTimer, MonitorImage, Off
        ToolTip
        MsgBox, 64, Monitoring Stopped, Continuous monitoring has been stopped.
    } else {
        MsgBox, 64, Monitoring Started, Continuous monitoring started!`n`nImage: %imageFileName%`n`nThe script will check every 500ms.`n`nWhen detected:`n• Tooltip shows coordinates`n• Red box marks location`n`nPress F11 again to stop.
        SetTimer, MonitorImage, 500
    }
Return

MonitorImage:
    variance := 80
    ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *%variance% %image_path%%imageFileName%
    
    if (ErrorLevel = 0) {
        ToolTip, ✓ DETECTED!`n%imageFileName%`nX: %foundX% Y: %foundY%, %foundX%, %foundY%
        
        ; Draw box
        Gui, Monitor:Destroy
        Gui, Monitor:+LastFound +AlwaysOnTop -Caption +ToolWindow
        Gui, Monitor:Color, Red
        Gui, Monitor:Show, x%foundX% y%foundY% w80 h40 NoActivate
    } else {
        ToolTip, Monitoring: %imageFileName%`n(Not detected)
        Gui, Monitor:Destroy
    }
Return

; ============================================
; F12 - Show Info
; ============================================
F12::
    MsgBox, 64, Current Settings, Image Detection Tool`n`nCurrent Image: %imageFileName%`nPath: %image_path%%imageFileName%`n`nHotkeys:`n• F9 - Full test (multiple variance)`n• F10 - Quick test (variance 80)`n• F11 - Continuous monitoring`n• F12 - Show this info`n• ESC - Exit
Return

; ============================================
; Exit
; ============================================
Esc::
    SetTimer, MonitorImage, Off
    ToolTip
    Gui, Marker:Destroy
    Gui, Quick:Destroy
    Gui, Monitor:Destroy
    MsgBox, 64, Goodbye!, Image Detection Tool closed.
    ExitApp
Return

GuiClose:
    Return
