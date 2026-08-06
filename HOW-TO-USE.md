# How to Use ZORO Tweaking Utility

This guide walks through launching ZORO, understanding why it needs elevation, what each main menu does, how the safety systems (Backup, Undo, Restore) work, and the order in which to approach tweaking a fresh system.

---

## 1. Launching the Tool

1. Open **PowerShell** (a regular, non-elevated window is fine — see the next section).
2. Navigate to the folder containing `ZORO Tweaking Utility.ps1`.
3. If this is your first time running a local script, allow it for this session:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
   ```
4. Run the script:
   ```powershell
   .\ZORO Tweaking Utility.ps1
   ```
5. ZORO checks its own privilege level immediately. If it isn't already elevated, it relaunches itself with a UAC prompt (see below) — you don't need to manually right-click → "Run as administrator" first, though you can if you prefer.

Once running, you land on the **Main Menu**, which lists menus **[1]** through **[15]**, plus **[U] Undo Last Session**, **[D] Discord**, **[G] GitHub**, and **[Q] Exit**.

## 2. Why Administrator Is Required

Nearly everything ZORO does requires elevated access:

- Writing to `HKLM` registry hives (most tweaks live under `HKEY_LOCAL_MACHINE`, not the per-user `HKCU` hive).
- Changing network adapter properties (RSS, power management, interrupt moderation, advanced driver properties) via `Set-NetAdapter*` cmdlets.
- Changing Windows service startup types.
- Creating a System Restore Point.
- Running DISM and SFC repairs.
- Uninstalling Microsoft Edge.

Because almost every menu needs this access, ZORO doesn't ask you to relaunch it yourself. On startup it checks `[Security.Principal.WindowsPrincipal]::IsInRole(Administrator)`; if that's false, it automatically calls `Start-Process powershell.exe -Verb RunAs` to relaunch itself elevated and exits the original, unprivileged instance. If you click **"No"** on the UAC prompt, elevation fails and ZORO exits cleanly with an on-screen message instead of continuing half-privileged (which would cause confusing, silent failures on nearly every tweak).

> **Note:** if you launched ZORO via `irm ... | iex` (piped directly from the internet rather than run from a saved `.ps1` file), self-elevation isn't possible — PowerShell has no file path to relaunch. In that case, open an **elevated** PowerShell window yourself first, then re-run the command.

## 3. What Each Main Menu Does

| # | Menu | Summary |
|---|---|---|
| **1** | **Network Optimization** | Adapter- and protocol-level tweaks: Nagle's Algorithm, Interrupt Moderation, ECN, NIC power-saving/RSS, Delivery Optimization P2P restriction, a before/after ping test, Automatic MTU Discovery, the Modern TCP Analyzer, the Advanced NIC Optimizer, and Energy Efficient Ethernet toggle. |
| **2** | **DNS Optimizer** | Smart DNS Benchmark (ranks 5 providers by real measured latency), quick-set Cloudflare/Google/AdGuard, DNS cache flush, live DNS config viewer, and restore-to-DHCP. |
| **3** | **Windows Tweaks** | Debloat checklist (removes selected pre-installed apps), temp file cleanup, startup app-launch delay removal/restore, and a global Background Apps disable/restore toggle. |
| **4** | **CPU Tweaks** | Switches the active power plan between Balanced, High Performance, and Ultimate Performance, plus a CPU/hybrid-topology diagnostics view. |
| **5** | **Gaming Tweaks** | Disables Xbox Game Bar/background recording, Fullscreen Optimizations, mouse acceleration, and vendor-specific AMD/NVIDIA gaming settings. |
| **6** | **Miscellaneous** | Create a System Restore Point, view the change log, view About/Credits, run the Tweak Health Check, and run the System Requirements Check. |
| **7** | **Backup & Restore** | Create a ZORO settings backup, restore from a previous backup, or open the backup folder in Explorer. |
| **8** | **Responsiveness & GPU Tweaks** | Multi-Plane Overlay, UI delay reduction, high-resolution timer, GPU MSI Mode, Memory Integrity (HVCI) toggle, GPU TDR delay, PCIe ASPM, Fullscreen Optimizations (global), USB Selective Suspend, Power Throttling, Dynamic Tick/platform timer, Hardware-Accelerated GPU Scheduling (HAGS), and AMD/NVIDIA-specific responsiveness settings. |
| **9** | **Service Tweaks** | Disable low-impact or "caution" background services, restore previously disabled services, and manage AMD/NVIDIA vendor background services separately. |
| **10** | **GPU Extras** | Clear the DirectX shader cache and, on modern GPUs, extend the TDR (Timeout Detection and Recovery) delay for sustained ray-tracing/frame-generation workloads. |
| **11** | **System Repair & RAM** | DISM CheckHealth/ScanHealth/RestoreHealth, System File Checker (`sfc /scannow`), a combined "full repair pass," and a standby memory list clean. |
| **12** | **Remove Microsoft Edge** | A standalone, complete removal of Microsoft Edge — process, services, scheduled tasks, files, registry entries, Appx packaging, and shortcuts. |
| **13** | **Connection Benchmark** | A full (ping/jitter/loss + DNS + throughput + weighted score) or quick (ping/jitter/loss + DNS only) network benchmark. |
| **14** | **Live Network Health Monitor** | An opt-in, start/stop/pause/resume live dashboard that tracks connection health over time. |
| **15** | **Game Network Diagnostics** | Best game adapter detection, NIC driver health check, IRQ/MSI detection, Bufferbloat test, route quality analyzer, per-service gaming connectivity test, and a full diagnostics report file. |
| **U** | **Undo Last Session** | Rolls back every registry value and service-startup type ZORO has changed, in reverse order, verifying each restore. |

Every individual tweak inside these menus is described, rated, and risk-assessed in [`TWEAK_AUDIT.md`](TWEAK_AUDIT.md).

## 4. Best Practices Before Applying Tweaks

1. **Create a System Restore Point first.** Menu **[6] Miscellaneous → [1] Create a System Restore Point**. This is a Windows-level safety net independent of ZORO's own backup system — it can recover from problems ZORO's own scope doesn't cover.
2. **Create a ZORO backup second.** Menu **[7] Backup & Restore → [1] Create a backup**. This captures the exact registry keys and DNS settings ZORO is capable of changing, in a format ZORO itself knows how to restore precisely (see §7 below).
3. **Run the System Requirements Check.** Menu **[6] Miscellaneous → [5]**. It reports what your specific hardware/OS actually qualifies for (HAGS prerequisites, GPU driver age/signature, Windows build) before you go hunting for a menu entry that turns out to be hidden because a prerequisite isn't met.
4. **Read the rating and the confirmation prompt for every tweak**, not just the menu label. The `[n/10]` tag is the *real* expected impact, and higher-impact or trade-off-bearing tweaks (HVCI, Winsock Reset, Dynamic Tick, service disabling) show additional warning text before you confirm.
5. **Apply tweaks one category at a time**, then use the tool (or your own workload — game, browser, benchmark) to confirm nothing regressed, before moving to the next menu. This makes it far easier to identify which single change caused a problem, if one occurs.
6. **Know what's reversible before you run it.** See §6 for the exact scope of Undo, and don't run irreversible actions (Debloat, Edge removal, temp cleanup) until you're confident.

## 5. How to Restore Defaults

Nearly every tweak menu has its own **"Restore ALL … to Windows defaults"** entry:

- Menu **[1]**, option **[11]** — reverts Nagle's Algorithm, Interrupt Moderation, ECN, Auto-Tuning, NIC Advanced settings, Delivery Optimization, and MTU.
- Menu **[2]**, option **[7]** — restores DHCP-assigned DNS, undoing any DNS provider change.
- Menu **[3]**, options **[4]** and **[6]** — restore startup delay and Background Apps individually.
- Menu **[5]** — "Restore ALL gaming tweaks to Windows defaults."
- Menu **[8]** — "Restore ALL of the above to Windows defaults," covering the full Responsiveness & GPU menu.
- Menu **[9]**, option **[3]** — "Restore previously disabled services," restoring each service to its recorded original startup type (not a guess).
- Menu **[10]** — "Restore ALL GPU Extras tweaks to Windows defaults."

These per-menu restores are the fastest way to cleanly revert a whole category. For a broader or more surgical rollback, use **Undo Last Session** or **Backup & Restore** instead (§6–§7).

## 6. How Undo Works

ZORO maintains a single **undo ledger** — a running record of every change it makes that is structurally reversible.

- **What's tracked:** every write made through the tool's own `Set-RegDword`, `Remove-RegValue`, or service-startup-type functions records the *prior* value, both in memory and to disk (`C:\ZORO_Suite\UndoSession.json`), **before** the change is applied. If ZORO or Windows crashes mid-tweak, the record of what to restore is already safely on disk.
- **How to trigger it:** select **[U] Undo Last Session** from the Main Menu. The Main Menu itself shows a live count of how many changes are currently recorded and undoable.
- **Order:** changes are rolled back in reverse order (most recent first), and each restore is verified by reading the value back — not just assumed to have succeeded.
- **Session persistence:** the ledger isn't wiped when you close ZORO. If you close the tool (or it crashes) without undoing, reopening it later still shows the same pending records and lets you undo them then.
- **What Undo does *not* cover** — stated plainly, because pretending otherwise would be a false safety net:
  - Debloat / pre-installed app removal (menu 3)
  - Microsoft Edge removal (menu 12)
  - Temp file cleanup (menu 3)
  - DISM / SFC repairs (menu 11)

  None of these are reversible by re-writing a saved registry value, so they're intentionally excluded from the undo ledger rather than given a fake "undo" that wouldn't actually restore anything. If you need to reverse one of these, see [`UNINSTALL.md`](UNINSTALL.md) and [`TWEAK_AUDIT.md`](TWEAK_AUDIT.md) for what's realistically achievable for each.

## 7. How Backup Works

Menu **[7] Backup & Restore → [1] Create a backup** creates a timestamped folder under `C:\ZORO_Suite\Backups\yyyy-MM-dd_HH-mm-ss\` containing:

- A `.reg` export for each registry path ZORO is capable of modifying (only the keys the tool actually touches — not your whole registry).
- `DnsServers.json` — a per-adapter snapshot of DNS server assignments, since DNS is configured per-adapter rather than through a static registry path.
- `ActivePowerScheme.txt` — the active power plan at the time of backup.

This is complementary to, not a substitute for, a Windows System Restore Point (§4, step 1): ZORO's backup only covers what ZORO itself can change, while a Restore Point covers the whole system.

## 8. How Restore Works

Menu **[7] Backup & Restore → [2] Restore settings from a previous backup**:

1. Lists all backups found under `C:\ZORO_Suite\Backups\`, newest first.
2. You select one by number.
3. You're asked to confirm — the prompt explicitly states this "overwrites current values in those specific keys only," not a full-system rollback.
4. Each `.reg` file is re-imported, with success/failure shown per file.
5. The DNS snapshot is restored per adapter and **verified** by reading the configuration back afterward, not just trusted based on the command's exit code. Adapters that no longer exist (e.g., you removed a USB NIC since the backup) are skipped safely rather than causing an error.
6. You're reminded that a sign-out or reboot may be needed for every restored value to fully take effect.

## 9. How to Use Diagnostics

ZORO includes several read-only diagnostic tools that don't change any settings on their own:

- **Menu [6] → [4] Tweak Health Check** — reports what's actually applied right now across the tweaks ZORO tracks, independent of what you remember selecting.
- **Menu [6] → [5] System Requirements Check** — reports what your specific hardware/OS qualifies for (HAGS prerequisites, GPU driver age and WHQL signature status, Windows build number).
- **Menu [4] → [4] CPU / hybrid-topology diagnostics** — reports CPU core/thread topology, useful on hybrid (P-core/E-core) CPUs.
- **Menu [13] Connection Benchmark** — full or quick network quality tests (ping/jitter/loss, DNS latency, throughput, and a weighted overall score).
- **Menu [14] Live Network Health Monitor** — an opt-in, continuously-refreshing dashboard; start it, and pause/resume/stop/reset it independently without restarting ZORO.
- **Menu [15] Game Network Diagnostics** — includes the Bufferbloat Test (real idle-vs-loaded latency), Route Quality Analyzer (per-hop trace analysis), Gaming Connectivity Test (against specific game services or a custom host), NIC Driver Health Check, IRQ/MSI Capability Detection, and a one-shot **Advanced Diagnostics Report** that writes everything above (plus DNS/Gateway/IPv4/IPv6/public IP) to a timestamped `.txt` file — useful to attach when asking for help or filing an issue.

## 10. Recommended Order for Applying Tweaks

For a first session on a new system, the following order minimizes risk and makes any regression easy to trace back to a specific change:

1. **[6] → [5] System Requirements Check** — see what your system actually qualifies for.
2. **[6] → [1] Create a System Restore Point.**
3. **[7] → [1] Create a ZORO backup.**
4. **[13] Connection Benchmark (Full)** — establish a network baseline before touching network settings.
5. **[2] DNS Optimizer → Smart DNS Benchmark** — apply a DNS change only if it measurably helps your connection.
6. **[1] Network Optimization** — apply Safe/Recommended items first (see `TWEAK_AUDIT.md`); leave Experimental/Situational items for later, deliberate sessions.
7. **[4] CPU Tweaks** — pick a power plan appropriate to your device (desktop vs. laptop-on-battery matters here).
8. **[3] Windows Tweaks** and **[9] Service Tweaks** — debloat and service changes, since these are lower-risk to defer and easier to evaluate once your network baseline is already good.
9. **[5] Gaming Tweaks** and **[8] Responsiveness & GPU Tweaks** — apply Safe/Recommended entries; treat HVCI and other security-trade-off tweaks as their own deliberate, separate decision.
10. **[10] GPU Extras** and **[11] System Repair & RAM** — as needed, not as a default pass.
11. Re-run **[13] Connection Benchmark** and **[6] → [4] Tweak Health Check** to confirm the end state matches what you intended.

If anything regresses at any point, use **[U] Undo Last Session** first (fastest, most surgical), then the relevant menu's "Restore ALL to Windows defaults" entry, then **[7] → [2] Restore from backup**, and — for anything outside ZORO's own scope — the System Restore Point you created in step 2.
