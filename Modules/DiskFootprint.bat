@echo off
:: ============================================================================
::  WindowsOPTGame - DiskFootprint.bat
:: ----------------------------------------------------------------------------
::  Deep Windows Disk Footprint Optimization:
::    [1] Compact OS Manager (compact.exe /CompactOS)
::    [2] Hibernation Manager (powercfg.exe -h)
::    [3] WinSxS Deep Cleanup (dism.exe /StartComponentCleanup /ResetBase)
::    [4] Safe UWP Debloat (Remove-AppxPackage for preinstalled bloatware)
::    [5] Remove OneDrive (Full uninstall, registry cleanup, Explorer unpin)
::    [6] Apply All Recommended Optimizations
:: ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog DiskFootprint
call "%HELPERS%" LoadConfig

call "%HELPERS%" RequireAdmin || (call "%HELPERS%" PauseKey & endlocal & exit /b 1)

:DiskFootprintMenu
call "%HELPERS%" Header "%L_DiskFootprint_Title%"
echo   %L_DiskFootprint_Intro1%
echo   %C_DIM%%L_DiskFootprint_Intro2%%C_RESET%
echo.

:: ---------------------------------------------------------------------------
:: Live Status Dashboard
:: ---------------------------------------------------------------------------
call :GetCompactStatus
call :GetHiberStatus
call :GetOneDriveStatus

echo   %C_DIM%------------------------------------------------------------------%C_RESET%
echo   %C_INFO%%L_DiskFootprint_DashCompact%%C_RESET% %_COMPACT_STATUS_TEXT%
echo   %C_INFO%%L_DiskFootprint_DashHiber%%C_RESET% %_HIBER_STATUS_TEXT%
echo   %C_INFO%%L_DiskFootprint_DashOneDrive%%C_RESET% %_ONEDRIVE_STATUS_TEXT%
echo   %C_DIM%------------------------------------------------------------------%C_RESET%
echo.

echo   %C_MENU%[1]%C_RESET% %L_DiskFootprint_M1%
echo   %C_MENU%[2]%C_RESET% %L_DiskFootprint_M2%
echo   %C_MENU%[3]%C_RESET% %L_DiskFootprint_M3%
echo   %C_MENU%[4]%C_RESET% %L_DiskFootprint_M4%
echo   %C_MENU%[5]%C_RESET% %L_DiskFootprint_M5%
echo   %C_MENU%[6]%C_RESET% %L_DiskFootprint_M6%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.

set "DFCHOICE="
set /p "DFCHOICE=  %L_Common_SelectOption% "
if "%DFCHOICE%"=="1" (call :ActionCompactOS       & goto :DiskFootprintMenu)
if "%DFCHOICE%"=="2" (call :ActionHibernation     & goto :DiskFootprintMenu)
if "%DFCHOICE%"=="3" (call :ActionWinSxS           & goto :DiskFootprintMenu)
if "%DFCHOICE%"=="4" (call :ActionDebloat         & goto :DiskFootprintMenu)
if "%DFCHOICE%"=="5" (call :ActionOneDrive        & goto :DiskFootprintMenu)
if "%DFCHOICE%"=="6" (call :ActionAllRecommended  & goto :DiskFootprintMenu)
if "%DFCHOICE%"=="0" (endlocal & exit /b 0)
goto :DiskFootprintMenu


:: ============================================================================
:: Status Queries
:: ============================================================================
:GetCompactStatus
set "_COMPACT_STATUS_TEXT=%C_DIM%%L_DiskFootprint_CompactOff%%C_RESET%"
set "_IS_COMPACT=0"
compact.exe /CompactOS:query 2>nul | findstr /i "is in the Compact state" >nul 2>&1
if not errorlevel 1 (
    set "_COMPACT_STATUS_TEXT=%C_OK%%L_DiskFootprint_CompactOn%%C_RESET%"
    set "_IS_COMPACT=1"
)
exit /b 0

:GetHiberStatus
set "_HIBER_STATUS_TEXT=%C_DIM%%L_DiskFootprint_HiberOff%%C_RESET%"
set "_HIBER_STATE=OFF"
if exist "%SystemDrive%\hiberfil.sys" (
    reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HiberFileType 2>nul | findstr /i "0x1" >nul 2>&1
    if not errorlevel 1 (
        set "_HIBER_STATUS_TEXT=%C_INFO%%L_DiskFootprint_HiberReduced%%C_RESET%"
        set "_HIBER_STATE=REDUCED"
    ) else (
        set "_HIBER_STATUS_TEXT=%C_WARN%%L_DiskFootprint_HiberFull%%C_RESET%"
        set "_HIBER_STATE=FULL"
    )
)
exit /b 0

:GetOneDriveStatus
set "_ONEDRIVE_STATUS_TEXT=%C_OK%%L_DiskFootprint_OneDriveRemoved%%C_RESET%"
set "_HAS_ONEDRIVE=0"
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe" set "_HAS_ONEDRIVE=1"
if exist "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe" set "_HAS_ONEDRIVE=1"
if exist "%ProgramFiles(x86)%\Microsoft OneDrive\OneDrive.exe" set "_HAS_ONEDRIVE=1"
if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" set "_HAS_ONEDRIVE=1"
if "%_HAS_ONEDRIVE%"=="1" (
    set "_ONEDRIVE_STATUS_TEXT=%C_WARN%%L_DiskFootprint_OneDriveInstalled%%C_RESET%"
)
exit /b 0


:: ============================================================================
:: [1] Compact OS Action
:: ============================================================================
:ActionCompactOS
call "%HELPERS%" Header "%L_DiskFootprint_M1%"
call :GetCompactStatus
if "%_IS_COMPACT%"=="1" (
    echo   %C_OK%%L_DiskFootprint_CompactOn%%C_RESET%
    echo.
    call "%HELPERS%" Confirm "%L_DiskFootprint_CompactDisable%"
    if /i not "!CONFIRM!"=="Y" exit /b 0
    echo.
    call "%HELPERS%" PrintInfo "%L_DiskFootprint_CompactDisable%"
    call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
    set "START_FREE=%FREESPACE_MB%"
    compact.exe /CompactOS:never
    call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
    call "%HELPERS%" PrintOK "%L_DiskFootprint_CompactDisabled%"
) else (
    echo   %C_DIM%%L_DiskFootprint_CompactOff%%C_RESET%
    echo.
    call "%HELPERS%" Confirm "%L_DiskFootprint_CompactAsk%"
    if /i not "!CONFIRM!"=="Y" exit /b 0
    echo.
    call "%HELPERS%" PrintInfo "%L_DiskFootprint_CompactEnable%"
    call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
    set "START_FREE=%FREESPACE_MB%"
    compact.exe /CompactOS:always
    call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
    set /a FREED_MB=FREESPACE_MB-START_FREE
    if !FREED_MB! LSS 0 set "FREED_MB=0"
    call "%HELPERS%" PrintOK "%L_DiskFootprint_CompactEnabled% [!FREED_MB! MB]"
    call "%HELPERS%" Log OK "Compact OS enabled. Freed: !FREED_MB! MB"
)
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [2] Hibernation Manager Action
:: ============================================================================
:ActionHibernation
call "%HELPERS%" Header "%L_DiskFootprint_M2%"
call :GetHiberStatus
echo   %L_DiskFootprint_DashHiber% %_HIBER_STATUS_TEXT%
echo.
echo   %C_MENU%[1]%C_RESET% %L_DiskFootprint_HiberDisabled%
echo   %C_MENU%[2]%C_RESET% %L_DiskFootprint_HiberSetReduced%
echo   %C_MENU%[3]%C_RESET% %L_DiskFootprint_HiberEnabled%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.
set "HCHOICE="
set /p "HCHOICE=  %L_Common_SelectOption% "
if "%HCHOICE%"=="1" (
    powercfg.exe -h off >nul 2>&1
    call "%HELPERS%" PrintOK "%L_DiskFootprint_HiberDisabled%"
    call "%HELPERS%" Log OK "Hibernation disabled via powercfg -h off"
)
if "%HCHOICE%"=="2" (
    powercfg.exe -h on >nul 2>&1
    powercfg.exe /h /type reduced >nul 2>&1
    call "%HELPERS%" PrintOK "%L_DiskFootprint_HiberSetReduced%"
    call "%HELPERS%" Log OK "Hibernation set to reduced via powercfg /h /type reduced"
)
if "%HCHOICE%"=="3" (
    powercfg.exe -h on >nul 2>&1
    powercfg.exe /h /type full >nul 2>&1
    call "%HELPERS%" PrintOK "%L_DiskFootprint_HiberEnabled%"
    call "%HELPERS%" Log OK "Hibernation enabled in full mode"
)
if "%HCHOICE%"=="0" exit /b 0
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [3] WinSxS Deep Cleanup Action
:: ============================================================================
:ActionWinSxS
call "%HELPERS%" Header "%L_DiskFootprint_M3%"
echo   %C_WARN%%L_DiskFootprint_WinSxSWarn%%C_RESET%
echo.
call "%HELPERS%" Confirm "%L_DiskFootprint_WinSxSConfirm%"
if /i not "%CONFIRM%"=="Y" exit /b 0

echo.
call "%HELPERS%" PrintInfo "%L_DiskFootprint_WinSxSStart%"
call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set "START_FREE=%FREESPACE_MB%"
call "%HELPERS%" Log EXEC "Starting DISM /StartComponentCleanup /ResetBase"

dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
set "DISM_RC=%ERRORLEVEL%"

call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set /a FREED_MB=FREESPACE_MB-START_FREE
if %FREED_MB% LSS 0 set "FREED_MB=0"

if %DISM_RC% EQU 0 (
    call "%HELPERS%" PrintOK "%L_DiskFootprint_WinSxSOK% [%FREED_MB% MB]"
    call "%HELPERS%" Log OK "WinSxS ResetBase finished successfully. Freed: %FREED_MB% MB"
) else (
    call "%HELPERS%" PrintWarn "%L_DiskFootprint_WinSxSFail% [%DISM_RC%]"
    call "%HELPERS%" Log WARN "WinSxS ResetBase returned error code %DISM_RC%"
)
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [4] Safe UWP Debloat Action
:: ============================================================================
:ActionDebloat
call "%HELPERS%" Header "%L_DiskFootprint_M4%"
echo   %L_DiskFootprint_DebloatStart%
echo.
call "%HELPERS%" Confirm "%L_DiskFootprint_DebloatAskXbox%"
set "REMOVE_XBOX=0"
if /i "%CONFIRM%"=="Y" set "REMOVE_XBOX=1"

echo.
call "%HELPERS%" PrintInfo "%L_DiskFootprint_DebloatStart%"
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'SilentlyContinue';" ^
  "$bloat = @(" ^
  "  'Clipchamp.Clipchamp'," ^
  "  'Microsoft.BingNews'," ^
  "  'Microsoft.BingWeather'," ^
  "  'Microsoft.GetHelp'," ^
  "  'Microsoft.Getstarted'," ^
  "  'Microsoft.MicrosoftFeedbackHub'," ^
  "  'Microsoft.MicrosoftSolitaireCollection'," ^
  "  'Microsoft.People'," ^
  "  'Microsoft.Todos'," ^
  "  'Microsoft.YourPhone'," ^
  "  'Microsoft.549981C3F5F10'," ^
  "  'Microsoft.WindowsMaps'," ^
  "  'Microsoft.ZuneVideo'," ^
  "  'Microsoft.ZuneMusic'," ^
  "  'Microsoft.MicrosoftOfficeHub'," ^
  "  'Microsoft.WindowsFeedbackHub'," ^
  "  'Microsoft.OutlookForWindows'," ^
  "  'Microsoft.SkypeApp'" ^
  ");" ^
  "if ('%REMOVE_XBOX%' -eq '1') {" ^
  "  $bloat += @('Microsoft.XboxApp','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay','Microsoft.GamingApp');" ^
  "};" ^
  "$count = 0;" ^
  "foreach ($app in $bloat) {" ^
  "  $pkgs = Get-AppxPackage -AllUsers -Name ('*' + $app + '*') -ErrorAction SilentlyContinue;" ^
  "  foreach ($p in $pkgs) {" ^
  "    try {" ^
  "      Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction SilentlyContinue;" ^
  "      $count++;" ^
  "    } catch {}" ^
  "  };" ^
  "  $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like ('*' + $app + '*') };" ^
  "  foreach ($pr in $prov) {" ^
  "    try { Remove-AppxProvisionedPackage -Online -PackageName $pr.PackageName -ErrorAction SilentlyContinue } catch {}" ^
  "  };" ^
  "};" ^
  "Write-Host ('  %L_DiskFootprint_DebloatRemoved% ' + $count);"

if "%REMOVE_XBOX%"=="1" (
    call "%HELPERS%" PrintOK "%L_DiskFootprint_DebloatXboxRemoved%"
) else (
    call "%HELPERS%" PrintInfo "%L_DiskFootprint_DebloatXboxKept%"
)
call "%HELPERS%" PrintOK "%L_DiskFootprint_DebloatOK%"
call "%HELPERS%" Log OK "Safe UWP Debloat completed. Xbox removed: %REMOVE_XBOX%"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [5] Complete OneDrive Removal Action
:: ============================================================================
:ActionOneDrive
call "%HELPERS%" Header "%L_DiskFootprint_M5%"
call :GetOneDriveStatus
if "%_HAS_ONEDRIVE%"=="0" (
    call "%HELPERS%" PrintInfo "%L_DiskFootprint_OneDriveNotFound%"
    call "%HELPERS%" PauseKey
    exit /b 0
)

call "%HELPERS%" Confirm "%L_DiskFootprint_OneDriveConfirm%"
if /i not "%CONFIRM%"=="Y" exit /b 0

echo.
call "%HELPERS%" PrintInfo "%L_DiskFootprint_OneDriveUninstalling%"
call "%HELPERS%" Log EXEC "Uninstalling OneDrive"

taskkill /f /im OneDrive.exe >nul 2>&1

:: Execute uninstaller
if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
    "%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall >nul 2>&1
) else if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
    "%SystemRoot%\System32\OneDriveSetup.exe" /uninstall >nul 2>&1
) else if exist "%LOCALAPPDATA%\Microsoft\OneDrive\Update\OneDriveSetup.exe" (
    "%LOCALAPPDATA%\Microsoft\OneDrive\Update\OneDriveSetup.exe" /uninstall >nul 2>&1
) else if exist "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe" (
    "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe" /uninstall >nul 2>&1
)

:: Remove auto-start entry
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1

:: Hide OneDrive from File Explorer Navigation Pane
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f >nul 2>&1

:: Clean leftover folders
if exist "%LOCALAPPDATA%\Microsoft\OneDrive" call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\Microsoft\OneDrive" "OneDrive LocalAppData" & rd /s /q "%LOCALAPPDATA%\Microsoft\OneDrive" >nul 2>&1
if exist "%ProgramData%\Microsoft OneDrive" call "%HELPERS%" CleanFolder "%ProgramData%\Microsoft OneDrive" "OneDrive ProgramData" & rd /s /q "%ProgramData%\Microsoft OneDrive" >nul 2>&1

call "%HELPERS%" PrintOK "%L_DiskFootprint_OneDriveOK%"
call "%HELPERS%" Log OK "OneDrive completely uninstalled and unpinned from Explorer"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [6] Apply ALL Recommended Footprint Reductions Action
:: ============================================================================
:ActionAllRecommended
call "%HELPERS%" Header "%L_DiskFootprint_M6%"
echo   %C_WARN%%L_DiskFootprint_WinSxSWarn%%C_RESET%
echo.
call "%HELPERS%" Confirm "%L_DiskFootprint_AllConfirm%"
if /i not "%CONFIRM%"=="Y" exit /b 0

call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set "START_ALL_FREE=%FREESPACE_MB%"

:: 1. Disable Hibernation
echo.
echo %C_INFO%  --- [1/5] %L_DiskFootprint_M2% ---%C_RESET%
powercfg.exe -h off >nul 2>&1
call "%HELPERS%" PrintOK "%L_DiskFootprint_HiberDisabled%"

:: 2. UWP Safe Debloat (keeps Xbox)
echo.
echo %C_INFO%  --- [2/5] %L_DiskFootprint_M4% ---%C_RESET%
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'SilentlyContinue';" ^
  "$bloat = @('Clipchamp.Clipchamp','Microsoft.BingNews','Microsoft.BingWeather','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftFeedbackHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.People','Microsoft.Todos','Microsoft.YourPhone','Microsoft.549981C3F5F10','Microsoft.WindowsMaps','Microsoft.ZuneVideo','Microsoft.ZuneMusic','Microsoft.MicrosoftOfficeHub','Microsoft.WindowsFeedbackHub','Microsoft.OutlookForWindows','Microsoft.SkypeApp');" ^
  "foreach ($app in $bloat) {" ^
  "  $pkgs = Get-AppxPackage -AllUsers -Name ('*' + $app + '*') -ErrorAction SilentlyContinue;" ^
  "  foreach ($p in $pkgs) { try { Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction SilentlyContinue } catch {} };" ^
  "  $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like ('*' + $app + '*') };" ^
  "  foreach ($pr in $prov) { try { Remove-AppxProvisionedPackage -Online -PackageName $pr.PackageName -ErrorAction SilentlyContinue } catch {} };" ^
  "};"
call "%HELPERS%" PrintOK "%L_DiskFootprint_DebloatOK%"

:: 3. Remove OneDrive if present
echo.
echo %C_INFO%  --- [3/5] %L_DiskFootprint_M5% ---%C_RESET%
call :GetOneDriveStatus
if "%_HAS_ONEDRIVE%"=="1" (
    taskkill /f /im OneDrive.exe >nul 2>&1
    if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
        "%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall >nul 2>&1
    ) else if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
        "%SystemRoot%\System32\OneDriveSetup.exe" /uninstall >nul 2>&1
    )
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
    reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0 /f >nul 2>&1
    call "%HELPERS%" PrintOK "%L_DiskFootprint_OneDriveOK%"
) else (
    call "%HELPERS%" PrintInfo "%L_DiskFootprint_OneDriveNotFound%"
)

:: 4. WinSxS ResetBase
echo.
echo %C_INFO%  --- [4/5] %L_DiskFootprint_M3% ---%C_RESET%
call "%HELPERS%" PrintInfo "%L_DiskFootprint_WinSxSStart%"
dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1
call "%HELPERS%" PrintOK "%L_DiskFootprint_WinSxSOK%"

:: 5. Compact OS
echo.
echo %C_INFO%  --- [5/5] %L_DiskFootprint_M1% ---%C_RESET%
call :GetCompactStatus
if not "%_IS_COMPACT%"=="1" (
    call "%HELPERS%" PrintInfo "%L_DiskFootprint_CompactEnable%"
    compact.exe /CompactOS:always >nul 2>&1
    call "%HELPERS%" PrintOK "%L_DiskFootprint_CompactEnabled%"
) else (
    call "%HELPERS%" PrintOK "%L_DiskFootprint_CompactOn%"
)

echo.
call "%HELPERS%" HR
call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set /a TOTAL_FREED=FREESPACE_MB-START_ALL_FREE
if %TOTAL_FREED% LSS 0 set "TOTAL_FREED=0"
echo   %C_OK%%L_DiskFootprint_AllDone%%C_RESET% %C_WHITE%%TOTAL_FREED% MB%C_RESET% %L_Cleanup_FreedOn% %SystemDrive%
call "%HELPERS%" Log OK "All recommended footprint optimizations finished. Freed: %TOTAL_FREED% MB"
call "%HELPERS%" PauseKey
exit /b 0
