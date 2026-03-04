; <COMPILER: v1.1.22.07>
#NoEnv
#SingleInstance, Force

#Persistent
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1

global RustExePath := "C:\Program Files (x86)\Steam\steamapps\common\Rust\Rust.exe"
global SteamExePath := "C:\Program Files (x86)\Steam\steam.exe"
global RegKey := "HKEY_CURRENT_USER\Software\RustAutoReconnect"
global ServerList := []

LoadServersFromRegistry()
if (ServerList.Length() = 0) {
    ServerList.Push({name: "Rustoria", command: "connect 208.52.153.80:28015"})
    ServerList.Push({name: "Moose", command: "connect monday.eu.moose.gg:28010"})
    ServerList.Push({name: "Rustopia", command: "connect USMedium.Rustopia.gg:28015"})
    SaveServersToRegistry()
}

global ScriptRunning := false
global CurrentServerIndex := 1
global ServerRotationMinutes := 30
global AFKMovementSeconds := 60
global LastServerRotation := 0
global LastAFKMovement := 0
global DisconnectCheckInterval := 5000
global SkipRustLaunch := 0

LoadSettingsFromRegistry()

global MovementKeys := ["w", "a", "s", "d"]
global LastMovementIndex := 0
global ConsoleLog := []
global MaxConsoleLines := 100
global StatusText
global CurrentServerText
global NextRotationText
global LastAFKText
global ConsoleOutput
global ServerListView
global RotationMinutes
global AFKSeconds
global SkipLaunchCheckbox
global CompactMode := false
global FullWindowHeight := 975
global CompactWindowHeight := 345

SaveServersToRegistry() {
    Loop, 100
    {
        RegDelete, %RegKey%, Server%A_Index%_Name
        RegDelete, %RegKey%, Server%A_Index%_Command
    }
    RegWrite, REG_DWORD, %RegKey%, ServerCount, % ServerList.Length()
    Loop, % ServerList.Length()
    {
        RegWrite, REG_SZ, %RegKey%, Server%A_Index%_Name, % ServerList[A_Index].name
        RegWrite, REG_SZ, %RegKey%, Server%A_Index%_Command, % ServerList[A_Index].command
    }
}

LoadServersFromRegistry() {
    RegRead, serverCount, %RegKey%, ServerCount
    if (ErrorLevel) {
        return
    }
    ServerList := []
    Loop, %serverCount%
    {
        RegRead, serverName, %RegKey%, Server%A_Index%_Name
        RegRead, serverCommand, %RegKey%, Server%A_Index%_Command
        if (!ErrorLevel && serverName != "" && serverCommand != "") {
            ServerList.Push({name: serverName, command: serverCommand})
        }
    }
}

SaveSettingsToRegistry() {
    RegWrite, REG_DWORD, %RegKey%, ServerRotationMinutes, %ServerRotationMinutes%
    RegWrite, REG_DWORD, %RegKey%, AFKMovementSeconds, %AFKMovementSeconds%
    RegWrite, REG_SZ, %RegKey%, RustExePath, %RustExePath%
    RegWrite, REG_DWORD, %RegKey%, SkipRustLaunch, %SkipRustLaunch%
}

LoadSettingsFromRegistry() {
    RegRead, loadedRotation, %RegKey%, ServerRotationMinutes
    if (!ErrorLevel) {
        ServerRotationMinutes := loadedRotation
    }
    RegRead, loadedAFK, %RegKey%, AFKMovementSeconds
    if (!ErrorLevel) {
        AFKMovementSeconds := loadedAFK
    }
    RegRead, loadedPath, %RegKey%, RustExePath
    if (!ErrorLevel && loadedPath != "") {
        RustExePath := loadedPath
    }
    RegRead, loadedSkip, %RegKey%, SkipRustLaunch
    if (!ErrorLevel) {
        SkipRustLaunch := loadedSkip
    }
}

CreateGUI()
return

CreateGUI() {
    global StartScriptButton, StopScriptButton, HotkeysText, BottomDivider
    Gui, Main:New, -Caption -DPIScale, Rust Auto Reconnect Manager
    Gui, Main:Color, 000000
    Gui, Main:Font, s12 Bold cYellow, Arial
    Gui, Main:Add, Text, x530 y5 w30 h30 gMinimizeWindow Center, _
    Gui, Main:Font, s14 Bold cRed, Arial
    Gui, Main:Add, Text, x565 y5 w30 h30 gHandleClose Center, X
    Gui, Main:Add, Text, x0 y0 w520 h40 gDragWindow
    Gui, Main:Font, s16 Bold c00FF00, Arial
    Gui, Main:Add, Text, x50 y10 w470 h30 Center BackgroundTrans, RUST AUTO RECONNECT
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x0 y45 w600 h20 Center, AFK Hours
    Gui, Main:Add, Progress, x20 y75 w560 h1 c00FF00
    Gui, Main:Font, s10 Bold c00FF00, Arial
    Gui, Main:Add, Text, x20 y85 w560 h25 Center, SYSTEM STATUS
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x40 y120 w140 Right, Script Status:
    Gui, Main:Font, s9 Bold cRed, Arial
    Gui, Main:Add, Text, x190 y120 w150 vStatusText, OFFLINE
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x40 y145 w140 Right, Current Server:
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x190 y145 w360 vCurrentServerText, None
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x40 y170 w140 Right, Next Rotation:
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x190 y170 w150 vNextRotationText, --
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x40 y195 w140 Right, Last AFK Action:
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x190 y195 w150 vLastAFKText, --
    Gui, Main:Add, Progress, x20 y230 w560 h1 c00FF00
    Gui, Main:Font, s10 Bold c00FF00, Arial
    Gui, Main:Add, Text, x20 y240 w560 h25 Center, SERVER ROTATION LIST
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, ListView, x30 y275 w540 h150 vServerListView Background000000 c00FF00 -E0x200, #|Server Name|Server Command|Status
    LV_ModifyCol(1, 40)
    LV_ModifyCol(2, 150)
    LV_ModifyCol(3, 270)
    LV_ModifyCol(4, 60)
    UpdateServerListView()
    Gui, Main:Font, s9 Bold c00FF00, Arial
    Gui, Main:Add, Text, x30 y435 w125 h25 gAddServer Center, [ Add Server ]
    Gui, Main:Add, Text, x165 y435 w125 h25 gEditServer Center, [ Edit Server ]
    Gui, Main:Add, Text, x300 y435 w125 h25 gDeleteServer Center, [ Delete Server ]
    Gui, Main:Add, Text, x435 y435 w135 h25 gMoveUpServer Center, [ Move Up ]
    Gui, Main:Add, Progress, x20 y475 w560 h1 c00FF00
    Gui, Main:Font, s10 Bold c00FF00, Arial
    Gui, Main:Add, Text, x20 y485 w560 h25 Center, CONFIGURATION
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x40 y525 w200, Server Rotation Interval (min):
    Gui, Main:Add, Edit, x250 y522 w80 h22 vRotationMinutes Background000000 c00FF00 Border, %ServerRotationMinutes%
    Gui, Main:Add, Text, x40 y555 w200, AFK Movement Interval (sec):
    Gui, Main:Add, Edit, x250 y552 w80 h22 vAFKSeconds Background000000 c00FF00 Border, %AFKMovementSeconds%
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Checkbox, x40 y585 w250 h20 vSkipLaunchCheckbox Checked%SkipRustLaunch%, Rust is already running (skip launch)
    Gui, Main:Font, s9 Bold c00FF00, Arial
    Gui, Main:Add, Text, x350 y522 w210 h30 gSaveSettings Center, [ Save Settings ]
    Gui, Main:Font, s9 Normal c00FF00, Arial
    Gui, Main:Add, Text, x40 y615 w200, Rust Executable Path:
    Gui, Main:Font, s9 Bold c00FF00, Arial
    Gui, Main:Add, Text, x250 y612 w80 h25 gBrowseRustExe Center, [ Browse ]
    Gui, Main:Add, Progress, x20 y650 w560 h1 c00FF00
    Gui, Main:Font, s10 Bold c00FF00, Arial
    Gui, Main:Add, Text, x20 y660 w460 h25, CONSOLE LOG
    Gui, Main:Font, s9 Bold c00FF00, Arial
    Gui, Main:Add, Text, x490 y660 w80 h25 gClearConsole Center, [ Clear ]
    Gui, Main:Font, s8 Normal c00FF00, Consolas
    Gui, Main:Add, Edit, x30 y695 w540 h150 vConsoleOutput ReadOnly Background000000 c00FF00 -Wrap HScroll
    Gui, Main:Add, Progress, x20 y860 w560 h1 c00FF00
    Gui, Main:Font, s12 Bold c00FF00, Arial
    Gui, Main:Add, Text, x30 y875 w260 h50 vStartScriptButton gStartScript Center, [ START SCRIPT ]
    Gui, Main:Add, Text, x310 y875 w260 h50 vStopScriptButton gStopScript Center, [ STOP SCRIPT ]
    Gui, Main:Font, s8 Normal c00FF00, Arial
    Gui, Main:Add, Text, x20 y940 w560 vHotkeysText Center, Hotkeys: F9 = Manual Rotation | F10 = Pause/Resume | F12 = Reload Script
    Gui, Main:Add, Progress, x20 y960 w560 h1 vBottomDivider c00FF00
    Gui, Main:Show, w600 h975
    LogConsole("System initialized successfully", "SUCCESS")
    LogConsole("Loaded " . ServerList.Length() . " servers from registry", "INFO")
    LogConsole("Ready to start - Click START SCRIPT button", "INFO")
}

SetCompactLayout(enableCompact := false) {
    global CompactMode, CompactWindowHeight, FullWindowHeight
    if (enableCompact) {
        if (CompactMode)
            return
        GuiControl, Main:Move, StartScriptButton, x30 y250 w260 h50
        GuiControl, Main:Move, StopScriptButton, x310 y250 w260 h50
        GuiControl, Main:Move, HotkeysText, x20 y315 w560 h20
        GuiControl, Main:Move, BottomDivider, x20 y335 w560 h1
        Gui, Main:Show, h%CompactWindowHeight%
        CompactMode := true
    } else {
        if (!CompactMode)
            return
        GuiControl, Main:Move, StartScriptButton, x30 y875 w260 h50
        GuiControl, Main:Move, StopScriptButton, x310 y875 w260 h50
        GuiControl, Main:Move, HotkeysText, x20 y940 w560 h20
        GuiControl, Main:Move, BottomDivider, x20 y960 w560 h1
        Gui, Main:Show, h%FullWindowHeight%
        CompactMode := false
    }
}

MinimizeWindow:
WinMinimize, Rust Auto Reconnect Manager
return

DragWindow:
PostMessage, 0xA1, 2
return

HandleClose:
if (ScriptRunning) {
    MsgBox, 4, Confirm Exit, The script is still running. Exit anyway?
    IfMsgBox Yes
    {
        ExitApp
    }
} else {
    ExitApp
}
return

MainGuiClose:
if (ScriptRunning) {
    MsgBox, 4, Confirm Exit, The script is still running. Exit anyway?
    IfMsgBox Yes
    {
        ExitApp
    }
} else {
    ExitApp
}
return

UpdateServerListView() {
    GuiControl, Main:-Redraw, ServerListView
    LV_Delete()
    Loop, % ServerList.Length()
    {
        status := (A_Index = CurrentServerIndex && ScriptRunning) ? "Active" : "Standby"
        LV_Add("", A_Index, ServerList[A_Index].name, ServerList[A_Index].command, status)
    }
    if (CurrentServerIndex > 0 && CurrentServerIndex <= ServerList.Length()) {
        LV_Modify(CurrentServerIndex, "Select")
    }
    GuiControl, Main:+Redraw, ServerListView
}

LogConsole(message, type := "INFO") {
    timestamp := A_Hour ":" A_Min ":" A_Sec
    if (type = "ERROR")
        prefix := "[ERROR]  "
    else if (type = "SUCCESS")
        prefix := "[OK]     "
    else if (type = "WARNING")
        prefix := "[WARN]   "
    else if (type = "SYSTEM")
        prefix := "[SYS]    "
    else
        prefix := "[INFO]   "
    logLine := timestamp " " prefix message "`r`n"
    GuiControlGet, currentLog, Main:, ConsoleOutput
    newLog := logLine . currentLog
    lines := StrSplit(newLog, "`n")
    if (lines.Length() > MaxConsoleLines) {
        newLog := ""
        Loop, %MaxConsoleLines%
        newLog .= lines[A_Index] "`n"
    }
    GuiControl, Main:, ConsoleOutput, %newLog%
    ConsoleLog.InsertAt(1, logLine)
    if (ConsoleLog.Length() > MaxConsoleLines)
        ConsoleLog.Pop()
}

ClearConsole:
GuiControl, Main:, ConsoleOutput,
ConsoleLog := []
LogConsole("Console cleared by user", "SYSTEM")
return

StartScript:
if (ScriptRunning) {
    LogConsole("Script is already running!", "WARNING")
    MsgBox, 48, Already Running, The script is already running!
    return
}
if (ServerList.Length() = 0) {
    LogConsole("Cannot start - No servers configured", "ERROR")
    MsgBox, 48, No Servers, Please add at least one server before starting!
    return
}
Gui, Main:Submit, NoHide
SkipRustLaunch := SkipLaunchCheckbox
LogConsole("==========================================", "SYSTEM")
LogConsole("Starting Rust Auto Reconnect System...", "SYSTEM")
LogConsole("==========================================", "SYSTEM")
ScriptRunning := true
Gui, Main:Font, s9 Bold c00FF00, Arial
GuiControl, Main:Font, StatusText
GuiControl, Main:, StatusText, ONLINE
SetCompactLayout(true)
LogConsole("Script status changed to ONLINE", "SUCCESS")
if (SkipRustLaunch) {
    LogConsole("Skipping Rust launch (Rust already running option enabled)", "INFO")
    LogConsole("Checking if Rust is actually running...", "INFO")
    Process, Exist, RustClient.exe
    if (ErrorLevel = 0) {
        LogConsole("WARNING: Rust is not running! Please start Rust first.", "ERROR")
        MsgBox, 48, Rust Not Running, Rust is not running! Please start Rust and try again.
        Gosub, StopScript
        return
    }
    LogConsole("Rust is running (PID: " . ErrorLevel . ")", "SUCCESS")
    LogConsole("Waiting 5 seconds before connecting...", "INFO")
    Sleep, 5000
} else {
    LogConsole("Launching Rust through Steam...", "INFO")
    LaunchRust()
    LogConsole("Waiting 45 seconds for Rust to load...", "INFO")
    LogConsole("Please wait while Rust launches...", "WARNING")
    remainingSeconds := 45
    Loop, 9
    {
        LogConsole("Waiting for Rust to load... " . remainingSeconds . " seconds remaining", "INFO")
        Sleep, 5000
        remainingSeconds -= 5
    }
    LogConsole("45 second wait complete", "SUCCESS")
}
LogConsole("Starting monitoring systems...", "INFO")
SetTimer, MonitorRust, %DisconnectCheckInterval%
SetTimer, PerformAFKMovement, % AFKMovementSeconds * 1000
SetTimer, RotateServer, % ServerRotationMinutes * 60000
SetTimer, UpdateStatusTimers, 1000
LogConsole("All monitoring systems active", "SUCCESS")
LogConsole("Connecting to first server in rotation...", "INFO")
ConnectToServer(CurrentServerIndex)
return

StopScript:
if (!ScriptRunning) {
    LogConsole("Script is not running", "WARNING")
    return
}
LogConsole("==========================================", "SYSTEM")
LogConsole("Stopping Rust Auto Reconnect System...", "SYSTEM")
LogConsole("==========================================", "SYSTEM")
ScriptRunning := false
Gui, Main:Font, s9 Bold cRed, Arial
GuiControl, Main:Font, StatusText
GuiControl, Main:, StatusText, OFFLINE
GuiControl, Main:, CurrentServerText, None
GuiControl, Main:, NextRotationText, --
GuiControl, Main:, LastAFKText, --
SetTimer, MonitorRust, Off
SetTimer, PerformAFKMovement, Off
SetTimer, RotateServer, Off
SetTimer, UpdateStatusTimers, Off
LogConsole("All monitoring systems disabled", "SUCCESS")
LogConsole("Script status changed to OFFLINE", "SUCCESS")
LogConsole("Rust will continue running", "INFO")
SetCompactLayout(false)
UpdateServerListView()
MsgBox, 64, Stopped, Script has been stopped. Rust will continue running.
return

AddServer:
Gui, AddServerGui:New, +AlwaysOnTop +Owner, Add New Server
Gui, AddServerGui:Color, 000000
Gui, AddServerGui:Font, s10 Bold c00FF00, Arial
Gui, AddServerGui:Add, Text, x20 y20 w360 Center, ADD NEW SERVER
Gui, AddServerGui:Font, s9 Normal c00FF00, Arial
Gui, AddServerGui:Add, Text, x20 y60 w100, Server Name:
nextServerNum := ServerList.Length() + 1
Gui, AddServerGui:Add, Edit, x130 y57 w250 h22 vNewServerName Background000000 c00FF00, Server %nextServerNum%
Gui, AddServerGui:Add, Text, x20 y95 w100, Server IP/Command:
Gui, AddServerGui:Add, Edit, x130 y92 w250 h22 vNewServerCommand Background000000 c00FF00, connect 127.0.0.1:28015
Gui, AddServerGui:Font, s9 Bold c00FF00, Arial
Gui, AddServerGui:Add, Text, x80 y140 w100 h30 gAddServerSubmit Center, [ Add ]
Gui, AddServerGui:Add, Text, x220 y140 w100 h30 gAddServerCancel Center, [ Cancel ]
Gui, AddServerGui:Show, w400 h190
return

AddServerSubmit:
Gui, AddServerGui:Submit
if (NewServerName != "" && NewServerCommand != "") {
    ServerList.Push({name: NewServerName, command: NewServerCommand})
    SaveServersToRegistry()
    UpdateServerListView()
    LogConsole("Added new server: " . NewServerName . " - " . NewServerCommand, "SUCCESS")
    LogConsole("Saved to registry", "INFO")
}
Gui, AddServerGui:Destroy
return

AddServerCancel:
AddServerGuiClose:
Gui, AddServerGui:Destroy
return

EditServer:
SelectedRow := LV_GetNext()
if (SelectedRow = 0) {
    LogConsole("Edit failed - No server selected", "WARNING")
    MsgBox, 48, No Selection, Please select a server to edit!
    return
}
currentName := ServerList[SelectedRow].name
currentCommand := ServerList[SelectedRow].command
Gui, EditServerGui:New, +AlwaysOnTop +Owner, Edit Server
Gui, EditServerGui:Color, 000000
Gui, EditServerGui:Font, s10 Bold c00FF00, Arial
Gui, EditServerGui:Add, Text, x20 y20 w360 Center, EDIT SERVER
Gui, EditServerGui:Font, s9 Normal c00FF00, Arial
Gui, EditServerGui:Add, Text, x20 y60 w100, Server Name:
Gui, EditServerGui:Add, Edit, x130 y57 w250 h22 vEditServerName Background000000 c00FF00, %currentName%
Gui, EditServerGui:Add, Text, x20 y95 w100, Server IP/Command:
Gui, EditServerGui:Add, Edit, x130 y92 w250 h22 vEditServerCommand Background000000 c00FF00, %currentCommand%
Gui, EditServerGui:Font, s9 Bold c00FF00, Arial
Gui, EditServerGui:Add, Text, x80 y140 w100 h30 gEditServerSubmit Center, [ Save ]
Gui, EditServerGui:Add, Text, x220 y140 w100 h30 gEditServerCancel Center, [ Cancel ]
global EditingRow := SelectedRow
Gui, EditServerGui:Show, w400 h190
return

EditServerSubmit:
Gui, EditServerGui:Submit
if (EditServerName != "" && EditServerCommand != "") {
    oldName := ServerList[EditingRow].name
    oldCommand := ServerList[EditingRow].command
    ServerList[EditingRow].name := EditServerName
    ServerList[EditingRow].command := EditServerCommand
    SaveServersToRegistry()
    UpdateServerListView()
    LogConsole("Edited server " . EditingRow . ": " . oldName . " -> " . EditServerName, "SUCCESS")
    LogConsole("Saved to registry", "INFO")
}
Gui, EditServerGui:Destroy
return

EditServerCancel:
EditServerGuiClose:
Gui, EditServerGui:Destroy
return

DeleteServer:
SelectedRow := LV_GetNext()
if (SelectedRow = 0) {
    LogConsole("Delete failed - No server selected", "WARNING")
    MsgBox, 48, No Selection, Please select a server to delete!
    return
}
MsgBox, 4, Confirm Delete, Are you sure you want to delete this server?
IfMsgBox Yes
{
    deletedServer := ServerList[SelectedRow].name . " - " . ServerList[SelectedRow].command
    ServerList.RemoveAt(SelectedRow)
    SaveServersToRegistry()
    UpdateServerListView()
    if (CurrentServerIndex > ServerList.Length()) {
        CurrentServerIndex := 1
    }
    LogConsole("Deleted server: " . deletedServer, "SUCCESS")
    LogConsole("Saved to registry", "INFO")
}
return

MoveUpServer:
SelectedRow := LV_GetNext()
if (SelectedRow = 0 || SelectedRow = 1) {
    LogConsole("Move failed - Select a server (not first) to move up", "WARNING")
    MsgBox, 48, Cannot Move, Please select a server (not the first one) to move up!
    return
}
temp := ServerList[SelectedRow]
ServerList[SelectedRow] := ServerList[SelectedRow - 1]
ServerList[SelectedRow - 1] := temp
SaveServersToRegistry()
UpdateServerListView()
LogConsole("Moved server from position " . SelectedRow . " to " . (SelectedRow - 1), "SUCCESS")
LogConsole("Saved to registry", "INFO")
return

SaveSettings:
Gui, Main:Submit, NoHide
oldRotation := ServerRotationMinutes
oldAFK := AFKMovementSeconds
ServerRotationMinutes := RotationMinutes
AFKMovementSeconds := AFKSeconds
SkipRustLaunch := SkipLaunchCheckbox
SaveSettingsToRegistry()
if (ScriptRunning) {
    SetTimer, PerformAFKMovement, % AFKMovementSeconds * 1000
    SetTimer, RotateServer, % ServerRotationMinutes * 60000
    LogConsole("Settings updated and applied to running script", "SUCCESS")
} else {
    LogConsole("Settings saved (will apply on next start)", "SUCCESS")
}
LogConsole("Rotation interval: " . oldRotation . "m -> " . ServerRotationMinutes . "m", "INFO")
LogConsole("AFK interval: " . oldAFK . "s -> " . AFKMovementSeconds . "s", "INFO")
LogConsole("Skip Rust launch: " . (SkipRustLaunch ? "Yes" : "No"), "INFO")
LogConsole("Saved to registry", "INFO")
MsgBox, 64, Saved, Settings have been saved and applied!
return

BrowseRustExe:
FileSelectFile, SelectedFile, 3, , Select Rust.exe, Executable Files (*.exe)
if (SelectedFile != "") {
    RustExePath := SelectedFile
    SaveSettingsToRegistry()
    LogConsole("Rust executable path updated: " . SelectedFile, "SUCCESS")
    LogConsole("Saved to registry", "INFO")
    MsgBox, 64, Success, Rust executable path updated!
}
return

LaunchRust() {
    Process, Exist, RustClient.exe
    if (ErrorLevel != 0) {
        LogConsole("Rust is already running (PID: " . ErrorLevel . ")", "WARNING")
        MsgBox, 48, Already Running, Rust is already running! Please close it first.
        return
    }
    Run, steam://rungameid/252490
    LogConsole("Sent launch command to Steam (AppID: 252490)", "SUCCESS")
    Sleep, 2000
}

ConnectToServer(serverIndex) {
    if (serverIndex < 1 || serverIndex > ServerList.Length()) {
        serverIndex := 1
        LogConsole("Invalid server index, defaulting to server 1", "WARNING")
    }
    CurrentServerIndex := serverIndex
    serverName := ServerList[serverIndex].name
    serverCommand := ServerList[serverIndex].command
    serverCount := ServerList.Length()
    GuiControl, Main:, CurrentServerText, Server %serverIndex%/%serverCount%: %serverName%
    UpdateServerListView()
    LogConsole("Connecting to " . serverName . " (" . serverIndex . "/" . ServerList.Length() . ")", "INFO")
    LogConsole("Command: " . serverCommand, "INFO")
    LogConsole("Waiting for Rust window to appear...", "INFO")
    WinWait, ahk_exe RustClient.exe, , 60
    if (ErrorLevel) {
        LogConsole("ERROR: Could not find Rust window after 60 seconds", "ERROR")
        MsgBox, 48, Error, Could not find Rust window!
        return
    }
    LogConsole("Rust window detected!", "SUCCESS")
    Sleep, 2000
    LogConsole("Activating Rust window...", "INFO")
    WinActivate, ahk_exe RustClient.exe
    Sleep, 1500
    LogConsole("Opening F1 console in Rust...", "INFO")
    Send, {F1}
    Sleep, 1000
    LogConsole("Sending command: " . serverCommand, "INFO")
    Send, {Text}%serverCommand%
    Sleep, 500
    Send, {Enter}
    Sleep, 1000
    Send, {F1}
    LogConsole("Connection command sent successfully to Rust", "SUCCESS")
    LastServerRotation := A_TickCount
}

MonitorRust() {
    if (!ScriptRunning)
        return
    Process, Exist, RustClient.exe
    if (ErrorLevel = 0) {
        LogConsole("CRITICAL: Rust process not detected!", "ERROR")
        LogConsole("Stopping script due to Rust closure", "ERROR")
        MsgBox, 48, Rust Closed, Rust has been closed. Stopping script.
        Gosub, StopScript
        return
    }
}

PerformAFKMovement() {
    if (!ScriptRunning)
        return
    WinGet, activeWindow, ProcessName, A
    if (activeWindow != "RustClient.exe") {
        LogConsole("AFK movement skipped - Rust not active window", "WARNING")
        return
    }
    Random, moveIndex, 1, 4
    Random, moveDuration, 100, 300
    Random, lookX, -50, 50
    Random, lookY, -50, 50
    moveKey := MovementKeys[moveIndex]
    Send, % "{" . moveKey . " down}"
    Sleep, %moveDuration%
    Send, % "{" . moveKey . " up}"
    MouseMove, %lookX%, %lookY%, 0, R
    Random, jumpChance, 1, 5
    jumpText := ""
    if (jumpChance = 1) {
        Send, {Space}
        jumpText := " + Jump"
    }
    LogConsole("AFK action: " . moveKey . " key (" . moveDuration . "ms) + Look" . jumpText, "INFO")
    LastAFKMovement := A_TickCount
    GuiControl, Main:, LastAFKText, % A_Hour ":" A_Min ":" A_Sec
}

RotateServer() {
    if (!ScriptRunning || ServerList.Length() <= 1)
        return
    LogConsole("==========================================", "SYSTEM")
    LogConsole("Starting server rotation sequence...", "SYSTEM")
    WinActivate, ahk_exe RustClient.exe
    Sleep, 1000
    LogConsole("Sending disconnect command...", "INFO")
    Send, {F1}
    Sleep, 500
    Send, {Text}disconnect
    Sleep, 200
    Send, {Enter}
    Sleep, 500
    Send, {F1}
    Sleep, 3000
    LogConsole("Disconnected from server " . CurrentServerIndex, "SUCCESS")
    oldIndex := CurrentServerIndex
    CurrentServerIndex++
    if (CurrentServerIndex > ServerList.Length())
        CurrentServerIndex := 1
    LogConsole("Rotating: Server " . oldIndex . " -> Server " . CurrentServerIndex, "INFO")
    ConnectToServer(CurrentServerIndex)
    LogConsole("Server rotation complete", "SUCCESS")
    LogConsole("==========================================", "SYSTEM")
}

UpdateStatusTimers() {
    if (!ScriptRunning)
        return
    rotationInterval := ServerRotationMinutes * 60000
    timeSinceRotation := A_TickCount - LastServerRotation
    timeUntilRotation := rotationInterval - timeSinceRotation
    if (timeUntilRotation < 0)
        timeUntilRotation := 0
    minutesLeft := Floor(timeUntilRotation / 60000)
    secondsLeft := Floor(Mod(timeUntilRotation / 1000, 60))
    GuiControl, Main:, NextRotationText, %minutesLeft%m %secondsLeft%s
}

RemoveToolTip:
ToolTip
SetTimer, RemoveToolTip, Off
return

F9::
if (ScriptRunning) {
    LogConsole("Manual server rotation triggered by user (F9)", "SYSTEM")
    ToolTip, Manually rotating server...
    RotateServer()
    SetTimer, RemoveToolTip, 3000
} else {
    LogConsole("F9 pressed but script is not running", "WARNING")
}
return

F10::
if (ScriptRunning) {
    Suspend, Toggle
    if (A_IsSuspended) {
        LogConsole("Script PAUSED by user (F10)", "WARNING")
        ToolTip, Script PAUSED
        Gui, Main:Font, s9 Bold cYellow, Arial
        GuiControl, Main:Font, StatusText
        GuiControl, Main:, StatusText, PAUSED
    } else {
        LogConsole("Script RESUMED by user (F10)", "SUCCESS")
        ToolTip, Script RESUMED
        Gui, Main:Font, s9 Bold c00FF00, Arial
        GuiControl, Main:Font, StatusText
        GuiControl, Main:, StatusText, ONLINE
    }
    SetTimer, RemoveToolTip, 2000
} else {
    LogConsole("F10 pressed but script is not running", "WARNING")
}
return

F12::
LogConsole("Script reload requested (F12)", "SYSTEM")
Reload
return
