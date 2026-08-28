@echo off
:: ============================================================================
::  WindowsOPTGame - RestorePoint.bat
:: ----------------------------------------------------------------------------
::  Creates a System Restore Point via the documented Checkpoint-Computer
::  cmdlet. Handles the common gotchas:
::    - System Protection disabled on C:  -> offers to enable it
::    - 24h/1440-minute creation frequency throttle -> temporarily bypassed
::      with the documented SystemRestorePointCreationFrequency value,
::      then restored to its previous state
::    - No admin rights -> clean error, no partial work
::
::  Call styles:
::      RestorePoint.bat          - interactive
::      RestorePoint.bat AUTO     - unattended (used by Tweaks/Backup)
:: ============================================================================
setlocal EnableExtensions
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog RestorePoint
set "MODE=%~1"

if /i not "%MODE%"=="AUTO" call "%HELPERS%" Header "%L_RestorePoint_Title%"

call "%HELPERS%" RequireAdmin || goto :Fail

:: ---------------------------------------------------------------------------
:: 1) Make sure System Protection is enabled on the system drive.
:: ---------------------------------------------------------------------------
call "%HELPERS%" Working "%L_RestorePoint_Checking%"
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "$k='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore';" ^
  "if ((Get-ItemProperty -Path $k -Name RPSessionInterval -ErrorAction SilentlyContinue).RPSessionInterval -eq 1) { exit 0 } else { exit 1 }" >nul 2>&1
if errorlevel 1 (
    call "%HELPERS%" PrintWarn "%L_RestorePoint_SPDisabled% %SystemDrive%"
    call :EnableProtection || goto :Fail
)
goto :CreatePoint

:: Enable System Protection with user consent (auto-consent in AUTO mode).
:EnableProtection
if /i "%MODE%"=="AUTO" (
    set "CONFIRM=Y"
    call "%HELPERS%" Log INFO "AUTO mode - enabling System Protection without prompt"
) else (
    call "%HELPERS%" Confirm "%L_RestorePoint_EnableAsk%"
)
if /i not "%CONFIRM%"=="Y" (
    call "%HELPERS%" PrintFail "%L_RestorePoint_CantCreate%"
    exit /b 1
)
call "%HELPERS%" Exec "%L_RestorePoint_EnableDesc% %SystemDrive%" ^
    "powershell -NoProfile -InputFormat None -Command Enable-ComputerRestore -Drive '%SystemDrive%\'"
exit /b %EXEC_RC%

:CreatePoint

:: ---------------------------------------------------------------------------
:: 2) Create the restore point.
::    Windows throttles restore-point creation (default: one per 24h). The
::    documented SystemRestorePointCreationFrequency value (set to 0) lifts
::    the throttle; we save+restore whatever was there before.
:: ---------------------------------------------------------------------------
set "SRKEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
set "PREV_FREQ="
for /f "tokens=3" %%V in ('reg query "%SRKEY%" /v SystemRestorePointCreationFrequency 2^>nul ^| findstr /i "SystemRestorePointCreationFrequency"') do set "PREV_FREQ=%%V"
reg add "%SRKEY%" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 0 /f >nul 2>&1

call "%HELPERS%" PrintInfo "%L_RestorePoint_Creating%"
call "%HELPERS%" Log EXEC "Checkpoint-Computer -Description 'WindowsOPTGame'"
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "try { Checkpoint-Computer -Description 'WindowsOPTGame' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }" >>"%LOGFILE%" 2>&1
set "RP_RC=%ERRORLEVEL%"

:: Put the throttle value back exactly as it was.
if defined PREV_FREQ (
    reg add "%SRKEY%" /v SystemRestorePointCreationFrequency /t REG_DWORD /d %PREV_FREQ% /f >nul 2>&1
) else (
    reg delete "%SRKEY%" /v SystemRestorePointCreationFrequency /f >nul 2>&1
)

if %RP_RC% NEQ 0 (
    call "%HELPERS%" PrintFail "%L_RestorePoint_CreateFail% %LOGFILE%"
    goto :Fail
)
call "%HELPERS%" PrintOK "%L_RestorePoint_Created%"

:: Show the newest restore points as confirmation (interactive mode only).
if /i not "%MODE%"=="AUTO" (
    echo.
    echo   %C_INFO%%L_RestorePoint_RecentHdr%%C_RESET%
    powershell -NoProfile -InputFormat None -Command ^
      "Get-ComputerRestorePoint | Select-Object -Last 3 | ForEach-Object { Write-Host ('   ' + $_.ConvertToDateTime($_.CreationTime).ToString('yyyy-MM-dd HH:mm') + '  ' + $_.Description) }" 2>nul
    call "%HELPERS%" PauseKey
)
endlocal
exit /b 0

:Fail
if /i not "%MODE%"=="AUTO" call "%HELPERS%" PauseKey
endlocal
exit /b 1
