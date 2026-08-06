# Installation Guide

## Supported Windows Versions

| Windows Version | Status |
|---|---|
| Windows 11, 23H2 or later (24H2 recommended) | ✅ Fully supported |
| Windows 10, 22H2 | ✅ Fully supported |
| Windows 10, versions older than 22H2 | ⚠️ Not tested or supported — update Windows first |
| Windows 8 / 8.1 | ❌ Out of scope — not checked for or supported anywhere in the script |
| Windows 7 | ❌ Out of scope — not checked for or supported anywhere in the script |
| Windows Server (any version) | ❌ Out of scope — not checked for or supported anywhere in the script |

See [`SUPPORTED.md`](SUPPORTED.md) for the full compatibility matrix, including hardware-dependent feature availability.

## PowerShell Requirements

- **PowerShell 5.1 or later.** This is the version that ships built into Windows 10 and Windows 11 by default — most users do not need to install anything extra.
- ZORO detects your PowerShell major version at launch (`$PSVersionTable.PSVersion.Major`) and adjusts certain diagnostic behavior accordingly (some `Test-Connection` output differs between PowerShell 5.1 and PowerShell 7+).
- PowerShell 7+ (PowerShell Core) is not required, but is compatible if you have it installed and choose to run the script through it.

## Installation Steps

ZORO is distributed as a **single PowerShell script** — there is no installer, and nothing is required to "install" beyond downloading the file.
1. **Download the script.**
   - From the repository's Releases page, or
   - Directly via a raw file link, or
   - By cloning the repository with `git clone`.
2. **Save it somewhere you'll remember** — its own working folder (`C:\ZORO_Suite\`) is created automatically the first time it runs; the `.ps1` file itself can live anywhere convenient, such as `Documents` or `Downloads`.
3. **(Recommended) Verify the file** you downloaded matches what's published in the repository if you obtained it from anywhere other than the official GitHub source, per the guidance in `SECURITY.md`.

There is nothing to register, no `.msi`/`.exe` to run, and no reboot required just to "install" the tool — it only makes system changes when you select a specific tweak from its menu.

## First Launch Instructions

1. Open **PowerShell** (Start menu → type `PowerShell` → Enter). An elevated window is not required to start — ZORO elevates itself.
2. Navigate to the folder where you saved the script:
   ```powershell
   cd "C:\Path\To\Folder"
   ```
3. Run it:
   ```powershell
   .\ZORO Tweaking Utility.ps1
   ```
4. If prompted by **UAC** ("Do you want to allow this app to make changes to your device?"), click **Yes**. ZORO relaunches itself elevated automatically — this is expected and is explained in detail in `HOW_TO_USE.md`.
5. On first successful launch, ZORO creates its working directory structure:
   - `C:\ZORO_Suite\Logs\` — daily session logs
   - `C:\ZORO_Suite\Backups\` — settings backups you create via menu [7]
   - `C:\ZORO_Suite\ServiceState.json` — original service startup types, created once you disable your first service
   - `C:\ZORO_Suite\UndoSession.json` — the undo ledger, created once you make your first trackable change
6. You'll land on the Main Menu. **Before selecting any tweak**, see the recommended first steps in [`HOW_TO_USE.md`](HOW_TO_USE.md#4-best-practices-before-applying-tweaks) — creating a System Restore Point and a ZORO backup first.

## Administrator Requirements

ZORO **must** run elevated because nearly every tweak writes to `HKLM` registry keys, changes adapter properties, or modifies service configuration — all of which require Administrator rights on Windows.

- **You do not need to manually launch an elevated PowerShell window.** ZORO checks its own privilege level at startup and, if it isn't already elevated, relaunches itself via `Start-Process -Verb RunAs`, triggering a UAC prompt.
- If you click **"No"** at the UAC prompt, elevation fails and ZORO exits with a clear on-screen message rather than continuing without the access it needs.
- **Exception:** if you ran ZORO via a direct pipe (`irm <url> | iex`) rather than from a saved file, self-elevation isn't possible (there's no file path to relaunch), and ZORO will tell you to open an elevated PowerShell window yourself and re-run the command from there.

## SmartScreen Considerations

Because ZORO is a script downloaded from the internet rather than a Microsoft Store or vendor-signed application, **Windows SmartScreen or your browser's download protection may flag it** as an unrecognized file. This is standard behavior for any unsigned script from a new or lesser-known publisher, not a signal specific to ZORO.

- If your browser shows a "this file isn't commonly downloaded" warning, this is expected for any file of this kind that hasn't yet built up enough download reputation with Microsoft's SmartScreen network.
- Only proceed past a SmartScreen or browser warning if you obtained the file from the official source (`github.com/zoronolonger`) and trust it — see `SECURITY.md` for source verification guidance.
- SmartScreen for scripts is separate from Windows Defender antivirus scanning; a script that isn't code-signed will typically show an "Unknown Publisher" prompt at the UAC elevation step as well. This is expected and does not indicate malicious behavior.

## Execution Policy Guidance

Windows PowerShell restricts running unsigned scripts by default via its **Execution Policy**. If you see an error like:

```
File ... cannot be loaded because running scripts is disabled on this system.
```

Use one of the following, in order of preference:

**Recommended — session-only, safest:**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```
This only affects the current PowerShell window and reverts automatically when you close it — it does not change your system-wide policy.

**Alternative — for your user account, persists across sessions:**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
This allows locally-created/downloaded-and-unblocked scripts to run for your user account while still requiring a digital signature for scripts obtained directly from the internet without being unblocked first.

**If the file shows as "blocked" after downloading** (right-click → Properties → an "Unblock" checkbox near the bottom), either check that box, or run:
```powershell
Unblock-File -Path ".\ZORO Tweaking Utility.ps1"
```

Avoid setting `-ExecutionPolicy Unrestricted` system-wide (`-Scope LocalMachine`) purely to run ZORO — the `Process`-scoped `Bypass` shown above is sufficient and doesn't leave a broader policy change behind.

## Next Steps

Once ZORO is running, continue to [`HOW_TO_USE.md`](HOW_TO_USE.md) for a full walkthrough of every menu, the recommended tweak order, and how Backup/Undo/Restore work.
