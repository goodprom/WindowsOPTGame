@echo off
:: ============================================================================
::  WindowsOPTGame - Main Launcher
:: ----------------------------------------------------------------------------
::  Entry point. Draws the dashboard + main menu and dispatches to the
::  modules in .\Modules\. All shared logic lives in Modules\Helpers.bat.
::  Every visible string comes from Languages\<code>.ini (see :LoadLanguage
::  in Helpers.bat) - never hardcode UI text here.
::
::  Supported: Windows 10 / Windows 11, x64.
::  Recommended: run elevated (right-click -> Run as administrator).
:: ============================================================================
setlocal EnableExtensions
title WindowsOPTGame by Shrammys
:: "<nul" keeps chcp from consuming stdin (would break set /p below).
chcp 65001 <nul >nul 2>&1
mode con: cols=100 lines=42 <nul >nul 2>&1

:: ---------------------------------------------------------------------------
:: Bootstrap: locate ourselves, verify the module folder, initialize env.
:: ---------------------------------------------------------------------------
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "HELPERS=%ROOT%\Modules\Helpers.bat"

if not exist "%HELPERS%" (
    echo [FAIL] Modules\Helpers.bat not found next to this script.
    echo        Please keep the original folder structure intact.
    pause
    exit /b 1
)

call "%HELPERS%" InitEnv "%ROOT%"
call "%HELPERS%" Timestamp
call "%HELPERS%" InitLog Session

if "%IS_ADMIN%"=="1" goto :MainMenu
call "%HELPERS%" Header "WindowsOPTGame v%WGO_VERSION% by %WGO_AUTHOR%"
echo   %C_WARN%[ !! ]%C_RESET% %L_Main_NotAdmin%
echo.
echo   %L_Main_ElevateHint1%
echo   %L_Main_ElevateHint2%
echo.
call "%HELPERS%" Confirm "%L_Main_ElevateAsk%"
if /i not "%CONFIRM%"=="Y" goto :MainMenu
call "%HELPERS%" Log INFO "Self-elevating via PowerShell Start-Process -Verb RunAs"
powershell -NoProfile -InputFormat None -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b 0

:: ---------------------------------------------------------------------------
:: Main loop
:: ---------------------------------------------------------------------------
:MainMenu
call "%HELPERS%" GatherSystemInfo
call "%HELPERS%" Header "WindowsOPTGame v%WGO_VERSION% by %WGO_AUTHOR%"
if "%IS_ADMIN%"=="1" (set "ADMTXT=%C_OK%%L_Main_AdminYes%%C_RESET%") else (set "ADMTXT=%C_FAIL%%L_Main_AdminNo%%C_RESET%")
echo   %C_DIM%%L_Main_DashOS%%C_RESET% %SYS_OS%
echo   %C_DIM%%L_Main_DashCPU%%C_RESET% %SYS_CPU%
echo   %C_DIM%%L_Main_DashGPU%%C_RESET% %SYS_GPU%
echo   %C_DIM%%L_Main_DashRAM%%C_RESET% %SYS_RAM%
echo   %C_DIM%%L_Main_DashDisk%%C_RESET% %SYS_DISK%
echo   %C_DIM%%L_Main_DashAdmin%%C_RESET% %ADMTXT%
echo   %C_DIM%%L_Main_DashTime%%C_RESET% %DATE% %TIME:~0,8%
echo.
call "%HELPERS%" HR
:: Left column items are padded to a fixed width so the two-column layout
:: stays aligned in every language.
call :Pad _m1 "%L_Main_Item1%"
call :Pad _m2 "%L_Main_Item2%"
call :Pad _m3 "%L_Main_Item3%"
call :Pad _m4 "%L_Main_Item4%"
call :Pad _m5 "%L_Main_Item5%"
call :Pad _m6 "%L_Main_Item6%"
call :Pad _m7 "%L_Main_Item7%"
echo   %C_MENU%[1]%C_RESET%  %_m1%%C_MENU%[8]%C_RESET%  %L_Main_Item8%
echo   %C_MENU%[2]%C_RESET%  %_m2%%C_MENU%[9]%C_RESET%  %L_Main_Item9%
echo   %C_MENU%[3]%C_RESET%  %_m3%%C_MENU%[10]%C_RESET% %L_Main_Item10%
echo   %C_MENU%[4]%C_RESET%  %_m4%%C_MENU%[11]%C_RESET% %L_Main_Item11%
echo   %C_MENU%[5]%C_RESET%  %_m5%%C_MENU%[12]%C_RESET% %L_Main_Item12%
echo   %C_MENU%[6]%C_RESET%  %_m6%%C_MENU%[13]%C_RESET% %L_Main_Item13%
echo   %C_MENU%[7]%C_RESET%  %_m7%%C_MENU%[0]%C_RESET%  %L_Main_Item0%
call "%HELPERS%" HR
echo.
set "CHOICE="
set /p "CHOICE=  %L_Common_SelectOption% "
if not defined CHOICE goto :MainMenu

call "%HELPERS%" Log INFO "Main menu selection: %CHOICE%"

if "%CHOICE%"=="1"  (call "%MODULES%\Tweaks.bat" FULL     & goto :MainMenu)
if "%CHOICE%"=="2"  (call "%MODULES%\Cleanup.bat"         & goto :MainMenu)
if "%CHOICE%"=="3"  (call "%MODULES%\Gaming.bat"          & goto :MainMenu)
if "%CHOICE%"=="4"  (call "%MODULES%\Network.bat"         & goto :MainMenu)
if "%CHOICE%"=="5"  (call "%MODULES%\Repair.bat"          & goto :MainMenu)
if "%CHOICE%"=="6"  (call "%MODULES%\Diagnostics.bat"      & goto :MainMenu)
if "%CHOICE%"=="7"  (call "%MODULES%\ProcessOptimizer.bat"  & goto :MainMenu)
if "%CHOICE%"=="8"  (call "%MODULES%\Services.bat"         & goto :MainMenu)
if "%CHOICE%"=="9"  (call "%MODULES%\SystemInfo.bat"      & goto :MainMenu)
if "%CHOICE%"=="10" (call "%MODULES%\RestorePoint.bat"    & goto :MainMenu)
if "%CHOICE%"=="11" (call "%MODULES%\Restore.bat"         & goto :MainMenu)
if "%CHOICE%"=="12" goto :Settings
if "%CHOICE%"=="13" goto :About
if "%CHOICE%"=="0"  goto :Quit
goto :MainMenu

:: :Pad <outvar> <text>  - pads <text> with spaces to a fixed column width.
:Pad
set "_pt=%~2                                                  "
set "%~1=%_pt:~0,32%"
exit /b 0

:: ---------------------------------------------------------------------------
:: [12] Settings - toggles persisted in Config\settings.ini
:: ---------------------------------------------------------------------------
:Settings
call "%HELPERS%" LoadConfig
call "%HELPERS%" Header "%L_Settings_Title%"
call :ShowToggle 1 AskConfirmation            "%L_Settings_T1%"
call :ShowToggle 2 CleanEventLogs             "%L_Settings_T2%"
call :ShowToggle 3 CleanBrowserCache          "%L_Settings_T3%"
call :ShowToggle 4 CleanRecycleBin            "%L_Settings_T4%"
call :ShowToggle 5 DisableGameBar             "%L_Settings_T5%"
call :ShowToggle 6 DisableBackgroundRecording "%L_Settings_T6%"
call :ShowToggle 7 CloseBackgroundApps        "%L_Settings_T7%"
call :ShowToggle 8 SetHighPerformancePower    "%L_Settings_T8%"
call :ShowToggle 9 RunChkdskInFullOptimization "%L_Settings_T9%"
echo.
call :FlagBar "%L_Meta_Flag%"
echo   %C_MENU%[10]%C_RESET% %_lflag% %L_Settings_LanguageItem%   %C_DIM%[%WGO_LANG%]%C_RESET%
echo.
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.
set "SCHOICE="
set /p "SCHOICE=  %L_Settings_ToggleAsk% "
if "%SCHOICE%"=="1" call :Flip AskConfirmation
if "%SCHOICE%"=="2" call :Flip CleanEventLogs
if "%SCHOICE%"=="3" call :Flip CleanBrowserCache
if "%SCHOICE%"=="4" call :Flip CleanRecycleBin
if "%SCHOICE%"=="5" call :Flip DisableGameBar
if "%SCHOICE%"=="6" call :Flip DisableBackgroundRecording
if "%SCHOICE%"=="7" call :Flip CloseBackgroundApps
if "%SCHOICE%"=="8" call :Flip SetHighPerformancePower
if "%SCHOICE%"=="9" call :Flip RunChkdskInFullOptimization
if "%SCHOICE%"=="10" goto :LangMenu
if "%SCHOICE%"=="0" goto :MainMenu
goto :Settings

:ShowToggle
call set "_v=%%CFG_%~2%%"
if "%_v%"=="1" (set "_state=%C_OK%[ON ]%C_RESET%") else (set "_state=%C_DIM%[OFF]%C_RESET%")
echo   %C_MENU%[%~1]%C_RESET% %_state% %~3
exit /b 0

:Flip
call set "_v=%%CFG_%~1%%"
if "%_v%"=="1" (call "%HELPERS%" SetConfig %~1 0) else (call "%HELPERS%" SetConfig %~1 1)
exit /b 0

:: ---------------------------------------------------------------------------
:: Settings -> Language: lists every Languages\*.ini automatically. Adding a
:: new language file requires NO code change - it appears here by itself.
:: The choice is persisted (Config\settings.ini, Language=<code>) and the
:: interface reloads immediately, no restart needed.
:: ---------------------------------------------------------------------------
:LangMenu
call "%HELPERS%" Header "%L_Language_Title%"
call :FlagBar "%L_Meta_Flag%"
echo   %C_INFO%%L_Language_Current%%C_RESET% %_lflag% %C_WHITE%%L_Meta_Name%%C_RESET%
echo.
echo   %L_Language_Select%
echo.
set "_ln=0"
for %%F in ("%LANGDIR%\*.ini") do call :LangShow "%%~nF"
if "%_ln%"=="0" (
    call "%HELPERS%" PrintWarn "%L_Language_None%"
    call "%HELPERS%" PauseKey
    goto :Settings
)
echo.
echo   %C_MENU%[0]%C_RESET% %L_Common_Back%
echo.
set "LCHOICE="
set /p "LCHOICE=  %L_Common_SelectOption% "
if not defined LCHOICE goto :LangMenu
if "%LCHOICE%"=="0" goto :Settings
call set "_pick=%%LANG_%LCHOICE%%%"
if not defined _pick goto :LangMenu
call "%HELPERS%" SetConfig Language %_pick%
call "%HELPERS%" LoadLanguage
call "%HELPERS%" Log INFO "Language changed to: %_pick%"
echo.
echo   %C_OK%%L_Language_Changed%%C_RESET%
ping -n 2 -w 500 127.0.0.1 >nul 2>&1
goto :Settings

:: :LangShow <code>  - one row per language file, with its native Name= and a
:: colored flag bar built from its Flag= ANSI color codes (see :FlagBar).
:LangShow
set /a _ln+=1
set "LANG_%_ln%=%~1"
set "_lname=%~1"
set "_lfc="
for /f "usebackq tokens=1* delims==" %%N in (`findstr /b /c:"Name=" "%LANGDIR%\%~1.ini"`) do set "_lname=%%O"
for /f "usebackq tokens=1* delims==" %%N in (`findstr /b /c:"Flag=" "%LANGDIR%\%~1.ini"`) do set "_lfc=%%O"
call :FlagBar "%_lfc%"
if /i "%~1"=="%WGO_LANG%" (
    echo   %C_MENU%[%_ln%]%C_RESET% %_lflag% %C_OK%%_lname%%C_RESET%  %C_DIM%[%~1] ^<--%C_RESET%
) else (
    echo   %C_MENU%[%_ln%]%C_RESET% %_lflag% %_lname%  %C_DIM%[%~1]%C_RESET%
)
exit /b 0

:: :FlagBar <space-separated ANSI color codes>
::   Builds a small colored flag in _lflag, one block per stripe. Emoji flags
::   do not render in the Windows console, so languages describe their flag
::   as color codes in [Meta] Flag= (e.g. "97 94 91" = white blue red).
:FlagBar
set "_lflag="
for %%C in (%~1) do call set "_lflag=%%_lflag%%%ESC%[%%Cm█"
if defined _lflag (set "_lflag=%_lflag%%C_RESET%") else (set "_lflag=%ESC%[36m»%C_RESET%")
exit /b 0

:: ---------------------------------------------------------------------------
:: [13] About
:: ---------------------------------------------------------------------------
:About
call "%HELPERS%" Header "%L_About_Title%"
echo   %C_WHITE%WindowsOPTGame v%WGO_VERSION%%C_RESET% %C_DIM%by %WGO_AUTHOR%%C_RESET%
echo.
echo   %L_About_Line1%
echo.
echo   %C_INFO%%L_About_PrinciplesHdr%%C_RESET%
echo    %L_About_P1%
echo    %L_About_P2%
echo    %L_About_P3%
echo    %L_About_P4%
echo    %L_About_P5%
echo.
echo   %C_INFO%%L_About_FoldersHdr%%C_RESET%
echo    %L_About_F1%
echo    %L_About_F2%
echo    %L_About_F3%
echo    %L_About_F4%
echo.
:: Copyright card: open right edge, so any translation length fits.
echo   %C_TITLE%╔════════════════════════════════════════════════════%C_RESET%
echo   %C_TITLE%║%C_RESET%  %C_WHITE%© %DATE:~-4% %WGO_COPYRIGHT%%C_RESET% %C_DIM%aka %WGO_AUTHOR%%C_RESET%
echo   %C_TITLE%║%C_RESET%  %C_DIM%%L_About_Rights%%C_RESET%
echo   %C_TITLE%╚════════════════════════════════════════════════════%C_RESET%
echo.
call "%HELPERS%" PauseKey
goto :MainMenu

:: ---------------------------------------------------------------------------
:: [0] Exit
:: ---------------------------------------------------------------------------
:Quit
call "%HELPERS%" Log INFO "===== Session ended by user ====="
echo.
echo   %C_OK%%L_Main_Goodbye% %LOGFILE%%C_RESET%
echo.
endlocal
exit /b 0
