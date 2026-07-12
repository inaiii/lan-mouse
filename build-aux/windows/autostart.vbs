' Autostart shim for Lan Mouse, registered by the installer under
' HKCU\Software\Microsoft\Windows\CurrentVersion\Run. Sets
' LAN_MOUSE_HIDDEN so the app starts minimized to the tray instead of
' opening its window, then launches it from the folder this script
' lives in. wscript runs windowless, so nothing flashes at sign-in.
Option Explicit
Dim shell, fso, dir
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
shell.Environment("PROCESS")("LAN_MOUSE_HIDDEN") = "1"
shell.Run """" & dir & "\lan-mouse.exe""", 1, False
