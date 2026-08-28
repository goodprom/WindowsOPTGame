@echo off
:: ============================================================================
::  WindowsOPTGame - Network.bat
:: ----------------------------------------------------------------------------
::  Safe, documented network maintenance only:
::    - Flush DNS resolver cache      (ipconfig /flushdns)
::    - Reset Winsock catalog         (netsh winsock reset)
::    - Reset TCP/IP stack            (netsh int ip reset)
::    - Release / renew DHCP lease    (ipconfig /release + /renew)
::    - Show adapter / connection information
::
::  Deliberately NO registry latency "tweaks" (TcpAckFrequency, throttling
::  hacks, etc.) - they are undocumented, often counter-productive, and
::  violate this project's safety rules.
::
::  Call styles:
::      Network.bat          - interactive menu
::      Network.bat AUTO     - flush DNS + winsock + TCP/IP reset, unattended
:: ============================================================================
setlocal EnableExtensions
if not defined WGO_INIT (
    call "%~dp0Helpers.bat" InitEnv "%~dp0.."
)
call "%HELPERS%" InitLog Network

if /i "%~1"=="AUTO" (
    call :FlushDNS
    call :ResetWinsock
    call :ResetTCPIP
    endlocal
    exit /b 0
)

:NetMenu
call "%HELPERS%" Header "%L_Network_Title%"
echo   %C_MENU%[1]%C_RESET% %L_Network_M1%
echo   %C_MENU%[2]%C_RESET% %L_Network_M2%          %C_DIM%%L_Network_RebootNote%%C_RESET%
echo   %C_MENU%[3]%C_RESET% %L_Network_M3%             %C_DIM%%L_Network_RebootNote%%C_RESET%
echo   %C_MENU%[4]%C_RESET% %L_Network_M4%
echo   %C_MENU%[5]%C_RESET% %L_Network_M5%
echo   %C_MENU%[6]%C_RESET% %L_Network_M6%
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.
set "NCHOICE="
set /p "NCHOICE=  %L_Common_SelectOption% "
if "%NCHOICE%"=="1" (call :FlushDNS      & call "%HELPERS%" PauseKey & goto :NetMenu)
if "%NCHOICE%"=="2" (call :ResetWinsock  & call "%HELPERS%" PauseKey & goto :NetMenu)
if "%NCHOICE%"=="3" (call :ResetTCPIP    & call "%HELPERS%" PauseKey & goto :NetMenu)
if "%NCHOICE%"=="4" (call :RenewIP       & call "%HELPERS%" PauseKey & goto :NetMenu)
if "%NCHOICE%"=="5" (call :RunAll        & call "%HELPERS%" PauseKey & goto :NetMenu)
if "%NCHOICE%"=="6" (call :NetInfo       & call "%HELPERS%" PauseKey & goto :NetMenu)
if "%NCHOICE%"=="0" (endlocal & exit /b 0)
goto :NetMenu

:RunAll
call :FlushDNS
call :ResetWinsock
call :ResetTCPIP
call :RenewIP
echo.
echo   %C_WARN%%L_Network_RunAllReboot%%C_RESET%
exit /b 0

:: ---------------------------------------------------------------------------
:FlushDNS
call "%HELPERS%" Exec "%L_Network_FlushDNS%" "ipconfig /flushdns"
exit /b %ERRORLEVEL%

:: ---------------------------------------------------------------------------
:ResetWinsock
call "%HELPERS%" RequireAdmin || exit /b 1
call "%HELPERS%" Exec "%L_Network_ResetWinsock%" "netsh winsock reset"
if %EXEC_RC% EQU 0 call "%HELPERS%" PrintInfo "%L_Network_WinsockAfter%"
exit /b %EXEC_RC%

:: ---------------------------------------------------------------------------
:ResetTCPIP
call "%HELPERS%" RequireAdmin || exit /b 1
:: netsh int ip reset returns 1 on some systems even on success (a few
:: subkeys need a reboot); treat that as a soft warning, not a failure.
call "%HELPERS%" Log EXEC "netsh int ip reset"
netsh int ip reset >>"%LOGFILE%" 2>&1
if errorlevel 2 (
    call "%HELPERS%" PrintFail "%L_Network_TCPIPFail%"
    exit /b 1
)
call "%HELPERS%" PrintOK "%L_Network_TCPIPOK%"
exit /b 0

:: ---------------------------------------------------------------------------
:RenewIP
call "%HELPERS%" PrintInfo "%L_Network_Releasing%"
call "%HELPERS%" Log EXEC "ipconfig /release + /renew"
ipconfig /release >>"%LOGFILE%" 2>&1
ipconfig /renew   >>"%LOGFILE%" 2>&1
if errorlevel 1 (
    call "%HELPERS%" PrintWarn "%L_Network_RenewWarn%"
    exit /b 1
)
call "%HELPERS%" PrintOK "%L_Network_RenewOK%"
exit /b 0

:: ---------------------------------------------------------------------------
:NetInfo
call "%HELPERS%" Header "%L_Network_InfoTitle%"
call "%HELPERS%" Working "%L_Network_Collecting%"
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {" ^
  "  Write-Host ('  Adapter : ' + $_.Name + '  [' + $_.InterfaceDescription + ']');" ^
  "  Write-Host ('  Speed   : ' + $_.LinkSpeed);" ^
  "  $ip = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue;" ^
  "  if ($ip) { Write-Host ('  IPv4    : ' + ($ip.IPAddress -join ', ')) };" ^
  "  Write-Host '' };" ^
  "$dns = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.ServerAddresses};" ^
  "Write-Host ('  DNS     : ' + (($dns.ServerAddresses | Select-Object -Unique) -join ', '))"
echo.
call "%HELPERS%" PrintInfo "%L_Network_PingTest%"
ping -n 2 8.8.8.8 | findstr /i "Average TTL"
if errorlevel 1 (
    call "%HELPERS%" PrintWarn "%L_Network_PingFail%"
) else (
    call "%HELPERS%" PrintOK "%L_Network_PingOK%"
)
exit /b 0
