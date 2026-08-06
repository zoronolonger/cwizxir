# ZORO — Ultimate Tweaking Utility

> Version 1.2.0 · Windows 10/11 · PowerShell 5.1+ · Administrator required

Everything you need to install, use, and uninstall ZORO in one place.

## Table of Contents

- [Requirements](#requirements)
- [Install](#install)
- [Launching](#launching)
- [GPU Profile Prompt](#gpu-profile-prompt)
- [Main Menu](#main-menu)
- [Menu Reference](#menu-reference)
- [Undoing Changes](#undoing-changes)
- [Logs](#logs)
- [Uninstall](#uninstall)

---

## Requirements

- Windows 10 or 11
- PowerShell 5.1 or newer
- Administrator privileges

ZORO only modifies network/DNS/power/gaming registry settings, adapter settings, curated background services, and a fixed list of first-party bundled apps. It never touches Windows Defender, UAC, Windows Update, the Microsoft Store, or Edge.

---

## Install

ZORO has no installer. Download the script and run it — that's the entire setup.

1. Download `ZORO Tweaking Utility.ps1` from:
   ```
   https://raw.githubusercontent.com/zoronolonger/cwizxir/refs/heads/main/ZORO%20Tweaking%20Utility.ps1
   ```
2. Save it anywhere on your system (e.g. Desktop or Downloads).
3. Run it as Administrator — see [Launching](#launching) below.

Nothing is installed elsewhere: no registry entries for the tool itself, no service, no scheduled task, no startup entry. ZORO only runs while its PowerShell window is open.

> **Tip**
> Before tweaking anything, run **`[7] Backup & Restore → [1] Create a backup`** and **`[6] Miscellaneous → [1] Create a System Restore Point`**. Both are optional but make undoing changes trivial later.

---

## Launching

Right-click `ZORO Tweaking Utility.ps1` → **Run with PowerShell**, or from an elevated PowerShell window:

```powershell
powershell -ExecutionPolicy Bypass -File "ZORO Tweaking Utility.ps1"
```

If PowerShell isn't elevated, ZORO prints:

```
[ERROR] Please run ZORO as Administrator!
```

and exits — relaunch as Administrator.

On success, ZORO creates its workspace automatically:

```
%SystemDrive%\ZORO_Suite\
├── Logs\               daily .log file of every change made
├── Backups\             timestamped backup folders + ServiceBackups\
└── ServiceState.json    original startup type of any service you disable
```

---

## GPU Profile Prompt

Before the main menu appears, ZORO detects your GPU and asks you to confirm a profile:

| Option | Effect |
|---|---|
| `[1] AMD` | Show AMD-specific tweaks only |
| `[2] NVIDIA` | Show NVIDIA-specific tweaks only |
| `[3] Auto-detect` | Use whatever ZORO detected |
| `[4] Show both / not sure` | Show every vendor section |

This affects the **Gaming Tweaks** and **Responsiveness & GPU Tweaks** menus for the rest of the session. It's asked once per launch — restart ZORO to change it.

---

## Main Menu

```
 [1] Network Optimization      [2] DNS Optimizer
 [3] Windows Tweaks            [4] CPU Tweaks
 [5] Gaming Tweaks             [6] Miscellaneous
 [7] Backup & Restore          [8] Responsiveness & GPU Tweaks
 [9] Service Tweaks
 [D] Discord   [G] GitHub   [Q] Exit
```

Every submenu has its own `[0] Back to Main Menu` option and pauses on `Press ENTER...` after each action so you can read the result.

---

## Menu Reference

<details>
<summary><b>[1] Network Optimization</b></summary>

Disable Nagle's Algorithm, set TCP Auto-Tuning to Normal, enable ECN, or apply NIC Advanced (disables adapter power-saving + enables RSS via official `Set-NetAdapter*` cmdlets — unsupported adapters are skipped, not forced). `[5]` runs a quick 4-ping test to `8.8.8.8` for before/after comparison. `[6]` reverts everything to Windows defaults.
</details>

<details>
<summary><b>[2] DNS Optimizer</b></summary>

`[1]` pings Cloudflare, Google, Quad9, and OpenDNS, then offers to apply the fastest to all active adapters. `[2]`/`[3]` quick-set Cloudflare or Google directly. `[4]` flushes the DNS cache. `[5]` reverts to DHCP-assigned DNS.
</details>

<details>
<summary><b>[3] Windows Tweaks</b></summary>

`[1] Debloat` shows a checklist of removable first-party apps (`1,3,5`, `all`, or ENTER to cancel) — never touches Defender, Store, or Edge. `[2]` clears temp files and reports approximate space freed. `[3]`/`[4]` remove or restore the Explorer startup launch delay.
</details>

<details>
<summary><b>[4] CPU Tweaks</b></summary>

Switch between **High Performance** and **Balanced** power plans, and enable/restore CPU core parking.
</details>

<details>
<summary><b>[5] Gaming Tweaks</b></summary>

Enable HAGS (needs a reboot), disable Xbox Game Bar/background recording, disable Fullscreen Optimizations globally, or disable mouse acceleration. Vendor-specific items only appear per your GPU profile:

- **AMD only** — disable the AMD External Events Utility service
- **NVIDIA only** — set Power Mode to Prefer Maximum Performance

`[6]` restores all Gaming Tweaks to defaults, including whichever vendor tweak applies.
</details>

<details>
<summary><b>[6] Miscellaneous</b></summary>

Create a System Restore Point, view the last 40 lines of today's log, or check version/credit info.
</details>

<details>
<summary><b>[7] Backup & Restore</b></summary>

`[1]` exports the specific registry keys ZORO can modify (TCP/IP interfaces, GameConfigStore, GameDVR, Mouse, Explorer Serialize, GraphicsDrivers, Desktop, Dwm, Multimedia SystemProfile, Session Manager kernel, plus the active power scheme) into a timestamped folder. `[2]` lists existing backups (newest first) for re-import. `[3]` opens the backups folder in Explorer.
</details>

<details>
<summary><b>[8] Responsiveness & GPU Tweaks</b></summary>

Rebuilt every time you open it based on your GPU profile, so item numbers shift depending on which vendor sections are showing. Always present: Multi-Plane Overlay, UI hover/menu delay, MMCSS "Games" profile, high-resolution timer, hover-to-focus window tracking, GPU driver TDR delay, PCIe ASPM power saving, a HAGS toggle (shows current state), and Fullscreen Optimizations. AMD-only and NVIDIA-only items are appended when applicable. The last item always reverts everything to Windows defaults.
</details>

<details>
<summary><b>[9] Service Tweaks</b></summary>

`[1]` and `[2]` show checklists of safe and caution-level background services you can disable (`all` or ENTER to cancel). Every disable is backed up as a `.reg` file with its original startup type recorded first. `[3]` restores any previously disabled service to its recorded original state.
</details>

---

## Undoing Changes

Three layers, from most to least specific:

1. **Per-menu restore options** — Network, DNS, Windows, CPU, Gaming, and Responsiveness & GPU each have a dedicated item that reverts just that menu to Windows defaults.
2. **`[9] → [3] Restore previously disabled services`** — restores any service ZORO disabled to its exact recorded startup type.
3. **`[7] → [2] Restore settings from a previous backup`** — re-imports a full `.reg` snapshot, independent of which individual restores you used.

For anything outside these registry keys, fall back to the **System Restore Point** created from the Miscellaneous menu.

Two actions in ZORO have no restore option because they're one-time operations, not persistent settings:

| Action | Why it can't be restored | What to do |
|---|---|---|
| Debloat — removed apps (`[3] → [1]`) | Uninstalling an app isn't reversible from the registry | Reinstall from the Microsoft Store if needed |
| Clean Temp Files (`[3] → [2]`) | Deleted files are gone | Nothing to do — this is expected |

---

## Logs

Every registry write or removal is timestamped to:

```
%SystemDrive%\ZORO_Suite\Logs\yyyy-MM-dd.log
```

View recent entries from `[6] Miscellaneous → [2] View change log`, or open the file directly for the full history.

---

## Uninstall

Uninstalling ZORO is two independent steps: **restore Windows** (recommended), then **remove the files**.

> **Do this in order.** Restore your settings first, then delete files. Once `ZORO_Suite` is gone, the built-in restore options no longer have anything to work from.

### 1. Restore Windows

Run the script one more time, elevated, and work through the [Undoing Changes](#undoing-changes) section above:

1. `[7] → [2]` — restore from a backup, if you made one.
2. Go through each menu's restore-to-defaults option.
3. `[9] → [3]` — restore any disabled services.
4. Reboot once if you toggled Hardware-Accelerated GPU Scheduling — it only takes effect after a restart, whether enabling or disabling.
5. (Optional) Roll back further via Windows System Restore (`rstrui.exe`) if you created a restore point.

### 2. Remove ZORO's data

Once tweaks are restored, the working folder is safe to delete — it only contains logs and backups, nothing Windows depends on:

```powershell
Remove-Item -Path "$env:SystemDrive\ZORO_Suite" -Recurse -Force
```

> **Note**
> This deletes `ServiceState.json`, which is how ZORO remembers each service's original startup type. Run `[9] → [3]` first if you're not fully done restoring services.

### 3. Remove the script

Delete `ZORO Tweaking Utility.ps1` from wherever you saved it. Since ZORO installs no service, scheduled task, startup entry, or background process, this is the entire removal — there's no leftover component anywhere else on the system.

### Quick checklist

1. Run ZORO as Administrator.
2. `[7] → [2]` restore from backup (if any).
3. Restore each menu to defaults (Network, DNS, Windows, CPU, Gaming, Responsiveness & GPU).
4. `[9] → [3]` restore disabled services.
5. Reboot if HAGS was toggled.
6. Delete `%SystemDrive%\ZORO_Suite`.
7. Delete `ZORO Tweaking Utility.ps1`.

> **Warning**
> Deleting ZORO's files does **not** undo any tweaks — the script only reads/writes registry values and service settings, and removing the `.ps1` or `ZORO_Suite` folder has no effect on changes already applied to Windows. Always restore first.

---

<div align="center">

Made by **zoro** (cwizxir) · [GitHub](https://github.com/zoronolonger)

</div>
