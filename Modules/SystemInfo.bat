@echo off
:: ============================================================================
::  WindowsOPTGame - SystemInfo.bat
:: ----------------------------------------------------------------------------
::  Read-only hardware and OS inventory:
::    Windows version/build, CPU, GPU, RAM modules, motherboard, BIOS,
::    disks (+ SMART status when exposed), network adapters, admin state.
::  Offers to export the report to Logs\.
:: ============================================================================
setlocal EnableExtensions
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog SystemInfo
if not defined TIMESTAMP call "%HELPERS%" Timestamp
set "SIREPORT=%TEMP%\wgo_systeminfo.txt"

call "%HELPERS%" Header "%L_SystemInfo_Title%"
call "%HELPERS%" Working "%L_SystemInfo_Collecting%"

:: One PowerShell pass builds the whole report; batch then displays it.
:: Keeping the query in PowerShell/CIM avoids a dozen slow wmic calls
:: (wmic is deprecated and removed from recent Windows 11 builds).
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "$os=Get-CimInstance Win32_OperatingSystem;" ^
  "$cs=Get-CimInstance Win32_ComputerSystem;" ^
  "Write-Output ('%L_SystemInfo_SecOS%');" ^
  "Write-Output ('  Edition   : ' + $os.Caption);" ^
  "Write-Output ('  Version   : ' + $os.Version + '  (build ' + $os.BuildNumber + ')');" ^
  "Write-Output ('  Installed : ' + $os.InstallDate.ToString('yyyy-MM-dd'));" ^
  "Write-Output ('  Uptime    : ' + ((Get-Date)-$os.LastBootUpTime).ToString('d\d\ h\h\ m\m'));" ^
  "Write-Output '';" ^
  "Write-Output ('%L_SystemInfo_SecCPU%');" ^
  "Get-CimInstance Win32_Processor | ForEach-Object {" ^
  "  Write-Output ('  Model     : ' + $_.Name.Trim());" ^
  "  Write-Output ('  Cores     : ' + $_.NumberOfCores + ' physical / ' + $_.NumberOfLogicalProcessors + ' logical');" ^
  "  Write-Output ('  Max clock : ' + $_.MaxClockSpeed + ' MHz') };" ^
  "Write-Output '';" ^
  "Write-Output ('%L_SystemInfo_SecGPU%');" ^
  "Get-CimInstance Win32_VideoController | ForEach-Object {" ^
  "  Write-Output ('  Model     : ' + $_.Name);" ^
  "  if ($_.AdapterRAM -gt 0) { Write-Output ('  VRAM      : ' + [math]::Round($_.AdapterRAM/1GB,1) + ' GB (as reported by WMI)') };" ^
  "  Write-Output ('  Driver    : ' + $_.DriverVersion) };" ^
  "Write-Output '';" ^
  "Write-Output ('%L_SystemInfo_SecRAM%');" ^
  "Write-Output ('  Total     : ' + [math]::Round($cs.TotalPhysicalMemory/1GB,1) + ' GB');" ^
  "Get-CimInstance Win32_PhysicalMemory | ForEach-Object {" ^
  "  Write-Output ('  Module    : ' + [math]::Round($_.Capacity/1GB) + ' GB @ ' + $_.Speed + ' MHz  [' + $_.Manufacturer.Trim() + ']  slot ' + $_.DeviceLocator) };" ^
  "Write-Output '';" ^
  "Write-Output ('%L_SystemInfo_SecBoard%');" ^
  "$bb=Get-CimInstance Win32_BaseBoard; $bi=Get-CimInstance Win32_BIOS;" ^
  "Write-Output ('  Board     : ' + $bb.Manufacturer + ' ' + $bb.Product);" ^
  "Write-Output ('  BIOS      : ' + $bi.Manufacturer + ' ' + $bi.SMBIOSBIOSVersion + '  (' + $bi.ReleaseDate.ToString('yyyy-MM-dd') + ')');" ^
  "Write-Output '';" ^
  "Write-Output ('%L_SystemInfo_SecDisks%');" ^
  "Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object {" ^
  "  Write-Output ('  Disk      : ' + $_.FriendlyName + '  [' + $_.MediaType + ', ' + [math]::Round($_.Size/1GB) + ' GB]');" ^
  "  Write-Output ('  Health    : ' + $_.HealthStatus + '  (SMART/reliability: ' + $_.OperationalStatus + ')') };" ^
  "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {" ^
  "  Write-Output ('  Volume ' + $_.DeviceID + ' : ' + [math]::Round(($_.Size-$_.FreeSpace)/1GB) + ' GB used / ' + [math]::Round($_.Size/1GB) + ' GB  (' + [math]::Round($_.FreeSpace/1GB) + ' GB free)') };" ^
  "Write-Output '';" ^
  "Write-Output ('%L_SystemInfo_SecNet%');" ^
  "Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up' | ForEach-Object {" ^
  "  Write-Output ('  Adapter   : ' + $_.Name + '  [' + $_.InterfaceDescription + ']  ' + $_.LinkSpeed) }" ^
  > "%SIREPORT%" 2>nul

if not exist "%SIREPORT%" (
    call "%HELPERS%" PrintFail "%L_SystemInfo_CollectFail%"
    call "%HELPERS%" PauseKey
    endlocal
    exit /b 1
)

:: Display with light coloring on section headers.
for /f "usebackq delims=" %%L in ("%SIREPORT%") do (
    echo %%L | findstr /b /c:"---" >nul && (echo %C_INFO%%%L%C_RESET%) || echo %%L
)
echo.
if "%IS_ADMIN%"=="1" (
    echo %C_INFO%%L_SystemInfo_SecSession%%C_RESET%
    echo   %L_SystemInfo_Privileges% %C_OK%%L_Main_AdminYes%%C_RESET%
) else (
    echo %C_INFO%%L_SystemInfo_SecSession%%C_RESET%
    echo   %L_SystemInfo_Privileges% %C_FAIL%%L_Main_AdminNo%%C_RESET%
)
echo.
call "%HELPERS%" HR
call "%HELPERS%" Confirm "%L_SystemInfo_SaveAsk%"
if /i "%CONFIRM%"=="Y" (
    copy /y "%SIREPORT%" "%LOGS%\SystemInfo_%TIMESTAMP%.txt" >nul
    call "%HELPERS%" PrintOK "%L_SystemInfo_Saved% Logs\SystemInfo_%TIMESTAMP%.txt"
)
del /q "%SIREPORT%" >nul 2>&1
call "%HELPERS%" Log OK "System information displayed"
call "%HELPERS%" PauseKey
endlocal
exit /b 0
