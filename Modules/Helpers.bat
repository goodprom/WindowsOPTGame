@echo off
:: ============================================================================
::  WindowsOPTGame - Helpers.bat
:: ----------------------------------------------------------------------------
::  Shared function library used by every module.
::
::  Usage from any script:
::      call "%HELPERS%" <FunctionName> [arg1] [arg2] ... [arg8]
::
::  This file deliberately does NOT call SETLOCAL at the top level so that
::  functions can return values to the caller through environment variables
::  (e.g. TIMESTAMP, FREESPACE_MB, CFG_*, SYS_*). Functions that need
::  delayed expansion open their own SETLOCAL/ENDLOCAL scope internally.
:: ============================================================================

if "%~1"=="" exit /b 0
call :%~1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b %ERRORLEVEL%


:: ============================================================================
:: :InitEnv <root-folder>
::   Initializes the whole environment: paths, ANSI colors, admin state,
::   configuration and version. Safe to call more than once.
::   Sets: ROOT MODULES LOGS CONFIG BACKUPS TOOLS ESC C_* IS_ADMIN
::         WGO_VERSION WGO_INIT CFG_*
:: ============================================================================
:InitEnv
set "ROOT=%~f1"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
:: UTF-8 codepage so localized OS strings render correctly, even when a
:: module is launched standalone (the main launcher also sets this).
:: NOTE: "<nul" is required - without it chcp consumes the script's stdin,
:: which breaks every later "set /p" and "choice" when input is redirected.
chcp 65001 <nul >nul 2>&1
set "MODULES=%ROOT%\Modules"
set "LOGS=%ROOT%\Logs"
set "CONFIG=%ROOT%\Config"
set "BACKUPS=%ROOT%\Backups"
set "TOOLS=%ROOT%\Tools"
set "LANGDIR=%ROOT%\Languages"
set "HELPERS=%MODULES%\Helpers.bat"
set "WGO_VERSION=1.0.0"
set "WGO_TITLE=WindowsOPTGame"
set "WGO_AUTHOR=Shrammys"
set "WGO_COPYRIGHT=Mitasov Serafim"

:: Make sure every runtime folder exists (fresh clone / partial copy).
if not exist "%LOGS%"    mkdir "%LOGS%"    >nul 2>&1
if not exist "%CONFIG%"  mkdir "%CONFIG%"  >nul 2>&1
if not exist "%BACKUPS%" mkdir "%BACKUPS%" >nul 2>&1
if not exist "%BACKUPS%\Registry" mkdir "%BACKUPS%\Registry" >nul 2>&1
if not exist "%TOOLS%"   mkdir "%TOOLS%"   >nul 2>&1
if not exist "%LANGDIR%" mkdir "%LANGDIR%" >nul 2>&1

:: Capture the ESC control character (0x1B) for ANSI/VT color sequences.
:: The child cmd echoes "#<ESC>#rem"; with delims=# the first token is ESC.
:: Windows 10 (10586+) and Windows 11 consoles process VT sequences natively.
for /f "tokens=1 delims=#" %%E in ('"prompt #$E# & for %%A in (1) do rem"') do set "ESC=%%E"

set "C_RESET=%ESC%[0m"
set "C_TITLE=%ESC%[96m"
set "C_MENU=%ESC%[95m"
set "C_OK=%ESC%[92m"
set "C_FAIL=%ESC%[91m"
set "C_WARN=%ESC%[93m"
set "C_INFO=%ESC%[94m"
set "C_DIM=%ESC%[90m"
set "C_WHITE=%ESC%[97m"

:: Administrator detection: "net session" succeeds only in elevated shells.
net session >nul 2>&1
if errorlevel 1 (set "IS_ADMIN=0") else (set "IS_ADMIN=1")

call :EnsureConfig
call :LoadConfig
call :LoadLanguage
set "WGO_INIT=1"
exit /b 0


:: ============================================================================
:: :InitLog <module-name>
::   Creates a per-run log file unless a session log is already active
::   (when a module is launched by the main menu it inherits LOGFILE).
::   Sets: LOGFILE TIMESTAMP
:: ============================================================================
:InitLog
if not defined TIMESTAMP call :Timestamp
if defined LOGFILE (
    call :Log INFO "===== Module started: %~1 ====="
    exit /b 0
)
set "LOGFILE=%LOGS%\%~1_%TIMESTAMP%.log"
> "%LOGFILE%" echo ============================================================
>>"%LOGFILE%" echo  WindowsOPTGame v%WGO_VERSION% - %~1 log
>>"%LOGFILE%" echo  Started : %DATE% %TIME%
>>"%LOGFILE%" echo  Admin   : %IS_ADMIN%
>>"%LOGFILE%" echo  Language: %WGO_LANG%
>>"%LOGFILE%" echo ============================================================
:: One-time translation audit - needs the log file, so it lives here.
if not defined WGO_LANGCHECK call :CheckLanguage
exit /b 0


:: ============================================================================
:: :Log <LEVEL> <message>
::   Appends one timestamped line to the active log file.
::   Levels used across the project: INFO OK WARN ERROR EXEC
:: ============================================================================
:Log
if not defined LOGFILE exit /b 0
>>"%LOGFILE%" echo [%DATE% %TIME:~0,8%] [%~1] %~2
exit /b 0


:: ============================================================================
:: :Timestamp
::   Sets TIMESTAMP to a filesystem-safe, locale-independent value
::   (yyyyMMdd_HHmmss). Uses PowerShell to avoid %DATE% locale pitfalls.
:: ============================================================================
:Timestamp
set "TIMESTAMP="
for /f "usebackq delims=" %%T in (`powershell -NoProfile -InputFormat None -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TIMESTAMP=%%T"
if not defined TIMESTAMP set "TIMESTAMP=%RANDOM%%RANDOM%"
exit /b 0


:: ============================================================================
:: Console output primitives
::   :Header <title>       - clear screen + framed title bar
::   :HR                   - horizontal rule
::   :PrintOK / :PrintFail / :PrintWarn / :PrintInfo <message>
:: ============================================================================
:Header
cls
echo %C_TITLE%==================================================================%C_RESET%
echo %C_TITLE%   %C_WHITE%%~1%C_RESET%
echo %C_TITLE%==================================================================%C_RESET%
echo.
exit /b 0

:HR
echo %C_DIM%------------------------------------------------------------------%C_RESET%
exit /b 0

:PrintOK
echo   %C_OK%[ OK ]%C_RESET% %~1
call :Log OK "%~1"
exit /b 0

:PrintFail
echo   %C_FAIL%[FAIL]%C_RESET% %~1
call :Log ERROR "%~1"
exit /b 0

:PrintWarn
echo   %C_WARN%[ !! ]%C_RESET% %~1
call :Log WARN "%~1"
exit /b 0

:PrintInfo
echo   %C_INFO%[ -- ]%C_RESET% %~1
call :Log INFO "%~1"
exit /b 0


:: ============================================================================
:: :Exec <description> <command>
::   Runs a quiet command, logs its full output to LOGFILE, prints a colored
::   status line and returns the command's exit code. Sets EXEC_RC.
::   Use for short commands whose output belongs in the log, not on screen.
:: ============================================================================
:Exec
call :Log EXEC "%~1 :: %~2"
<nul set /p "=  %C_DIM%[ .. ]%C_RESET% %~1"
cmd /c %~2 >>"%LOGFILE%" 2>&1
set "EXEC_RC=%ERRORLEVEL%"
if %EXEC_RC% NEQ 0 goto :ExecFail
echo %ESC%[2K%ESC%[0G  %C_OK%[ OK ]%C_RESET% %~1
call :Log OK "%~1"
exit /b 0

:ExecFail
echo %ESC%[2K%ESC%[0G  %C_FAIL%[FAIL]%C_RESET% %~1 %C_DIM%[exit code %EXEC_RC%]%C_RESET%
call :Log ERROR "%~1 failed with exit code %EXEC_RC%"
exit /b %EXEC_RC%


:: ============================================================================
:: :ProgressBar <current> <total> <label>
::   Draws a single-line progress bar in place (no newline until 100%).
:: ============================================================================
:ProgressBar
setlocal EnableExtensions EnableDelayedExpansion
set /a _pct=%~1*100/%~2
set /a _fill=%~1*30/%~2
set /a _rest=30-_fill
set "_bar="
for /l %%i in (1,1,%_fill%) do set "_bar=!_bar!#"
for /l %%i in (1,1,%_rest%) do set "_bar=!_bar!."
<nul set /p "=%ESC%[2K%ESC%[0G  %C_OK%[!_bar!]%C_RESET% %_pct%%% - %~3"
if %~1 GEQ %~2 echo.
endlocal
exit /b 0


:: ============================================================================
:: :Working <label>
::   Short "loading" animation (~1 second) used before launching a phase.
:: ============================================================================
:Working
setlocal EnableExtensions
<nul set /p "=  %C_INFO%%~1%C_RESET% "
for /l %%i in (1,1,3) do (
    <nul set /p "=."
    ping -n 1 -w 300 192.0.2.1 >nul 2>&1
)
echo.
endlocal
exit /b 0


:: ============================================================================
:: :Confirm <prompt>
::   Asks a Y/N question. Sets CONFIRM=Y or CONFIRM=N.
::   When CFG_AskConfirmation=0 and WGO_AUTO=1, auto-answers Y.
:: ============================================================================
:Confirm
set "CONFIRM=N"
if "%WGO_AUTO%"=="1" if "%CFG_AskConfirmation%"=="0" (
    set "CONFIRM=Y"
    call :Log INFO "Auto-confirmed: %~1"
    exit /b 0
)
:: choice.exe reads the console directly and, when stdin is redirected
:: (scripted/piped runs), swallows the whole input stream - starving every
:: later "set /p". Detect redirection with the documented "timeout" quirk
:: (it refuses redirected input with exit code 1) and fall back to set /p.
timeout /t 0 >nul 2>&1
if errorlevel 1 goto :ConfirmPiped
choice /c YN /n /m "  %~1 [Y/N] "
if %ERRORLEVEL% EQU 1 set "CONFIRM=Y"
call :Log INFO "Prompt '%~1' answered: %CONFIRM%"
exit /b 0

:ConfirmPiped
set "_ans="
<nul set /p "=  %~1 [Y/N] "
set /p "_ans="
echo.
if /i "%_ans%"=="Y" set "CONFIRM=Y"
set "_ans="
call :Log INFO "Prompt '%~1' answered: %CONFIRM% (piped input)"
exit /b 0


:: ============================================================================
:: :PauseKey
::   "Press any key" without the default English-only message clutter.
:: ============================================================================
:PauseKey
echo.
<nul set /p "=  %C_DIM%%L_Common_PressAnyKey%%C_RESET%"
:: pause consumes a single CHARACTER from redirected stdin, breaking line
:: alignment for scripted input. timeout errors when stdin is redirected -
:: in that case consume one full LINE with set /p instead.
timeout /t 0 >nul 2>&1
if errorlevel 1 (
    set "_pk="
    set /p "_pk="
    set "_pk="
) else (
    pause >nul
)
echo.
exit /b 0


:: ============================================================================
:: :RequireAdmin
::   Guards privileged operations. Returns 1 (and prints help) if the
::   current console is not elevated.
:: ============================================================================
:RequireAdmin
if "%IS_ADMIN%"=="1" exit /b 0
echo.
echo   %C_FAIL%[FAIL]%C_RESET% %L_Common_NeedAdmin%
echo   %C_DIM%%L_Common_NeedAdminHint%%C_RESET%
call :Log ERROR "Blocked: administrator privileges required"
exit /b 1


:: ============================================================================
:: Configuration (Config\settings.ini  -  simple key=value store)
::   :EnsureConfig            - writes the default file if missing
::   :LoadConfig              - loads every key into CFG_<key>
::   :GetConfig <key> <def>   - loads one key (with default) into CFG_<key>
::   :SetConfig <key> <value> - persists one key and updates CFG_<key>
:: ============================================================================
:EnsureConfig
if exist "%CONFIG%\settings.ini" exit /b 0
> "%CONFIG%\settings.ini" (
    echo ; WindowsOPTGame configuration
    echo ; 1 = enabled, 0 = disabled
    echo AskConfirmation=1
    echo CleanEventLogs=0
    echo CleanBrowserCache=0
    echo CleanRecycleBin=1
    echo DisableGameBar=1
    echo DisableBackgroundRecording=1
    echo CloseBackgroundApps=1
    echo ApplyMMCSSTweaks=1
    echo DisableNetworkThrottling=1
    echo EnableHAGS=1
    echo DisablePowerThrottling=1
    echo SetUltimatePerformancePower=1
    echo RunChkdskInFullOptimization=1
    echo ; Comma-separated list of non-essential processes Gaming Mode may close
    echo BackgroundApps=OneDrive.exe,PhoneExperienceHost.exe,YourPhone.exe,GameBarFTServer.exe
)
exit /b 0

:LoadConfig
if not exist "%CONFIG%\settings.ini" call :EnsureConfig
for /f "usebackq eol=; tokens=1* delims==" %%A in ("%CONFIG%\settings.ini") do set "CFG_%%A=%%B"
exit /b 0

:GetConfig
set "CFG_%~1=%~2"
if not exist "%CONFIG%\settings.ini" exit /b 0
for /f "usebackq eol=; tokens=1* delims==" %%A in ("%CONFIG%\settings.ini") do (
    if /i "%%A"=="%~1" set "CFG_%~1=%%B"
)
exit /b 0

:SetConfig
if not exist "%CONFIG%\settings.ini" call :EnsureConfig
findstr /v /b /i /c:"%~1=" "%CONFIG%\settings.ini" > "%CONFIG%\settings.ini.tmp"
>>"%CONFIG%\settings.ini.tmp" echo %~1=%~2
move /y "%CONFIG%\settings.ini.tmp" "%CONFIG%\settings.ini" >nul
set "CFG_%~1=%~2"
call :Log INFO "Config changed: %~1=%~2"
exit /b 0


:: ============================================================================
:: Localization (Languages\<code>.ini  -  [Section] Key=Value store)
::   :LoadLanguage          - loads English baseline, then the selected
::                            language on top of it (per-key fallback)
::   :DetectLanguage        - one-time: picks the OS display language if a
::                            matching file exists, persists the choice
::   :CheckLanguage         - audits the selected translation for missing
::                            keys and logs a warning for each one
::   :ParseLangFile <file>  - internal: fills L_<Section>_<Key> variables
::   :LangLine              - internal: processes one parsed line
::
::   Every visible string in the project is a %L_Section_Key% variable.
::   New languages: drop <code>.ini into Languages\ - no code changes.
:: ============================================================================
:LoadLanguage
if not defined CFG_Language call :DetectLanguage
if not defined CFG_Language set "CFG_Language=en"
:: English is ALWAYS loaded first: any key a translation lacks keeps its
:: English value, so a missing key can never crash or blank the UI.
if exist "%LANGDIR%\en.ini" (
    call :ParseLangFile "%LANGDIR%\en.ini"
) else (
    echo   [WARN] Languages\en.ini is missing - interface texts unavailable.
    call :Log WARN "Languages\en.ini missing - no fallback strings"
)
if /i not "%CFG_Language%"=="en" if exist "%LANGDIR%\%CFG_Language%.ini" call :ParseLangFile "%LANGDIR%\%CFG_Language%.ini"
if /i not "%CFG_Language%"=="en" if not exist "%LANGDIR%\%CFG_Language%.ini" call :Log WARN "Language file missing: %CFG_Language%.ini - English used"
set "WGO_LANG=%CFG_Language%"
exit /b 0

:DetectLanguage
:: First run only: match the OS display language against available files.
:: Get-WinUserLanguageList reflects the user's real preferred language even
:: when the process UI culture reports en; Get-UICulture is the fallback.
set "_syslang="
for /f "usebackq delims=" %%L in (`powershell -NoProfile -InputFormat None -Command "$t=$null; try { $t=(Get-WinUserLanguageList)[0].LanguageTag } catch {}; if (-not $t) { $t=(Get-UICulture).Name }; $t.Substring(0,2).ToLower()"`) do set "_syslang=%%L"
if not defined _syslang set "_syslang=en"
if not exist "%LANGDIR%\%_syslang%.ini" set "_syslang=en"
call :SetConfig Language %_syslang%
set "_syslang="
exit /b 0

:ParseLangFile
set "_LSEC="
for /f "usebackq eol=; tokens=1* delims==" %%A in ("%~1") do call :LangLine "%%A" "%%B"
set "_LSEC="
exit /b 0

:LangLine
set "_lk=%~1"
if "%_lk:~0,1%"=="[" (
    set "_LSEC=%_lk:~1,-1%"
    exit /b 0
)
if not defined _LSEC exit /b 0
set "L_%_LSEC%_%_lk%=%~2"
set "_lk="
exit /b 0

:CheckLanguage
:: Compares key sets of en.ini and the selected translation; every key the
:: translation lacks is logged once (the English text is used silently).
set "WGO_LANGCHECK=1"
if /i "%CFG_Language%"=="en" exit /b 0
if not exist "%LANGDIR%\%CFG_Language%.ini" exit /b 0
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "function GK($f){$s='';foreach($l in Get-Content -LiteralPath $f){$t=$l.Trim();" ^
  "if($t -match '^\[(.+)\]$'){$s=$Matches[1]}elseif($t -match '^([^;\[=][^=]*)='){($s+'_'+$Matches[1].Trim())}}};" ^
  "$en=GK '%LANGDIR%\en.ini'; $tr=GK '%LANGDIR%\%CFG_Language%.ini';" ^
  "$en | Where-Object { $tr -notcontains $_ }" > "%TEMP%\wgo_langcheck.txt" 2>nul
if exist "%TEMP%\wgo_langcheck.txt" for /f "usebackq delims=" %%K in ("%TEMP%\wgo_langcheck.txt") do call :Log WARN "Translation %CFG_Language%.ini missing key L_%%K - English text used"
del /q "%TEMP%\wgo_langcheck.txt" >nul 2>&1
exit /b 0


:: ============================================================================
:: :GetFreeSpace <drive-letter>
::   Sets FREESPACE_MB for the given drive (e.g. "C").
:: ============================================================================
:GetFreeSpace
set "FREESPACE_MB=0"
for /f "usebackq delims=" %%S in (`powershell -NoProfile -InputFormat None -Command "[math]::Round((Get-PSDrive -Name '%~1' -ErrorAction SilentlyContinue).Free/1MB)"`) do set "FREESPACE_MB=%%S"
exit /b 0


:: ============================================================================
:: :CleanFolder <path> <description>
::   Safely empties the CONTENTS of a folder (never the folder itself),
::   skipping locked files silently, and reports how many MB were freed.
::   Refuses to run when the target does not exist or looks dangerous.
::   Adds freed MB to global counter TOTAL_FREED_MB when defined.
:: ============================================================================
:CleanFolder
if "%~1"=="" (call :PrintFail "CleanFolder called without a path" & exit /b 1)
:: Safety net: never operate on a bare drive root such as "C:\".
if "%~pnx1"=="\" (
    call :PrintFail "%L_Common_RefusedRoot% %~1"
    exit /b 1
)
if not exist "%~1" (
    call :PrintInfo "%~2 - %L_Common_FolderMissing%"
    exit /b 0
)
call :GetFreeSpace %SystemDrive:~0,1%
set "_before=%FREESPACE_MB%"
call :Log EXEC "Cleaning folder: %~1 (%~2)"
del /f /s /q "%~1\*" >nul 2>&1
for /d %%D in ("%~1\*") do rd /s /q "%%D" >nul 2>&1
call :GetFreeSpace %SystemDrive:~0,1%
set /a _freed=%FREESPACE_MB%-_before
if %_freed% LSS 0 set "_freed=0"
if defined TOTAL_FREED_MB set /a TOTAL_FREED_MB+=_freed
call :PrintOK "%~2 - %L_Common_Freed% %_freed% MB"
exit /b 0


:: ============================================================================
:: :GatherSystemInfo
::   One PowerShell round-trip that fills the dashboard variables:
::   SYS_OS SYS_BUILD SYS_CPU SYS_GPU SYS_RAM SYS_DISK
:: ============================================================================
:GatherSystemInfo
set "SYS_OS=Unknown" & set "SYS_CPU=Unknown" & set "SYS_GPU=Unknown"
set "SYS_RAM=Unknown" & set "SYS_DISK=Unknown"
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
  "$os=Get-CimInstance Win32_OperatingSystem;" ^
  "'OS='+$os.Caption+' (build '+$os.BuildNumber+')';" ^
  "$cpu=Get-CimInstance Win32_Processor|Select-Object -First 1;'CPU='+$cpu.Name.Trim();" ^
  "'GPU='+((Get-CimInstance Win32_VideoController|ForEach-Object{$_.Name}) -join ' / ');" ^
  "$t=[math]::Round($os.TotalVisibleMemorySize/1MB,1);$f=[math]::Round($os.FreePhysicalMemory/1MB,1);" ^
  "$u=[math]::Round($t-$f,1);$p=[math]::Round(($t-$f)*100/$t);" ^
  "'RAM='+$u+' GB / '+$t+' GB in use ('+$p+' percent)';" ^
  "$d=Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\";" ^
  "$ds=[math]::Round($d.Size/1GB);$df=[math]::Round($d.FreeSpace/1GB);" ^
  "'DISK=C: '+($ds-$df)+' GB used / '+$ds+' GB ('+$df+' GB free)'" ^
  > "%TEMP%\wgo_sysinfo.txt" 2>nul
if exist "%TEMP%\wgo_sysinfo.txt" (
    for /f "usebackq tokens=1* delims==" %%A in ("%TEMP%\wgo_sysinfo.txt") do set "SYS_%%A=%%B"
    del /q "%TEMP%\wgo_sysinfo.txt" >nul 2>&1
)
exit /b 0


:: ============================================================================
:: :IsProtectedService <service-name>
::   Sets PROTECTED=1 when the service must NEVER be stopped/disabled by this
::   tool (security, update, networking and core OS plumbing), else 0.
:: ============================================================================
:IsProtectedService
set "PROTECTED=0"
set "_PLIST=;wuauserv;usosvc;waasmedicsvc;windefend;wdnissvc;sense;securityhealthservice;wscsvc;mpssvc;bfe;dhcp;dnscache;nsi;netprofm;nlasvc;rpcss;rpceptmapper;dcomlaunch;lsm;winmgmt;eventlog;schedule;profsvc;usermanager;cryptsvc;keyiso;samss;vaultsvc;power;plugplay;brokerinfrastructure;coremessagingregistrar;audiosrv;audioendpointbuilder;themes;dwm;uxsms;sgrmbroker;msiserver;trustedinstaller;"
for %%P in ("%_PLIST%") do (
    echo %%~P | findstr /i /c:";%~1;" >nul && set "PROTECTED=1"
)
set "_PLIST="
exit /b 0


:: ============================================================================
:: :ServiceState <service-name>
::   Sets SVC_STATE = RUNNING | STOPPED | MISSING
:: ============================================================================
:ServiceState
set "SVC_STATE=MISSING"
sc query "%~1" >nul 2>&1
if errorlevel 1 exit /b 0
set "SVC_STATE=STOPPED"
sc query "%~1" | findstr /i "RUNNING" >nul 2>&1
if not errorlevel 1 set "SVC_STATE=RUNNING"
exit /b 0


:: ============================================================================
:: :BackupRegKey <key> <file-basename>
::   Exports one registry key into Backups\Registry\<timestamp>\ before it is
::   modified. Creates the timestamped folder on first use (REGBACKDIR).
:: ============================================================================
:BackupRegKey
if not defined TIMESTAMP call :Timestamp
if not defined REGBACKDIR set "REGBACKDIR=%BACKUPS%\Registry\%TIMESTAMP%"
if not exist "%REGBACKDIR%" mkdir "%REGBACKDIR%" >nul 2>&1
reg query "%~1" >nul 2>&1
if errorlevel 1 (
    :: Key does not exist yet - record that so Restore can delete it later.
    >>"%REGBACKDIR%\_created_keys.txt" echo %~1
    call :Log INFO "Registry key not present (will be created): %~1"
    exit /b 0
)
reg export "%~1" "%REGBACKDIR%\%~2.reg" /y >nul 2>&1
if errorlevel 1 (
    call :PrintFail "Registry backup failed for %~1"
    exit /b 1
)
call :Log OK "Registry backup: %~1 -> %~2.reg"
exit /b 0


:: ============================================================================
:: :SetRegDWORD <key> <value_name> <data>
::   Safely writes a DWORD value into the registry with quiet execution.
:: ============================================================================
:SetRegDWORD
reg add "%~1" /v "%~2" /t REG_DWORD /d %~3 /f >nul 2>&1
exit /b %ERRORLEVEL%


:: ============================================================================
:: :SetRegSZ <key> <value_name> <data>
::   Safely writes a STRING value into the registry with quiet execution.
:: ============================================================================
:SetRegSZ
reg add "%~1" /v "%~2" /t REG_SZ /d "%~3" /f >nul 2>&1
exit /b %ERRORLEVEL%


:: ============================================================================
:: :FlushRAM
::   Flushes working sets, standby list, modified list and system file cache.
:: ============================================================================
:FlushRAM
if exist "%TOOLS%\FlushMem.ps1" (
    powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -File "%TOOLS%\FlushMem.ps1" >nul 2>&1
)
exit /b 0

