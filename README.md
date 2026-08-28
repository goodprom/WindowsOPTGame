# 🚀 WindowsOPTGame

<div align="center">

### Safe, Modular & Fully-Logged System & Gaming Optimization Suite for Windows 10 / 11 (x64)
*Developed by **Shrammys** — © 2026 Mitasov Serafim*

[![Download ZIP](https://img.shields.io/badge/Download-ZIP%20Archive%20(v1.0.0)-FF5722?style=for-the-badge&logo=windows-terminal&logoColor=white)](https://github.com/goodprom/WindowsOPTGame/releases/download/v1.0.0/WindowsOPTGame-v1.0.0.zip)
[![Release](https://img.shields.io/badge/Release-v1.0.0-0078D6?style=for-the-badge&logo=github&logoColor=white)](https://github.com/goodprom/WindowsOPTGame/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-0078D6?style=for-the-badge&logo=windows&logoColor=white)](#-system-requirements--системные-требования)
[![Shell](https://img.shields.io/badge/Shell-Batch%20%26%20PowerShell-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](#-project-structure)
[![Safety](https://img.shields.io/badge/Safety-100%25%20Reversible-brightgreen?style=for-the-badge&logo=shield&logoColor=white)](#-safety-guarantees)
[![Languages](https://img.shields.io/badge/Languages-English%20%7C%20%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-blueviolet?style=for-the-badge)](#-multi-language-support)

---

### 🌐 Quick Navigation / Быстрый переход

**[ 🇬🇧 English Documentation ](#-english)** &nbsp;&nbsp;•&nbsp;&nbsp; **[ 🇷🇺 Документация на русском ](#-русский)**

---

</div>

<br>

<a name="english"></a>
# 🇬🇧 English

## ⚡ Overview & Key Highlights

**WindowsOPTGame** is a lightweight, safe, and modular optimization toolkit engineered specifically for **Windows 10** and **Windows 11 (x64)**. It combines native batch scripting with Win32 API calls and documented PowerShell CIM/WMI queries to clean, optimize, and streamline your operating system without compromising stability.

- 🛡️ **Safety First**: Automatically creates a System Restore Point and registry backups prior to applying optimizations.
- 🔄 **100% Reversible**: Every modification can be rolled back via module `[11] Restore Previous Settings` or modular `[R]` sub-options.
- 🧠 **Native RAM Flushing**: Includes built-in `Tools\FlushMem.ps1` utilizing Win32 APIs (`ntdll`, `psapi`, `kernel32`) to purge Standby Lists, process Working Sets, and System File Cache without third-party dependencies.
- 🎯 **Non-Destructive**: Never permanently disables Windows Defender, Windows Update, Security Center, audio, or core system components. User personal files (Documents, Desktop, Downloads, browser profiles/passwords) remain untouched.
- 🌍 **Fully Localized**: Zero hardcoded strings. Features dynamic language detection and seamless real-time switching between English and Russian with ANSI-styled flag badges.

---

## 🚀 Quick Start & Download

### 📦 1. Download
👉 **[Click Here to Download WindowsOPTGame-v1.0.0.zip](https://github.com/goodprom/WindowsOPTGame/releases/download/v1.0.0/WindowsOPTGame-v1.0.0.zip)** *(Direct ZIP download)*  
Or check the **[Releases Page](https://github.com/goodprom/WindowsOPTGame/releases/latest)** for release notes.

### 🏃 2. Launch
1. Extract the downloaded `WindowsOPTGame-v1.0.0.zip` to any folder on your PC.
2. Right-click **`WindowsOPTGame.bat`** and select **Run as administrator**.  
   *(If started without elevation, the launcher will offer a one-click self-elevation prompt).*
3. Choose your desired operation from the interactive dashboard.

---

## 📁 Project Structure

```text
WindowsOPTGame/
├── WindowsOPTGame.bat         Main launcher: real-time dashboard & dispatch menu
├── Modules/                   Specialized optimization modules
│   ├── Helpers.bat            Shared core library (logging, colors, config, checks)
│   ├── Tweaks.bat             [1]  Full System Optimization (automated 7-stage pipeline)
│   ├── Cleanup.bat            [2]  Windows Cleanup (Standard & Extreme cleaning)
│   ├── DiskFootprint.bat      [2]  Disk Footprint Reducer (Compact OS, WinSxS, Debloat)
│   ├── Gaming.bat             [3]  Advanced Gaming Mode & Latency Optimization
│   ├── Network.bat            [4]  Network Stack Reset & Diagnostics
│   ├── Repair.bat             [5]  Windows Repair (SFC / DISM / CHKDSK)
│   ├── Diagnostics.bat        [6]  SSD / HDD Drive Diagnostics (Read-only)
│   ├── ProcessOptimizer.bat   [7]  Process & RAM Footprint Optimizer
│   ├── Services.bat           [8]  Service Manager with Safety Lock
│   ├── SystemInfo.bat         [9]  System Hardware & OS Information (CIM)
│   ├── RestorePoint.bat       [10] System Restore Point Creator
│   ├── Restore.bat            [11] Centralized Rollback & Undo Wizard
│   └── Backup.bat             Automatic registry and settings backup engine
├── Languages/                 Translation tables (UTF-8)
│   ├── en.ini                 English translation
│   └── ru.ini                 Russian translation (Русский)
├── Config/                    Persistent user configuration
│   └── settings.ini           Toggles, blacklists, and active language
├── Tools/                     Auxiliary and optional tools
│   ├── FlushMem.ps1           Zero-dependency Win32 memory purger
│   ├── RAMMap64.exe           Optional Sysinternals RAM tool
│   └── RAMMap.exe             Optional 32-bit Sysinternals RAM tool
├── Logs/                      Timestamped session logs and diagnostic reports
└── Backups/                   Registry exports (.reg), power profiles & service snapshots
```

---

## 🛠️ Menu Reference

### `[1]` Full System Optimization (`Tweaks.bat`)
An unattended 7-stage maintenance pipeline with real-time progress indicators:
1. **Restore Point**: Creates a Windows System Restore Point (prompts if disabled).
2. **Registry Backup**: Snapshots all targeted registry hives to `Backups\Registry\<timestamp>\`.
3. **Cleanup**: Cleans temporary files, shader caches, update leftovers, and thumbnail caches.
4. **Network Refresh**: Flushes DNS resolver, resets Winsock, and resets TCP/IP stack.
5. **System Repair**: Runs `SFC /SCANNOW`, `DISM /RestoreHealth`, and `DISM /StartComponentCleanup`.
6. **Disk Check**: Executes a read-only `CHKDSK` scan (configurable in settings).
7. **Report**: Generates `Logs\OptimizationReport_<timestamp>.txt` with summary verdicts.

### `[2]` Windows Cleanup & Disk Footprint (`Cleanup.bat` & `DiskFootprint.bat`)
- **Standard Cleanup**: Clears user/system `%TEMP%`, DirectX `D3DSCache`, Prefetch, Windows Update download cache (`SoftwareDistribution\Download`), WER crash reports, Delivery Optimization cache, and browser caches (without touching bookmarks or passwords).
- **Extreme Cleanup**: Identifies downloads older than 30 days (moves to Recycle Bin) and cleans orphaned application folders in `AppData` and `ProgramData` using a smart registry whitelist.
- **Disk Footprint Reducer**:
  - *Compact OS*: Transparent system binary compression (`compact.exe /CompactOS:always`, frees 2–4+ GB).
  - *Hibernation Control*: Disable or switch to `Reduced` mode (retains Fast Startup while saving 50% RAM size).
  - *WinSxS ResetBase*: Deep component cleanup removing superseded Windows updates.
  - *Safe UWP Debloat*: Removes pre-installed bloatware (Clipchamp, News, Weather, Solitaire, etc.).
  - *OneDrive Removal*: Complete uninstallation, registry cleanup, and Explorer tree uncluttering.

### `[3]` Advanced Gaming Mode (`Gaming.bat`)
Maximizes framerates, stabilizes frame times, and minimizes input latency:
- **Live Status Dashboard**: Monitors RAM usage, MMCSS status, Network Throttling, HAGS, VRR, power schemes, and CPU throttling.
- **MMCSS & 3D Game Priority**: Configures Multimedia Class Scheduler (`SystemResponsiveness = 0`, Game GPU Priority = `8`, Priority = `6`).
- **Network Throttling Index**: Unlocks network packet throughput for competitive multiplayer games (`0xFFFFFFFF`).
- **HAGS & Windowed Optimizations**: Enables Hardware-Accelerated GPU Scheduling and Variable Refresh Rate / AutoHDR for windowed games.
- **Ultimate Performance Plan**: Activates the hidden Windows Ultimate/High Performance power scheme (snapshots previous plan).
- **Disable CPU Power Throttling**: Prevents Windows from throttling execution threads under load.
- **Service Pausing**: Temporarily stops non-critical services (`SysMain`, `DiagTrack`, `Spooler`, `WSearch`, etc.) with instant snapshot rollback.
- **RAM & Shader Flushing**: Flushes standby memory and purges DirectX / NVIDIA / AMD shader caches.

### `[4]` Network Optimization (`Network.bat`)
Applies official network stack maintenance commands:
- `ipconfig /flushdns` (DNS resolver flush)
- `netsh winsock reset` (Winsock catalog reset)
- `netsh int ip reset` (TCP/IP stack reset)
- `ipconfig /release` & `ipconfig /renew` (DHCP lease refresh)
- Gateway reachability and ping diagnostic checks.

### `[5]` Windows Repair (`Repair.bat`)
Automates Windows image and system file health verification:
- `SFC /SCANNOW` (System File Checker)
- `DISM /Online /Cleanup-Image /ScanHealth`
- `DISM /Online /Cleanup-Image /RestoreHealth`
- `DISM /Online /Cleanup-Image /StartComponentCleanup`
- `CHKDSK C:` (with automated reboot-scheduling if errors are detected).

### `[6]` SSD / HDD Diagnostics (`Diagnostics.bat`)
Non-destructive read-only drive inspection:
- Physical disk list and SMART health status.
- Storage reliability counters (temperature, wear %, power-on hours, read/write errors).
- Drive fragmentation analysis (`defrag /A`, no defragmentation performed).
- TRIM status check (`fsutil behavior query DisableDeleteNotify`).

### `[7]` Process & RAM Optimizer (`ProcessOptimizer.bat`)
Monitors and optimizes active processes and memory consumption:
- **Live Process Dashboard**: Displays total process count, live RAM utilization (GB and %), and tweak states.
- **Quick RAM Flush**: Clears working sets of running processes via native `psapi.dll` `EmptyWorkingSet`.
- **Disable UWP Background Apps**: Prevents background Windows Store applications from idling in memory.
- **Disable Edge Background & Copilot**: Disables Edge background mode, Startup Boost, Taskbar Widgets (News & Interests), and Windows Copilot.
- **Disable Telemetry Services & Tasks**: Disables 9 non-essential telemetry services and background Task Scheduler tasks.

### `[8]` Service Manager (`Services.bat`)
Interactive control for non-essential Windows services with live state indicators (RUNNING / STOPPED / NOT INSTALLED).
- *Protected Services*: Hard-coded safety locks protect Defender, Windows Update, Firewall, RPC, Audio, and core network services from being stopped.

### `[9]` System Information (`SystemInfo.bat`)
Comprehensive hardware and environment audit using CIM (replacing deprecated `wmic`):
- OS Edition, Build number, Uptime.
- CPU model, Core/Thread counts, Base clock.
- GPU model, VRAM capacity, Driver version.
- RAM modules, Speed (MHz), Form factor, Manufacturer.
- Motherboard, BIOS / UEFI revision, Disk partitions, and Network interfaces.

### `[10]` Create Restore Point (`RestorePoint.bat`)
Creates an immediate system restore checkpoint via PowerShell `Checkpoint-Computer`. Automatically detects if System Protection is turned off on `C:` and temporarily lifts the 24-hour restore point creation throttle.

### `[11]` Restore Previous Settings (`Restore.bat`)
The central undo mechanism:
- Restores services paused by Gaming Mode from snapshot.
- Imports registry backup sets (`Backups\Registry\<timestamp>\`) and deletes keys added by the optimizer.
- Restores original power plan GUID.
- Restores `Config\settings.ini` backups.
- Launches the native Windows System Restore Wizard (`rstrui.exe`).

### `[12]` Settings Configuration (`Config\settings.ini`)

| Setting | Default | Description |
|---|:---:|---|
| `AskConfirmation` | `1` | Prompts for confirmation before executing actions |
| `CleanEventLogs` | `0` | Clears Windows Event Logs during cleanup |
| `CleanBrowserCache` | `0` | Clears Edge, Chrome, and Firefox cache directories |
| `CleanRecycleBin` | `1` | Empties the Windows Recycle Bin |
| `DisableGameBar` | `1` | Gaming Mode disables Xbox Game Bar |
| `DisableBackgroundRecording` | `1` | Gaming Mode disables Game DVR |
| `CloseBackgroundApps` | `1` | Gaming Mode closes configured `BackgroundApps` list |
| `SetHighPerformancePower` | `0` | Switches to High/Ultimate power plan in Gaming Mode |
| `RunChkdskInFullOptimization` | `1` | Includes CHKDSK read-only scan in Full Optimization |
| `BackgroundApps` | *list* | Comma-separated list of background processes to close |
| `Language` | `auto` | Active UI language (`en`, `ru`, etc.) |

---

## 🛡️ Safety Guarantees

1. **Strict Non-Destructive Policy**: Personal user data (Documents, Desktop, Downloads, browser profiles, tabs, saved passwords) are strictly excluded from any cleanup path.
2. **System Service Guard**: Core OS services, security providers, and firewall rules cannot be stopped or disabled.
3. **Automated Rollback Sets**: Registry keys are backed up as standard `.reg` files before alteration.
4. **Transparent Code**: Written cleanly in Batch and PowerShell without obfuscation or binary payloads.
5. **Zero Installation**: Completely portable — leaves no background services, drivers, or autorun entries. To uninstall, simply delete the folder.

---

<br>
<hr>
<br>

<a name="русский"></a>
# 🇷🇺 Русский

## ⚡ Описание и ключевые преимущества

**WindowsOPTGame** — это безопасная, модульная утилита для оптимизации и тонкой настройки **Windows 10** и **Windows 11 (x64)**. Программа написана на Batch с использованием документированных системных вызовов PowerShell (CIM/WMI), нативных функций Win32 API и проверенных системных утилит Windows.

- 🛡️ **Безопасность превыше всего**: перед любыми изменениями автоматически создаются контрольная точка восстановления системы и резервные копии изменяемых веток реестра.
- 🔄 **100% обратимость**: все параметры можно вернуть обратно через мастер отката `[11] Восстановить прежние настройки`, встроенные кнопки отката `[R]` в модулях или при перезагрузке ПК.
- 🧠 **Нативная очистка памяти**: встроенный инструмент `Tools\FlushMem.ps1` очищает Standby List, рабочие наборы процессов и системный файловый кэш через прямые вызовы Win32 API (`ntdll`, `psapi`, `kernel32`) без необходимости установки стороннего софта.
- 🎯 **Без вреда для системы**: Defender, Центр безопасности, Windows Update и критические службы ядра никогда не отключаются навсегда. Пользовательские файлы (Документы, Рабочий стол, Загрузки, профили браузеров) остаются в полной сохранности.
- 🌍 **Полная локализация**: интерфейс переведён на русский и английский языки с возможностью мгновенного переключения на лету без перезапуска программы.

---

## 🚀 Быстрый запуск и скачивание

### 📦 1. Скачивание архива
👉 **[Нажмите здесь для скачивания WindowsOPTGame-v1.0.0.zip](https://github.com/goodprom/WindowsOPTGame/releases/download/v1.0.0/WindowsOPTGame-v1.0.0.zip)** *(Прямая загрузка готового ZIP-архива)*  
Либо перейдите на **[Страницу релизов](https://github.com/goodprom/WindowsOPTGame/releases/latest)**.

### 🏃 2. Запуск программы
1. Распакуйте скачанный архив `WindowsOPTGame-v1.0.0.zip` в любую папку на диске.
2. Нажмите правой кнопкой мыши на **`WindowsOPTGame.bat`** → **Запуск от имени администратора**.  
   *(При обычном запуске программа сама предложит перезапуститься с повышенными привилегиями в 1 клик).*
3. Выберите нужный пункт в интерактивном главном меню.

---

## 📁 Структура проекта

```text
WindowsOPTGame/
├── WindowsOPTGame.bat         Главный лаунчер: дашборд системы и меню навигации
├── Modules/                   Специализированные модули оптимизации
│   ├── Helpers.bat            Библиотека общих функций (логи, цвета, конфиг, проверки)
│   ├── Tweaks.bat             [1]  Полная оптимизация (автоматический конвейер из 7 этапов)
│   ├── Cleanup.bat            [2]  Очистка Windows (Стандартная и Экстремальная)
│   ├── DiskFootprint.bat      [2]  Уменьшение размера Windows (Compact OS, WinSxS, Debloat)
│   ├── Gaming.bat             [3]  Игровой режим и снижение задержек
│   ├── Network.bat            [4]  Очистка сетевого стека и диагностика
│   ├── Repair.bat             [5]  Восстановление Windows (SFC / DISM / CHKDSK)
│   ├── Diagnostics.bat        [6]  Диагностика накопителей SSD / HDD (только чтение)
│   ├── ProcessOptimizer.bat   [7]  Оптимизация фоновых процессов и ОЗУ
│   ├── Services.bat           [8]  Менеджер служб с аппаратной защитой
│   ├── SystemInfo.bat         [9]  Информация о системе и комплектующих (CIM)
│   ├── RestorePoint.bat       [10] Создание точки восстановления системы
│   ├── Restore.bat            [11] Центр отката и отмены всех изменений
│   └── Backup.bat             Автоматический бэкап реестра и конфигурации
├── Languages/                 Файлы локализации (UTF-8)
│   ├── ru.ini                 Русский язык (основной)
│   └── en.ini                 Английский язык
├── Config/                    Пользовательская конфигурация
│   └── settings.ini           Параметры работы, переключатели и текущий язык
├── Tools/                     Вспомогательные утилиты
│   ├── FlushMem.ps1           Нативный инструмент сброса памяти Win32
│   ├── RAMMap64.exe           Опциональная утилита Sysinternals для ОЗУ
│   └── RAMMap.exe             Опциональная 32-битная утилита Sysinternals
├── Logs/                      Журналы сессий и подробные отчёты диагностики
└── Backups/                   Бэкапы реестра (.reg), профилей электропитания и служб
```

---

## 🛠️ Справочник меню

### `[1]` Полная оптимизация системы (`Tweaks.bat`)
Автоматический конвейер комплексного обслуживания из 7 этапов с отображением прогресса:
1. **Точка восстановления**: создаёт контрольную точку Windows (предлагает включить Защиту системы, если отключена).
2. **Бэкап реестра**: экспортирует все изменяемые ветки в `Backups\Registry\<timestamp>\`.
3. **Очистка диска**: удаляет временные файлы, кэши шейдеров, остатки обновлений и эскизы.
4. **Обновление сети**: сбрасывает DNS-кэш, каталог Winsock и стек протокола TCP/IP.
5. **Восстановление системы**: выполняет `SFC /SCANNOW`, `DISM /RestoreHealth` и `DISM /StartComponentCleanup`.
6. **Проверка диска**: запускает `CHKDSK` в режиме безопасного чтения.
7. **Отчёт**: формирует итоговый файл `Logs\OptimizationReport_<timestamp>.txt`.

### `[2]` Очистка Windows и сжатие диска (`Cleanup.bat` & `DiskFootprint.bat`)
- **Стандартная очистка**: временные файлы пользователя и системы (`%TEMP%`, `Windows\Temp`), Prefetch, дампы памяти (`MEMORY.DMP`, `Minidump`), отчёты WER, кэш DirectX `D3DSCache`, кэш обновлений `SoftwareDistribution\Download` (службы безопасно останавливаются и перезапускаются), кэш Delivery Optimization и кэши браузеров (без удаления паролей и закладок).
- **Экстремальная очистка**: поиск файлов в папке «Загрузки» старше 30 дней (с перемещением в Корзину) и глубокий поиск остатков (Orphaned Data) от удалённых программ в `AppData` и `ProgramData` по белому списку с ручным подтверждением.
- **Уменьшение размера диска (Disk Footprint)**:
  - *Compact OS*: сжатие системных файлов алгоритмами Windows без потери скорости (`compact.exe /CompactOS:always`, экономия 2–4+ ГБ).
  - *Управление гибернацией*: отключение либо сжатый режим `Reduced` (сохраняет функцию быстрого запуска Windows, экономя 50% размера файла).
  - *WinSxS ResetBase*: глубокая очистка хранилища компонентов от устаревших версий обновлений.
  - *Debloat UWP*: удаление предустановленных приложений (Clipchamp, Новости, Погода, Пасьянс, FeedbackHub и др.).
  - *Удаление OneDrive*: полная деинсталляция, удаление автозапуска и интеграции из проводника.

### `[3]` Игровой режим (`Gaming.bat`)
Повышение FPS, стабилизация времени кадра (Frametime) и минимизация задержки ввода:
- **Живой дашборд**: мониторинг статуса ОЗУ, MMCSS, сетевого троттлинга, HAGS, VRR, схемы питания и троттлинга CPU.
- **MMCSS и приоритет 3D-игр**: настройка мультимедийного планировщика (`SystemResponsiveness = 0`, Games GPU Priority = `8`, Priority = `6`).
- **Сетевой троттлинг**: снятие системного ограничения сетевых пакетов для онлайн-игр (`0xFFFFFFFF`).
- **HAGS и оконные игры**: включение аппаратного ускорения планирования GPU, Variable Refresh Rate (VRR) и AutoHDR.
- **Схема питания «Максимальная производительность»**: активация Ultimate Performance / High Performance (исходный план запоминается для отката).
- **Отключение CPU Power Throttling**: предотвращение принудительного снижения частот ядер процессора.
- **Приостановка служб**: временная остановка некритичных служб (`SysMain`, `DiagTrack`, `Spooler`, `WSearch` и др.) с сохранением снимка.
- **Сброс ОЗУ и шейдеров**: очистка Standby-памяти и кэшей шейдеров DirectX, NVIDIA и AMD.

### `[4]` Оптимизация сети (`Network.bat`)
Обслуживание сетевого стека документированными командами:
- `ipconfig /flushdns` (очистка кэша DNS)
- `netsh winsock reset` (сброс каталога Winsock)
- `netsh int ip reset` (сброс стека TCP/IP)
- `ipconfig /release` и `ipconfig /renew` (обновление аренды DHCP)
- Проверка доступности шлюза и пинга.

### `[5]` Восстановление Windows (`Repair.bat`)
Автоматизированная проверка целостности системных файлов и компонентов:
- `SFC /SCANNOW` (проверка системных файлов)
- `DISM /Online /Cleanup-Image /ScanHealth`
- `DISM /Online /Cleanup-Image /RestoreHealth`
- `DISM /Online /Cleanup-Image /StartComponentCleanup`
- `CHKDSK C:` (с возможностью планирования исправления ошибок при перезагрузке).

### `[6]` Диагностика SSD / HDD (`Diagnostics.bat`)
Безопасная диагностика дисков (строго только для чтения):
- Список накопителей и статус SMART.
- Счётчики надёжности (температура, износ в %, часы наработки, ошибки чтения/записи).
- Анализ фрагментации системного диска (`defrag /A`, без запуска дефрагментации).
- Проверка активности функции TRIM для SSD.

### `[7]` Оптимизация процессов и ОЗУ (`ProcessOptimizer.bat`)
Снижение количества фоновых процессов и освобождение оперативной памяти:
- **Дашборд процессов**: живой счётчик запущенных процессов, занятая ОЗУ в ГБ и %, статусы оптимизаций.
- **Быстрый сброс ОЗУ**: очистка рабочих наборов (Working Sets) процессов через нативный `psapi.dll` `EmptyWorkingSet`.
- **Запрет фоновых UWP**: отключение фоновой активности неактивных приложений Microsoft Store.
- **Отключение фонового Edge и Copilot**: отключение фонового режима Edge, Startup Boost, виджетов панели задач и Copilot.
- **Отключение служб и задач телеметрии**: отключение 9 второстепенных служб сбора данных и задач в Планировщике.

### `[8]` Менеджер служб (`Services.bat`)
Управление второстепенными службами с отображением реального статуса.
- *Защита ядра*: защитные механизмы блокируют возможность остановки Defender, Windows Update, Брандмауэра, аудио и сети.

### `[9]` Информация о системе (`SystemInfo.bat`)
Аппаратный и системный аудит через современный интерфейс CIM:
- Выпуск Windows, номер сборки, время аптайма.
- Процессор, ядра, логические потоки, базовая частота.
- Видеокарта, объём видеопамяти, версия драйвера.
- Модули ОЗУ, частота (МГц), слоты, производитель.
- Материнская плата, версия BIOS/UEFI, разделы дисков и сетевые адаптеры.

### `[10]` Создать точку восстановления (`RestorePoint.bat`)
Создание контрольной точки восстановления системы через PowerShell `Checkpoint-Computer` со снятием 24-часового лимита частоты создания точек.

### `[11]` Восстановить прежние настройки (`Restore.bat`)
Центр полного отката:
- Перезапуск служб, остановленных Игровым режимом (по файлу снимка).
- Восстановление реестра из бэкапов `Backups\Registry\<timestamp>\` с удалением созданных ключей.
- Возврат исходного плана электропитания.
- Восстановление файла конфигурации `Config\settings.ini`.
- Запуск системного мастера восстановления Windows (`rstrui.exe`).

### `[12]` Настройки (`Config\settings.ini`)

| Параметр | По умолчанию | Описание |
|---|:---:|---|
| `AskConfirmation` | `1` | Запрашивать подтверждение перед выполнением операций |
| `CleanEventLogs` | `0` | Очищать журналы событий Windows при очистке |
| `CleanBrowserCache` | `0` | Очищать кэш Edge, Chrome и Firefox |
| `CleanRecycleBin` | `1` | Очищать Корзину при запуске очистки |
| `DisableGameBar` | `1` | Игровой режим отключает Xbox Game Bar |
| `DisableBackgroundRecording` | `1` | Игровой режим отключает Game DVR |
| `CloseBackgroundApps` | `1` | Игровой режим закрывает приложения из списка `BackgroundApps` |
| `SetHighPerformancePower` | `0` | Переключать план питания на максимальный в Игровом режиме |
| `RunChkdskInFullOptimization` | `1` | Включать проверку CHKDSK в полную оптимизацию |
| `BackgroundApps` | *список* | Список фоновых процессов для закрытия через запятую |
| `Language` | `auto` | Язык интерфейса (`ru`, `en` и др.) |

---

## 🛡️ Гарантии безопасности

1. **Неразрушаемость**: личные файлы пользователя (Документы, Рабочий стол, Загрузки, профили браузеров, вкладки, пароли) никогда не удаляются и не изменяются.
2. **Защита служб**: Defender, Центр безопасности, Windows Update и критически важные компоненты ОС невозможно случайно остановить.
3. **Автоматический бэкап**: перед любыми изменениями реестра сохраняются стандартные файлы отката `.reg`.
4. **Прозрачность кода**: открытый и чистый код на Batch и PowerShell без обфускации или скрытых бинарников.
5. **Портативность**: утилита работает без установки. Для полного удаления программы достаточно просто удалить её папку.

---

## 💻 System Requirements / Системные требования

- **Operating System**: Windows 10 (1809+) / Windows 11 (64-bit / x64).
- **Environment**: PowerShell 5.1 (встроена в Windows по умолчанию).
- **Privileges**: Права администратора для применения системных настроек (без них утилита работает в режиме чтения).

---

## 🗑️ Uninstallation / Удаление

Delete the folder. The tool creates no background services, tasks, or persistent drivers.  
*Просто удалите папку с программой. Утилита не оставляет скрытых служб, фоновых драйверов или записей в автозагрузке.*

---

<div align="center">

**WindowsOPTGame** is developed with care for Windows performance and system stability.  
*Разработано с заботой о максимальной производительности и стабильности Windows.*

</div>