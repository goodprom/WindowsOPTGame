@echo off
:: ============================================================================
::  WindowsOPTGame - Restore.bat
:: ----------------------------------------------------------------------------
::  "Restore Previous Settings" - the undo button for everything this tool
::  changed:
::    [1] Restart services stopped by Gaming Mode / Service Manager
::    [2] Re-import registry backups (Backups\Registry\<timestamp>\*.reg)
::    [3] Restore the previous power plan
::    [4] Restore a configuration backup (settings.ini)
::    [5] Open Windows System Restore (rstrui) for full rollback
:: ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog Restore

:ResMenu
call "%HELPERS%" Header "%L_Restore_Title%"
echo   %C_MENU%[1]%C_RESET% %L_Restore_M1%
echo   %C_MENU%[2]%C_RESET% %L_Restore_M2%
echo   %C_MENU%[3]%C_RESET% %L_Restore_M3%
echo   %C_MENU%[4]%C_RESET% %L_Restore_M4%
echo   %C_MENU%[5]%C_RESET% %L_Restore_M5%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.
set "RCHOICE="
set /p "RCHOICE=  %L_Common_SelectOption% "
if "%RCHOICE%"=="1" (call :RestoreServices  & call "%HELPERS%" PauseKey & goto :ResMenu)
if "%RCHOICE%"=="2" (call :RestoreRegistry  & call "%HELPERS%" PauseKey & goto :ResMenu)
if "%RCHOICE%"=="3" (call :RestorePower     & call "%HELPERS%" PauseKey & goto :ResMenu)
if "%RCHOICE%"=="4" (call :RestoreConfig    & call "%HELPERS%" PauseKey & goto :ResMenu)
if "%RCHOICE%"=="5" (call :OpenSystemRestore & goto :ResMenu)
if "%RCHOICE%"=="0" (endlocal & exit /b 0)
goto :ResMenu

:: ---------------------------------------------------------------------------
:: [1] Services - delegate to the single implementation in Services.bat
::     (no duplicated code: Services.bat RESTORESNAPSHOT runs it headless).
:: ---------------------------------------------------------------------------
:RestoreServices
set "SVCSNAP=%BACKUPS%\services_snapshot.txt"
if not exist "%SVCSNAP%" (
    call "%HELPERS%" PrintInfo "%L_Restore_NoSnapshot%"
    exit /b 0
)
call "%HELPERS%" RequireAdmin || exit /b 1
for /f "usebackq eol=; delims=" %%S in ("%SVCSNAP%") do (
    call "%HELPERS%" ServiceState %%S
    if "!SVC_STATE!"=="STOPPED" (
        call "%HELPERS%" Exec "%L_Services_RestartDesc% %%S" "net start %%S"
    ) else (
        call "%HELPERS%" PrintInfo "%%S %L_Services_AlreadyRunning%"
    )
)
del /q "%SVCSNAP%" >nul 2>&1
call "%HELPERS%" PrintOK "%L_Restore_SvcRestored%"
exit /b 0

:: ---------------------------------------------------------------------------
:: [2] Registry - list timestamped backup sets, import the chosen one.
:: ---------------------------------------------------------------------------
:RestoreRegistry
call "%HELPERS%" RequireAdmin || exit /b 1
set "REGROOT=%BACKUPS%\Registry"
set /a _n=0
echo.
echo   %L_Restore_RegSetsHdr%
for /d %%D in ("%REGROOT%\*") do (
    set /a _n+=1
    set "REGSET_!_n!=%%~fD"
    echo   %C_MENU%[!_n!]%C_RESET% %%~nxD
)
if %_n% EQU 0 (
    call "%HELPERS%" PrintInfo "%L_Restore_NoRegBackups%"
    exit /b 0
)
echo.
set "PICK="
set /p "PICK=  %L_Restore_PickSet% (1-%_n%): "
if not defined PICK exit /b 0
set "PICKDIR=!REGSET_%PICK%!"
if not defined PICKDIR (
    call "%HELPERS%" PrintFail "%L_Common_InvalidSelection%"
    exit /b 1
)
call "%HELPERS%" Confirm "%L_Restore_ConfirmImport%"
if /i not "%CONFIRM%"=="Y" exit /b 0

set /a _imported=0
for %%F in ("%PICKDIR%\*.reg") do (
    reg import "%%F" >nul 2>&1
    if errorlevel 1 (
        call "%HELPERS%" PrintFail "%L_Restore_ImportFail% %%~nxF"
    ) else (
        set /a _imported+=1
        call "%HELPERS%" PrintOK "%L_Restore_Imported% %%~nxF"
    )
)
:: Keys that did not exist before our tweaks were recorded in
:: _created_keys.txt - remove the values we added so state matches the backup.
if exist "%PICKDIR%\_created_keys.txt" (
    for /f "usebackq delims=" %%K in ("%PICKDIR%\_created_keys.txt") do (
        reg delete "%%K" /f >nul 2>&1
        call "%HELPERS%" PrintOK "%L_Restore_RemovedKey% %%K"
    )
)
echo.
call "%HELPERS%" PrintOK "%L_Restore_RegDone% %_imported%"
call "%HELPERS%" PrintInfo "%L_Restore_SignOut%"
exit /b 0

:: ---------------------------------------------------------------------------
:: [3] Power plan
:: ---------------------------------------------------------------------------
:RestorePower
if not exist "%BACKUPS%\powerplan_snapshot.txt" (
    call "%HELPERS%" PrintInfo "%L_Restore_NoPower%"
    exit /b 0
)
set "PREV_SCHEME="
for /f "usebackq delims=" %%G in ("%BACKUPS%\powerplan_snapshot.txt") do set "PREV_SCHEME=%%G"
if not defined PREV_SCHEME (
    call "%HELPERS%" PrintWarn "%L_Restore_PowerEmpty%"
    exit /b 1
)
call "%HELPERS%" Exec "%L_Restore_RestorePlanDesc% %PREV_SCHEME%" "powercfg /setactive %PREV_SCHEME%"
if %EXEC_RC% EQU 0 del /q "%BACKUPS%\powerplan_snapshot.txt" >nul 2>&1
exit /b %EXEC_RC%

:: ---------------------------------------------------------------------------
:: [4] Configuration backup (created by Backup.bat)
:: ---------------------------------------------------------------------------
:RestoreConfig
set /a _n=0
echo.
for %%F in ("%BACKUPS%\settings_*.ini") do (
    set /a _n+=1
    set "CFGBAK_!_n!=%%~fF"
    echo   %C_MENU%[!_n!]%C_RESET% %%~nxF
)
if %_n% EQU 0 (
    call "%HELPERS%" PrintInfo "%L_Restore_NoCfgBackups%"
    exit /b 0
)
echo.
set "PICK="
set /p "PICK=  %L_Restore_PickCfg% (1-%_n%): "
if not defined PICK exit /b 0
set "PICKFILE=!CFGBAK_%PICK%!"
if not defined PICKFILE (
    call "%HELPERS%" PrintFail "%L_Common_InvalidSelection%"
    exit /b 1
)
copy /y "%PICKFILE%" "%CONFIG%\settings.ini" >nul 2>&1
if errorlevel 1 (
    call "%HELPERS%" PrintFail "%L_Restore_CfgFail%"
    exit /b 1
)
call "%HELPERS%" LoadConfig
call "%HELPERS%" PrintOK "%L_Restore_CfgOK% %PICKFILE%"
exit /b 0

:: ---------------------------------------------------------------------------
:: [5] Full system rollback via the Windows System Restore wizard.
:: ---------------------------------------------------------------------------
:OpenSystemRestore
call "%HELPERS%" Log EXEC "Launching rstrui.exe (System Restore wizard)"
call "%HELPERS%" PrintInfo "%L_Restore_OpeningRstrui%"
start "" rstrui.exe
exit /b 0
