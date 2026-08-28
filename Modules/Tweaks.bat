@echo off
:: ============================================================================
::  WindowsOPTGame - Tweaks.bat
:: ----------------------------------------------------------------------------
::  Orchestrator for [1] Full System Optimization. It contains NO cleanup or
::  repair logic of its own - it sequences the other modules in their
::  unattended (AUTO) modes, tracks phase progress, and writes a final
::  human-readable optimization report.
::
::  Sequence:
::    Phase 1  Restore Point            (RestorePoint.bat AUTO)
::    Phase 2  Registry/Config Backup   (Backup.bat AUTO)
::    Phase 3  Full Cleanup             (Cleanup.bat AUTO)
::    Phase 4  Network refresh          (Network.bat AUTO)
::    Phase 5  System repair            (Repair.bat AUTO: SFC+DISM+cleanup)
::    Phase 6  CHKDSK read-only scan    (optional, config-driven)
::    Phase 7  Report
::
::  Call style:  Tweaks.bat FULL
:: ============================================================================
setlocal EnableExtensions
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog FullOptimization
call "%HELPERS%" LoadConfig
if not defined TIMESTAMP call "%HELPERS%" Timestamp
set "OPTREPORT=%LOGS%\OptimizationReport_%TIMESTAMP%.txt"

call "%HELPERS%" Header "%L_Tweaks_Title%"
echo   %L_Tweaks_Intro%
echo.
echo    %L_Tweaks_S1%
echo    %L_Tweaks_S2%
echo    %L_Tweaks_S3%
echo    %L_Tweaks_S4%
echo    %L_Tweaks_S5%
if "%CFG_RunChkdskInFullOptimization%"=="1" echo    %L_Tweaks_S6%
echo    %L_Tweaks_S7%
echo.
echo   %C_WARN%%L_Tweaks_TimeNote%%C_RESET%
echo   %C_DIM%%L_Tweaks_RebootNote%%C_RESET%
echo.

call "%HELPERS%" RequireAdmin || goto :Abort

call "%HELPERS%" Confirm "%L_Tweaks_ConfirmStart%"
if /i not "%CONFIRM%"=="Y" goto :Abort
echo.

:: WGO_AUTO tells Confirm in child modules to auto-answer when the user has
:: disabled per-action confirmations in Settings.
set "WGO_AUTO=1"
set "PHASES=7"
set "PHASE_RESULTS="

call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set "OPT_START_FREE=%FREESPACE_MB%"

> "%OPTREPORT%" echo ==========================================================
>>"%OPTREPORT%" echo  Full System Optimization Report - %DATE% %TIME%
>>"%OPTREPORT%" echo ==========================================================

:: ------------------------- Phase 1: Restore Point --------------------------
call "%HELPERS%" ProgressBar 0 %PHASES% "%L_Tweaks_Ph1%"
echo.
call "%MODULES%\RestorePoint.bat" AUTO
set "RP_RC=%ERRORLEVEL%"
call :Record 1 "System Restore Point" %RP_RC%
if %RP_RC% NEQ 0 (
    echo.
    call "%HELPERS%" PrintWarn "%L_Tweaks_RPFailed%"
    call "%HELPERS%" Confirm "%L_Tweaks_ContinueAsk%"
)
if %RP_RC% NEQ 0 if /i not "%CONFIRM%"=="Y" goto :Abort

:: ------------------------- Phase 2: Backups --------------------------------
echo.
call "%HELPERS%" ProgressBar 1 %PHASES% "%L_Tweaks_Ph2%"
echo.
call "%MODULES%\Backup.bat" AUTO
call :Record 2 "Registry and configuration backup" %ERRORLEVEL%

:: ------------------------- Phase 3: Cleanup --------------------------------
echo.
call "%HELPERS%" ProgressBar 2 %PHASES% "%L_Tweaks_Ph3%"
echo.
call "%MODULES%\Cleanup.bat" AUTO
call "%MODULES%\ProcessOptimizer.bat" AUTO
call :Record 3 "Windows cleanup and process optimization" %ERRORLEVEL%

:: ------------------------- Phase 4: Network --------------------------------
echo.
call "%HELPERS%" ProgressBar 3 %PHASES% "%L_Tweaks_Ph4%"
echo.
call "%MODULES%\Network.bat" AUTO
call :Record 4 "Network refresh (DNS/Winsock/TCPIP)" %ERRORLEVEL%

:: ------------------------- Phase 5: Repair ---------------------------------
echo.
call "%HELPERS%" ProgressBar 4 %PHASES% "%L_Tweaks_Ph5%"
echo.
call "%MODULES%\Repair.bat" AUTO
call :Record 5 "System repair (SFC + DISM + component cleanup)" %ERRORLEVEL%

:: ------------------------- Phase 6: CHKDSK ---------------------------------
echo.
call "%HELPERS%" ProgressBar 5 %PHASES% "%L_Tweaks_Ph6%"
echo.
if "%CFG_RunChkdskInFullOptimization%"=="1" (
    call :RunDiskScan
) else (
    call "%HELPERS%" PrintInfo "%L_Tweaks_ChkSkipped%"
    call :Record 6 "CHKDSK (skipped by settings)" 0
)
goto :Phase7

:RunDiskScan
call "%HELPERS%" Log EXEC "chkdsk %SystemDrive% (read-only)"
chkdsk %SystemDrive%
call :Record 6 "CHKDSK read-only scan" %ERRORLEVEL%
exit /b 0

:Phase7

:: ------------------------- Phase 7: Report ---------------------------------
echo.
call "%HELPERS%" ProgressBar 6 %PHASES% "%L_Tweaks_Ph7%"
echo.
call "%HELPERS%" GetFreeSpace %SystemDrive:~0,1%
set /a OPT_FREED=%FREESPACE_MB%-OPT_START_FREE
if %OPT_FREED% LSS 0 set "OPT_FREED=0"
>>"%OPTREPORT%" echo.
>>"%OPTREPORT%" echo Disk space freed on %SystemDrive% : approx. %OPT_FREED% MB
>>"%OPTREPORT%" echo Session log               : %LOGFILE%
>>"%OPTREPORT%" echo Registry backups          : %BACKUPS%\Registry\
>>"%OPTREPORT%" echo.
>>"%OPTREPORT%" echo Recommendation: reboot to complete Winsock/TCPIP resets
>>"%OPTREPORT%" echo and to let Windows finish any pending repairs.
call :Record 7 "Report generation" 0
call "%HELPERS%" ProgressBar 7 %PHASES% "%L_Tweaks_PhDone%"

:: ------------------------- Summary ------------------------------------------
echo.
call "%HELPERS%" HR
echo   %C_OK%%L_Tweaks_Finished%%C_RESET%
echo.
echo   %L_Tweaks_FreedLbl% %C_WHITE%~%OPT_FREED% MB%C_RESET%
echo   %L_Tweaks_ReportLbl% %C_WHITE%%OPTREPORT%%C_RESET%
echo   %L_Tweaks_LogLbl% %C_DIM%%LOGFILE%%C_RESET%
echo.
echo   %C_WARN%%L_Tweaks_RebootFinal%%C_RESET%
call "%HELPERS%" Log OK "Full optimization pipeline complete - %OPT_FREED% MB freed"
set "WGO_AUTO="
call "%HELPERS%" PauseKey
endlocal
exit /b 0

:Abort
set "WGO_AUTO="
call "%HELPERS%" Log WARN "Full optimization aborted before completion"
echo.
echo   %C_WARN%%L_Tweaks_Aborted%%C_RESET%
call "%HELPERS%" PauseKey
endlocal
exit /b 1

:: ---------------------------------------------------------------------------
:: :Record <phase#> <name> <exitcode>  - appends a phase verdict to the report
:: ---------------------------------------------------------------------------
:Record
set "_verdict=OK  "
if not "%~3"=="0" set "_verdict=WARN"
>>"%OPTREPORT%" echo [%_verdict%] Phase %~1: %~2 - exit code %~3
exit /b 0
