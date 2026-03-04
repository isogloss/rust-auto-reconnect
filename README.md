
# Rust Auto Reconnect Manager

A powerful AutoHotkey v1 script that automates Rust server rotation, AFK movement simulation, and connection management.

## Overview

This script provides a full-featured GUI-based manager for automatically rotating between multiple Rust servers, maintaining AFK status to prevent disconnect, and managing server connections without manual intervention.

## Core Features

### Server Rotation System
- **Multiple Server Management**: Add, edit, delete, and reorder up to 100 servers in a list
- **Automatic Rotation**: Servers rotate on a user-defined interval (default: 30 minutes)
- **Disconnect/Reconnect**: Automatically sends disconnect command via F1 console, waits for cleanup, then connects to next server
- **Status Tracking**: Real-time display of current server, rotation countdown, and connection status

### AFK Movement Simulation
- **Automatic Movement**: Performs random key presses (W, A, S, D) at user-defined intervals (default: 60 seconds)
- **Variable Timing**: Each movement has randomized duration (100-300ms) and direction changes to avoid detection
- **Camera Movement**: Random mouse movements (-50 to +50 pixels) to simulate player look changes
- **Jump Mechanic**: 20% chance to perform a jump action during movement
- **Active Window Detection**: Only performs AFK actions when Rust is the active window

### Configuration Management
- **Registry Storage**: All settings persist across script restarts in `HKEY_CURRENT_USER\Software\RustAutoReconnect`
- **Customizable Settings**:
  - Server rotation interval (minutes)
  - AFK movement interval (seconds)
  - Rust executable path
  - Auto-launch Rust toggle
- **Real-time Settings**: Changes apply immediately to running script without restart

### GUI Interface
- **System Status Panel**: Real-time display of script status, current server, rotation timer, and last AFK action
- **Server List View**: Table showing all configured servers with active/standby status indicators
- **Console Log**: Timestamped console with color-coded message types (INFO, SUCCESS, ERROR, WARNING, SYSTEM)
- **Custom Controls**: Stylized black background with green/yellow text (hacker aesthetic)

## Usage

### Installation
1. Download AutoHotkey v1.1.22+ from [autohotkey.com](https://www.autohotkey.com)
2. Save the script as `RustAutoReconnect.ahk`
3. Double-click to run

### Getting Started

**Initial Setup:**
1. Script loads with 3 default servers (Rustoria, Moose, Rustopia)
2. Set your Rust executable path (default: `C:\Program Files (x86)\Steam\steamapps\common\Rust\Rust.exe`)
3. Adjust rotation interval and AFK timing as desired
4. Click [Save Settings] to persist changes
5. Click [START SCRIPT]

**Managing Servers:**
- **Add**: Click [Add Server], enter name and connection command (e.g., `connect 208.52.153.80:28015`)
- **Edit**: Select server in list, click [Edit Server], modify name/command
- **Delete**: Select server, click [Delete Server], confirm
- **Reorder**: Select server (not first), click [Move Up] to change order

## Hotkeys

| Hotkey | Function |
|--------|----------|
| **F9** | Manually trigger immediate server rotation |
| **F10** | Pause/Resume script execution |
| **F12** | Reload entire script |

## Console Log Types

- `[INFO]` - General information messages
- `[OK]` - Successful operations
- `[WARN]` - Warning messages (non-fatal issues)
- `[ERROR]` - Error conditions
- `[SYS]` - System status changes

## Connection Logic

### Startup Process
1. Optionally launch Rust via Steam (or wait for existing instance)
2. Wait for Rust window to appear (60 second timeout)
3. Activate Rust window and press F1 to open console
4. Type server connection command and press Enter
5. Close console with F1
6. Record connection timestamp for rotation timer

### Rotation Process
Every `ServerRotationMinutes`:
1. Activate Rust window
2. Open console (F1)
3. Type `disconnect` command
4. Close console (F1)
5. Wait 3 seconds for disconnection
6. Move to next server in rotation
7. Execute connection sequence
8. Reset rotation timer

### AFK Prevention
Every `AFKMovementSeconds` (while Rust is active):
1. Randomly select movement key (W/A/S/D)
2. Hold key for 100-300ms
3. Release key
4. Move mouse randomly (-50 to +50 pixels)
5. 20% chance to jump
6. Update last AFK timestamp in GUI

## Configuration Storage

Settings are stored in Windows Registry:
```
HKEY_CURRENT_USER\Software\RustAutoReconnect\
├── ServerRotationMinutes (DWORD)
├── AFKMovementSeconds (DWORD)
├── RustExePath (SZ)
├── SkipRustLaunch (DWORD)
├── ServerCount (DWORD)
├── Server1_Name (SZ)
├── Server1_Command (SZ)
├── Server2_Name (SZ)
├── Server2_Command (SZ)
└── ...
```

## Technical Details

### Requirements
- Windows OS
- AutoHotkey v1.1.22+
- Rust game installed
- Steam (if using auto-launch)

### Threading
- **MonitorRust** (5000ms): Checks if Rust process is running
- **PerformAFKMovement** (configurable): Executes AFK actions
- **RotateServer** (configurable): Triggers server rotation
- **UpdateStatusTimers** (1000ms): Updates GUI rotation countdown

### GUI Dimensions
- Window: 600×975 pixels
- Resizable position via drag header
- Minimize/maximize buttons in top-right
- Console output: 100 message buffer (oldest messages removed)

## Default Servers

```
Rustoria - connect 208.52.153.80:28015
Moose - connect monday.eu.moose.gg:28010
Rustopia - connect USMedium.Rustopia.gg:28015
```

## Troubleshooting

**Script won't connect to server:**
- Verify Rust.exe path is correct
- Ensure Rust is running (or auto-launch is enabled)
- Check console log for connection errors
- Manually verify server is online and accessible

**AFK actions not working:**
- Ensure Rust window is active (script skips actions if minimized)
- Check AFK interval is not set too high
- Verify script status shows "ONLINE"

**Rotation not triggering:**
- Confirm server list has multiple servers
- Check rotation interval in settings
- Watch "Next Rotation" timer for countdown

**Settings not saving:**
- Ensure Windows Registry is accessible
- Check user has write permissions to HKEY_CURRENT_USER

## Limitations

- Registry-based storage (tied to Windows account)
- Requires console access (F1 key) in Rust
- No support for scripted commands beyond connect/disconnect
- Single-server at a time (cannot farm multiple servers simultaneously)

## License

Use at your own risk. This tool is designed for legitimate AFK farming on authorized servers only.
