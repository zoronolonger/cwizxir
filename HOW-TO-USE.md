# How to Use ZORO

## Launch

Run `ZORO Tweaking Utility.ps1` in PowerShell. There's nothing to install —
the script is self-contained.

## Administrator behavior

On launch, ZORO checks whether the current session is elevated
(`WindowsPrincipal`/`WindowsBuiltInRole::Administrator`). If it is not
running as Administrator, it prints an error and exits immediately after
you press Enter.

## Auto elevation

ZORO does **not** auto-elevate itself. You must start PowerShell as
Administrator (or right-click the script and choose "Run with PowerShell"
from an already-elevated shell/File Explorer configuration) before running
it. There is no relaunch/UAC-prompt logic in the script.

## GPU profile prompt

Immediately after the admin check, ZORO asks which GPU brand you run:

- `[1] AMD` — show AMD-only tweaks
- `[2] NVIDIA` — show NVIDIA-only tweaks
- `[3] Auto-detect` — uses the GPU ZORO already detected via WMI
- `[4] Show both / not sure` — shows every vendor's tweaks

This choice is remembered for the rest of the session and controls which
options appear in the **Gaming Tweaks** and **Responsiveness & GPU Tweaks**
menus. It is asked once per run — restart the script to change it.

## The banner

Every menu screen redraws a banner showing your CPU, RAM, OS build, GPU
(plus your selected profile), and current ping to 8.8.8.8.

## Main Menu

```
[1] Network Optimization      [2] DNS Optimizer
[3] Windows Tweaks            [4] CPU Tweaks
[5] Gaming Tweaks             [6] Miscellaneous
[7] Backup & Restore          [8] Responsiveness & GPU Tweaks
[9] Service Tweaks
[D] Discord   [G] GitHub   [Q] Exit
```

### [1] Network Optimization
- **[1]** Disable Nagle's Algorithm — writes `TcpAckFrequency`/`TCPNoDelay`
  to every network adapter's interface key. Confirmation required.
- **[2]** TCP Auto-Tuning: Normal — `netsh int tcp set global
  autotuninglevel=normal`.
- **[3]** Enable ECN — `netsh int tcp set global ecncapability=enabled`.
- **[4]** NIC Advanced — disables adapter power-saving and enables RSS on
  every active physical adapter via `Set-NetAdapterPowerManagement` /
  `Enable-NetAdapterRss`. Adapters whose driver doesn't support a setting
  are skipped, not force-written. Confirmation required.
- **[5]** Quick before/after ping test — 4 pings to 8.8.8.8, reports the
  average.
- **[6]** Restore ALL network tweaks — reverts Nagle, resets TCP
  autotuning/ECN to their "normal"/"enabled" values, and re-enables NIC
  power-saving. Confirmation required.

### [2] DNS Optimizer
- **[1]** Benchmark providers and auto-apply the fastest — pings
  Cloudflare (1.1.1.1), Google (8.8.8.8), Quad9 (9.9.9.9), and OpenDNS
  (208.67.222.222), 2 pings each, then offers to apply the winner to every
  active adapter.
- **[2]** Quick-set Cloudflare (1.1.1.1 / 1.0.0.1)
- **[3]** Quick-set Google (8.8.8.8 / 8.8.4.4)
- **[4]** Flush DNS cache
- **[5]** Restore DHCP-assigned DNS on all active adapters (undoes 1–3)

### [3] Windows Tweaks
- **[1]** Debloat — a checklist of 19 first-party bundled apps (3D
  Builder, 3D Viewer, Mixed Reality Portal, Weather, News, Get Help,
  Get Started, Office Hub, Solitaire Collection, People, Feedback Hub,
  Your Phone, Zune Music/Video, Skype, To Do, Clipchamp, Teams, Power
  Automate Desktop). Select by number, comma list, or `all`. Never removes
  Defender, Store, or Edge.
- **[2]** Clean Temp Files — clears `%TEMP%` and `%SystemRoot%\Temp`,
  reports approximate MB freed.
- **[3]** Remove startup app launch delay (`StartupDelayInMSec = 0`).
- **[4]** Restore startup delay to Windows default (removes the override).

### [4] CPU Tweaks
- **[1]** Set Power Plan: High Performance
- **[2]** Disable CPU Core Parking (`CPMINCORES = 100` on the active
  scheme). Confirmation required — can raise idle power draw.
- **[3]** Restore Power Plan: Balanced (Windows default)
- **[4]** Restore CPU Core Parking to default (`CPMINCORES = 5`)

### [5] Gaming Tweaks
- **[1]** Enable Hardware-Accelerated GPU Scheduling (needs reboot)
- **[2]** Disable Xbox Game Bar / background recording
- **[3]** Disable Fullscreen Optimizations (global default)
- **[4]** Disable Mouse Acceleration
- **[5]** AMD-only: Disable AMD External Events Utility service — shown
  unless your GPU profile is NVIDIA
- **[7]** NVIDIA-only: Prefer Maximum Performance power mode — shown
  unless your GPU profile is AMD
- **[6]** Restore ALL gaming tweaks — reverts everything above, including
  whichever vendor tweak applies to your profile

Note the numbering here is exactly as implemented: options 5 and 7 are
vendor-conditional and 6 is the restore-all option, so the on-screen list
isn't strictly sequential when only one vendor section is showing.

### [6] Miscellaneous
- **[1]** Create a System Restore Point (`Checkpoint-Computer`, type
  `MODIFY_SETTINGS`). Not automatic — you must run this yourself before
  tweaking if you want a restore point.
- **[2]** View change log — last 40 lines of today's log file.
- **[3]** About / Credits — version, author, GitHub link.

### [7] Backup & Restore
- **[1]** Create a backup — exports these registry paths (where present)
  to a timestamped folder under `ZORO_Suite\Backups`:
  `Tcpip\Parameters\Interfaces`, `GameConfigStore`, `GameDVR`,
  `GameDVR` policy, `Control Panel\Mouse`, `Explorer\Serialize`,
  `GraphicsDrivers`, `Control Panel\Desktop`, `Dwm`,
  `Multimedia\SystemProfile`, `Session Manager\kernel`. Also records the
  active power scheme.
- **[2]** Restore settings from a previous backup — pick a timestamped
  backup from a list, confirm, and every `.reg` file in it is re-imported.
- **[3]** Open the backups folder in Explorer.

### [8] Responsiveness & GPU Tweaks
This menu is built dynamically each time it opens, so its numbering shifts
depending on your GPU profile. The vendor-neutral items always shown:

1. Disable Multi-Plane Overlay
2. Reduce menu/mouse-hover delay
3. Apply MMCSS "Games" profile + `SystemResponsiveness = 0`
4. Enable high-resolution system timer
5. Enable hover-to-focus window tracking
6. Extend GPU driver TDR delay to 8 seconds
7. Disable PCIe ASPM power saving (asks whether to also disable it in BIOS)
8. Toggle Hardware-Accelerated GPU Scheduling (shows current state)
9. Disable Fullscreen Optimizations for all games

If your GPU profile is not NVIDIA, AMD-only items are appended: Shader
Cache (Always On / Off), Tessellation override (Max 16x / Application
controlled), Disable ULPS (confirmation required — raises idle GPU power),
and Set AMD FUEL Service to Manual.

If your GPU profile is not AMD, NVIDIA-only items are appended: Power Mode
(Prefer Maximum Performance), Set NVIDIA Telemetry service to Manual, and
Set NVIDIA Container services (`NvContainerLocalSystem` /
`NvContainerNetworkService`) to Manual.

The last item is always **Restore ALL of the above to Windows defaults**,
which also reverts whichever vendor section applied to your session.

### [9] Service Tweaks
- **[1]** Disable low-impact services — a checklist of 19 services
  considered safe for most PCs (DiagTrack telemetry, Maps Broker,
  Geolocation, Parental Controls, Fax, Retail Demo Mode, Offline Files,
  Payments/NFC, Link-Layer Topology Discovery, App-V, Assigned Access,
  Work Folders, UE-V, Phone Link messaging, Shared PC Account Manager,
  Program Compatibility Assistant, Windows Error Reporting, Net.Tcp Port
  Sharing, Quality Windows A/V Experience).
- **[2]** Disable caution services — a second checklist with an extra
  warning, covering Bluetooth, Windows Hello biometrics, Print Spooler,
  Windows Search, Smart Card, touch/handwriting input, Phone Link, mail
  sync, and several Xbox Live services.
- **[3]** Restore previously disabled services — restores each service to
  the exact startup type it had before ZORO touched it (from
  `ServiceState.json`), starting it back up if it was originally
  Automatic.

Every disable in this menu is preceded by an automatic `.reg` export of
that service's key and a record of its original startup type.

## Backup workflow

1. `[7] Backup & Restore → [1] Create a backup` before making changes.
2. Apply whatever tweaks you want.
3. If something feels wrong, `[7] Backup & Restore → [2] Restore settings
   from a previous backup` and pick the backup you made.

## Restore workflow

- For most individual tweaks: use the matching "Restore" option in the
  same menu.
- For registry-key-level rollback: `[7] Backup & Restore → [2]`.
- For services disabled via `[9]`: `[9] → [3] Restore previously disabled
  services`.

## Recommended order

1. Launch as Administrator, pick your GPU profile.
2. `[6] Miscellaneous → [1]` Create a System Restore Point.
3. `[7] Backup & Restore → [1]` Create a backup.
4. Apply tweaks menu by menu.
5. Reboot if you touched HAGS, TDR delay, or anything else flagged as
   needing a restart.

## Best practices

- Read each confirmation prompt — several tweaks explicitly warn about
  trade-offs (idle power draw, fan noise, driver crash-recovery timing).
- Don't disable a "Caution" service unless you're sure you don't use the
  feature it backs.
- Re-run the GPU profile prompt (restart the script) if you change your
  graphics card.

## Warnings

- ZORO will not run without Administrator rights.
- Disabling Print Spooler, Windows Search, Bluetooth, or Windows Hello
  services will break the corresponding Windows feature until restored.
- NIC power-saving/RSS changes are skipped (not forced) on adapters whose
  driver doesn't expose the setting.
