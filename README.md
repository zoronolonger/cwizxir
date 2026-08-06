# Installing ZORO

ZORO is a single PowerShell script. There is no installer, package, or
compiled executable — "installing" just means getting the `.ps1` file onto
your machine and being able to run it.

## 1. Download from GitHub

Clone the repository:

```powershell
git clone https://github.com/zoronolonger/cwizxir.git
```

Or download the script directly:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zoronolonger/cwizxir/refs/heads/main/ZORO%20Tweaking%20Utility.ps1" -OutFile "ZORO Tweaking Utility.ps1"
```

## 2. PowerShell execution policy

If your system's execution policy blocks running local scripts, either
run the script through Right-click → **Run with PowerShell**, or bypass
the policy for this one process:

```powershell
powershell -ExecutionPolicy Bypass -File ".\ZORO Tweaking Utility.ps1"
```

To check your current policy:

```powershell
Get-ExecutionPolicy
```

## 3. Launch instructions

ZORO must be launched from an **elevated (Administrator)** PowerShell
session or via "Run as administrator" on the script itself. It performs an
admin check at startup and exits immediately if it isn't elevated — it
does not attempt to relaunch itself with elevated rights.

## 4. Administrator behavior

- Elevated: proceeds straight to the GPU profile prompt and main menu.
- Not elevated: prints `[ERROR] Please run ZORO as Administrator!` and
  exits after you press Enter.

## 5. Supported PowerShell versions

PowerShell 5.1 or newer (built into Windows 10/11). The script checks
`$PSVersionTable.PSVersion.Major` to adjust how it reads ping latency, so
both Windows PowerShell 5.1 and PowerShell 7+ work.

## 6. Windows requirements

- Windows 10 or Windows 11
- Some individual tweaks require a specific build: Hardware-Accelerated
  GPU Scheduling requires Windows 10 build 19041 (version 2004) or newer;
  on older builds that option is skipped with a message.

## 7. Troubleshooting

**"cannot be loaded because running scripts is disabled on this system"**
Your execution policy is blocking script execution. Use the
`-ExecutionPolicy Bypass` launch command above, or set a less restrictive
policy for your user:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

**"[ERROR] Please run ZORO as Administrator!"**
Launch PowerShell itself as Administrator, then run the script — ZORO
will not elevate itself.

**A tweak reports `[SKIPPED]` or "not found on this system"**
Several tweaks (AMD/NVIDIA-specific registry keys, particular services)
only exist if the corresponding hardware or software is present. This is
expected behavior, not an error.

## 8. Common errors

| Symptom | Cause |
|---|---|
| Script exits immediately with an admin error | Not launched elevated |
| NIC power-saving/RSS reports `[SKIPPED]` for an adapter | Adapter driver doesn't expose that setting |
| AMD/NVIDIA tweak reports no registry key/service found | That vendor's hardware/driver/software isn't present |
| HAGS toggle says unsupported | Windows build older than 19041 |
| Restore Point creation fails | System Restore disabled by policy, or one was created too recently |
