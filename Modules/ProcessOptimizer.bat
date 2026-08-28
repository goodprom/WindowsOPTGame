@echo off
:: ============================================================================
::  WindowsOPTGame - ProcessOptimizer.bat
:: ----------------------------------------------------------------------------
::  Process & RAM Footprint Optimization:
::    [1] Quick RAM Flush (clear memory cache & working sets)
::    [2] Disable UWP Background Apps Activity
::    [3] Disable Edge Background Processes, Taskbar Widgets & Copilot
::    [4] Disable 9 Secondary & Telemetry Background Services
::    [5] Disable Scheduled Telemetry Tasks
::    [6] Apply ALL Process & RAM Optimizations
::    [R] Restore All Defaults (Rollback)
::
::  Call styles:
::      ProcessOptimizer.bat       - interactive menu
::      ProcessOptimizer.bat AUTO  - unattended mode (used in Full Optimization)
:: ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog ProcessOptimizer
call "%HELPERS%" LoadConfig

set "MODE=%~1"
if /i "%MODE%"=="AUTO" goto :RunAutoMode

call "%HELPERS%" RequireAdmin || (call "%HELPERS%" PauseKey & endlocal & exit /b 1)

:ProcessMenu
call "%HELPERS%" Header "%L_ProcessOptimizer_Title%"
echo   %L_ProcessOptimizer_Intro1%
echo   %C_DIM%%L_ProcessOptimizer_Intro2%%C_RESET%
echo.

:: ---------------------------------------------------------------------------
:: Live Status Dashboard
:: ---------------------------------------------------------------------------
call :GetLiveMetrics
call :GetTweaksStatus

echo   %C_DIM%------------------------------------------------------------------%C_RESET%
echo   %C_INFO%%L_ProcessOptimizer_DashProcesses%%C_RESET% %C_WHITE%%_PROC_COUNT% processes%C_RESET%
echo   %C_INFO%%L_ProcessOptimizer_DashRAM%%C_RESET% %C_WHITE%%_RAM_METRIC%%C_RESET%
echo   %C_INFO%%L_ProcessOptimizer_DashBgApps%%C_RESET% %_BGAPPS_STATUS_TEXT%
echo   %C_INFO%%L_ProcessOptimizer_DashEdgeWidg%%C_RESET% %_EDGEWIDG_STATUS_TEXT%
echo   %C_INFO%%L_ProcessOptimizer_DashServices%%C_RESET% %_SERVICES_STATUS_TEXT%
echo   %C_INFO%%L_ProcessOptimizer_DashTasks%%C_RESET% %_TASKS_STATUS_TEXT%
echo   %C_DIM%------------------------------------------------------------------%C_RESET%
echo.

echo   %C_MENU%[1]%C_RESET% %L_ProcessOptimizer_M1%
echo   %C_MENU%[2]%C_RESET% %L_ProcessOptimizer_M2%
echo   %C_MENU%[3]%C_RESET% %L_ProcessOptimizer_M3%
echo   %C_MENU%[4]%C_RESET% %L_ProcessOptimizer_M4%
echo   %C_MENU%[5]%C_RESET% %L_ProcessOptimizer_M5%
echo   %C_MENU%[6]%C_RESET% %L_ProcessOptimizer_M6%
echo   %C_MENU%[R]%C_RESET% %L_ProcessOptimizer_MRestore%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.

set "POCHOICE="
set /p "POCHOICE=  %L_Common_SelectOption% "
if "%POCHOICE%"=="1" (call :ActionRAMFlush           & goto :ProcessMenu)
if "%POCHOICE%"=="2" (call :ActionBackgroundApps     & goto :ProcessMenu)
if "%POCHOICE%"=="3" (call :ActionEdgeWidgetsCopilot & goto :ProcessMenu)
if "%POCHOICE%"=="4" (call :ActionDisableServices    & goto :ProcessMenu)
if "%POCHOICE%"=="5" (call :ActionDisableTasks       & goto :ProcessMenu)
if "%POCHOICE%"=="6" (call :ActionAll                & goto :ProcessMenu)
if /i "%POCHOICE%"=="R" (call :ActionRestore         & goto :ProcessMenu)
if "%POCHOICE%"=="0" (endlocal & exit /b 0)
goto :ProcessMenu


:: ============================================================================
:: Metric & Status Queries
:: ============================================================================
:GetLiveMetrics
set "_PROC_COUNT=0"
for /f "usebackq" %%C in (`powershell -NoProfile -InputFormat None -Command "(Get-Process).Count" 2^>nul`) do set "_PROC_COUNT=%%C"
set "_RAM_METRIC=-- / --"
for /f "usebackq delims=" %%M in (`powershell -NoProfile -InputFormat None -Command "$os=Get-CimInstance Win32_OperatingSystem;$u=[math]::Round(($os.TotalVisibleMemorySize-$os.FreePhysicalMemory)/1MB,1);$t=[math]::Round($os.TotalVisibleMemorySize/1MB,1);$p=[math]::Round(($u/$t)*100);Write-Host ($u.ToString()+' / '+$t.ToString()+' GB ['+$p+'%%]')" 2^>nul`) do set "_RAM_METRIC=%%M"
exit /b 0

:GetTweaksStatus
:: Background apps status
set "_BGAPPS_STATUS_TEXT=%C_WARN%%L_ProcessOptimizer_StateActive%%C_RESET%"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled 2>nul | findstr /i "0x1" >nul 2>&1
if not errorlevel 1 set "_BGAPPS_STATUS_TEXT=%C_OK%%L_ProcessOptimizer_StateDisabled%%C_RESET%"

:: Edge / Widgets status
set "_EDGEWIDG_STATUS_TEXT=%C_WARN%%L_ProcessOptimizer_StateActive%%C_RESET%"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled 2>nul | findstr /i "0x0" >nul 2>&1
if not errorlevel 1 set "_EDGEWIDG_STATUS_TEXT=%C_OK%%L_ProcessOptimizer_StateDisabled%%C_RESET%"

:: Services status (check DiagTrack)
set "_SERVICES_STATUS_TEXT=%C_WARN%%L_ProcessOptimizer_StateActive%%C_RESET%"
sc qc DiagTrack 2>nul | findstr /i "DISABLED" >nul 2>&1
if not errorlevel 1 set "_SERVICES_STATUS_TEXT=%C_OK%%L_ProcessOptimizer_StateDisabled%%C_RESET%"

:: Tasks status (check Compatibility Appraiser)
set "_TASKS_STATUS_TEXT=%C_WARN%%L_ProcessOptimizer_StateActive%%C_RESET%"
schtasks /query /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" 2>nul | findstr /i "Disabled Отключено" >nul 2>&1
if not errorlevel 1 set "_TASKS_STATUS_TEXT=%C_OK%%L_ProcessOptimizer_StateDisabled%%C_RESET%"
exit /b 0


:: ============================================================================
:: [1] Quick RAM Flush Action
:: ============================================================================
:ActionRAMFlush
call "%HELPERS%" Header "%L_ProcessOptimizer_M1%"
call "%HELPERS%" PrintInfo "%L_ProcessOptimizer_RAMCleanStart%"
call "%HELPERS%" Log EXEC "Flushing RAM working sets and standby list"
call "%HELPERS%" FlushRAM
call "%HELPERS%" PrintOK "%L_ProcessOptimizer_RAMCleanDone%"
call "%HELPERS%" Log OK "RAM working sets flushed"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [2] Background Apps Action
:: ============================================================================
:ActionBackgroundApps
call "%HELPERS%" Header "%L_ProcessOptimizer_M2%"
call "%HELPERS%" Confirm "%L_ProcessOptimizer_BgAppsAsk%"
if /i not "%CONFIRM%"=="Y" exit /b 0

call "%MODULES%\Backup.bat" AUTO >nul 2>&1
call "%HELPERS%" SetRegDWORD "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2
call "%HELPERS%" PrintOK "%L_ProcessOptimizer_BgAppsDone%"
call "%HELPERS%" Log OK "Disabled UWP background apps activity"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [3] Edge, Widgets and Copilot Action
:: ============================================================================
:ActionEdgeWidgetsCopilot
call "%HELPERS%" Header "%L_ProcessOptimizer_M3%"
call "%HELPERS%" Confirm "%L_ProcessOptimizer_EdgeWidgAsk%"
if /i not "%CONFIRM%"=="Y" exit /b 0

call "%MODULES%\Backup.bat" AUTO >nul 2>&1

:: Taskbar Widgets (News and Interests)
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
call "%HELPERS%" SetRegDWORD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0

:: Microsoft Edge background mode & Startup Boost
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" 0
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" 0

:: Windows Copilot
call "%HELPERS%" SetRegDWORD "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1

call "%HELPERS%" PrintOK "%L_ProcessOptimizer_EdgeWidgDone%"
call "%HELPERS%" Log OK "Disabled Edge background processes, Widgets and Copilot"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [4] Disable 9 Secondary & Telemetry Services Action
:: ============================================================================
:ActionDisableServices
call "%HELPERS%" Header "%L_ProcessOptimizer_M4%"
call "%HELPERS%" Confirm "%L_ProcessOptimizer_ServicesAsk%"
if /i not "%CONFIRM%"=="Y" exit /b 0

call "%MODULES%\Backup.bat" AUTO >nul 2>&1

set "_SVC_LIST=DiagTrack dmwappushservice MapsBroker WerSvc RetailDemo PcaSvc wisvc SharedRealitySvc WbioSrvc"
for %%S in (%_SVC_LIST%) do (
    net stop %%S /y >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
    call "%HELPERS%" PrintOK "%%S -> Disabled"
)

call "%HELPERS%" PrintOK "%L_ProcessOptimizer_ServicesDone%"
call "%HELPERS%" Log OK "Disabled 9 telemetry and secondary background services"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [5] Disable Telemetry Scheduled Tasks Action
:: ============================================================================
:ActionDisableTasks
call "%HELPERS%" Header "%L_ProcessOptimizer_M5%"
call "%HELPERS%" Confirm "%L_ProcessOptimizer_TasksAsk%"
if /i not "%CONFIRM%"=="Y" exit /b 0

schtasks /Change /Disable /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Autochk\Proxy" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" >nul 2>&1

call "%HELPERS%" PrintOK "%L_ProcessOptimizer_TasksDone%"
call "%HELPERS%" Log OK "Disabled telemetry tasks in Task Scheduler"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [6] Apply ALL Process & RAM Optimizations Action
:: ============================================================================
:ActionAll
call "%HELPERS%" Header "%L_ProcessOptimizer_M6%"
call "%HELPERS%" Confirm "%L_ProcessOptimizer_AllConfirm%"
if /i not "%CONFIRM%"=="Y" exit /b 0

call "%MODULES%\Backup.bat" AUTO >nul 2>&1

echo.
echo %C_INFO%  --- [1/5] %L_ProcessOptimizer_M2% ---%C_RESET%
call "%HELPERS%" SetRegDWORD "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2
call "%HELPERS%" PrintOK "%L_ProcessOptimizer_BgAppsDone%"

echo.
echo %C_INFO%  --- [2/5] %L_ProcessOptimizer_M3% ---%C_RESET%
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
call "%HELPERS%" SetRegDWORD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" 0
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" 0
call "%HELPERS%" SetRegDWORD "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
call "%HELPERS%" PrintOK "%L_ProcessOptimizer_EdgeWidgDone%"

echo.
echo %C_INFO%  --- [3/5] %L_ProcessOptimizer_M4% ---%C_RESET%
set "_SVC_LIST=DiagTrack dmwappushservice MapsBroker WerSvc RetailDemo PcaSvc wisvc SharedRealitySvc WbioSrvc"
for %%S in (%_SVC_LIST%) do (
    net stop %%S /y >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
)
call "%HELPERS%" PrintOK "%L_ProcessOptimizer_ServicesDone%"

echo.
echo %C_INFO%  --- [4/5] %L_ProcessOptimizer_M5% ---%C_RESET%
schtasks /Change /Disable /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Autochk\Proxy" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" >nul 2>&1
call "%HELPERS%" PrintOK "%L_ProcessOptimizer_TasksDone%"

echo.
echo %C_INFO%  --- [5/5] %L_ProcessOptimizer_M1% ---%C_RESET%
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "[System.GC]::Collect();" ^
  "$code = @'" ^
  "using System;" ^
  "using System.Runtime.InteropServices;" ^
  "public class MemUtil {" ^
  "  [DllImport(\"psapi.dll\")]" ^
  "  public static extern int EmptyWorkingSet(IntPtr hwProc);" ^
  "}" ^
  "'@;" ^
  "Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue;" ^
  "Get-Process | Where-Object { $_.Handle -ne $null } | ForEach-Object { try { [MemUtil]::EmptyWorkingSet($_.Handle) } catch {} }" >nul 2>&1
call "%HELPERS%" PrintOK "%L_ProcessOptimizer_RAMCleanDone%"

echo.
call "%HELPERS%" HR
echo   %C_OK%%L_ProcessOptimizer_AllDone%%C_RESET%
call "%HELPERS%" Log OK "Applied all process and RAM optimizations"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [R] Restore All Defaults (Rollback) Action
:: ============================================================================
:ActionRestore
call "%HELPERS%" Header "%L_ProcessOptimizer_MRestore%"
call "%HELPERS%" Confirm "%L_ProcessOptimizer_RestoreConfirm%"
if /i not "%CONFIRM%"=="Y" exit /b 0

:: Restore Background Apps
call "%HELPERS%" SetRegDWORD "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 0
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /f >nul 2>&1

:: Restore Edge, Widgets, Copilot
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /f >nul 2>&1
call "%HELPERS%" SetRegDWORD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "StartupBoostEnabled" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "BackgroundModeEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f >nul 2>&1

:: Restore Services
sc config DiagTrack start= auto >nul 2>&1
sc config dmwappushservice start= demand >nul 2>&1
sc config MapsBroker start= auto >nul 2>&1
sc config WerSvc start= demand >nul 2>&1
sc config RetailDemo start= demand >nul 2>&1
sc config PcaSvc start= auto >nul 2>&1
sc config wisvc start= demand >nul 2>&1
sc config SharedRealitySvc start= demand >nul 2>&1
sc config WbioSrvc start= demand >nul 2>&1

:: Restore Tasks
schtasks /Change /Enable /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" >nul 2>&1
schtasks /Change /Enable /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" >nul 2>&1
schtasks /Change /Enable /TN "\Microsoft\Windows\Autochk\Proxy" >nul 2>&1
schtasks /Change /Enable /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" >nul 2>&1
schtasks /Change /Enable /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" >nul 2>&1
schtasks /Change /Enable /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" >nul 2>&1

call "%HELPERS%" PrintOK "%L_ProcessOptimizer_RestoreDone%"
call "%HELPERS%" Log OK "Restored all process and service settings to factory defaults"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: AUTO Mode (unattended, called by Full Optimization)
:: ============================================================================
:RunAutoMode
call "%HELPERS%" Log INFO "Running ProcessOptimizer AUTO mode"

:: 1. Background Apps
call "%HELPERS%" SetRegDWORD "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsRunInBackground" 2

:: 2. Edge, Widgets, Copilot
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
call "%HELPERS%" SetRegDWORD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" 0
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" 0
call "%HELPERS%" SetRegDWORD "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1

:: 3. Telemetry Tasks
schtasks /Change /Disable /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Autochk\Proxy" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" >nul 2>&1
schtasks /Change /Disable /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" >nul 2>&1

:: 4. Flush RAM
call "%HELPERS%" FlushRAM

call "%HELPERS%" Log OK "ProcessOptimizer AUTO mode finished"
endlocal
exit /b 0
