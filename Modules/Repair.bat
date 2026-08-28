@echo off
:: ============================================================================
::  WindowsOPTGame - Repair.bat
:: ----------------------------------------------------------------------------
::  Windows integrity repair using only documented Microsoft tooling:
::    - SFC /SCANNOW                       (System File Checker)
::    - DISM /Online /Cleanup-Image ...    (ScanHealth / RestoreHealth)
::    - DISM /StartComponentCleanup        (WinSxS component store cleanup)
::    - CHKDSK read-only scan              (schedules full check on demand)
::  A plain-text repair report is generated in Logs\.
::
::  Call styles:
::      Repair.bat           - interactive menu
::      Repair.bat AUTO      - SFC + DISM RestoreHealth + component cleanup
:: ============================================================================
setlocal EnableExtensions
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog Repair
if not defined TIMESTAMP call "%HELPERS%" Timestamp
set "REPORT=%LOGS%\RepairReport_%TIMESTAMP%.txt"

if /i "%~1"=="AUTO" (
    call "%HELPERS%" RequireAdmin || (endlocal & exit /b 1)
    call :ReportHeader
    call :RunSFC
    call :RunDISMRestore
    call :RunComponentCleanup
    call :ReportFooter
    endlocal
    exit /b 0
)

:RepMenu
call "%HELPERS%" Header "%L_Repair_Title%"
echo   %C_DIM%%L_Repair_Note%%C_RESET%
echo.
echo   %C_MENU%[1]%C_RESET% SFC /SCANNOW                 %C_DIM%%L_Repair_D1%%C_RESET%
echo   %C_MENU%[2]%C_RESET% DISM ScanHealth              %C_DIM%%L_Repair_D2%%C_RESET%
echo   %C_MENU%[3]%C_RESET% DISM RestoreHealth           %C_DIM%%L_Repair_D3%%C_RESET%
echo   %C_MENU%[4]%C_RESET% DISM Component Cleanup       %C_DIM%%L_Repair_D4%%C_RESET%
echo   %C_MENU%[5]%C_RESET% CHKDSK                       %C_DIM%%L_Repair_D5%%C_RESET%
echo   %C_MENU%[6]%C_RESET% %L_Repair_M6%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.
set "RCHOICE="
set /p "RCHOICE=  %L_Common_SelectOption% "
if "%RCHOICE%"=="0" (endlocal & exit /b 0)

call "%HELPERS%" RequireAdmin || (call "%HELPERS%" PauseKey & goto :RepMenu)

if "%RCHOICE%"=="1" (call :RunSFC              & call "%HELPERS%" PauseKey & goto :RepMenu)
if "%RCHOICE%"=="2" (call :RunDISMScan         & call "%HELPERS%" PauseKey & goto :RepMenu)
if "%RCHOICE%"=="3" (call :RunDISMRestore      & call "%HELPERS%" PauseKey & goto :RepMenu)
if "%RCHOICE%"=="4" (call :RunComponentCleanup & call "%HELPERS%" PauseKey & goto :RepMenu)
if "%RCHOICE%"=="5" (call :RunChkdsk           & call "%HELPERS%" PauseKey & goto :RepMenu)
if "%RCHOICE%"=="6" goto :FullRepair
goto :RepMenu

:FullRepair
call :ReportHeader
call :RunDISMScan
call :RunDISMRestore
call :RunSFC
call :RunComponentCleanup
call :RunChkdsk
call :ReportFooter
echo.
echo   %C_OK%%L_Repair_SeqDone%%C_RESET% %L_Repair_ReportLbl% %C_WHITE%%REPORT%%C_RESET%
call "%HELPERS%" PauseKey
goto :RepMenu

:: ---------------------------------------------------------------------------
:: Report helpers - repair steps append their verdicts to a readable report.
:: ---------------------------------------------------------------------------
:ReportHeader
> "%REPORT%" echo ==========================================================
>>"%REPORT%" echo  Windows Repair Report - %DATE% %TIME%
>>"%REPORT%" echo ==========================================================
exit /b 0

:ReportFooter
>>"%REPORT%" echo.
>>"%REPORT%" echo Detailed command output: %LOGFILE%
>>"%REPORT%" echo Also check: %%WinDir%%\Logs\CBS\CBS.log and %%WinDir%%\Logs\DISM\dism.log
call "%HELPERS%" Log OK "Repair report written: %REPORT%"
exit /b 0

:Verdict
>>"%REPORT%" echo [%~1] %~2
exit /b 0

:: ---------------------------------------------------------------------------
:RunSFC
echo.
call "%HELPERS%" PrintInfo "%L_Repair_SFCStart%"
call "%HELPERS%" Log EXEC "sfc /scannow"
:: SFC writes progress to the console; show it live, capture the verdict after.
sfc /scannow
set "RC=%ERRORLEVEL%"
if %RC% EQU 0 (
    call "%HELPERS%" PrintOK "%L_Repair_SFCOK%"
    call :Verdict OK "SFC /SCANNOW completed (exit code 0)"
) else (
    call "%HELPERS%" PrintWarn "%L_Repair_SFCWarn% %RC%"
    call :Verdict WARN "SFC /SCANNOW exit code %RC% - review CBS.log"
)
exit /b %RC%

:: ---------------------------------------------------------------------------
:RunDISMScan
echo.
call "%HELPERS%" PrintInfo "%L_Repair_ScanStart%"
call "%HELPERS%" Log EXEC "dism /online /cleanup-image /scanhealth"
dism /online /cleanup-image /scanhealth
set "RC=%ERRORLEVEL%"
if %RC% EQU 0 (
    call "%HELPERS%" PrintOK "%L_Repair_ScanOK%"
    call :Verdict OK "DISM ScanHealth completed (exit code 0)"
) else (
    call "%HELPERS%" PrintWarn "%L_Repair_ScanWarn% %RC%"
    call :Verdict WARN "DISM ScanHealth exit code %RC%"
)
exit /b %RC%

:: ---------------------------------------------------------------------------
:RunDISMRestore
echo.
call "%HELPERS%" PrintInfo "%L_Repair_RestoreStart%"
call "%HELPERS%" Log EXEC "dism /online /cleanup-image /restorehealth"
dism /online /cleanup-image /restorehealth
set "RC=%ERRORLEVEL%"
if %RC% EQU 0 (
    call "%HELPERS%" PrintOK "%L_Repair_RestoreOK%"
    call :Verdict OK "DISM RestoreHealth completed (exit code 0)"
) else (
    call "%HELPERS%" PrintFail "%L_Repair_RestoreFail% %RC%"
    call :Verdict FAIL "DISM RestoreHealth exit code %RC% - review dism.log"
)
exit /b %RC%

:: ---------------------------------------------------------------------------
:RunComponentCleanup
echo.
call "%HELPERS%" PrintInfo "%L_Repair_CompStart%"
call "%HELPERS%" Log EXEC "dism /online /cleanup-image /startcomponentcleanup"
dism /online /cleanup-image /startcomponentcleanup
set "RC=%ERRORLEVEL%"
if %RC% EQU 0 (
    call "%HELPERS%" PrintOK "%L_Repair_CompOK%"
    call :Verdict OK "DISM StartComponentCleanup completed"
) else (
    call "%HELPERS%" PrintWarn "%L_Repair_CompWarn% %RC%"
    call :Verdict WARN "DISM StartComponentCleanup exit code %RC%"
)
exit /b %RC%

:: ---------------------------------------------------------------------------
:RunChkdsk
echo.
call "%HELPERS%" PrintInfo "%L_Repair_ChkStart% %SystemDrive% ..."
call "%HELPERS%" Log EXEC "chkdsk %SystemDrive%"
chkdsk %SystemDrive%
set "RC=%ERRORLEVEL%"
if %RC% EQU 0 (
    call "%HELPERS%" PrintOK "%L_Repair_ChkOK%"
    call :Verdict OK "CHKDSK read-only scan clean"
) else (
    call "%HELPERS%" PrintWarn "%L_Repair_ChkWarn% %RC%"
    call :Verdict WARN "CHKDSK exit code %RC% - errors were found"
    call :OfferFullScan
)
exit /b %RC%

:OfferFullScan
call "%HELPERS%" Confirm "%L_Repair_OfferFull%"
if /i not "%CONFIRM%"=="Y" exit /b 0
echo Y | chkdsk %SystemDrive% /f >nul 2>&1
call "%HELPERS%" PrintOK "%L_Repair_FullScheduled%"
call :Verdict INFO "Full chkdsk /f scheduled at next reboot"
exit /b 0
