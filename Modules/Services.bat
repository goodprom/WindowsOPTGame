@echo off
:: ============================================================================
::  WindowsOPTGame - Services.bat
:: ----------------------------------------------------------------------------
::  Service Manager: temporarily stop, restart or restore a curated list of
::  NON-ESSENTIAL services. Start types are never changed, so every service
::  returns on reboot. A snapshot of what was stopped is stored in Backups\
::  so "Restore stopped services" can bring them back on demand.
::
::  Hard rule (enforced twice - here and in Helpers :IsProtectedService):
::  Windows Update, Defender, Security Center, firewall, networking and
::  core OS services can NEVER be stopped or disabled by this tool.
:: ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog Services

:: Curated manageable services: name|friendly description (localized)
set "MSVC_1=SysMain|%L_Services_D1%"
set "MSVC_2=DiagTrack|%L_Services_D2%"
set "MSVC_3=dmwappushservice|%L_Services_D3%"
set "MSVC_4=WSearch|%L_Services_D4%"
set "MSVC_5=Spooler|%L_Services_D5%"
set "MSVC_6=Fax|%L_Services_D6%"
set "MSVC_7=MapsBroker|%L_Services_D7%"
set "MSVC_8=WerSvc|%L_Services_D8%"
set "MSVC_9=RetailDemo|%L_Services_D9%"
set "MSVC_10=TabletInputService|%L_Services_D10%"
set "MSVC_11=PcaSvc|%L_Services_D11%"
set "MSVC_12=wisvc|%L_Services_D12%"
set "MSVC_13=SharedRealitySvc|%L_Services_D13%"
set "MSVC_14=WbioSrvc|%L_Services_D14%"
set "MSVC_COUNT=14"

:SvcMenu
call "%HELPERS%" Header "%L_Services_Title%"
echo   %C_DIM%%L_Services_Note1%%C_RESET%
echo   %C_DIM%%L_Services_Note2%%C_RESET%
echo.
for /l %%i in (1,1,%MSVC_COUNT%) do (
    for /f "tokens=1,2 delims=|" %%A in ("!MSVC_%%i!") do (
        call "%HELPERS%" ServiceState %%A
        if "!SVC_STATE!"=="RUNNING"  set "_st=%C_OK%[RUNNING]%C_RESET%"
        if "!SVC_STATE!"=="STOPPED"  set "_st=%C_DIM%[STOPPED]%C_RESET%"
        if "!SVC_STATE!"=="MISSING"  set "_st=%C_DIM%[  N/A  ]%C_RESET%"
        echo   %C_MENU%[%%i]%C_RESET% !_st! %%A %C_DIM%- %%B%C_RESET%
    )
)
echo.
echo   %C_MENU%[S]%C_RESET% %L_Services_ActStop%         %C_MENU%[R]%C_RESET% %L_Services_ActRestart%
echo   %C_MENU%[A]%C_RESET% %L_Services_ActRestore%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.
set "SVCHOICE="
set /p "SVCHOICE=  %L_Common_SelectAction% "
if /i "%SVCHOICE%"=="S" (call :PickService STOP    & goto :SvcMenu)
if /i "%SVCHOICE%"=="R" (call :PickService RESTART & goto :SvcMenu)
if /i "%SVCHOICE%"=="A" (call :RestoreSnapshot     & call "%HELPERS%" PauseKey & goto :SvcMenu)
if "%SVCHOICE%"=="0" (endlocal & exit /b 0)
goto :SvcMenu

:: ---------------------------------------------------------------------------
:: :PickService <STOP|RESTART>
::   Asks for a number from the curated list, then acts on that service.
:: ---------------------------------------------------------------------------
:PickService
call "%HELPERS%" RequireAdmin || (call "%HELPERS%" PauseKey & exit /b 1)
set "IDX="
set /p "IDX=  %L_Services_PickNumber% (1-%MSVC_COUNT%): "
if not defined IDX exit /b 0
set "TARGET="
for /f "tokens=1 delims=|" %%A in ("!MSVC_%IDX%!") do set "TARGET=%%A"
if not defined TARGET (
    call "%HELPERS%" PrintFail "%L_Common_InvalidSelection%"
    call "%HELPERS%" PauseKey
    exit /b 1
)

:: Defence in depth: verify against the protected list even for curated names.
call "%HELPERS%" IsProtectedService %TARGET%
if "%PROTECTED%"=="1" (
    call "%HELPERS%" PrintFail "%TARGET% %L_Services_Protected%"
    call "%HELPERS%" PauseKey
    exit /b 1
)

call "%HELPERS%" ServiceState %TARGET%
if "%SVC_STATE%"=="MISSING" (
    call "%HELPERS%" PrintWarn "%TARGET% %L_Services_NotInstalled%"
    call "%HELPERS%" PauseKey
    exit /b 0
)

if /i "%~1"=="STOP" (
    if "%SVC_STATE%"=="STOPPED" (
        call "%HELPERS%" PrintInfo "%TARGET% %L_Services_AlreadyStopped%"
    ) else (
        call "%HELPERS%" Exec "%L_Services_StopDesc% %TARGET%" "net stop %TARGET% /y"
        if !EXEC_RC! EQU 0 >>"%BACKUPS%\services_snapshot.txt" echo %TARGET%
    )
) else (
    call "%HELPERS%" Exec "%L_Services_RestartStopDesc% %TARGET%" "net stop %TARGET% /y"
    call "%HELPERS%" Exec "%L_Services_RestartStartDesc% %TARGET%" "net start %TARGET%"
)
call "%HELPERS%" PauseKey
exit /b 0

:: ---------------------------------------------------------------------------
:: :RestoreSnapshot
::   Restarts every service recorded in Backups\services_snapshot.txt,
::   then clears the snapshot. Shared with Restore.bat behaviour.
:: ---------------------------------------------------------------------------
:RestoreSnapshot
call "%HELPERS%" RequireAdmin || exit /b 1
set "SVCSNAP=%BACKUPS%\services_snapshot.txt"
if not exist "%SVCSNAP%" (
    call "%HELPERS%" PrintInfo "%L_Services_NoSnapshot%"
    exit /b 0
)
echo.
for /f "usebackq eol=; delims=" %%S in ("%SVCSNAP%") do (
    call "%HELPERS%" ServiceState %%S
    if "!SVC_STATE!"=="STOPPED" (
        call "%HELPERS%" Exec "%L_Services_RestartDesc% %%S" "net start %%S"
    ) else (
        call "%HELPERS%" PrintInfo "%%S %L_Services_AlreadyRunning%"
    )
)
del /q "%SVCSNAP%" >nul 2>&1
call "%HELPERS%" PrintOK "%L_Services_SnapshotDone%"
exit /b 0
