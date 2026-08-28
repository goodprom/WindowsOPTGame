@echo off
:: ============================================================================
::  WindowsOPTGame - Cleanup.bat
:: ----------------------------------------------------------------------------
::  Tiered Windows cleanup module:
::    [1] Standard Cleanup  - safe removal of temporary files, caches,
::                            old Windows updates, driver installers, and dumps.
::    [2] Extreme Cleanup   - deep clean of stale user files (>30 days, sent
::                            to Recycle Bin), orphaned uninstalled app data,
::                            deep browser caches, and event logs.
::
::  Call styles:
::      Cleanup.bat          - interactive menu
::      Cleanup.bat AUTO     - unattended Standard Cleanup (used by Full Optimization)
::      Cleanup.bat EXTREME  - unattended Extreme Cleanup
:: ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog Cleanup
call "%HELPERS%" LoadConfig

set "MODE=%~1"
set "TOTAL_FREED_MB=0"

if /i "%MODE%"=="AUTO" goto :StartStandardClean
if /i "%MODE%"=="EXTREME" goto :StartExtremeClean

:CleanupMenu
call "%HELPERS%" Header "%L_Cleanup_Title%"
echo   %L_Cleanup_Intro1%
echo   %C_DIM%%L_Cleanup_Intro2%%C_RESET%
echo.
echo   %C_MENU%[1]%C_RESET% %L_Cleanup_SubMenu1%
echo   %C_MENU%[2]%C_RESET% %L_Cleanup_SubMenu2%
echo   %C_MENU%[3]%C_RESET% %L_Cleanup_SubMenu3%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.
set "CLCHOICE="
set /p "CLCHOICE=  %L_Common_SelectOption% "
if "%CLCHOICE%"=="1" (call :InteractiveStandard & goto :CleanupMenu)
if "%CLCHOICE%"=="2" (call :InteractiveExtreme  & goto :CleanupMenu)
if "%CLCHOICE%"=="3" (call "%~dp0DiskFootprint.bat" & goto :CleanupMenu)
if "%CLCHOICE%"=="0" (endlocal & exit /b 0)
goto :CleanupMenu

:: ---------------------------------------------------------------------------
:: Interactive wrappers
:: ---------------------------------------------------------------------------
:InteractiveStandard
call "%HELPERS%" Header "%L_Cleanup_Title%"
echo   %L_Cleanup_Intro1%
echo   %C_DIM%%L_Cleanup_Intro2%%C_RESET%
echo.
call "%HELPERS%" Confirm "%L_Cleanup_ConfirmStart%"
if /i not "%CONFIRM%"=="Y" exit /b 0
echo.
call :StartStandardClean
call "%HELPERS%" PauseKey
exit /b 0

:InteractiveExtreme
call "%HELPERS%" Header "%L_Cleanup_ExtremeTitle%"
call "%HELPERS%" RequireAdmin || (call "%HELPERS%" PauseKey & exit /b 1)
echo.
echo   %C_WARN%%L_Cleanup_ExtremeWarn%%C_RESET%
echo.
call "%HELPERS%" Confirm "%L_Cleanup_ExtremeConfirm%"
if /i not "%CONFIRM%"=="Y" exit /b 0
echo.
call :StartExtremeClean
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: :StartStandardClean
::   Standard / System Cleanup for OS stability and maximum C: space recovery
:: ============================================================================
:StartStandardClean
call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set "START_FREE=%FREESPACE_MB%"
call "%HELPERS%" Log INFO "Free space before cleanup: %START_FREE% MB"

:: ---------------------------------------------------------------------------
:: 1) User-level caches (no elevation needed)
:: ---------------------------------------------------------------------------
echo %C_INFO%  %L_Cleanup_SecUser%%C_RESET%
call "%HELPERS%" CleanFolder "%TEMP%" "%L_Cleanup_UserTemp%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\D3DSCache" "%L_Cleanup_ShaderCache%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\Microsoft\Windows\INetCache" "%L_Cleanup_InetCache%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\CrashDumps" "%L_Cleanup_CrashDumps%"

:: Recent items shortcuts
if exist "%APPDATA%\Microsoft\Windows\Recent" (
    del /f /q "%APPDATA%\Microsoft\Windows\Recent\*.lnk" >nul 2>&1
    call "%HELPERS%" PrintOK "%L_Cleanup_RecentCleared%"
)

:: Thumbnail + icon caches: safely delete unlocked cache files without terminating explorer
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1
del /f /q /a:h "%LOCALAPPDATA%\IconCache.db" >nul 2>&1
call "%HELPERS%" PrintOK "%L_Cleanup_ThumbCleared%"

:: Clipboard
echo. | clip >nul 2>&1
cmd /c "echo off | clip" >nul 2>&1
call "%HELPERS%" PrintOK "%L_Cleanup_ClipboardCleared%"

:: ---------------------------------------------------------------------------
:: 2) System-level caches (admin required)
:: ---------------------------------------------------------------------------
echo.
echo %C_INFO%  %L_Cleanup_SecSystem%%C_RESET%
if "%IS_ADMIN%"=="0" (
    call "%HELPERS%" PrintWarn "%L_Cleanup_NotElevated%"
    goto :OptionalStandard
)

call "%HELPERS%" CleanFolder "%SystemRoot%\Temp" "%L_Cleanup_WinTemp%"
call "%HELPERS%" CleanFolder "%SystemRoot%\Prefetch" "%L_Cleanup_Prefetch%"
call "%HELPERS%" CleanFolder "%SystemRoot%\Minidump" "%L_Cleanup_Minidump%"
if exist "%SystemRoot%\MEMORY.DMP" (
    del /f /q "%SystemRoot%\MEMORY.DMP" >nul 2>&1
    call "%HELPERS%" PrintOK "%L_Cleanup_MemoryDmp%"
)
call "%HELPERS%" CleanFolder "%SystemRoot%\LiveKernelReports" "%L_Cleanup_LiveKernel%"
call "%HELPERS%" CleanFolder "%ProgramData%\Microsoft\Windows\WER\ReportQueue" "%L_Cleanup_WERQueue%"
call "%HELPERS%" CleanFolder "%ProgramData%\Microsoft\Windows\WER\ReportArchive" "%L_Cleanup_WERArchive%"

:: DirectX shader cache (system side)
call "%HELPERS%" CleanFolder "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\D3DSCache" "%L_Cleanup_DXSystem%"

:: Windows Update download cache
call "%HELPERS%" Log EXEC "Stopping wuauserv/bits to clean SoftwareDistribution\Download"
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
call "%HELPERS%" CleanFolder "%SystemRoot%\SoftwareDistribution\Download" "%L_Cleanup_WUCache%"
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
call "%HELPERS%" PrintOK "%L_Cleanup_WURestarted%"

:: Delivery Optimization cache
call "%HELPERS%" Exec "%L_Cleanup_DOCache%" "powershell -NoProfile -InputFormat None -Command Delete-DeliveryOptimizationCache -Force"

:: Windows Store cache
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache" "%L_Cleanup_StoreReset%"

:: Previous Windows installations (Windows.old, $Windows.~BT, $Windows.~WS)
echo.
echo %C_INFO%  %L_Cleanup_SecWinOld%%C_RESET%
set "_found_winold=0"
if exist "%SystemDrive%\Windows.old" (
    set "_found_winold=1"
    call "%HELPERS%" CleanFolder "%SystemDrive%\Windows.old" "Windows.old"
    rd /s /q "%SystemDrive%\Windows.old" >nul 2>&1
)
if exist "%SystemDrive%\$Windows.~BT" (
    set "_found_winold=1"
    call "%HELPERS%" CleanFolder "%SystemDrive%\$Windows.~BT" "$Windows.~BT"
    rd /s /q "%SystemDrive%\$Windows.~BT" >nul 2>&1
)
if exist "%SystemDrive%\$Windows.~WS" (
    set "_found_winold=1"
    call "%HELPERS%" CleanFolder "%SystemDrive%\$Windows.~WS" "$Windows.~WS"
    rd /s /q "%SystemDrive%\$Windows.~WS" >nul 2>&1
)
if "%_found_winold%"=="1" (
    call "%HELPERS%" PrintOK "%L_Cleanup_WinOldCleaned%"
) else (
    call "%HELPERS%" PrintInfo "Windows.old / $Windows.~BT - %L_Common_FolderMissing%"
)

:: Temporary driver installers
echo.
echo %C_INFO%  %L_Cleanup_SecDrivers%%C_RESET%
if exist "%SystemDrive%\NVIDIA" call "%HELPERS%" CleanFolder "%SystemDrive%\NVIDIA" "%L_Cleanup_DriverTemp% - NVIDIA" & rd /s /q "%SystemDrive%\NVIDIA" >nul 2>&1
if exist "%SystemDrive%\AMD" call "%HELPERS%" CleanFolder "%SystemDrive%\AMD" "%L_Cleanup_DriverTemp% - AMD" & rd /s /q "%SystemDrive%\AMD" >nul 2>&1
if exist "%SystemDrive%\Intel" call "%HELPERS%" CleanFolder "%SystemDrive%\Intel" "%L_Cleanup_DriverTemp% - Intel" & rd /s /q "%SystemDrive%\Intel" >nul 2>&1
if exist "%SystemDrive%\Drivers" call "%HELPERS%" CleanFolder "%SystemDrive%\Drivers" "%L_Cleanup_DriverTemp% - Drivers" & rd /s /q "%SystemDrive%\Drivers" >nul 2>&1

:: System installer patch cache and logs
echo.
echo %C_INFO%  %L_Cleanup_SecPatchCache%%C_RESET%
if exist "%SystemRoot%\Installer\$PatchCache$" call "%HELPERS%" CleanFolder "%SystemRoot%\Installer\$PatchCache$" "%L_Cleanup_PatchCache%"
if exist "%SystemRoot%\Logs\CBS" (
    forfiles /p "%SystemRoot%\Logs\CBS" /s /m *.log /d -7 /c "cmd /c del /f /q @path" >nul 2>&1
    forfiles /p "%SystemRoot%\Logs\CBS" /s /m *.cab /d -7 /c "cmd /c del /f /q @path" >nul 2>&1
)
if exist "%SystemRoot%\Logs\DISM" (
    forfiles /p "%SystemRoot%\Logs\DISM" /s /m *.log /d -7 /c "cmd /c del /f /q @path" >nul 2>&1
)
call "%HELPERS%" PrintOK "%L_Cleanup_OldLogs%"

:: ---------------------------------------------------------------------------
:: 3) Optional items (config-driven)
:: ---------------------------------------------------------------------------
:OptionalStandard
echo.
echo %C_INFO%  %L_Cleanup_SecOptional%%C_RESET%

if "%CFG_CleanRecycleBin%"=="1" (
    call "%HELPERS%" Exec "%L_Cleanup_RecycleBin%" "powershell -NoProfile -InputFormat None -Command Clear-RecycleBin -Force -ErrorAction SilentlyContinue; exit 0"
) else (
    call "%HELPERS%" PrintInfo "%L_Cleanup_RecycleSkipped%"
)

if "%CFG_CleanEventLogs%"=="1" (
    if "%IS_ADMIN%"=="1" (
        call "%HELPERS%" Log EXEC "Clearing event logs via wevtutil"
        for /f "delims=" %%L in ('wevtutil el 2^>nul') do (
            wevtutil cl "%%L" >nul 2>&1
        )
        call "%HELPERS%" PrintOK "%L_Cleanup_EvtCleared%"
    ) else (
        call "%HELPERS%" PrintWarn "%L_Cleanup_EvtNeedAdmin%"
    )
) else (
    call "%HELPERS%" PrintInfo "%L_Cleanup_EvtKept%"
)

if "%CFG_CleanBrowserCache%"=="1" (
    call :BrowserCaches
) else (
    call "%HELPERS%" PrintInfo "%L_Cleanup_BrowserKept%"
)

:: ---------------------------------------------------------------------------
:: Summary
:: ---------------------------------------------------------------------------
echo.
call "%HELPERS%" HR
call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set /a SESSION_FREED=%FREESPACE_MB%-START_FREE
if %SESSION_FREED% LSS 0 set "SESSION_FREED=0"
echo   %C_OK%%L_Cleanup_Complete%%C_RESET% %C_WHITE%%SESSION_FREED% MB%C_RESET% %L_Cleanup_FreedOn% %SystemDrive%
call "%HELPERS%" Log OK "Standard Cleanup finished - approx %SESSION_FREED% MB freed"
exit /b 0


:: ============================================================================
:: :StartExtremeClean
::   Deep cleanup of stale files (>30 days) and orphaned uninstalled app data
:: ============================================================================
:StartExtremeClean
call "%HELPERS%" Header "%L_Cleanup_ExtremeTitle%"
call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set "START_FREE=%FREESPACE_MB%"
call "%HELPERS%" Log INFO "Extreme cleanup started. Free space: %START_FREE% MB"

:: First, run baseline standard cleanup
call :StartStandardClean

:: ---------------------------------------------------------------------------
:: Step 1: Stale User Files (> 30 days) in Downloads
:: ---------------------------------------------------------------------------
echo.
echo %C_INFO%  %L_Cleanup_SecStaleFiles%%C_RESET%
call "%HELPERS%" PrintInfo "%L_Cleanup_StaleScanning%"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='SilentlyContinue';" ^
  "Add-Type -AssemblyName Microsoft.VisualBasic;" ^
  "$dl=[Environment]::GetFolderPath('UserProfile')+'\Downloads';" ^
  "$cnt=0;$freed=0;" ^
  "if (Test-Path $dl) {" ^
  "  $cutoff=(Get-Date).AddDays(-30);" ^
  "  $files=Get-ChildItem -LiteralPath $dl -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoff };" ^
  "  foreach ($f in $files) {" ^
  "    try {" ^
  "      $freed += $f.Length;" ^
  "      [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($f.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin');" ^
  "      $cnt++;" ^
  "    } catch {}" ^
  "  }" ^
  "};" ^
  "$mb=[math]::Round($freed/1MB);" ^
  "if ($cnt -gt 0) {" ^
  "  Write-Host ('  %L_Cleanup_StaleFound% ' + $cnt + ' (~' + $mb + ' MB)');" ^
  "  exit 0" ^
  "} else {" ^
  "  exit 2" ^
  "}"

if errorlevel 2 (
    call "%HELPERS%" PrintInfo "%L_Cleanup_StaleNone%"
) else (
    call "%HELPERS%" PrintOK "%L_Cleanup_StaleMoved%"
)

:: ---------------------------------------------------------------------------
:: Step 2: Orphaned application data in AppData & ProgramData
:: ---------------------------------------------------------------------------
echo.
echo %C_INFO%  %L_Cleanup_SecOrphans%%C_RESET%
call "%HELPERS%" PrintInfo "%L_Cleanup_OrphansScanning%"
if not defined TIMESTAMP call "%HELPERS%" Timestamp
set "ORPHAN_LIST_FILE=%TEMP%\wgo_orphans_%TIMESTAMP%.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='SilentlyContinue';" ^
  "$uninst = @(Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue);" ^
  "$regNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase);" ^
  "foreach ($u in $uninst) {" ^
  "  if ($u.DisplayName) { [void]$regNames.Add($u.DisplayName.Trim()) };" ^
  "  if ($u.PSChildName) { [void]$regNames.Add($u.PSChildName.Trim()) };" ^
  "};" ^
  "$whiteList = @('Microsoft','Windows','WindowsApps','Packages','Programs','Package Cache','USOPrivate','USOShared','USO_Download','SoftwareDistribution','Comms','ConnectedDevicesPlatform','Publishers','Common Files','Identities','VirtualStore','ElevatedDiagnostics','Downloaded Installations','Temp','CrashDumps','INetCache','D3DSCache','IconCache','pip','npm','node','node-gyp','dotnet','git','PowerShell','NVIDIA','AMD','Intel','Realtek','Steam','Discord','Telegram','Epic','Google','Mozilla','Visual Studio','VSCode','Cursor','Antigravity','agy','Gemini','Claude','Anthropic','OpenAI','Python','uv','cargo','rust','Oracle','Java','Adobe','Spotify','OBS','Battle.net','Electronic Arts','EA','Ubisoft','GOG','Origin','Docker','WSL');" ^
  "$targets = @($env:LOCALAPPDATA, $env:APPDATA, $env:ProgramData);" ^
  "$orphans = @();" ^
  "foreach ($t in $targets) {" ^
  "  if (-not (Test-Path $t)) { continue };" ^
  "  $dirs = Get-ChildItem -LiteralPath $t -Directory -ErrorAction SilentlyContinue;" ^
  "  foreach ($d in $dirs) {" ^
  "    $name = $d.Name;" ^
  "    if ($d.FullName -eq ($env:LOCALAPPDATA + '\Programs')) { continue };" ^
  "    if ($whiteList | Where-Object { $name -like ('*' + $_ + '*') }) { continue };" ^
  "    $foundMatch = $false;" ^
  "    foreach ($rn in $regNames) {" ^
  "      if ($rn -like ('*' + $name + '*') -or $name -like ('*' + $rn + '*')) { $foundMatch = $true; break };" ^
  "    };" ^
  "    if (-not $foundMatch) {" ^
  "      $sz = 0;" ^
  "      try { $sz = (Get-ChildItem -LiteralPath $d.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum } catch {};" ^
  "      $szMB = [math]::Round($sz / 1MB, 1);" ^
  "      if ($szMB -gt 0) { $orphans += [PSCustomObject]@{ Path=$d.FullName; Name=$name; SizeMB=$szMB } }" ^
  "    }" ^
  "  }" ^
  "};" ^
  "if ($orphans.Count -gt 0) {" ^
  "  $orphans | ForEach-Object { $_.Path + '|' + $_.SizeMB } | Out-File -FilePath '%ORPHAN_LIST_FILE%' -Encoding utf8;" ^
  "  exit 0" ^
  "} else { exit 2 }"

if errorlevel 2 (
    call "%HELPERS%" PrintInfo "%L_Cleanup_OrphansNone%"
    if exist "%ORPHAN_LIST_FILE%" del /q "%ORPHAN_LIST_FILE%" >nul 2>&1
    goto :ExtremeDeepCaches
)

if not exist "%ORPHAN_LIST_FILE%" goto :ExtremeDeepCaches

echo.
echo   %C_WARN%%L_Cleanup_OrphansFound%%C_RESET%
set "_oc=0"
for /f "usebackq tokens=1,2 delims=|" %%P in ("%ORPHAN_LIST_FILE%") do (
    set /a _oc+=1
    echo     %C_MENU%[!_oc!]%C_RESET% %%P  %C_DIM%[%%Q MB]%C_RESET%
)
echo.
call "%HELPERS%" Confirm "%L_Cleanup_OrphansAsk%"
if /i not "!CONFIRM!"=="Y" goto :SkipOrphanDelete

for /f "usebackq tokens=1,2 delims=|" %%P in ("%ORPHAN_LIST_FILE%") do (
    if exist "%%P" rd /s /q "%%P" >nul 2>&1
)
call "%HELPERS%" PrintOK "%L_Cleanup_OrphansDeleted%"
goto :OrphansFinished

:SkipOrphanDelete
call "%HELPERS%" PrintInfo "%L_Cleanup_OrphansSkipped%"

:OrphansFinished
if exist "%ORPHAN_LIST_FILE%" del /q "%ORPHAN_LIST_FILE%" >nul 2>&1

:ExtremeDeepCaches
:: ---------------------------------------------------------------------------
:: Step 3: Deep browser caches, event logs, and final Recycle Bin purge
:: ---------------------------------------------------------------------------
echo.
echo %C_INFO%  %L_Cleanup_SecOptional%%C_RESET%
call :BrowserCaches

if "%IS_ADMIN%"=="1" (
    call "%HELPERS%" Log EXEC "Clearing event logs via wevtutil"
    for /f "delims=" %%L in ('wevtutil el 2^>nul') do (
        wevtutil cl "%%L" >nul 2>&1
    )
    call "%HELPERS%" PrintOK "%L_Cleanup_EvtCleared%"
)

call "%HELPERS%" Exec "%L_Cleanup_RecycleBin%" "powershell -NoProfile -InputFormat None -Command Clear-RecycleBin -Force -ErrorAction SilentlyContinue; exit 0"

:: ---------------------------------------------------------------------------
:: Final Summary
:: ---------------------------------------------------------------------------
echo.
call "%HELPERS%" HR
call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set /a SESSION_FREED=%FREESPACE_MB%-START_FREE
if %SESSION_FREED% LSS 0 set "SESSION_FREED=0"
echo   %C_OK%%L_Cleanup_Complete%%C_RESET% %C_WHITE%%SESSION_FREED% MB%C_RESET% %L_Cleanup_FreedOn% %SystemDrive%
call "%HELPERS%" Log OK "Extreme Cleanup finished - approx %SESSION_FREED% MB freed"
exit /b 0


:: ============================================================================
:: :BrowserCaches
::   Empties only the Cache/Code Cache/GPUCache folders of installed
::   browsers. Warns if the browser is currently running.
:: ============================================================================
:BrowserCaches
tasklist /fi "imagename eq msedge.exe"  2>nul | find /i "msedge.exe"  >nul && call "%HELPERS%" PrintWarn "%L_Cleanup_EdgeRunning%"
tasklist /fi "imagename eq chrome.exe"  2>nul | find /i "chrome.exe"  >nul && call "%HELPERS%" PrintWarn "%L_Cleanup_ChromeRunning%"
tasklist /fi "imagename eq firefox.exe" 2>nul | find /i "firefox.exe" >nul && call "%HELPERS%" PrintWarn "%L_Cleanup_FirefoxRunning%"

call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" "%L_Cleanup_EdgeCache%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache" "%L_Cleanup_EdgeCode%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" "%L_Cleanup_ChromeCache%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache" "%L_Cleanup_ChromeCode%"
if exist "%LOCALAPPDATA%\Mozilla\Firefox\Profiles" (
    for /d %%P in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do (
        call "%HELPERS%" CleanFolder "%%P\cache2" "%L_Cleanup_FirefoxCache% - %%~nxP"
    )
)
exit /b 0
