# ZORO Tweaking Utility

**A menu-driven PowerShell utility for optimizing network, DNS, power, CPU, and gaming-related settings on Windows 10 / 11 — with built-in backups, an undo ledger, and honest, numeric ratings for every tweak.**

Author: **zoro** (`cwizxir`) · Discord: `cwizxir` · GitHub: [github.com/zoronolonger](https://github.com/zoronolonger)
Current version: **3.9.0** · License: MIT

---

## What ZORO Actually Is

ZORO is a single PowerShell script (`ZORO Tweaking Utility.ps1`) that presents a text menu in a console window. Every action it can take — from disabling Nagle's Algorithm to running an MTU discovery scan to uninstalling Microsoft Edge — is triggered explicitly by you, from a numbered menu. Nothing runs automatically in the background unless you start it (the one exception, the optional **Live Network Health Monitor**, is a feature you turn on yourself and can pause, resume, or stop at any time).

ZORO's scope is deliberately narrow: **network/DNS registry and adapter settings, power plans, CPU/GPU responsiveness settings, gaming-related registry values, and first-party "bloat" apps that ship with Windows.** It does not touch Windows Defender, User Account Control, Windows Update, BitLocker, or any other security control — with a single, clearly-labeled, opt-in exception: Memory Integrity (HVCI) can be toggled from the Responsiveness menu, and the tool warns you about the security trade-off every time, before you confirm it.

## What ZORO Is Not

- It is **not** a "one-click optimizer." There is no "apply everything" button. Every tweak is its own menu entry that you select individually.
- It does **not** claim inflated performance numbers. Every tweak that changes system behavior carries an honesty rating from **1/10 to 10/10** describing its *real-world* impact on a modern system — not a marketing figure. The full reasoning behind every rating is documented in [`TWEAK_AUDIT.md`](TWEAK_AUDIT.md).
- It does **not** pretend every change is reversible by magic. Registry values and service startup types are undoable. App/Edge removal, temp-file deletion, and DISM/SFC repairs are not — and ZORO tells you so, in the tool itself and in this documentation.

## Feature Overview

| Menu | What it does |
|---|---|
| **[1] Network Optimization** | Nagle's Algorithm, Interrupt Moderation, ECN, NIC power/RSS, Delivery Optimization P2P restriction, MTU Discovery, TCP Analyzer, Advanced NIC Optimizer, Energy Efficient Ethernet |
| **[2] DNS Optimizer** | Smart DNS Benchmark, quick-set Cloudflare/Google/AdGuard, DNS flush, current config viewer, restore to DHCP |
| **[3] Windows Tweaks** | Debloat checklist, temp file cleanup, startup delay, Background Apps toggle |
| **[4] CPU Tweaks** | High Performance / Ultimate Performance / Balanced power plans, CPU & hybrid-topology diagnostics |
| **[5] Gaming Tweaks** | Game Bar/DVR, mouse acceleration, AMD/NVIDIA vendor-specific tweaks |
| **[6] Miscellaneous** | System Restore Point creation, change log, About, Tweak Health Check, System Requirements Check |
| **[7] Backup & Restore** | Create/restore a ZORO settings backup, open the backup folder |
| **[8] Responsiveness & GPU Tweaks** | MPO, UI delays, timer resolution, GPU MSI Mode, HVCI/Memory Integrity, TDR delay, ASPM, Fullscreen Optimizations, USB Selective Suspend, Power Throttling, Dynamic Tick, HAGS, AMD/NVIDIA-specific settings |
| **[9] Service Tweaks** | Disable low-impact/caution Windows services, GPU vendor background services, restore |
| **[10] GPU Extras** | Clear DirectX shader cache, extend TDR delay for RT/frame-gen workloads |
| **[11] System Repair & RAM** | DISM CheckHealth/ScanHealth/RestoreHealth, SFC, full repair pass, standby memory list clean |
| **[12] Remove Microsoft Edge** | Complete, standalone removal of Microsoft Edge (process, services, files, registry, Appx, shortcuts) |
| **[13] Connection Benchmark** | Full or quick network quality benchmark (ping/jitter/loss, DNS latency, throughput, weighted score) |
| **[14] Live Network Health Monitor** | Start/stop/pause/resume a live, auto-refreshing dashboard of connection health |
| **[15] Game Network Diagnostics** | Best game adapter detection, NIC driver health check, IRQ/MSI detection, Bufferbloat test, route quality analyzer, gaming service connectivity test, diagnostics report |
| **[U] Undo Last Session** | Rolls back every registry/service-startup change ZORO has made this session (or a previous unclosed session) |

Every menu is documented in detail, tweak by tweak, in [`HOW_TO_USE.md`](HOW_TO_USE.md) and [`TWEAK_AUDIT.md`](TWEAK_AUDIT.md).

## First Launch Safety

The first time you run ZORO, it walks through the following sequence before it ever changes a single setting:

1. **Environment validation.** The script checks that it's running on a supported OS build and that required system components (registry access, `Get-NetAdapter`, `powercfg`, etc.) respond as expected.
2. **Administrator privilege check.** If ZORO is not already elevated, it automatically relaunches itself via a UAC prompt. If you decline the UAC prompt, ZORO exits with a clear message instead of continuing in a broken, unprivileged state.
3. **Windows version detection.** The banner and System Requirements Check ([6] → [5]) report your detected Windows build and flag anything below the supported minimum (Windows 10 22H2 / Windows 11 23H2).
4. **Workspace creation, not a system backup, on launch.** On first run ZORO creates its working folder structure at `C:\ZORO_Suite` (`Logs\`, `Backups\`) — but it does **not** automatically back up your registry or create a System Restore Point the moment it opens. Backups and restore points are both one menu selection away ([7] Backup & Restore, and [6] → [1] Create a System Restore Point) and ZORO reminds you to use them before you start tweaking. See [`HOW_TO_USE.md`](HOW_TO_USE.md) for exactly when to run each.
5. **Why a restore point is strongly recommended.** ZORO's own backup mechanism (menu [7]) only captures the specific registry keys and DNS settings *it* is capable of changing. A Windows System Restore Point is a broader, OS-level safety net that can recover from problems outside ZORO's own scope (driver issues, unrelated registry damage, a bad service change) — the two are complementary, not redundant, and ZORO's Miscellaneous menu makes creating one a single keypress.
6. **No unattended changes.** ZORO never applies a tweak without you selecting it from a menu and, for anything higher-impact or irreversible, confirming a yes/no prompt first. There is no silent "recommended settings" pass.
7. **Logging from the first line of output.** Every session — successes, failures, skipped tweaks, and unhandled errors — is appended to a dated log file under `C:\ZORO_Suite\Logs\`, starting from the moment the script launches.
8. **Reverting changes is always available.** Registry and service-startup changes can be rolled back individually or as a batch through **[U] Undo Last Session**, and more broadly through **[7] Backup & Restore**. Not every change ZORO can make is undoable this way (see [`HOW_TO_USE.md`](HOW_TO_USE.md#how-undo-works) for the exact scope) — where that's true, ZORO says so up front instead of pretending otherwise.

## Requirements

- Windows 10 22H2 or later, or Windows 11 23H2 (24H2 recommended)
- PowerShell 5.1 or later (the version that ships with Windows 10/11 by default)
- Administrator rights (ZORO self-elevates via UAC — you don't need to manually launch an elevated prompt)
- Windows 7, Windows 8/8.1, and Windows Server editions are **out of scope** and are not detected for or supported anywhere in the script.

See [`INSTALL.md`](INSTALL.md) for full setup instructions.

## Documentation Index

| Document | Purpose |
|---|---|
| [`HOW_TO_USE.md`](HOW_TO_USE.md) | Full usage walkthrough: launching, every menu, best practices, Undo/Backup/Restore/Diagnostics |
| [`INSTALL.md`](INSTALL.md) | Installing and first-launch instructions |
| [`UNINSTALL.md`](UNINSTALL.md) | Safely reverting changes and removing ZORO from your system |
| [`TWEAK_AUDIT.md`](TWEAK_AUDIT.md) | Every tweak classified (Safe / Recommended / Situational / Legacy / Experimental) with purpose, benefit, risk, and restart requirement |
| [`SECURITY.md`](SECURITY.md) | Supported versions and vulnerability reporting |
| [`PRIVACY.md`](PRIVACY.md) | What data ZORO reads, stores, and never sends anywhere |
| [`DISCLAIMER.md`](DISCLAIMER.md) | No-warranty terms and use-at-your-own-risk notice |
| [`SUPPORTED.md`](SUPPORTED.md) | Supported Windows versions, hardware, and PowerShell versions |
| [`ROADMAP.md`](ROADMAP.md) | Planned direction for future releases |
| [`VERSIONING.md`](VERSIONING.md) | How ZORO's version numbers are structured |
| [`CHANGELOG.md`](CHANGELOG.md) | Full version history |
| [`LICENSE`](LICENSE) | MIT License |

## Quick Start

```powershell
# From an elevated or a regular PowerShell prompt (ZORO will elevate itself)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\ZORO Tweaking Utility.ps1
```

See [`INSTALL.md`](INSTALL.md) for details, including SmartScreen and Execution Policy guidance.

## Safety Philosophy

ZORO is built around three rules that shape every menu in this document set:

1. **Nothing happens without a choice.** No tweak fires without an explicit menu selection, and higher-impact tweaks require an additional yes/no confirmation.
2. **Say what a tweak actually does — and doesn't.** Every performance claim carries a real-world rating instead of a marketing number, and situational risk (battery impact, security trade-offs, hardware dependency) is called out in the confirmation prompt itself, not buried in a README.
3. **Make it reversible, and say so honestly when it isn't.** Registry writes and service-startup changes go through a verified undo ledger. App removal and file cleanup do not — and ZORO tells you that before you run them, not after.

## Support & Community

- **Discord:** `cwizxir`
- **GitHub:** [github.com/zoronolonger](https://github.com/zoronolonger)
- **Security issues:** see [`SECURITY.md`](SECURITY.md)

## License

ZORO Tweaking Utility is released under the [MIT License](LICENSE).
