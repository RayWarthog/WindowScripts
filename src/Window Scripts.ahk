#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;------------------------------------
;   Credits, instructions
;------------------------------------

authorString = By Warthog455

versionString = Last Updated: 17/10/2017

helpString =
(
Ctrl + Alt + h for help
Ctrl + Alt + p to suspend script (pause all hotkeys from working)

Ctrl + Alt + q for always on top
Ctrl + Alt + x for clickthroughable toggle (requires it to be transparent to be clickthroughable)

Ctrl + Alt + t for transparent toggle
Ctrl + Alt + [ to decrease opacity
Ctrl + Alt + ] to increase opacity

Ctrl + Alt + f for borderless fullscreen toggle
Ctrl + Alt + b for borderless toggle

Ctrl + Alt + 9 to move the window to middle of the screen at current monitor
Ctrl + Alt + 0 to move the window to middle of the screen at primary monitor (for out of bounds windows)

Ctrl + Alt + i to view current window info (debug purposes)
Ctrl + Alt + \ to loop through all windows, getting their info
)

;------------------------------------
;   Version History
;------------------------------------

; 17/10/2017

; Added text to show author and version in help dialog.
; Made code in help dialog string cleaner.
; Added version history

;------------------------------------
;   Issues
;------------------------------------

; Using on non-standard windows, e.g. Desktop, Taskbar may have unintended consequences and may require a restart
; Clickthroughable command requires the window to be transparent to work
; Borderless Fullscreen doesn't work on programs that doesn't support normal resizable windows, like cmd.exe
; Borderless Fullscreen does not guarantee optimal monitor is chosen

;------------------------------------
;   Global variables
;------------------------------------

; Dictionary to store original positions of windows (WindowID as key, positions as value)
WindowPositionDict := {}

;------------------------------------
;   Hotkeys
;------------------------------------

!^h::
helpDialogString =
(
%helpString%

%authorString%
%versionString%
)
Msgbox, 0, Window Scripts Help, %helpDialogString%
return

!^p::Suspend
return

!^q::
WinGet, alwaysOnTopWindowID, ID, A
WinGetTitle, alwaysOnTopWindowTitle, ahk_id %alwaysOnTopWindowID%
Winset, Alwaysontop, TOGGLE, ahk_id %alwaysOnTopWindowID%
WinGet, ExStyle, ExStyle, ahk_id %alwaysOnTopWindowID%
; & 0x8 is WS_EX_TOPMOST
if (ExStyle & 0x8)
{
    ToolTip, AlwaysOnTop: Enabled (%alwaysOnTopWindowTitle%)
    SetTimer, RemoveToolTip, 2000
}
Else
{
    ToolTip, AlwaysOnTop: Disabled (%alwaysOnTopWindowTitle%)
    SetTimer, RemoveToolTip, 2000
}
return

!^x::
WinGet, clickthroughableWindowID, ID, A
WinGetTitle, clickthroughableWindowTitle, ahk_id %clickthroughableWindowID%
WinGet, Exstyle, ExStyle, ahk_id %clickthroughableWindowID%
; & 0x20 is WS_EX_CLICKTHROUGH
if (ExStyle & 0x20)
{
    WinSet, ExStyle, -0x20, ahk_id %clickthroughableWindowID%
    ToolTip, Clickthroughable: Disabled (%clickthroughableWindowTitle%)
    SetTimer, RemoveToolTip, 2000
}
Else
{
    WinSet, ExStyle, +0x20, ahk_id %clickthroughableWindowID%
    ToolTip, Clickthroughable: Enable (%clickthroughableWindowTitle%)
    SetTimer, RemoveToolTip, 2000
}
return

!^t::
WinGet, transparentWindowID, ID, A
WinGetTitle, transparentWindowTitle, ahk_id %transparentWindowID%
WinGet, opacity, Transparent, ahk_id %transparentWindowID%
if (opacity)
{
    WinSet, TransColor, Off, ahk_id %transparentWindowID%
    ToolTip, Transparency Off (%transparentWindowTitle%)
    SetTimer, RemoveToolTip, 2000
}
Else
{
    WinSet, Transparent, 200, ahk_id %transparentWindowID%
    ToolTip, Opacity: 200 (%transparentWindowTitle%)
    SetTimer, RemoveToolTip, 2000
}
return

!^]::
WinGet, transparentWindowID, ID, A
WinGetTitle, transparentWindowTitle, ahk_id %transparentWindowID%
WinGet, opacity, Transparent, ahk_id %transparentWindowID%
if (!opacity && opacity != 0)
{
    opacity = 255
}
opacity:=opacity+5
WinSet, Transparent, %opacity%, ahk_id %transparentWindowID%
; Get the opacity again and display
WinGet, opacity, Transparent, ahk_id %transparentWindowID%
ToolTip, Opacity: %opacity% (%transparentWindowTitle%)
SetTimer, RemoveToolTip, 2000
if ( opacity == 255 )
{
    WinSet, TransColor, Off, ahk_id %transparentWindowID%
}
return

!^[::
WinGet, transparentWindowID, ID, A
WinGetTitle, transparentWindowTitle, ahk_id %transparentWindowID%
WinGet, opacity, Transparent, ahk_id %transparentWindowID%
if (!opacity && opacity != 0)
{
    opacity = 255
}
opacity:=opacity-5
WinSet, Transparent, %opacity%, ahk_id %transparentWindowID%
; Get the opacity again and display
WinGet, opacity, Transparent, ahk_id %transparentWindowID%
ToolTip, Opacity: %opacity% (%transparentWindowTitle%)
SetTimer, RemoveToolTip, 2000
return

!^f::
WinGet, WindowID, ID, A
; First check the dictionary, if exists revert to original position and delete from dictionary
WindowOriginalPosition := WindowPositionDict[WindowID]
if (WindowOriginalPosition)
{
    ; Revert to original position
    WinPosX := WindowOriginalPosition.x
    WinPosY := WindowOriginalPosition.y
    WindowWidth := WindowOriginalPosition.width
    WindowHeight := WindowOriginalPosition.height
    WinSet, Style, +0xC40000, ahk_id %WindowID%
    WinMove, ahk_id %WindowID%, , WinPosX, WinPosY, WindowWidth, WindowHeight
    WindowPositionDict.Delete(WindowID)
}
; Otherwise add original position to dictionary, and fullscreen it
else
{
    WinGetPos, WinPosX, WinPosY, WindowWidth, WindowHeight, ahk_id %WindowID%
    WindowOriginalPosition := new WindowPosition(WinPosX,WinPosY,WindowWidth,WindowHeight)
    WindowPositionDict[WindowID] := WindowOriginalPosition
    RelativeMonitorFullscreen(WindowID)
}
; Purge useless keys
PurgeUselessKeys()
return

!^b::
WinGet WindowID, ID, A
WinGet, Style, Style, ahk_id %WindowID%
; First check the dictionary, if exists revert to original position and delete from dictionary
WindowOriginalPosition := WindowPositionDict[WindowID]
if (WindowOriginalPosition)
{
    ; Revert to original position
    WinPosX := WindowOriginalPosition.x
    WinPosY := WindowOriginalPosition.y
    WindowWidth := WindowOriginalPosition.width
    WindowHeight := WindowOriginalPosition.height
    WinSet, Style, +0xC40000, ahk_id %WindowID%
    WinMove, ahk_id %WindowID%, , WinPosX, WinPosY, WindowWidth, WindowHeight
    WindowPositionDict.Delete(WindowID)
}
; Otherwise swap toggle borderless
else if (Style & +0xC40000)
{
    WinSet, Style, -0xC40000, ahk_id %WindowID%
}
else
{
    WinSet, Style, +0xC40000, ahk_id %WindowID%
}
; Purge useless keys
PurgeUselessKeys()
return

!^9::
WinGet WindowMoveID, ID, A
WinGetPos,,, Width, Height, ahk_id %WindowMoveID%
monitorInfo := GetMonitorInfoWindow(WindowMoveID)
x := monitorInfo[1]
y := monitorInfo[2]
monWidth := monitorInfo[3]
monHeight := monitorInfo[4]
WinMove, ahk_id %WindowMoveID%, , x+(monWidth/2)-(Width/2), y+(monHeight/2)-(Height/2)
return

!^0::
WinGet WindowMoveID, ID, A
WinGetPos,,, Width, Height, ahk_id %WindowMoveID%
WinMove, ahk_id %WindowMoveID%, , (A_ScreenWidth/2)-(Width/2), (A_ScreenHeight/2)-(Height/2)
return

!^i::
WinGet WindowID, ID, A
WindowInfoString := GetWindowInfoString(WindowID)
Msgbox, 0, %WindowTitle%, %WindowInfoString%
return

!^\::
winList := 
WinGet winList, List
Loop %winList%
{
    id := winList%A_Index%
    WinGetTitle, windowTitle, ahk_id %id%
    WindowInfoString := "Window " . A_Index . "/" . winList . "`n" . "`n"
    WindowInfoString := WindowInfoString . GetWindowInfoString(id) . "`n`n" . "Click ok to continue, cancel to stop."
    MsgBox, 1, %windowTitle%, %WindowInfoString%
    IfMsgBox, Ok
        Continue
    Else
        Break
}
; CreateWindowsInfoListGUI()
return

;------------------------------------
;   Autohotkey Labels
;------------------------------------

RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return

;------------------------------------
;   Classes
;------------------------------------

class WindowPosition
{
    __New(WinPosX, WinPosY, WindowWidth, WindowHeight)
    {
        this.x := WinPosX
        this.y := WinPosY
        this.width := WindowWidth
        this.height := WindowHeight
    }
}

;------------------------------------
;   Functions
;------------------------------------

; Function to purge the dictionary of useless keys (the window not existing anymore)
PurgeUselessKeys()
{
    global WindowPositionDict
    For key, value in WindowPositionDict
    {
        IfWinNotExist, ahk_id %key%
        {
            WindowPositionDict.Delete(key)
        }
    }
    return
}

; Function to make a window fullscreen, relative to their monitor
RelativeMonitorFullscreen(WindowID)
{
    monitorInfo := GetMonitorInfoWindow(WindowID)
    x := monitorInfo[1]
    y := monitorInfo[2]

    width := monitorInfo[3]
    height := monitorInfo[4]

    ; Fullscreen
    WinSet, Style, -0xC40000, ahk_id %WindowID%
    WinMove, ahk_id %WindowID%, , x, y, width, height
    return  
}

; Given a windowID, returns an array [x, y, width, heigth], which contains info about the monitor the window is on
; The monitor chosen is determined by postition of top left and bottom right corners of the window
GetMonitorInfoWindow(WindowID)
{
    WinGetPos, WinPosX, WinPosY, width, height, ahk_id %WindowID%

    return GetMonitorInfoPos(WinPosX, WinPosY)
}

; Given a position coordinate, returns an array [x, y, width, heigth], Where
; x, y are the top left coordinate of the monitor the position is in
; width, heigth are the height and width of the monitor the position is in
;
; code partially taken from https://autohotkey.com/board/topic/111638-activemonitorinfo-get-monitor-resolution-and-origin-from-of-monitor-with-mouse-on/
GetMonitorInfoPos(positionX, positionY)
{
    SysGet, monCount, MonitorCount

    ; the distance between the point and the primary monitor top left coordinate, used to determine the closest monitor, if invalid Pos ie out of bounds
    minimumMonitorIndex := 1
    minimumDistance := GetEuclideanDistance(positionX, positionY, 0, 0)
    
    Loop %monCount%
    {
        SysGet, curMon, Monitor, %a_index%
        if ( positionX >= curMonLeft and positionX <= curMonRight and positionY >= curMonTop and positionY <= curMonBottom )
        {
            X      := curMonLeft
            y      := curMonTop
            width  := curMonRight  - curMonLeft
            height := curMonBottom - curMonTop      

            return [x, y , width, height, a_index]
        }
        ; Calculate distance, and store the monitor index if it is the minimum distance with the point
        else
        {
            distance := GetEuclideanDistance(positionX, positionY, curMonLeft, curMonTop)
            if ( distance < minimumDistance )
            {
                minimumMonitorIndex := a_index
                minimumDistance := distance
            }
        }
    }

    ; Loop finished, use the minimum distance monitor
    SysGet, minMon, Monitor, %minimumMonitorIndex%
    X      := minMonLeft
    y      := minMonTop
    width  := minMonRight  - minMonLeft
    height := minMonBottom - minMonTop      

    return [x, y, width, height, minimumMonitorIndex]
}

GetEuclideanDistance(x1, y1, x2, y2)
{
    return Sqrt( ( ( x2 - x1 ) ** 2 ) + ( ( y2 - y1 ) ** 2 ) )
}

GetWindowInfoString(WindowID)
{
    WinGetTitle WindowTitle, ahk_id %WindowID%
    WinGet Style, Style, ahk_id %WindowID%
    WinGet ExStyle, ExStyle, ahk_id %WindowID%
    WinGet MinMax, MinMax, ahk_id %WindowID%
    WinGet ProcessName, ProcessName, ahk_id %WindowID%
    WinGet ProcessPath, ProcessPath, ahk_id %WindowID%
    WinGet PID, PID, ahk_id %WindowID%
    WinGet Transparent, Transparent, ahk_id %WindowID%
    WinGet TransColor, TransColor, ahk_id %WindowID%
    WinGetPos, X, Y, Width, Height, ahk_id %WindowID%
    SysGet, VirtualScreenWidth, 78
    SysGet, VirtualScreenHeight, 79
    monitorInfo := GetMonitorInfoWindow(WindowID)
    monitorX := monitorInfo[1]
    monitorY := monitorInfo[2]
    monitorWidth := monitorInfo[3]
    monitorHeight := monitorInfo[4]
    monitorIndex := monitorInfo[5]
    WindowInfoString =
    (
%WindowTitle%
ID: %WindowID%

MinMax code: %MinMax%
(-1 = minimized, 1 = maximized, 0 = neither)

Process:        %ProcessName%
Process path:   (%ProcessPath%)
Process ID: %PID%

Style Code: %Style%
ExStyle Code:   %ExStyle%

Current Transparency:   %Transparent%
TransColor code:    %TransColor%

Position and size:
X: %X% Y: %Y%
Width: %Width% Height: %Height%

Virtual Screen Width: %VirtualScreenWidth%
Virtual Screen Height: %VirtualScreenHeight%

Monitor info where window is positioned:
Index: %monitorIndex%
Top Left Postion:
X: %monitorX% Y: %monitorY%
Width: %monitorWidth% Height: %monitorHeight%
    )
    return WindowInfoString
}

CreateWindowsInfoListGUI()
{
    Gui, Add, Text,, Hey you shouldn't be here!
    Gui, show
}