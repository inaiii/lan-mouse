; Inno Setup script for the Lan Mouse windows installer.
; Compiled by nightly.yml from the staged portable payload:
;   iscc /DAppVer=<display> /DAppVerNumeric=<a.b.c.d> /DStageDir=<dir> installer.iss

#ifndef AppVer
  #define AppVer "0.0.0-dev"
#endif
#ifndef AppVerNumeric
  #define AppVerNumeric "0.0.0.0"
#endif
#ifndef StageDir
  #define StageDir "..\..\target\lan-mouse-windows"
#endif

#define AppName "Lan Mouse"
#define AppExe "lan-mouse.exe"

[Setup]
; never change AppId: it is what makes a newer installer upgrade an
; existing install in place instead of creating a second entry
AppId={{E4398822-EECF-4D0C-B997-84C0CAE43F17}
AppName={#AppName}
AppVersion={#AppVer}
VersionInfoVersion={#AppVerNumeric}
AppPublisher=Lan Mouse
AppPublisherURL=https://github.com/feschber/lan-mouse
; per-user install, no UAC: {autopf} resolves to %LOCALAPPDATA%\Programs
PrivilegesRequired=lowest
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
OutputBaseFilename=lan-mouse-setup-x86_64
SetupIconFile=lan-mouse.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; running instances are stopped by the path-filtered kill in [Code]
CloseApplications=no

[Tasks]
Name: "autostart"; Description: "Start {#AppName} at sign-in (minimized to the tray)"
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked

[InstallDelete]
; upgrades only overwrite: clear the previous gtk runtime first so dlls
; dropped by a toolchain update do not linger in the install dir
Type: files; Name: "{app}\*.dll"

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "autostart.vbs"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; the autostart entry is always created; the task checkbox only decides
; whether it starts out enabled or disabled on Task Manager's Startup
; page (StartupApproved flag 02 = enabled, 03 = disabled). The vbs shim
; sets LAN_MOUSE_HIDDEN so the app starts minimized to the tray.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#AppName}"; ValueData: """{sys}\wscript.exe"" ""{app}\autostart.vbs"""; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"; ValueType: binary; ValueName: "{#AppName}"; ValueData: "02 00 00 00 00 00 00 00 00 00 00 00"; Flags: uninsdeletevalue; Tasks: autostart
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"; ValueType: binary; ValueName: "{#AppName}"; ValueData: "03 00 00 00 00 00 00 00 00 00 00 00"; Flags: uninsdeletevalue; Tasks: not autostart

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[Code]
// Stop instances running from the install dir (GUI + daemon child) so
// their files can be replaced or removed. Path-filtered on purpose:
// portable or development copies elsewhere must not be touched.
procedure StopInstalledInstances();
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
    '-NoProfile -Command "Get-Process lan-mouse -ErrorAction SilentlyContinue ' +
    '| Where-Object { $_.Path -like ''' + ExpandConstant('{app}') + '\*'' } ' +
    '| Stop-Process -Force; Start-Sleep -Milliseconds 300"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  StopInstalledInstances();
  Result := '';
end;

function InitializeUninstall(): Boolean;
begin
  StopInstalledInstances();
  Result := True;
end;
