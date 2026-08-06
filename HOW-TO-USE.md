# How to Use ZORO — Ultimate Tweaking Utility

This guide walks through running ZORO (v1.2.0) and using each menu. For a full feature reference see `README.md`.

---

## 1. Before You Start

- Windows 10 or 11, PowerShell 5.1+, Administrator rights.
- ZORO only modifies network/DNS/power/gaming registry settings and a fixed list of first-party bundled apps. It never touches Windows Defender, UAC, Windows Update, or any other security feature.
- Recommended first steps once the app opens: go to **[7] Backup & Restore → [1] Create a backup**, and **[6] Miscellaneous → [1] Create a System Restore Point**. Both are optional but make undoing anything trivial.

---

## 2. Launching ZORO

1. Right-click `ZORO Tweaking Utility.ps1` → **Run with PowerShell**, or run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "ZORO Tweaking Utility.ps1"
   or powershell -ExecutionPolicy Bypass -File "C:\Users\...\ZORO Tweaking Utility.ps1"
   ```
2. If PowerShell isn't elevated, ZORO prints `[ERROR] Please run ZORO as Administrator!` and exits — relaunch as Administrator.
3. On success, ZORO creates its workspace automatically:
   ```
   %SystemDrive%\ZORO_Suite\
   ├── Logs\               daily .log file of every change made
   ├── Backups\             timestamped backup folders + ServiceBackups\
   └── ServiceState.json     original startup type of any service you disable
   ```

---

## 3. First Prompt: GPU Profile

Before the main menu appears, ZORO detects your GPU and asks you to confirm:

- **[1] AMD** — only show AMD-specific tweaks
- **[2] NVIDIA** — only show NVIDIA-specific tweaks
- **[3] Auto-detect** — use whatever ZORO detected
- **[4] Show both / not sure** — show every vendor section

This choice only affects which items appear in the **Gaming Tweaks** and **Responsiveness & GPU Tweaks** menus for the rest of the session. It is asked once per launch — to change it, restart ZORO.

---

## 4. Main Menu

```
 [1] Network Optimization      [2] DNS Optimizer
 [3] Windows Tweaks            [4] CPU Tweaks
 [5] Gaming Tweaks             [6] Miscellaneous
 [7] Backup & Restore          [8] Responsiveness & GPU Tweaks
 [9] Service Tweaks
 [D] Discord   [G] GitHub   [Q] Exit
```

Every submenu has its own `[0] Back to Main Menu` option, and prompts you with `Press ENTER...` after each action so you can read the result before continuing.

---

## 5. Using Each Section

### [1] Network Optimization
Disable Nagle's Algorithm, set TCP Auto-Tuning to Normal, enable ECN, or apply NIC Advanced (disables adapter power-saving + enables RSS via official `Set-NetAdapter*` cmdlets — unsupported adapters are skipped, not forced). Option **[5]** runs a quick 4-ping test to 8.8.8.8 so you can compare before/after. Option **[6]** reverts everything in this menu to Windows defaults.

### [2] DNS Optimizer
Option **[1]** pings Cloudflare, Google, Quad9, and OpenDNS, then offers to apply the fastest to all active adapters. Options **[2]**/**[3]** quick-set Cloudflare or Google directly. **[4]** flushes the DNS cache. **[5]** reverts to DHCP-assigned DNS on all active adapters.

### [3] Windows Tweaks
**[1] Debloat** shows a checklist of removable first-party apps (type numbers like `1,3,5`, `all`, or ENTER to cancel) — this never touches Defender, Store, or Edge. **[2]** clears temp files and reports approximate space freed. **[3]**/**[4]** remove or restore the Explorer startup launch delay.

### [4] CPU Tweaks
Switch between the **High Performance** and **Balanced** power plans, and enable/restore CPU core parking.

### [5] Gaming Tweaks
Enable HAGS (needs a reboot to apply), disable Xbox Game Bar/background recording, disable Fullscreen Optimizations globally, or disable mouse acceleration. Vendor-specific options only appear based on your GPU profile:
- **AMD only:** disable the AMD External Events Utility service
- **NVIDIA only:** set Power Mode to Prefer Maximum Performance

Option **[6]** restores all Gaming Tweaks to defaults, including whichever vendor tweak applies to your profile.

### [6] Miscellaneous
Create a System Restore Point, view the last 40 lines of today's log, or see version/credit info.

### [7] Backup & Restore
**[1]** exports the specific registry keys ZORO can modify (TCP/IP interfaces, GameConfigStore, GameDVR, Mouse, Explorer Serialize, GraphicsDrivers, Desktop, Dwm, Multimedia SystemProfile, Session Manager kernel, plus the active power scheme) into a timestamped folder. **[2]** lists existing backups (newest first) and lets you pick one to re-import. **[3]** opens the backups folder in Explorer.

### [8] Responsiveness & GPU Tweaks
The list is rebuilt every time you open this menu based on your GPU profile, so item numbers shift depending on which vendor sections are showing. General tweaks (always present) include Multi-Plane Overlay, UI hover/menu delay, the MMCSS "Games" profile, high-resolution timer, hover-to-focus window tracking, GPU driver TDR delay, PCIe ASPM power saving, a Hardware-Accelerated GPU Scheduling toggle (the menu shows its current state), and Fullscreen Optimizations. AMD-only and NVIDIA-only items are appended when applicable. The last item on the list always reverts everything in this menu to Windows defaults.

### [9] Service Tweaks
**[1]** and **[2]** show checklists of safe and caution-level background services you can disable (type numbers, `all`, or ENTER to cancel). Every disable is backed up as a `.reg` file and its original startup type is recorded first. **[3]** lists services ZORO has previously disabled and lets you restore any of them to their recorded original state — the safest way to undo a service change.

---

## 6. Undoing Changes

ZORO gives you three layers of undo, from most to least specific:

1. **Per-menu "Restore" options** — most menus (Network, DNS, Windows, CPU, Gaming, Responsiveness & GPU) have a dedicated restore/undo item that reverts just that menu's tweaks to Windows defaults.
2. **[9] Service Tweaks → [3] Restore previously disabled services** — restores any service ZORO disabled to its exact recorded startup type.
3. **[7] Backup & Restore → [2] Restore settings from a previous backup** — re-imports a full `.reg` snapshot taken earlier, independent of which individual restore options you used.

For anything outside these registry keys (e.g., a driver-level change), use the **System Restore Point** created from the Miscellaneous menu.

---

## 7. Logs

Every registry write or removal is timestamped and logged to `%SystemDrive%\ZORO_Suite\Logs\yyyy-MM-dd.log`. View the most recent entries from **[6] Miscellaneous → [2] View change log**, or open the file directly for the full history.

---

## Credits

Made by zoro (cwizxir)
GitHub: https://github.com/zoronolonger
