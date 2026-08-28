@echo off
:: ============================================================================
::  WindowsOPTGame - Diagnostics.bat
:: ----------------------------------------------------------------------------
::  SSD / HDD diagnostics - strictly read-only:
::    - Physical disk inventory (model, media type, bus, size)
::    - Health / SMART status (Get-PhysicalDisk + StorageReliabilityCounter)
::    - Temperature, wear and power-on hours where the drive exposes them
::    - Volume fragmentation analysis (defrag /A - analysis only)
::    - TRIM status for SSDs
::  Nothing is written to any disk except the log/report in Logs\.
:: ============================================================================
setlocal EnableExtensions
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog Diagnostics
if not defined TIMESTAMP call "%HELPERS%" Timestamp

:DiagMenu
call "%HELPERS%" Header "%L_Diagnostics_Title%"
echo   %C_DIM%%L_Diagnostics_Note%%C_RESET%
echo.
echo   %C_MENU%[1]%C_RESET% %L_Diagnostics_M1%
echo   %C_MENU%[2]%C_RESET% %L_Diagnostics_M2%
echo   %C_MENU%[3]%C_RESET% %L_Diagnostics_M3%
echo   %C_MENU%[4]%C_RESET% %L_Diagnostics_M4%
echo   %C_MENU%[5]%C_RESET% %L_Diagnostics_M5%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.
set "DCHOICE="
set /p "DCHOICE=  %L_Common_SelectOption% "
if "%DCHOICE%"=="1" (call :HealthOverview & call "%HELPERS%" PauseKey & goto :DiagMenu)
if "%DCHOICE%"=="2" (call :Reliability    & call "%HELPERS%" PauseKey & goto :DiagMenu)
if "%DCHOICE%"=="3" (call :FragAnalysis   & call "%HELPERS%" PauseKey & goto :DiagMenu)
if "%DCHOICE%"=="4" (call :TrimStatus     & call "%HELPERS%" PauseKey & goto :DiagMenu)
if "%DCHOICE%"=="5" (call :FullReport     & call "%HELPERS%" PauseKey & goto :DiagMenu)
if "%DCHOICE%"=="0" (endlocal & exit /b 0)
goto :DiagMenu

:: ---------------------------------------------------------------------------
:HealthOverview
echo.
call "%HELPERS%" Working "%L_Diagnostics_QueryHealth%"
call "%HELPERS%" Log EXEC "Get-PhysicalDisk health overview"
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "Get-PhysicalDisk | ForEach-Object {" ^
  "  $c = if ($_.HealthStatus -eq 'Healthy') {'Green'} else {'Red'};" ^
  "  Write-Host ('  ' + $_.FriendlyName) -NoNewline;" ^
  "  Write-Host ('  [' + $_.MediaType + ', ' + $_.BusType + ', ' + [math]::Round($_.Size/1GB) + ' GB]') -NoNewline;" ^
  "  Write-Host ('  ' + $_.HealthStatus) -ForegroundColor $c }"
if errorlevel 1 (
    call "%HELPERS%" PrintFail "%L_Diagnostics_QueryFail%"
    exit /b 1
)
echo.
call "%HELPERS%" PrintInfo "%L_Diagnostics_HealthyNote%"
exit /b 0

:: ---------------------------------------------------------------------------
:Reliability
echo.
call "%HELPERS%" Working "%L_Diagnostics_ReadingCounters%"
call "%HELPERS%" Log EXEC "Get-StorageReliabilityCounter"
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "$found=$false;" ^
  "Get-PhysicalDisk | ForEach-Object {" ^
  "  $r = $_ | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue;" ^
  "  if ($r) { $found=$true;" ^
  "    Write-Host ('  --- ' + $_.FriendlyName + ' ---');" ^
  "    if ($null -ne $r.Temperature -and $r.Temperature -gt 0) { Write-Host ('  Temperature    : ' + $r.Temperature + ' C') };" ^
  "    if ($null -ne $r.Wear) { Write-Host ('  Wear           : ' + $r.Wear + ' percent used') };" ^
  "    if ($null -ne $r.PowerOnHours) { Write-Host ('  Power-on hours : ' + $r.PowerOnHours) };" ^
  "    Write-Host ('  Read errors    : ' + $r.ReadErrorsTotal);" ^
  "    Write-Host ('  Write errors   : ' + $r.WriteErrorsTotal);" ^
  "    Write-Host '' } };" ^
  "if (-not $found) { Write-Host '  This system does not expose reliability counters (common on some NVMe/USB drives).' }"
if "%IS_ADMIN%"=="0" call "%HELPERS%" PrintWarn "%L_Diagnostics_CountersNeedAdmin%"
exit /b 0

:: ---------------------------------------------------------------------------
:FragAnalysis
call "%HELPERS%" RequireAdmin || exit /b 1
echo.
call "%HELPERS%" PrintInfo "%L_Diagnostics_FragStart%"
call "%HELPERS%" Log EXEC "defrag %SystemDrive% /A"
defrag %SystemDrive% /A
if errorlevel 1 (
    call "%HELPERS%" PrintWarn "%L_Diagnostics_FragWarn%"
    exit /b 1
)
call "%HELPERS%" PrintOK "%L_Diagnostics_FragOK%"
call "%HELPERS%" PrintInfo "%L_Diagnostics_FragSSDNote%"
exit /b 0

:: ---------------------------------------------------------------------------
:TrimStatus
echo.
call "%HELPERS%" Log EXEC "fsutil behavior query DisableDeleteNotify"
:: "<nul" is required: fsutil consumes all remaining stdin when it is
:: redirected (same family as choice/pause), which would starve the menu.
<nul fsutil behavior query DisableDeleteNotify 2>nul | findstr /i "= 0" >nul
if errorlevel 1 (
    <nul fsutil behavior query DisableDeleteNotify
    call "%HELPERS%" PrintWarn "%L_Diagnostics_TrimWarn%"
    call "%HELPERS%" PrintInfo "%L_Diagnostics_TrimHint%"
) else (
    call "%HELPERS%" PrintOK "%L_Diagnostics_TrimOK%"
)
exit /b 0

:: ---------------------------------------------------------------------------
:FullReport
set "DIAGREPORT=%LOGS%\DiskReport_%TIMESTAMP%.txt"
echo.
call "%HELPERS%" Working "%L_Diagnostics_Building%"
> "%DIAGREPORT%" echo ==========================================================
>>"%DIAGREPORT%" echo  Disk Diagnostics Report - %DATE% %TIME%
>>"%DIAGREPORT%" echo ==========================================================
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "Get-PhysicalDisk | ForEach-Object {" ^
  "  Write-Output ('Disk    : ' + $_.FriendlyName);" ^
  "  Write-Output ('Type    : ' + $_.MediaType + ' on ' + $_.BusType);" ^
  "  Write-Output ('Size    : ' + [math]::Round($_.Size/1GB) + ' GB');" ^
  "  Write-Output ('Health  : ' + $_.HealthStatus + ' / ' + $_.OperationalStatus);" ^
  "  $r = $_ | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue;" ^
  "  if ($r) {" ^
  "    if ($null -ne $r.Temperature -and $r.Temperature -gt 0) { Write-Output ('Temp    : ' + $r.Temperature + ' C') };" ^
  "    if ($null -ne $r.Wear) { Write-Output ('Wear    : ' + $r.Wear + ' percent') };" ^
  "    if ($null -ne $r.PowerOnHours) { Write-Output ('Hours   : ' + $r.PowerOnHours) } };" ^
  "  Write-Output '' };" ^
  "Get-Volume | Where-Object DriveLetter | ForEach-Object {" ^
  "  Write-Output ('Volume ' + $_.DriveLetter + ': ' + $_.FileSystem + ', ' + [math]::Round($_.SizeRemaining/1GB) + ' GB free of ' + [math]::Round($_.Size/1GB) + ' GB, health ' + $_.HealthStatus) }" ^
  >> "%DIAGREPORT%" 2>nul
if errorlevel 1 (
    call "%HELPERS%" PrintFail "%L_Diagnostics_ReportFail%"
    exit /b 1
)
call "%HELPERS%" PrintOK "%L_Diagnostics_ReportSaved% %DIAGREPORT%"
exit /b 0
