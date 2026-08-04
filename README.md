# ZORO Ultimate Tweaking Utility

A single-file PowerShell menu utility for tuning Windows 10/11 network, power, gaming and background-service settings — with logging, backups, and one-click restore built in.

**Author:** zoro (`cwizxir`) · **Version:** 1.2.0 · **Requires:** Windows 10/11, Administrator, PowerShell 5.1+

---

## What it does

ZORO is a plain-text `.ps1` script (no installer, no compiled binary) that opens an interactive console menu with the following sections:

| # | Section | Examples |
|---|---------|----------|
| 1 | Network Optimization | Disable Nagle's Algorithm, TCP auto-tuning, ECN, NIC power-saving/RSS, ping test |
| 2 | DNS Optimizer | Benchmark Cloudflare / Google / Quad9 / OpenDNS and apply the fastest, flush cache |
| 3 | Windows Tweaks | Debloat first-party bundled apps, clean temp files, startup delay |
| 4 | CPU Tweaks | Power plan (High Performance / Balanced), core parking |
| 5 | Gaming Tweaks | HAGS, Xbox Game Bar, Fullscreen Optimizations, mouse acceleration, vendor-specific GPU tweaks |
| 6 | Miscellaneous | System Restore Point, change log viewer, about |
| 7 | Backup & Restore | Export/import every registry key the tool can touch |
| 8 | Responsiveness & GPU Tweaks | MMCSS "Games" profile, timer resolution, PCIe ASPM, AMD/NVIDIA-specific tweaks (menu adapts to your detected GPU) |
| 9 | Optional Service Tweaks | Disable low-impact or "caution" Windows services, each auto-backed-up and fully restorable |

On launch, ZORO detects your GPU vendor (or asks you to confirm it) so the Gaming and Responsiveness menus only show tweaks that apply to your hardware.

### Safety by design

- **Scope-limited:** it only touches network/DNS/power/gaming registry keys and first-party bundled "bloat" apps. It never disables Windows Defender, UAC, or Windows Update.
- **Everything is logged** to `C:\ZORO_Suite\Logs\`.
- **Every risky action asks for confirmation** (`Type Y to continue`) before it runs.
- **Backup & Restore (menu 7)** exports the exact registry keys the tool can modify, so you can roll back even outside the per-feature "restore default" options.
- **Service tweaks (menu 9)** remember each service's original startup type before disabling it, so restoring is exact — not a guess.

---

## Requirements

- Windows 10 (2004/build 19041+ for some GPU-scheduling tweaks) or Windows 11
- PowerShell 5.1 or newer (built into Windows)
- Administrator privileges — the script exits immediately if not run elevated

---

## Quick Start

### Option A — run directly from GitHub (no download step)

Open **PowerShell as Administrator**, then run:

```powershell
irm "https://raw.githubusercontent.com/zoronolonger/cwizxir/refs/heads/main/ZORO%20Tweaking%20Utility.ps1" | iex
```

### Option B — clone/download and run locally

```powershell
git clone https://github.com/zoronolonger/cwizxir.git
cd cwizxir
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\ZORO Tweaking Utility.ps1
```

> Full step-by-step instructions (with troubleshooting for execution-policy / SmartScreen warnings) are in [`HOW-TO-RUN.md`](HOW-TO-RUN.md).

---

## Before you tweak

Menu **[7] Backup & Restore → [1] Create a backup** and **[6] Miscellaneous → [1] Create a System Restore Point** are strongly recommended before applying tweaks, especially anything under menus 8 and 9.

## Disclaimer

This tool edits the Windows registry, services, and power settings. While every tweak is reversible through the built-in restore options, you are using it at your own risk. Review what a tweak does (the menu text and inline comments describe each one) before applying it, and always keep a backup or restore point.

## Changelog

See [`CHANGELOG.md`](CHANGELOG.md).

## License

Released under the [MIT License](LICENSE).

## Contact

- Discord: `cwizxir`
- GitHub: [github.com/zoronolonger](https://github.com/zoronolonger)
