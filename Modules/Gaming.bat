@echo off
:: ============================================================================
::  WindowsOPTGame - Gaming.bat
:: ----------------------------------------------------------------------------
::  Advanced Gaming Mode:
::    [1] Activate Full Gaming Mode (all-in-one 1-click optimization)
::    [2] Pause or Resume Gaming Services
::    [3] MMCSS and 3D Game Priority (SystemResponsiveness & Tasks\Games)
::    [4] Network Throttling Index Optimization
::    [5] HAGS and Windowed Game Optimization (VRR / AutoHDR)
::    [6] Ultimate Performance Power Plan
::    [7] Disable CPU Power Throttling
::    [8] Flush RAM and GPU Shader Caches
::    [R] Restore Factory Defaults
::
::  Call styles:
::      Gaming.bat            - full Gaming Mode dashboard
::      Gaming.bat RAMONLY    - only the RAM Cleanup section
:: ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog Gaming
call "%HELPERS%" LoadConfig

if /i "%~1"=="RAMONLY" goto :RamCleanupOnly

call "%HELPERS%" RequireAdmin || (call "%HELPERS%" PauseKey & endlocal & exit /b 1)

set "GAME_SVCS=SysMain DiagTrack dmwappushservice Fax Spooler WSearch MapsBroker RetailDemo WerSvc PcaSvc"

:GamingMenu
call "%HELPERS%" Header "%L_Gaming_Title%"
echo   %L_Gaming_Intro1%
echo   %C_DIM%%L_Gaming_Intro2%%C_RESET%
echo.

:: ---------------------------------------------------------------------------
:: Live Status Dashboard
:: ---------------------------------------------------------------------------
call :GetLiveRAM
call :GetMMCSSStatus
call :GetNetThrotStatus
call :GetHAGSStatus
call :GetVRRStatus
call :GetPowerPlanStatus
call :GetPwrThrotStatus
call :GetServicesStatus

echo   %C_DIM%------------------------------------------------------------------%C_RESET%
echo   %C_INFO%%L_Gaming_DashRAM%%C_RESET% %C_WHITE%%_RAM_METRIC%%C_RESET%
echo   %C_INFO%%L_Gaming_DashMMCSS%%C_RESET% %_MMCSS_STATUS_TEXT%
echo   %C_INFO%%L_Gaming_DashNetThrot%%C_RESET% %_NETTHROT_STATUS_TEXT%
echo   %C_INFO%%L_Gaming_DashHAGS%%C_RESET% %_HAGS_STATUS_TEXT%
echo   %C_INFO%%L_Gaming_DashVRR%%C_RESET% %_VRR_STATUS_TEXT%
echo   %C_INFO%%L_Gaming_DashPower%%C_RESET% %_POWER_STATUS_TEXT%
echo   %C_INFO%%L_Gaming_DashPwrThrot%%C_RESET% %_PWRTHROT_STATUS_TEXT%
echo   %C_INFO%%L_Gaming_DashServices%%C_RESET% %_SVCS_STATUS_TEXT%
echo   %C_DIM%------------------------------------------------------------------%C_RESET%
echo.

echo   %C_MENU%[1]%C_RESET% %L_Gaming_M1%
echo   %C_MENU%[2]%C_RESET% %L_Gaming_M2%
echo   %C_MENU%[3]%C_RESET% %L_Gaming_M3%
echo   %C_MENU%[4]%C_RESET% %L_Gaming_M4%
echo   %C_MENU%[5]%C_RESET% %L_Gaming_M5%
echo   %C_MENU%[6]%C_RESET% %L_Gaming_M6%
echo   %C_MENU%[7]%C_RESET% %L_Gaming_M7%
echo   %C_MENU%[8]%C_RESET% %L_Gaming_M8%
echo   %C_MENU%[R]%C_RESET% %L_Gaming_MRestore%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.

set "GCHOICE="
set /p "GCHOICE=  %L_Common_SelectOption% "
if "%GCHOICE%"=="1" (call :ActionAll                & goto :GamingMenu)
if "%GCHOICE%"=="2" (call :ActionServices           & goto :GamingMenu)
if "%GCHOICE%"=="3" (call :ActionMMCSS              & goto :GamingMenu)
if "%GCHOICE%"=="4" (call :ActionNetThrot           & goto :GamingMenu)
if "%GCHOICE%"=="5" (call :ActionHAGS               & goto :GamingMenu)
if "%GCHOICE%"=="6" (call :ActionPowerPlan          & goto :GamingMenu)
if "%GCHOICE%"=="7" (call :ActionPowerThrottling    & goto :GamingMenu)
if "%GCHOICE%"=="8" (call :ActionRAMAndShaderCaches & goto :GamingMenu)
if /i "%GCHOICE%"=="R" (call :ActionRestore         & goto :GamingMenu)
if "%GCHOICE%"=="0" (endlocal & exit /b 0)
goto :GamingMenu


:: ============================================================================
:: Metric and Status Queries
:: ============================================================================
:GetLiveRAM
set "_RAM_METRIC=-- / --"
for /f "usebackq delims=" %%M in (`powershell -NoProfile -InputFormat None -Command "$o=Get-CimInstance Win32_OperatingSystem;$u=[math]::Round(($o.TotalVisibleMemorySize-$o.FreePhysicalMemory)/1MB,1);$t=[math]::Round($o.TotalVisibleMemorySize/1MB,1);$p=[math]::Round(($u/$t)*100);Write-Host ($u.ToString()+' / '+$t.ToString()+' GB ['+$p+'%%]')" 2^>nul`) do set "_RAM_METRIC=%%M"
exit /b 0

:GetMMCSSStatus
set "_MMCSS_STATUS_TEXT=%C_DIM%%L_Gaming_StateStandard%%C_RESET%"
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness 2>nul | findstr /i "0x0" >nul 2>&1
if not errorlevel 1 set "_MMCSS_STATUS_TEXT=%C_OK%%L_Gaming_StateEnabled%%C_RESET%"
exit /b 0

:GetNetThrotStatus
set "_NETTHROT_STATUS_TEXT=%C_DIM%%L_Gaming_StateStandard%%C_RESET%"
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex 2>nul | findstr /i "0xffffffff" >nul 2>&1
if not errorlevel 1 set "_NETTHROT_STATUS_TEXT=%C_OK%%L_Gaming_StateDisabled%%C_RESET%"
exit /b 0

:GetHAGSStatus
set "_HAGS_STATUS_TEXT=%C_DIM%%L_Gaming_StateDisabled%%C_RESET%"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode 2>nul | findstr /i "0x2" >nul 2>&1
if not errorlevel 1 set "_HAGS_STATUS_TEXT=%C_OK%%L_Gaming_StateEnabled%%C_RESET%"
exit /b 0

:GetVRRStatus
set "_VRR_STATUS_TEXT=%C_DIM%%L_Gaming_StateDisabled%%C_RESET%"
reg query "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v DirectXUserGlobalSettings 2>nul | findstr /i "VRROptimizeEnable=1" >nul 2>&1
if not errorlevel 1 set "_VRR_STATUS_TEXT=%C_OK%%L_Gaming_StateActive%%C_RESET%"
exit /b 0

:GetPowerPlanStatus
set "_POWER_STATUS_TEXT=%C_DIM%Balanced%C_RESET%"
for /f "usebackq" %%G in (`powershell -NoProfile -InputFormat None -Command "if ((powercfg /getactivescheme) -match '([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})') { Write-Host $matches[1] }" 2^>nul`) do (
    if /i "%%G"=="e9a42b02-d5df-448d-aa00-03f14749eb61" set "_POWER_STATUS_TEXT=%C_OK%Ultimate Performance%C_RESET%"
    if /i "%%G"=="8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" set "_POWER_STATUS_TEXT=%C_INFO%High Performance%C_RESET%"
)
exit /b 0

:GetPwrThrotStatus
set "_PWRTHROT_STATUS_TEXT=%C_DIM%%L_Gaming_StateActive%%C_RESET%"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff 2>nul | findstr /i "0x1" >nul 2>&1
if not errorlevel 1 set "_PWRTHROT_STATUS_TEXT=%C_OK%%L_Gaming_StateDisabled%%C_RESET%"
exit /b 0

:GetServicesStatus
set "_SVCS_STATUS_TEXT=%C_DIM%%L_Gaming_StateActive%%C_RESET%"
if exist "%BACKUPS%\services_snapshot.txt" set "_SVCS_STATUS_TEXT=%C_OK%%L_Gaming_StatePaused%%C_RESET%"
exit /b 0


:: ============================================================================
:: [1] Activate Full Gaming Mode (All-in-One)
:: ============================================================================
:ActionAll
call "%HELPERS%" Header "%L_Gaming_Title%"
echo   %L_Gaming_WillDo%
if "%CFG_CloseBackgroundApps%"=="1"        echo    %L_Gaming_WDApps% %CFG_BackgroundApps%
echo    %L_Gaming_WDServices% %GAME_SVCS%
if "%CFG_DisableGameBar%"=="1"             echo    %L_Gaming_WDGameBar%
if "%CFG_DisableBackgroundRecording%"=="1" echo    %L_Gaming_WDRecording%
echo    %L_Gaming_WDPower%
echo    %L_Gaming_WDGameMode%
echo    %L_Gaming_WDMemory%
echo.
call "%HELPERS%" Confirm "%L_Gaming_ConfirmStart%"
if /i not "%CONFIRM%"=="Y" exit /b 0

call :MemSnapshot
set "MEM_BEFORE=%MEM_FREE_MB%"
echo.
echo   %C_INFO%%L_Gaming_MemBefore%%C_RESET% %MEM_USED_MB% %L_Gaming_MemOf% %MEM_TOTAL_MB% MB, %L_Gaming_MemFree% %MEM_FREE_MB% MB
echo.

:: 1) Pause services
echo %C_INFO%  %L_Gaming_SecServices%%C_RESET%
if not defined TIMESTAMP call "%HELPERS%" Timestamp
set "SVCSNAP=%BACKUPS%\services_snapshot.txt"
> "%SVCSNAP%" echo ; Services stopped by Gaming Mode on %DATE% %TIME% - restored by Restore.bat
for %%S in (%GAME_SVCS%) do (
    call "%HELPERS%" IsProtectedService %%S
    if "!PROTECTED!"=="1" (
        call "%HELPERS%" PrintWarn "%%S %L_Gaming_SvcProtected%"
    ) else (
        call "%HELPERS%" ServiceState %%S
        if "!SVC_STATE!"=="RUNNING" (
            net stop %%S /y >nul 2>&1
            call "%HELPERS%" ServiceState %%S
            if "!SVC_STATE!"=="STOPPED" (
                >>"%SVCSNAP%" echo %%S
                call "%HELPERS%" PrintOK "%L_Gaming_SvcPaused% %%S"
            ) else (
                call "%HELPERS%" PrintWarn "%%S %L_Gaming_SvcCouldNotStop%"
            )
        ) else (
            call "%HELPERS%" PrintInfo "%%S %L_Gaming_SvcAlreadyStopped%"
        )
    )
)

:: 2) Close background apps
if "%CFG_CloseBackgroundApps%"=="1" (
    echo.
    echo %C_INFO%  %L_Gaming_SecApps%%C_RESET%
    for %%A in (%CFG_BackgroundApps%) do (
        tasklist /fi "imagename eq %%A" 2>nul | find /i "%%A" >nul
        if not errorlevel 1 (
            taskkill /f /im "%%A" >nul 2>&1
            call "%HELPERS%" PrintOK "%L_Gaming_AppClosed% %%A"
        ) else (
            call "%HELPERS%" PrintInfo "%%A %L_Gaming_AppNotRunning%"
        )
    )
)

:: 3) Game Bar / Game DVR / Windows Game Mode
echo.
echo %C_INFO%  %L_Gaming_SecGame%%C_RESET%
if "%CFG_DisableGameBar%"=="1" (
    call "%HELPERS%" BackupRegKey "HKCU\SOFTWARE\Microsoft\GameBar" GameBar
    call "%HELPERS%" SetRegDWORD "HKCU\SOFTWARE\Microsoft\GameBar" "UseNexusForGameBarEnabled" 0
    call "%HELPERS%" SetRegDWORD "HKCU\SOFTWARE\Microsoft\GameBar" "ShowStartupPanel" 0
    call "%HELPERS%" PrintOK "%L_Gaming_GameBarOff%"
) else (
    call "%HELPERS%" PrintInfo "%L_Gaming_GameBarKept%"
)

if "%CFG_DisableBackgroundRecording%"=="1" (
    call "%HELPERS%" BackupRegKey "HKCU\System\GameConfigStore" GameConfigStore
    call "%HELPERS%" BackupRegKey "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" GameDVR
    call "%HELPERS%" SetRegDWORD "HKCU\System\GameConfigStore" "GameDVR_Enabled" 0
    call "%HELPERS%" SetRegDWORD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
    call "%HELPERS%" PrintOK "%L_Gaming_RecordingOff%"
) else (
    call "%HELPERS%" PrintInfo "%L_Gaming_RecordingKept%"
)

call "%HELPERS%" BackupRegKey "HKCU\SOFTWARE\Microsoft\GameBar" GameBar
call "%HELPERS%" SetRegDWORD "HKCU\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" 1
call "%HELPERS%" SetRegDWORD "HKCU\SOFTWARE\Microsoft\GameBar" "AllowAutoGameMode" 1
call "%HELPERS%" PrintOK "%L_Gaming_GameModeOn%"

:: 4) MMCSS and SystemResponsiveness
echo.
echo %C_INFO%  %L_Gaming_SecMMCSS%%C_RESET%
call "%HELPERS%" BackupRegKey "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" SystemProfile
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6
call "%HELPERS%" SetRegSZ "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High"
call "%HELPERS%" SetRegSZ "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "High"
call "%HELPERS%" SetRegSZ "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Background Only" "False"
call "%HELPERS%" PrintOK "%L_Gaming_MMCSSOn%"

:: 5) Network Throttling Index
echo.
echo %C_INFO%  %L_Gaming_SecNetThrot%%C_RESET%
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295
call "%HELPERS%" PrintOK "%L_Gaming_NetThrotOff%"

:: 6) HAGS and Windowed Optimization
echo.
echo %C_INFO%  %L_Gaming_SecHAGS%%C_RESET%
call "%HELPERS%" BackupRegKey "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" GraphicsDrivers
call "%HELPERS%" SetRegDWORD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
call "%HELPERS%" PrintOK "%L_Gaming_HAGSOn%"
call "%HELPERS%" SetRegSZ "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" "DirectXUserGlobalSettings" "VRROptimizeEnable=1;"
call "%HELPERS%" PrintOK "%L_Gaming_VRROn%"

:: 7) Power Scheme (Ultimate Performance with laptop hint)
echo.
echo %C_INFO%  %L_Gaming_SecPower%%C_RESET%
for /f "usebackq" %%G in (`powershell -NoProfile -InputFormat None -Command "if ((powercfg /getactivescheme) -match '([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})') { Write-Host $matches[1] }" 2^>nul`) do (
    if not exist "%BACKUPS%\powerplan_snapshot.txt" (
        > "%BACKUPS%\powerplan_snapshot.txt" echo %%G
        call "%HELPERS%" Log INFO "Saved previous power scheme: %%G"
    )
)
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
if errorlevel 1 (
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
)
call "%HELPERS%" PrintOK "%L_Gaming_PowerOn%"

for /f "usebackq" %%B in (`powershell -NoProfile -InputFormat None -Command "if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) { Write-Host 1 } else { Write-Host 0 }" 2^>nul`) do (
    if "%%B"=="1" call "%HELPERS%" PrintInfo "%L_Gaming_PowerLaptopHint%"
)

:: 8) Disable CPU Power Throttling
echo.
echo %C_INFO%  %L_Gaming_SecPwrThrot%%C_RESET%
call "%HELPERS%" BackupRegKey "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" PowerThrottling
call "%HELPERS%" SetRegDWORD "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1
call "%HELPERS%" PrintOK "%L_Gaming_PwrThrotOff%"

:: 9) Native Memory Trim and Shader Caches
echo.
echo %C_INFO%  %L_Gaming_SecMemory%%C_RESET%
call :EmptyStandbyList
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\D3DSCache" "%L_Gaming_DXUser%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\NVIDIA\DXCache" "%L_Gaming_NvDX%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\NVIDIA\GLCache" "%L_Gaming_NvGL%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\AMD\DxCache" "%L_Gaming_AmdDX%"
call "%HELPERS%" CleanFolder "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\D3DSCache" "%L_Gaming_DXSystem2%"

:: Summary
echo.
call :MemSnapshot
set /a MEM_GAINED=%MEM_FREE_MB%-MEM_BEFORE
if %MEM_GAINED% LSS 0 set "MEM_GAINED=0"
call "%HELPERS%" HR
echo   %C_INFO%%L_Gaming_MemAfter%%C_RESET% %MEM_USED_MB% %L_Gaming_MemOf% %MEM_TOTAL_MB% MB, %L_Gaming_MemFree% %MEM_FREE_MB% MB
echo   %C_OK%%L_Gaming_Active%%C_RESET% %C_WHITE%%MEM_GAINED% MB%C_RESET% %L_Gaming_ExtraRam%
echo.
echo   %C_DIM%%L_Gaming_UndoHint1%%C_RESET%
echo   %C_DIM%%L_Gaming_UndoHint2%%C_RESET%
call "%HELPERS%" Log OK "Full Gaming Mode activated - %MEM_GAINED% MB RAM gained"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [2] Pause or Resume Gaming Services
:: ============================================================================
:ActionServices
call "%HELPERS%" Header "%L_Gaming_M2%"
set "SVCSNAP=%BACKUPS%\services_snapshot.txt"
if exist "%SVCSNAP%" (
    echo   %C_INFO%Restoring previously stopped services...%C_RESET%
    for /f "usebackq eol=; delims=" %%S in ("%SVCSNAP%") do (
        call "%HELPERS%" ServiceState %%S
        if "!SVC_STATE!"=="STOPPED" (
            net start %%S >nul 2>&1
            call "%HELPERS%" PrintOK "Restored: %%S"
        )
    )
    del /q "%SVCSNAP%" >nul 2>&1
    call "%HELPERS%" PrintOK "%L_Restore_SvcRestored%"
) else (
    echo   %C_INFO%Pausing non-essential services for game session...%C_RESET%
    if not defined TIMESTAMP call "%HELPERS%" Timestamp
    > "%SVCSNAP%" echo ; Services stopped by Gaming Mode on %DATE% %TIME%
    for %%S in (%GAME_SVCS%) do (
        call "%HELPERS%" IsProtectedService %%S
        if "!PROTECTED!"=="0" (
            call "%HELPERS%" ServiceState %%S
            if "!SVC_STATE!"=="RUNNING" (
                net stop %%S /y >nul 2>&1
                >>"%SVCSNAP%" echo %%S
                call "%HELPERS%" PrintOK "%L_Gaming_SvcPaused% %%S"
            )
        )
    )
)
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [3] MMCSS and 3D Game Priority
:: ============================================================================
:ActionMMCSS
call "%HELPERS%" Header "%L_Gaming_M3%"
call "%HELPERS%" BackupRegKey "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" SystemProfile
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6
call "%HELPERS%" SetRegSZ "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High"
call "%HELPERS%" SetRegSZ "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "High"
call "%HELPERS%" SetRegSZ "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Background Only" "False"
call "%HELPERS%" PrintOK "%L_Gaming_MMCSSOn%"
call "%HELPERS%" Log OK "MMCSS gaming priorities applied"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [4] Network Throttling Index
:: ============================================================================
:ActionNetThrot
call "%HELPERS%" Header "%L_Gaming_M4%"
call "%HELPERS%" BackupRegKey "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" SystemProfile
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 4294967295
call "%HELPERS%" PrintOK "%L_Gaming_NetThrotOff%"
call "%HELPERS%" Log OK "Network throttling disabled (0xFFFFFFFF)"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [5] HAGS and Windowed Game Optimization
:: ============================================================================
:ActionHAGS
call "%HELPERS%" Header "%L_Gaming_M5%"
call "%HELPERS%" BackupRegKey "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" GraphicsDrivers
call "%HELPERS%" SetRegDWORD "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
call "%HELPERS%" PrintOK "%L_Gaming_HAGSOn%"
call "%HELPERS%" SetRegSZ "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" "DirectXUserGlobalSettings" "VRROptimizeEnable=1;"
call "%HELPERS%" PrintOK "%L_Gaming_VRROn%"
call "%HELPERS%" Log OK "HAGS and Windowed VRR optimizations applied"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [6] Ultimate Performance Power Plan
:: ============================================================================
:ActionPowerPlan
call "%HELPERS%" Header "%L_Gaming_M6%"
for /f "usebackq" %%G in (`powershell -NoProfile -InputFormat None -Command "if ((powercfg /getactivescheme) -match '([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})') { Write-Host $matches[1] }" 2^>nul`) do (
    if not exist "%BACKUPS%\powerplan_snapshot.txt" (
        > "%BACKUPS%\powerplan_snapshot.txt" echo %%G
        call "%HELPERS%" Log INFO "Saved previous power scheme: %%G"
    )
)
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
if errorlevel 1 (
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
)
call "%HELPERS%" PrintOK "%L_Gaming_PowerOn%"

for /f "usebackq" %%B in (`powershell -NoProfile -InputFormat None -Command "if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) { Write-Host 1 } else { Write-Host 0 }" 2^>nul`) do (
    if "%%B"=="1" call "%HELPERS%" PrintInfo "%L_Gaming_PowerLaptopHint%"
)
call "%HELPERS%" Log OK "Ultimate Performance power scheme activated"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [7] Disable CPU Power Throttling
:: ============================================================================
:ActionPowerThrottling
call "%HELPERS%" Header "%L_Gaming_M7%"
call "%HELPERS%" BackupRegKey "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" PowerThrottling
call "%HELPERS%" SetRegDWORD "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1
call "%HELPERS%" PrintOK "%L_Gaming_PwrThrotOff%"
call "%HELPERS%" Log OK "CPU Power Throttling disabled"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [8] Flush RAM and GPU Shader Caches
:: ============================================================================
:ActionRAMAndShaderCaches
call "%HELPERS%" Header "%L_Gaming_M8%"
call :MemSnapshot
set "MEM_BEFORE=%MEM_FREE_MB%"
echo   %C_INFO%%L_Gaming_MemBefore%%C_RESET% %MEM_USED_MB% %L_Gaming_MemOf% %MEM_TOTAL_MB% MB, %L_Gaming_MemFree% %MEM_FREE_MB% MB
echo.
call :EmptyStandbyList
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\D3DSCache" "%L_Gaming_DXUser%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\NVIDIA\DXCache" "%L_Gaming_NvDX%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\NVIDIA\GLCache" "%L_Gaming_NvGL%"
call "%HELPERS%" CleanFolder "%LOCALAPPDATA%\AMD\DxCache" "%L_Gaming_AmdDX%"
call "%HELPERS%" CleanFolder "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\D3DSCache" "%L_Gaming_DXSystem2%"
echo.
call :MemSnapshot
set /a MEM_GAINED=%MEM_FREE_MB%-MEM_BEFORE
if %MEM_GAINED% LSS 0 set "MEM_GAINED=0"
call "%HELPERS%" HR
echo   %C_INFO%%L_Gaming_MemAfter%%C_RESET% %MEM_USED_MB% %L_Gaming_MemOf% %MEM_TOTAL_MB% MB, %L_Gaming_MemFree% %MEM_FREE_MB% MB
echo   %C_OK%%L_Gaming_Gained% %MEM_GAINED% %L_Gaming_GainedTail%%C_RESET%
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: [R] Restore Factory Defaults (Rollback)
:: ============================================================================
:ActionRestore
call "%HELPERS%" Header "%L_Gaming_MRestore%"
call "%HELPERS%" Confirm "%L_Gaming_RestoreConfirm%"
if /i not "%CONFIRM%"=="Y" exit /b 0

:: Restore services
set "SVCSNAP=%BACKUPS%\services_snapshot.txt"
if exist "%SVCSNAP%" (
    for /f "usebackq eol=; delims=" %%S in ("%SVCSNAP%") do (
        net start %%S >nul 2>&1
    )
    del /q "%SVCSNAP%" >nul 2>&1
)

:: Restore MMCSS
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 20
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 2
call "%HELPERS%" SetRegSZ "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "Medium"
call "%HELPERS%" SetRegSZ "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "Normal"
call "%HELPERS%" SetRegSZ "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Background Only" "False"

:: Restore Network Throttling
call "%HELPERS%" SetRegDWORD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10

:: Restore Power Throttling
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /f >nul 2>&1

:: Restore Power Plan
if exist "%BACKUPS%\powerplan_snapshot.txt" (
    for /f "usebackq delims=" %%G in ("%BACKUPS%\powerplan_snapshot.txt") do (
        powercfg /setactive %%G >nul 2>&1
    )
    del /q "%BACKUPS%\powerplan_snapshot.txt" >nul 2>&1
)

call "%HELPERS%" PrintOK "%L_Gaming_RestoreDone%"
call "%HELPERS%" Log OK "Gaming mode settings restored to factory defaults"
call "%HELPERS%" PauseKey
exit /b 0


:: ============================================================================
:: Standalone RAM Cleanup
:: ============================================================================
:RamCleanupOnly
call "%HELPERS%" Header "%L_Gaming_RamTitle%"
call :MemSnapshot
set "MEM_BEFORE=%MEM_FREE_MB%"
echo   %C_INFO%%L_Gaming_MemBefore%%C_RESET% %MEM_USED_MB% %L_Gaming_MemOf% %MEM_TOTAL_MB% MB, %L_Gaming_MemFree% %MEM_FREE_MB% MB
echo.
call :EmptyStandbyList
echo.
call :MemSnapshot
set /a MEM_GAINED=%MEM_FREE_MB%-MEM_BEFORE
if %MEM_GAINED% LSS 0 set "MEM_GAINED=0"
echo   %C_INFO%%L_Gaming_MemAfter%%C_RESET% %MEM_USED_MB% %L_Gaming_MemOf% %MEM_TOTAL_MB% MB, %L_Gaming_MemFree% %MEM_FREE_MB% MB
echo   %C_OK%%L_Gaming_Gained% %MEM_GAINED% %L_Gaming_GainedTail%%C_RESET%
call "%HELPERS%" PauseKey
endlocal
exit /b 0


:: ============================================================================
:: Memory Helpers
:: ============================================================================
:MemSnapshot
set "MEM_TOTAL_MB=0" & set "MEM_FREE_MB=0"
for /f "usebackq tokens=1,2" %%A in (`powershell -NoProfile -InputFormat None -Command "$o=Get-CimInstance Win32_OperatingSystem; Write-Host ([math]::Round($o.TotalVisibleMemorySize/1KB)) ([math]::Round($o.FreePhysicalMemory/1KB))" 2^>nul`) do (
    set "MEM_TOTAL_MB=%%A"
    set "MEM_FREE_MB=%%B"
)
set /a MEM_USED_MB=MEM_TOTAL_MB-MEM_FREE_MB
exit /b 0

:EmptyStandbyList
set "RAMMAP="
if exist "%TOOLS%\RAMMap64.exe" set "RAMMAP=%TOOLS%\RAMMap64.exe"
if not defined RAMMAP if exist "%TOOLS%\RAMMap.exe" set "RAMMAP=%TOOLS%\RAMMap.exe"

if defined RAMMAP if "%IS_ADMIN%"=="1" (
    "%RAMMAP%" -accepteula -Ew >nul 2>&1
    call "%HELPERS%" PrintOK "%L_Gaming_RmOK%"
)

:: Zero-dependency native RAM, Standby List, Working Set and Cache Purger
call "%HELPERS%" FlushRAM

if not defined RAMMAP call "%HELPERS%" PrintOK "%L_Gaming_NativeRamOK%"
exit /b 0
