@echo off
:: ============================================================================
::  WindowsOPTGame - Backup.bat
:: ----------------------------------------------------------------------------
::  Pre-change safety net, invoked automatically before any system change
::  (Full Optimization, Gaming Mode registry tweaks) and available manually.
::
::  Creates:
::    - Registry backups of every key this tool may touch
::        Backups\Registry\<timestamp>\*.reg
::    - Configuration backup
::        Backups\settings_<timestamp>.ini
::    - (Restore point creation is delegated to RestorePoint.bat - the
::      single implementation, no duplicated code.)
::
::  Call styles:
::      Backup.bat            - interactive
::      Backup.bat AUTO       - unattended, no pauses (used by other modules)
:: ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog Backup
if not defined TIMESTAMP call "%HELPERS%" Timestamp
set "MODE=%~1"

if /i not "%MODE%"=="AUTO" (
    call "%HELPERS%" Header "%L_Backup_Title%"
    echo   %L_Backup_Intro1%
    echo   %L_Backup_Intro2%
    echo.
)

:: ---------------------------------------------------------------------------
:: 1) Registry backups - every key any module may write to.
::    :BackupRegKey stores them under Backups\Registry\<timestamp>\ and
::    records not-yet-existing keys for clean rollback.
:: ---------------------------------------------------------------------------
echo %C_INFO%  %L_Backup_SecReg%%C_RESET%
call "%HELPERS%" BackupRegKey "HKCU\SOFTWARE\Microsoft\GameBar" GameBar
call "%HELPERS%" BackupRegKey "HKCU\System\GameConfigStore" GameConfigStore
call "%HELPERS%" BackupRegKey "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" GameDVR
call "%HELPERS%" BackupRegKey "HKCU\Control Panel\Desktop" ControlPanelDesktop
if "%IS_ADMIN%"=="1" (
    call "%HELPERS%" BackupRegKey "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" MemoryManagement
    call "%HELPERS%" BackupRegKey "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" SystemProfile
) else (
    call "%HELPERS%" PrintWarn "%L_Backup_HKLMSkipped%"
)
call "%HELPERS%" PrintOK "%L_Backup_RegSetSaved% %REGBACKDIR%"

:: ---------------------------------------------------------------------------
:: 2) Configuration backup
:: ---------------------------------------------------------------------------
echo.
echo %C_INFO%  %L_Backup_SecCfg%%C_RESET%
if exist "%CONFIG%\settings.ini" (
    copy /y "%CONFIG%\settings.ini" "%BACKUPS%\settings_%TIMESTAMP%.ini" >nul
    if errorlevel 1 (
        call "%HELPERS%" PrintFail "%L_Backup_CfgFail%"
    ) else (
        call "%HELPERS%" PrintOK "%L_Backup_CfgSaved% Backups\settings_%TIMESTAMP%.ini"
    )
) else (
    call "%HELPERS%" PrintInfo "%L_Backup_NoCfg%"
)

:: ---------------------------------------------------------------------------
:: 3) Housekeeping - keep the 10 newest registry backup sets, prune the rest.
:: ---------------------------------------------------------------------------
set /a _keep=0
for /f "delims=" %%D in ('dir /b /ad /o-n "%BACKUPS%\Registry" 2^>nul') do (
    set /a _keep+=1
    if !_keep! GTR 10 rd /s /q "%BACKUPS%\Registry\%%D" >nul 2>&1
)
call "%HELPERS%" Log INFO "Backup housekeeping done (kept 10 newest registry sets)"

echo.
call "%HELPERS%" PrintOK "%L_Backup_Complete%"
if /i "%MODE%"=="AUTO" goto :End
echo.
call "%HELPERS%" Confirm "%L_Backup_AskRP%"
if /i "%CONFIRM%"=="Y" call "%MODULES%\RestorePoint.bat" AUTO
call "%HELPERS%" PauseKey
:End
endlocal
exit /b 0
