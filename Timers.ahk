; Timer script created by XRay71
; Check out some of my other work! https://github.com/XRay71
; Please leave credit when sharing
; Use via ctrl + shift + [

#NoEnv
#Persistent
#SingleInstance, Ignore
#UseHook, On

SetWorkingDir %A_ScriptDir%
SetBatchLines, -1
SetTitleMatchMode, 2
CoordMode, Mouse, Screen
SetWinDelay, -1

FileDelete, %A_ScriptDir%\icon.ico

IniRead, DurationSettingsSelection, %A_ScriptFullPath%, Duration Settings, Selection
IniRead, TransparencySettings, %A_ScriptFullPath%, Transparency, Transparency

Hotkey, ^+[, OpenTimers

Gui, Main:+HwndGuiHWND -Resize
Gui, Main:Default

Gui, Main:Add, Button, x0 y0 w1 h1 +Default Hidden vNewTimerLabelButton gNewTimerLabelSubmitted
Gui, Main:Add, Button, x0 y0 w1 h1 Hidden vNewTimerTimeButton gNewTimerTimeSubmitted

Gui, Main:Add, Edit, x8 w220 h20 Hidden Disabled vNewTimerDuration gEditUpdated HwndNewTimerDurationHWND
Gui, Main:Add, Edit, x+4 w220 h20 Hidden Disabled vNewTimerUntil gEditUpdated HwndNewTimerUntilHWND
Gui, Main:Add, Edit, x8 yp w446 h20 vNewTimerLabel gEditUpdated HwndNewTimerLabelHWND

Gui, Main:Add, Text, x+4 yp+3 w49 Center Border vCurrentTime, %A_Hour%:%A_Min%:%A_Sec%
Gui, Main:Add, Slider, x8 y+8 w500 h20 TickInterval5 Page5 Line1 ToolTip vTransparencySlider gSetTransparency, %TransparencySettings%

Gui, Main:Font, s11 Norm cBlack, Calibri
Gui, Main:Add, GroupBox, x8 y+4 w500 h40 vActiveTimers, Active Timers

Gui, Main:Font, s7
Gui, Main:Add, Button, xp+95 yp+2 w50 h15 vClearAllButton gClearAllTimers, Clear All
Gui, Main:Add, Text, x+4 yp+1 h16 0x1 0x10

Gui, Main:Add, Button, xp+5 yp-1 w50 h15 vDurationSettingsHoursButton gDurationSettingsUpdated HwndDurationSettingsHoursButtonHWND, Hours
Gui, Main:Add, Button, x+4 yp w50 h15 vDurationSettingsMinutesButton gDurationSettingsUpdated HwndDurationSettingsMinutesButtonHWND, Minutes
Gui, Main:Add, Button, x+4 yp w50 h15 vDurationSettingsHHMMButton gDurationSettingsUpdated HwndDurationSettingsHHMMButtonHWND, hh:mm
Gui, Main:Add, Text, x+4 yp+1 h16 0x1 0x10
Gui, Main:Add, Text, xp+5 yp h14 w90 Center Border vSelectedDurationSettings, Selected: %DurationSettingsSelection%

Gui, Main:Font
Gui, Main:Add, Text, x14 yp+18 w488 0x10

Gui, Main:Add, Text, xp yp+4 vNoActiveTimers, No active timers!
Gui, Main:Add, Text, xp y40 Hidden Disabled

SetTimer, UpdateTime, 100, 2
SetTimer, WatchMouse, 10, 1
SetCueBanner(NewTimerLabelHWND, "What do you want to set a timer for?")
SetCueBanner(NewTimerDurationHWND, DurationSettingsSelection == "Hours" ? "Please input a positive number of hours." : DurationSettingsSelection == "Minutes" ? "Please input a positive number of minutes." : "hh:mm until the end of the timer.")
SetCueBanner(NewTimerUntilHWND, "The timer ends at hh:mm (24 hour time).")

Gui, Transparency:+AlwaysOnTop +ToolWindow
Gui, Transparency:Show, x0 y0 w1 h1 NoActivate, Transparency
IfWinExist Transparency
    WinSet, Style, -0xC40000,
DllCall("SetMenu", "Ptr", WinExist(), "Ptr", 0)
Gui, Transparency:Cancel

Gui, Transparency:Add, Text, x8 y8 vTransPreview, Transparency Preview

Sleep, 100

Gui, TimersFinished:+AlwaysOnTop +ToolWindow
Gui, TimersFinished:Show, x0 y0 w1 h1 NoActivate, Finished Timers
IfWinExist Finished Timers
    WinSet, Style, -0xC40000,
DllCall("SetMenu", "Ptr", WinExist(), "Ptr", 0)
Gui, TimersFinished:Cancel

GroupBoxR := 1
GuiY := 85
GuiFinishedY := 8
TimerList := []
ControlNum := 0
ControlNumFinished := 0
TimerFinishedList := []

WatchMouse() {
    CoordMode, Mouse, Screen
    MouseGetPos, mX, mY
    IfWinExist, Transparency
        WinMove, Transparency,, mX + 10, mY + 10
    IfWinExist, Finished Timers
        WinMove, Finished Timers,, mX + 10, mY + 10
}

DurationSettingsUpdated(HWND) {
    Global
    DurationSettingsSelection := HWND == DurationSettingsHoursButtonHWND ? "Hours" : HWND == DurationSettingsMinutesButtonHWND ? "Minutes" : "hh:mm"
    GuiControl, Main:Text, SelectedDurationSettings, Selected: %DurationSettingsSelection%
    IniWrite, %DurationSettingsSelection%, %A_ScriptFullPath%, Duration Settings, Selection
    SetCueBanner(NewTimerDurationHWND, DurationSettingsSelection == "Hours" ? "Please input a positive number of hours." : DurationSettingsSelection == "Minutes" ? "Please input a positive number of minutes." : "hh:mm until your timer stops")
}

SetTransparency() {
    Global
    Gui, Main:Submit, NoHide
    IniWrite, %TransparencySlider%, %A_ScriptFullPath%, Transparency, Transparency
    IfWinNotExist, Finished Timers
    {
        Gui, Transparency:Show, AutoSize NoActivate, Transparency
        TransValue := 255 - Floor(TransparencySlider * 2.55)
        WinSet, Transparent, %TransValue%, Transparency
        SetTimer, ClosePreview, Off
        if (!flag)
            SetTimer, ClosePreview, -1500, 3
    }
    TransValue := 255 - Floor(TransparencySlider * 2.55)
    WinSet, Transparent, %TransValue%, Finished Timers
}

ClosePreview() {
    Global
    Gui, Transparency:Cancel
}

TimerReady(timer, index) {
    Global
    Thread, NoTimers, true
    if (timer.Finished)
        Return
    if (timer) {
        TimerFinishedList.Push(timer)
        TimerList[index].Finished := true
        SortTimers()
    }
    Gui, TimersFinished:Margin, 8, 8
    Gui, TimersFinished:Add, Text, Hidden, x8 y8
    for i, timer1 in TimerFinishedList
    {
        if (i <= ControlNumFinished) {
            Gui, Dummy:Font
            Gui, Dummy:Add, Text, -Wrap vDummy, % timer1.LabelName
            GuiControlGet, size, Dummy:Pos, Dummy
            Gui, Dummy:Destroy
            GuiControl, TimersFinished:Move, TimerFinishedNumber%i%Text, w%sizew%
            GuiControl, TimersFinished:Text, TimerFinishedNumber%i%Text, % timer1.LabelName
            GuiControl, TimersFinished:Show, TimerFinishedNumber%i%Text
        } else {
            Gui, TimersFinished:Font
            Gui, TimersFinished:Add, Text, xp y%GuiFinishedY% h15 vTimerFinishedNumber%i%Text, % timer1.LabelName
            GuiFinishedY += 20
        }
        ControlNumFinished := Max(ControlNumFinished, i)
    }
    Gui, TimersFinished:Show, AutoSize NoActivate, Finished Timers
    GuiControlGet, TransparencySlider
    Sleep, 100
    IfWinExist Finished Timers
        WinSet, Style, -0xC40000,
    DllCall("SetMenu", "Ptr", WinExist(), "Ptr", 0)
    TransValue := 255 - Floor(TransparencySlider * 2.55)
    WinSet, Transparent, %TransValue%, Finished Timers
    Thread, NoTimers, false
}

UpdateTime() {
    Global
    if (TimerList.Length())
        GuiControl, Main:Hide, NoActiveTimers
    else
        GuiControl, Main:Show, NoActiveTimers
    GuiControl, Main:Text, CurrentTime, %A_Hour%:%A_Min%:%A_Sec%
    for i, timer in TimerList
    {
        TimerEnding := timer.EndTime
        TimerProgressText := HHMMSSUntil(TimerEnding)
        EnvSub, TimerEnding, A_Now, Seconds
        timer.ProgressProgress := TimerEnding
        TimerProgress := timer.ProgressProgress
        TimerRange := timer.ProgressRange
        GuiControl, Main:, TimerNumber%i%Progress, % -TimerProgress
        GuiControl, Main:Text, TimerNumber%i%ProgressText, %TimerProgressText%
        if (TimerProgress <= 0)
            TimerReady(timer, i)
    }
    if (!TimerFinishedList.Length()) {
        Gui, TimersFinished:Cancel
    }
}

SetCueBanner(HWND, PlaceholderText, Show := true)
{
    DllCall("user32\SendMessage", "ptr", HWND, "uint", 0x1501, "int", Show, "str", PlaceholderText, "int")
}

NewTimerLabelSubmitted() {
    Global
    if (!NewTimerLabel) {
        MainGuiClose()
        Gui, Main:Cancel
    } else {
        GuiControl, Main:-Default, NewTimerLabelButton
        GuiControl, Main:+Default, NewTimerTimeButton
        GuiControl, Main:Show, NewTimerDuration
        GuiControl, Main:Show, NewTimerUntil
        GuiControl, Main:Enable, NewTimerDuration
        GuiControl, Main:Enable, NewTimerUntil
        GuiControl, Main:Hide, NewTimerLabel
        GuiControl, Main:Disable, NewTimerLabel
        GuiControl, Main:Focus, NewTimerDuration
    }
}

NewTimerTimeSubmitted() {
    Global
    if (!NewTimerDuration && !NewTimerUntil){
        MainGuiClose()
        Gui, Main:Cancel
    } else {
        NowTime := A_Now
        TimerEndTime := ""
        if (NewTimerDuration) {
            if (DurationSettingsSelection != "hh:mm") {
                if NewTimerDuration is not number
                    Return
                if (NewTimerDuration < 0)
                    Return
                TimerEndTime += NewTimerDuration, %DurationSettingsSelection%
            } else {
                if (!RegExMatch(NewTimerDuration, "^\d\d:\d\d$"))
                    Return
                TimerEndTime += SubStr(NewTimerDuration, 1, 2), Hours
                TimerEndTime += SubStr(NewTimerDuration, 4), Minutes
            }
        } else {
            if (!RegExMatch(NewTimerUntil, "^\d\d:\d\d$"))
                Return
            NewHour := StrSplit(NewTimerUntil, ":")[1]
            NewMinute := StrSplit(NewTimerUntil, ":")[2]
            if (NewHour > 23 || NewMinute > 59)
                Return
            if (A_Hour > NewHour) {
                TimerEndTime += 24 - A_Hour + NewHour, Hours
                if (A_Min - NewMinute > 0)
                    TimerEndTime += -Abs(A_Min - NewMinute), Minutes
                else
                    TimerEndTime += Abs(A_Min - NewMinute), Minutes
            } else if (A_Hour == NewHour && A_Min > NewMinute) {
                TimerEndTime += 24, Hours
                TimerEndTime += -(A_Min - NewMinute), Minutes
            } else {
                TimerEndTime += Abs(A_Hour - NewHour), Hours
                if (A_Min - NewMinute > 0)
                    TimerEndTime += -Abs(A_Min - NewMinute), Minutes
                else
                    TimerEndTime += Abs(A_Min - NewMinute), Minutes
            }
        }
        TimerRange := TimerEndTime
        EnvSub, TimerRange, %A_Now%, Seconds
        TimerList.Push(new TimerObject(TimerRange, TimerEndTime, NewTimerLabel))
        MainGuiClose()
        SortTimers()
        UpdateTimers()
    }
}

UpdateTimers() {
    Global
    Thread, NoTimers, true
    GroupBoxR := Max(0, 4 * TimerList.Length() - 1)
    if (GroupBoxR != 1)
        GuiControl, Main:Hide, NoActiveTimers
    GuiH := 40 + GroupBoxR * 20
    GuiControl, Main:Move, ActiveTimers, h%GuiH%
    For i, timer in TimerList
    {
        TimerEndTime := timer.EndTime
        TimerProgressText := HHMMSSUntil(TimerEndTime)
        FormatTime, TimerEndTime, %TimerEndTime%, dd MMMM (dddd) 'in the year' yyyy', at' HH:mm (hh:mm tt)
        TimerRange := timer.ProgressRange
        TimerProgress := timer.ProgressProgress
        if (i <= ControlNum) {
            GuiControl, Main:Text, TimerNumber%i%Label, % "Label: " timer.LabelName
            GuiControl, Main:Show, TimerNumber%i%Label
            GuiControl, Main:Text, TimerNumber%i%EndTime, Ends %TimerEndTime%
            GuiControl, Main:Show, TimerNumber%i%EndTime
            GuiControl, Main:+Range-%TimerRange%-0, TimerNumber%i%Progress
            GuiControl, Main:, TimerNumber%i%Progress, % -TimerProgress
            GuiControl, Main:Show, TimerNumber%i%Progress
            GuiControl, Main:Text, TimerNumber%i%ProgressText, %TimerProgressText%
            GuiControl, Main:Show, TimerNumber%i%ProgressText
            GuiControl, Main:Show, TimerNumber%i%RemoveButton
        } else {
            Gui, Main:Add, Text, x14 y%GuiY% w488 h16 +BackgroundTrans vTimerNumber%i%Label, % "Label: " timer.LabelName
            Gui, Main:Add, Text, xp yp+20 w375 h16 +BackgroundTrans vTimerNumber%i%EndTime, Ends %TimerEndTime%
            Gui, Main:Add, Button, x401 yp-2 w100 h16 vTimerNumber%i%RemoveButton gRemoveTimer HwndTimerNumber%i%RemoveButtonHWND, Remove Timer
            Gui, Main:Add, Progress, x14 yp+22 w488 h16 Range-%TimerRange%-0 Border cBlue vTimerNumber%i%Progress, % -TimerProgress
            Gui, Main:Font, cRed
            Gui, Main:Add, Text, x14 yp+1 w488 h16 +BackgroundTrans Center vTimerNumber%i%ProgressText, %TimerProgressText%
            Gui, Main:Add, Text, x14 yp+19 Hidden
            Gui, Main:Font
            GuiY += 80
        }
        ControlNum := Max(i, ControlNum)
    }
    Thread, NoTimers, false
    Gui, Main:Show, w516 AutoSize, Timers
}

RemoveTimer(HWND) {
    Global
    for i, timer in TimerList
    {
        if (HWND == TimerNumber%i%RemoveButtonHWND) {
            timer1 := TimerList[i]
            TimerList.RemoveAt(i)
            RemoveNum := TimerList.Length() + 1
            GuiControl, Main:Hide, TimerNumber%RemoveNum%Label
            GuiControl, Main:Hide, TimerNumber%RemoveNum%EndTime
            GuiControl, Main:Hide, TimerNumber%RemoveNum%RemoveButton
            GuiControl, Main:Hide, TimerNumber%RemoveNum%Progress
            GuiControl, Main:Hide, TimerNumber%RemoveNum%ProgressText
            GroupBoxR := Max(0, 4 * TimerList.Length() - 1)
            if (GroupBoxR != 1)
                GuiControl, Main:Hide, NoActiveTimers
            else
                GuiControl, Main:Show, NoActiveTimers
            GuiH := 40 + GroupBoxR * 20
            GuiControl, Main:Move, ActiveTimers, h%GuiH%
            UpdateTimers()
            Gui, Main:Show, w516 AutoSize, Timers
            if (timer1.Finished) {
                for i, timer2 in TimerFinishedList
                {
                    if (timer2.EndTime == timer1.EndTime) {
                        TimerFinishedList.RemoveAt(i)
                        RemoveNum1 := TimerFinishedList.Length() + 1
                        GuiControl, TimersFinished:Hide, TimerFinishedNumber%RemoveNum1%Text
                        TimerReady(0, 0)
                        Gui, TimersFinished:Show, AutoSize NoActivate, Finished Timers
                        Break
                    }
                }
            }
            Return
        }
    }
}

EditUpdated() {
    Gui, Main:Submit, NoHide
}

OpenTimers() {
    Global
    Gui, Main:Show, xCenter yCenter w516 AutoSize, Timers
}

HHMMSSUntil(NumSec) {
    EnvSub, NumSec, A_Now, Seconds
    if (NumSec < 0)
        return "00:00:00"
    time := 19990101
    time += %NumSec%, seconds
    FormatTime, mmss, %time%, mm:ss
    return (NumSec//3600 < 10 ? "0" NumSec//3600 : NumSec//3600) ":" mmss
}

ClearAllTimers() {
    Global
    for i, timer in TimerList
    {
        GuiControl, Main:Hide, TimerNumber%i%Label
        GuiControl, Main:Hide, TimerNumber%i%EndTime
        GuiControl, Main:Hide, TimerNumber%i%RemoveButton
        GuiControl, Main:Hide, TimerNumber%i%Progress
        GuiControl, Main:Hide, TimerNumber%i%ProgressText
    }
    TimerList := []
    GroupBoxR := Max(0, 4 * TimerList.Length() - 1)
    if (GroupBoxR != 1)
        GuiControl, Main:Hide, NoActiveTimers
    else
        GuiControl, Main:Show, NoActiveTimers
    GuiH := 40 + GroupBoxR * 20
    GuiControl, Main:Move, ActiveTimers, h%GuiH%
    for i, timer in TimerFinishedList
    {
        GuiControl, TimersFinished:Hide, TimerFinishedNumber%i%Text
    }
    TimerFinishedList := []
    UpdateTime()
    TimerReady(0, 0)
    Gui, Main:Show, w516 AutoSize, Timers
    Gui, TimersFinished:Show, AutoSize NoActivate, Finished Timers
}

MainGuiClose() {
    GuiControl, Main:Text, NewtimerLabel,
    GuiControl, Main:Text, NewtimerDuration,
    GuiControl, Main:Text, NewtimerUntil,
    GuiControl, Main:+Default, NewTimerLabelButton
    GuiControl, Main:Show, NewTimerLabel
    GuiControl, Main:Enable, NewTimerLabel
    GuiControl, Main:Hide, NewTimerDuration
    GuiControl, Main:Hide, NewTimerUntil
    GuiControl, Main:Disable, NewTimerDuration
    GuiControl, Main:Disable, NewTimerUntil
    GuiControl, Main:Focus, NewTimerLabel
}

CompareTimers(Timer1, Timer2) {
    Return Timer1.EndTime > Timer2.EndTime ? 1 : Timer1.EndTime == Timer2.EndTime ? 0 : -1
}

SortTimers() {
    Global
    i := 1
    while (i < TimerList.Length()) {
        if (CompareTimers(TimerList[i], TimerList[i + 1]) == 1) {
            Temp1 := TimerList[i]
            TimerList[i] := TimerList[i + 1]
            TimerList[i + 1] := Temp1
            if (i != 1)
                i -= 2
        }
        i++
    }
    while (i < TimerFinishedList.Length()) {
        if (CompareTimers(TimerFinishedList[i], TimerFinishedList[i + 1]) == 1) {
            Temp1 := TimerFinishedList[i]
            TimerFinishedList[i] := TimerFinishedList[i + 1]
            TimerFinishedList[i + 1] := Temp1
            if (i != 1)
                i -= 2
        }
        i++
    }
}

class TimerObject
{
    ProgressRange := 100
    EndTime := A_Now
    LabelName := "hi"
    ProgressProgress := 0
    Finished := false
    
    __New(newProgressRange, newEndTime, NewLabelName) {
        this.ProgressRange := newProgressRange
        this.EndTime := newEndTime
        this.LabelName := newLabelName
        this.ProgressProgress := newProgressRange
    }
}

/*
[Duration Settings]
Selection=Minutes
[Transparency]
Transparency=30
*/
