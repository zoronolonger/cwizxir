# ZORO — Ultimate Tweaking Utility

A single-file PowerShell console tool for Windows 10/11 that optimizes network, DNS, CPU, gaming, and system responsiveness settings, with built-in backup/restore, logging, and safe service management.

**Version:** 1.2.0
**Author:** zoro (cwizxir)
**GitHub:** https://github.com/zoronolonger

**Scope:** ZORO only touches network/DNS/power/gaming registry settings and first-party bundled "bloat" apps. It never disables Windows Defender, UAC, Windows Update, or any other security feature.

---

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later
- Administrator privileges (the script checks on launch and exits if not elevated)

---

## Installation & Usage

1. Download `ZORO Tweaking Utility.ps1`.
2. Right-click the file and choose **Run with PowerShell**, or run it from an elevated PowerShell prompt:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "ZORO Tweaking Utility.ps1"
   ```
3. If not launched as Administrator, ZORO will show an error and exit — relaunch elevated.
4. On first launch, you'll be asked to pick your **GPU brand** (AMD, NVIDIA, Auto-detect, or Both/not sure). This choice filters which vendor-specific tweaks appear in the Gaming and Responsiveness & GPU menus for the rest of the session.
5. Use the numbered Main Menu to navigate. Each submenu has its own `[0] Back to Main Menu` option.

On startup, ZORO creates a workspace at:
```
%SystemDrive%\ZORO_Suite
├── Logs\        (daily .log files of every change made)
└── Backups\     (timestamped folders from Backup & Restore, plus service backups)
```
It also tracks the original startup type of any service you disable in `ServiceState.json`, so restores are exact rather than guessed.

---

## Main Menu

| Option | Section |
|---|---|
| 1 | Network Optimization |
| 2 | DNS Optimizer |
| 3 | Windows Tweaks |
| 4 | CPU Tweaks |
| 5 | Gaming Tweaks |
| 6 | Miscellaneous |
| 7 | Backup & Restore |
| 8 | Responsiveness & GPU Tweaks |
| 9 | Service Tweaks |
| D | Discord link |
| G | GitHub link |
| Q | Exit |

The banner also displays a live system snapshot (CPU, RAM, OS build, GPU, selected GPU profile, and ping to 8.8.8.8).

---

## 1. Network Optimization

- Disable Nagle's Algorithm (per-adapter `TcpAckFrequency` / `TCPNoDelay`)
- Set TCP Auto-Tuning to Normal
- Enable ECN (Explicit Congestion Notification)
- NIC Advanced: disable adapter power-saving and enable RSS on active physical adapters, using official `Set-NetAdapter*` cmdlets (adapters that don't support a setting are skipped safely, not force-written)
- Quick before/after ping test (4 pings to 8.8.8.8)
- Restore ALL network tweaks to Windows defaults

## 2. DNS Optimizer

- Benchmark Cloudflare, Google, Quad9, and OpenDNS, then optionally auto-apply the fastest to all active adapters
- Quick-set Cloudflare (1.1.1.1)
- Quick-set Google (8.8.8.8)
- Flush DNS cache
- Restore DHCP-assigned DNS on all active adapters

## 3. Windows Tweaks (Debloat + Cleanup)

- Debloat: remove selected pre-installed first-party apps from a fixed safe list (e.g. 3D Builder, Mixed Reality Portal, Bing Weather/News, Get Help, Office Hub, Solitaire Collection, People, Feedback Hub, Your Phone, Zune Music/Video, Skype, To Do, Clipchamp, Teams, Power Automate Desktop). Never touches Defender, Store, or Edge.
- Clean Temp Files (`%TEMP%` and `%SystemRoot%\Temp`, reports approximate space freed)
- Remove startup app launch delay
- Restore startup delay to Windows default

## 4. CPU Tweaks

- Set Power Plan: High Performance
- Disable CPU Core Parking
- Restore Power Plan: Balanced (Windows default)
- Restore CPU Core Parking to default

## 5. Gaming Tweaks

- Enable Hardware-Accelerated GPU Scheduling (requires reboot)
- Disable Xbox Game Bar / background recording
- Disable Fullscreen Optimizations (global default)
- Disable Mouse Acceleration
- **AMD only** (shown unless GPU profile is NVIDIA): disable the AMD External Events Utility service
- **NVIDIA only** (shown unless GPU profile is AMD): set NVIDIA Power Mode to Prefer Maximum Performance
- Restore ALL gaming tweaks to Windows defaults

## 6. Miscellaneous

- Create a System Restore Point
- View change log (last 40 log lines)
- About / Credits

## 7. Backup & Restore

Exports/imports only the specific registry locations ZORO itself can modify, so any tweak can be undone even without using that tweak's own "restore default" option:

- TCP/IP interface parameters
- GameConfigStore, GameDVR, and GameDVR policy keys
- Mouse settings
- Explorer startup-delay serialization
- Graphics drivers key (HAGS, TDR delay)
- Desktop (UI delay) settings
- DWM (Multi-Plane Overlay)
- Multimedia SystemProfile (MMCSS "Games" task)
- Session Manager kernel key (timer resolution)
- Active power scheme (saved as a text snapshot)

Menu options:
- Create a backup of tweakable settings
- Restore settings from a previous backup (choose from a list, newest first)
- Open the backups folder in Explorer

## 8. Responsiveness & GPU Tweaks

Menu items are built dynamically each time based on your selected GPU profile.

**Always shown:**
- Disable Multi-Plane Overlay
- Reduce menu/mouse-hover delay
- Apply MMCSS "Games" profile + SystemResponsiveness = 0
- Enable high-resolution system timer
- Enable hover-to-focus window tracking
- Extend GPU driver TDR delay to 8 seconds (reduces false "driver crashed" recoveries under sustained load)
- Disable PCIe ASPM power saving (Windows-side; notes that BIOS-side disable is also needed for full effect)
- Toggle Hardware-Accelerated GPU Scheduling (menu shows current state)
- Disable Fullscreen Optimizations for all games

**AMD only** (shown unless GPU profile is NVIDIA):
- Shader Cache = Always On
- Shader Cache = Off
- Tessellation override = Max 16x
- Tessellation override = Application Controlled
- Disable ULPS
- Set AMD FUEL Service to Manual

**NVIDIA only** (shown unless GPU profile is AMD):
- Power Mode = Prefer Maximum Performance
- Set NVIDIA Telemetry service to Manual
- Set NVIDIA Container services (NvContainerLocalSystem / NvContainerNetworkService) to Manual

- Restore ALL of the above to Windows defaults

## 9. Optional Service Tweaks

Curated, opt-in service disabling. Every disable is backed up (`.reg` export) and its original startup type is recorded before changing it, so restores are exact.

- **Disable low-impact services** — a fixed safe list (e.g. DiagTrack, Maps Broker, Geolocation, Family Safety, Fax, Retail Demo Mode, Offline Files, Payments/NFC, Link-Layer Topology Discovery, App-V, Assigned Access, Work Folders, UE-V, Messaging, Shared PC Account Manager, Program Compatibility Assistant, Windows Error Reporting, Net.Tcp Port Sharing, Quality Windows A/V Experience)
- **Disable caution services** — a fixed list with explicit warnings about what breaks (e.g. Bluetooth, Windows Hello biometrics, Print Spooler, Windows Search, Smart Card, touch keyboard/handwriting, Phone Link, Mail/Calendar sync, Xbox Live services, Game DVR/Broadcast)
- **Restore previously disabled services** — restores services back to their recorded original startup type (and starts them if that type was Automatic)

---

## Safety Systems

- **Admin check** — the script refuses to run without Administrator rights.
- **Confirmation prompts** — risky actions require an explicit `Y` before applying.
- **Logging** — every registry write/removal is logged with a timestamp to a daily log file under `Logs\`, viewable from the Miscellaneous menu.
- **System Restore Point** — can be created on demand before making changes.
- **Backup & Restore** — exports/imports the exact registry keys ZORO can modify, as timestamped `.reg` backups.
- **Service state tracking** — original service startup types are recorded before any change and restored precisely, not guessed.
- **Debloat scope guard** — only removes apps from a fixed first-party list; never touches Defender, Microsoft Store, Edge, or Windows Update.
- **NIC changes use official cmdlets** — power-saving/RSS changes go through `Set-NetAdapter*`, which validates against driver support and skips unsupported adapters instead of forcing raw registry writes.

---

## Credits

Made by zoro (cwizxir)
GitHub: https://github.com/zoronolonger
