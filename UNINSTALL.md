# Uninstalling ZORO Tweaking Utility

ZORO doesn't use a traditional installer, so "uninstalling" it means two separate things: **(1) restoring Windows to the state it was in before you applied tweaks**, and **(2) removing ZORO's own files from your system.** Do them in that order — reversing your changes first, cleanup second.

---

## Step 1: Restore Windows to Its Previous State

### 1a. Use the built-in Restore option first

Before anything else, open ZORO one more time and go to **[7] Backup & Restore → [2] Restore settings from a previous backup**. Pick the earliest backup you created (ideally the one made before your first tweaking session) and confirm. This reverts every registry key and DNS setting captured in that backup back to its saved state, restoring per-adapter DNS with verification.

> If you never created a ZORO backup, skip to 1b and 1c — the Undo ledger and per-menu "Restore ALL" options can still cover most changes, and a Windows System Restore Point (if you created one) can recover the rest.

### 1b. Undo any tweaks not covered by the backup

If you made changes *after* your last backup, or never created one:

1. From the Main Menu, select **[U] Undo Last Session**. This rolls back, in reverse order, every registry value and service-startup-type change ZORO has tracked — verifying each restore as it goes.
2. For anything the ledger doesn't have (e.g., you closed ZORO between sessions and the ledger only tracks what's currently pending), use each menu's own **"Restore ALL … to Windows defaults"** entry:
   - **[1]** Network Optimization → option **[11]**
   - **[2]** DNS Optimizer → option **[7]** (Restore DHCP-assigned DNS)
   - **[3]** Windows Tweaks → options **[4]** and **[6]**
   - **[5]** Gaming Tweaks → "Restore ALL gaming tweaks"
   - **[8]** Responsiveness & GPU Tweaks → "Restore ALL of the above"
   - **[9]** Service Tweaks → option **[3]** "Restore previously disabled services"
   - **[10]** GPU Extras → "Restore ALL GPU Extras tweaks"
   - **[4]** CPU Tweaks → option **[3]** "Restore Power Plan: Balanced"

### 1c. What Undo/Restore does *not* cover — and what to do instead

| Change | Reversible via Undo/Restore? | What to do instead |
|---|---|---|
| Debloat (removed pre-installed apps) | ❌ No | Reinstall from the Microsoft Store (if the app is still available there) or perform a Windows repair/reset if you need the exact original app back |
| Microsoft Edge removal | ❌ No | Download and run Microsoft's official standalone Edge installer from microsoft.com if you want Edge back |
| Temp file cleanup | ❌ No — files are deleted, not archived | Nothing to restore; this was disk-space cleanup by design |
| DISM/SFC repairs | ❌ No (not applicable — these repair files, they don't need reverting) | N/A |
| Registry values / service startup types | ✅ Yes | Undo Last Session or a ZORO backup, as above |
| DNS server assignment | ✅ Yes | Undo Last Session, "Restore DHCP-assigned DNS," or backup restore |
| Power plan | ✅ Yes | "Restore Power Plan: Balanced" |
| HVCI, GPU MSI Mode, HAGS, Dynamic Tick | ✅ Yes (value), ⚠️ needs reboot to fully apply | Restore via Undo/menu, **then reboot** — see the reboot list below |

### 1d. Which changes require a reboot after restoration

The following, if you applied them, need a **restart** for the *reverted* value to fully take effect — not just the original applied value:

- **Memory Integrity (HVCI)** — re-enabling it requires a reboot before the protection is actually active again.
- **GPU MSI Mode** — reverting requires a reboot for the driver's interrupt mode to actually change back.
- **Hardware-Accelerated GPU Scheduling (HAGS)** — reverting requires a reboot.
- **Dynamic Tick / platform timer** — this edits boot configuration (`bcdedit`) directly; reverting the setting requires a reboot to take effect on the next boot cycle.
- **Winsock Reset** (if you ran it from the Network Recovery menu) — always requires a restart, both to apply and to fully settle after any related follow-up change.

If you've restored settings through ZORO and something still looks unchanged, reboot before assuming the restore failed — check `TWEAK_AUDIT.md`'s "Restart" column for the specific tweak in question.

### 1e. If you also created a Windows System Restore Point

If you created a System Restore Point before tweaking (recommended in `HOW_TO_USE.md`), and you want the broadest possible rollback — beyond just what ZORO itself changed — you can use it independently of the steps above:

1. Open **Start → type "Create a restore point" → System Properties → System Restore…**
2. Choose the restore point you created (it will be labeled "ZORO Utility - before tweaks" if it was created through ZORO's own **[6] → [1]** option, or whatever label you gave it if created manually).
3. Follow the wizard to complete the restore. This reboots your system.

This is a full Windows Restore, not a ZORO feature — it restores registry state, system files, and installed driver/software state to that point in time system-wide.

---

## Step 2: Delete Backups and Logs

Once you're satisfied your settings are back to where you want them, you can clean up ZORO's data:

1. Open File Explorer and navigate to `C:\ZORO_Suite\`.
2. This folder contains:
   - `Logs\` — daily session log files
   - `Backups\` — every settings backup you created
   - `ServiceState.json` — recorded original service startup types
   - `UndoSession.json` — the undo ledger
3. Delete the folder (or its contents) once you no longer need this history. **Do this only after you're confident you won't need to Undo or Restore anything further** — deleting this folder removes ZORO's ability to roll back any remaining changes through its own Undo/Restore system (a Windows System Restore Point, if you made one, is stored separately by Windows and is unaffected by deleting this folder).

```powershell
Remove-Item -Path "C:\ZORO_Suite" -Recurse -Force
```

## Step 3: Completely Remove ZORO From Your System

Because ZORO is a single script with no installer, background service, scheduled task, or registry-based "install" footprint of its own, full removal is straightforward:

1. Delete the `ZORO Tweaking Utility.ps1` file from wherever you saved it.
2. Delete `C:\ZORO_Suite\` (Step 2 above), if you haven't already.
3. If you ever ran **[14] Live Network Health Monitor**, confirm it isn't still running: it registers a cleanup handler on exit and is not designed to persist after the script closes, but if you're uncertain, simply closing the PowerShell window ZORO was running in ends any monitoring immediately.
4. That's it. ZORO does not install a service, scheduled task, browser extension, or startup entry — there's nothing else to remove.

---

## Quick Reference: Recommended Uninstall Order

1. **[7] → [2] Restore from your earliest backup** (if you made one)
2. **[U] Undo Last Session** (for anything since your last backup)
3. Relevant **"Restore ALL to Windows defaults"** entries per menu (for anything the ledger no longer has)
4. **Reboot** if you touched HVCI, GPU MSI Mode, HAGS, or Dynamic Tick
5. If needed, roll back further via your **Windows System Restore Point**
6. Delete `C:\ZORO_Suite\`
7. Delete the `.ps1` file

If you're unsure whether a specific change was reverted, run **[6] Miscellaneous → [4] Tweak Health Check** before deleting anything — it reports what's actually applied right now, independent of what you remember doing.
