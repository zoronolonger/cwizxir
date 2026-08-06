Uninstalling ZORO Tweaking Utility

Uninstalling ZORO is really two independent tasks:

Restore Windows — revert whatever tweaks you applied back to their defaults.
Remove ZORO files — delete the script and the data it generated.

ZORO doesn't install anything system-wide (no service, no scheduled task, no startup entry), so there's nothing to "uninstall" in the traditional sense — you're just cleaning up files and reverting registry/service changes you chose to make.

Do this in order. Restore your settings first, then delete files. Once ZORO_Suite is gone, the built-in restore options in menus 7 and 9 no longer have anything to work from.

Step 1 — Restore Windows

Run the script one more time, elevated, and work through its restore options before deleting anything.

powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\...\ZORO Tweaking Utility.ps1"

If PowerShell isn't elevated, ZORO prints [ERROR] Please run ZORO as Administrator! and exits — relaunch as Administrator.

Recommended order

1. Restore from a backup (if you made one)
[7] Backup & Restore → [2] Restore settings from a previous backup
This re-imports the .reg files saved when you ran [7] → [1] Create a backup, writing the exact values that were present in those registry keys before you started tweaking.

2. Restore each area to its defaults
Every menu that changes something reversible has its own restore option:

Menu	Restore option
[1] Network Optimization	[6] Restore ALL network tweaks to Windows defaults
[2] DNS Optimizer	[5] Restore DHCP-assigned DNS
[3] Windows Tweaks	[4] Restore startup delay to Windows default
[4] CPU Tweaks	[3] Restore Power Plan: Balanced and [4] Restore CPU Core Parking to default
[5] Gaming Tweaks	[6] Restore ALL gaming tweaks to Windows defaults
[8] Responsiveness & GPU Tweaks	last item, Restore ALL of the above to Windows defaults (also reverts your AMD/NVIDIA-specific tweaks)
[9] Service Tweaks	[3] Restore previously disabled services

These restore options don't require a prior backup — they write known Windows-default values directly. Running [9] → [3] restores each service to the exact startup type it had before ZORO touched it, using the value saved in ServiceState.json.

3. Reboot if required
Hardware-Accelerated GPU Scheduling ([8]) only takes effect after a restart, whether you're enabling or disabling it. Reboot once after restoring it to confirm the change actually applied.

4. Windows System Restore (optional)
If you created a restore point via [6] Miscellaneous → [1] Create a System Restore Point before tweaking, you can roll back through Windows' own System Restore (rstrui.exe) as a fallback. This is independent of anything ZORO tracks itself.

What can't be automatically restored

A few actions in ZORO aren't "tweaks" with a default state to go back to — they're one-time operations. There's nothing to undo through the menus:

Action	Why it can't be restored	What to do
Debloat — removed apps ([3] → [1])	Uninstalling an app isn't reversible from the registry	Reinstall from the Microsoft Store if needed
Clean Temp Files ([3] → [2])	Deleted files are gone	Nothing to do — this is expected behavior
SFC / DISM repairs ([10])	These replace corrupted system files, not a setting	No action needed
Standby list / RAM clean ([10] → [6])	Just releases cached memory pages, not a persistent change	No action needed
Step 2 — Remove ZORO Data

Once your tweaks are restored, ZORO's working folder is safe to delete. It only contains logs and backups — nothing Windows depends on.

%SystemDrive%\ZORO_Suite\
├── Logs\                    daily .log file of every change ZORO made
├── Backups\
│   ├── <timestamp>\*.reg    snapshots created via [7] → [1] Create a backup
│   └── ServiceBackups\*.reg per-service export, made automatically when you disable a service
└── ServiceState.json        original startup type of every service you disabled via [9]

Delete it with:

powershell
Remove-Item -Path "$env:SystemDrive\ZORO_Suite" -Recurse -Force

Note: Deleting ServiceState.json removes ZORO's memory of what each disabled service's original startup type was. If you're not fully done restoring services, run [9] → [3] first.

Step 3 — Remove the Script

ZORO installs:

No Windows service
No scheduled task
No startup entry
No background process

Everything the tool does happens only while the PowerShell window running ZORO Tweaking Utility.ps1 is open. Deleting the .ps1 file itself is the entire "uninstall" — there's no installer to reverse and no leftover component elsewhere on the system.

Quick Reference
Run ZORO Tweaking Utility.ps1 as Administrator.
[7] → [2] — restore from backup, if you made one.
Go through each menu's Restore to defaults option (see table above).
[9] → [3] — restore any disabled services.
Reboot once, if you toggled Hardware-Accelerated GPU Scheduling.
(Optional) Roll back via Windows System Restore if you created a restore point.
Delete %SystemDrive%\ZORO_Suite.
Delete ZORO Tweaking Utility.ps1.
Notes
Deleting ZORO does not undo any tweaks. The script only reads and writes registry values and service settings — removing the .ps1 file or the ZORO_Suite folder has no effect on changes already applied to Windows. Always restore first.
If you're unsure which services you've disabled, check [9] Service Tweaks → [3] Restore previously disabled services] — it lists everything currently tracked — before deleting ServiceState.json.
Debloated apps and cleaned temp files are the only non-reversible actions ZORO performs; everything else in the menus has a matching restore path.
