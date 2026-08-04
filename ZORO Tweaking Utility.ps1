# ==============================================================================
#  ZORO - Ultimate Tweaking Utility
#  Made by zoro (cwizxir)
#  Discord: cwizxir | GitHub: https://github.com/zoronolonger
#  Version 1.1.0 | Requires: Windows 10/11, Administrator, PowerShell 5.1+
#
#  Scope note: this tool only touches network/DNS/power/gaming registry
#  settings and first-party bundled "bloat" apps. It never disables Windows
#  Defender, UAC, Windows Update, or any security feature.
#
#  Changelog 1.2.0:
#   - On launch, ZORO now asks which GPU brand you run (AMD / NVIDIA /
#     auto-detect / both) and remembers it for the session. The
#     Responsiveness & GPU menu and the Gaming menu use that answer to only
#     list tweaks that apply to your hardware instead of showing every
#     vendor's options to everyone.
#   - Responsiveness & GPU menu rebuilt on a dynamic list so vendor sections
#     appear/disappear based on your GPU profile instead of being fixed
#     menu numbers.
#   - AMD: Shader Cache now supports Off / Default / Always On (was
#     Default/Always On only), plus a new Tessellation Level override and
#     an AMD FUEL Service toggle (handles Radeon overlay/eventing features).
#   - NVIDIA: added a toggle for the NVIDIA Container background services
#     (NvContainerLocalSystem / NvContainerNetworkService - GeForce
#     Experience overlay & telemetry plumbing, not the display driver).
#   - Added a vendor-neutral GPU driver TDR delay tweak (reduces false
#     "driver crashed" recoveries during sustained heavy load).
#   - "Restore ALL" on the Responsiveness & GPU page now also reverts every
#     new tweak above.
#
#  Changelog 1.1.0:
#   - Main menu was missing [8] Responsiveness & GPU Tweaks and
#     [9] Service Tweaks, so both pages existed but could never be opened.
#     Wired both into the menu.
#   - Added NVIDIA-specific tweaks (Power Mode: Prefer Maximum Performance,
#     NVIDIA Telemetry service toggle) so NVIDIA users get the same kind of
#     vendor tweaks AMD users already had.
#   - Added AMD Crash Defender Service toggle alongside the existing
#     ShaderCache / ULPS tweaks.
#   - Renumbered section headers (comment-only, no logic change).
# ==============================================================================

# ---------- 0. CONFIG ----------
$ScriptVersion = "1.2.0"
$DiscordName   = "cwizxir"
$DiscordInvite = ""   # put your invite link here (e.g. "https://discord.gg/xxxxx") to auto-open on [D]
$GitHubUrl     = "https://github.com/zoronolonger"

# ---------- 1. ADMIN CHECK ----------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[ERROR] Please run ZORO as Administrator!`n" -ForegroundColor Red
    Read-Host "Press ENTER to exit..." | Out-Null
    Exit
}

# ---------- 2. WORKSPACE / LOG ----------
$WorkDir    = "$env:SystemDrive\ZORO_Suite"
$LogDir     = "$WorkDir\Logs"
$BackupRoot = "$WorkDir\Backups"
foreach ($dir in @($WorkDir, $LogDir, $BackupRoot)) {
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
}
$LogFile          = "$LogDir\$(Get-Date -Format 'yyyy-MM-dd').log"
$ServiceStateFile = "$WorkDir\ServiceState.json"   # remembers each service's original startup type so it can be restored precisely

function Write-Log ($message, $level = "INFO") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$timestamp] [$level] $message"
}

# ---------- 3. SMALL REGISTRY HELPERS (every tweak funnels through these) ----------
function Set-RegDword ($Path, $Name, $Value) {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
        Write-Log "SET $Path\$Name = $Value"
        return $true
    } catch {
        Write-Log "FAILED to set $Path\$Name : $_" "ERROR"
        return $false
    }
}

function Remove-RegValue ($Path, $Name) {
    try {
        if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }
        Write-Log "RESET $Path\$Name to Windows default"
        return $true
    } catch {
        return $false
    }
}

function Confirm-Action ($msg) {
    Write-Host "`n$msg" -ForegroundColor Yellow
    $r = Read-Host "Type Y to continue, anything else to cancel"
    return ($r -eq "Y" -or $r -eq "y")
}

# ---------- 4. SYSTEM INFO / GPU VENDOR DETECTION ----------
function Get-GpuVendor {
    <# Returns "AMD", "NVIDIA", "INTEL" or "UNKNOWN" based on the primary GPU name. #>
    try {
        $gpu = Get-CimInstance Win32_VideoController -ErrorAction Stop | Select-Object -First 1
        if ($gpu.Name -match "NVIDIA|GeForce|Quadro") { return "NVIDIA" }
        if ($gpu.Name -match "AMD|Radeon") { return "AMD" }
        if ($gpu.Name -match "Intel") { return "INTEL" }
        return "UNKNOWN"
    } catch { return "UNKNOWN" }
}

function Get-SystemSnapshot {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
    $ramGb = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1MB, 1) } else { 0 }
    $ping = "n/a"
    try {
        $p = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction Stop
        $rt = if ($script:PSMajor -ge 6) { $p.Latency } else { $p.ResponseTime }
        $ping = "$rt ms"
    } catch { $ping = "unreachable" }

    return [PSCustomObject]@{
        CPU = if ($cpu) { $cpu.Name.Trim() } else { "Unknown" }
        RAM = "$ramGb GB"
        OS  = if ($os) { "$($os.Caption) ($($os.BuildNumber))" } else { "Unknown" }
        GPU = if ($gpu) { $gpu.Name } else { "Unknown" }
        Ping = $ping
        GpuVendor = Get-GpuVendor
    }
}
$script:PSMajor = $PSVersionTable.PSVersion.Major

# ---------- 4b. GPU PROFILE SELECTION ----------
# Asked once at launch so the Responsiveness & GPU / Gaming menus can hide
# tweaks that don't apply to your hardware instead of listing everything.
$script:GpuProfile = "BOTH"   # "AMD", "NVIDIA", or "BOTH" (shows every vendor section)

function Select-GpuProfile {
    $detected = Get-GpuVendor
    Clear-Host
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  ZORO needs to know your GPU brand to show the right tweak list." -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("  Detected GPU: {0} (vendor: {1})" -f (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Name), $detected) -ForegroundColor Gray
    Write-Host ""
    Write-Host " [1] AMD          - show AMD-only tweaks"
    Write-Host " [2] NVIDIA       - show NVIDIA-only tweaks"
    Write-Host (" [3] Auto-detect  - use what ZORO found above ({0})" -f $detected)
    Write-Host " [4] Show both / not sure"
    Write-Host ""
    $c = Read-Host "Select your GPU"
    switch ($c) {
        "1" { $script:GpuProfile = "AMD" }
        "2" { $script:GpuProfile = "NVIDIA" }
        "3" {
            $script:GpuProfile = if ($detected -eq "AMD" -or $detected -eq "NVIDIA") { $detected } else { "BOTH" }
        }
        default { $script:GpuProfile = "BOTH" }
    }
    Write-Log "GPU profile selected: $script:GpuProfile (auto-detected: $detected)"
}
Select-GpuProfile

# ---------- 5. BANNER ----------
function Show-Banner {
    $Host.UI.RawUI.WindowTitle = "ZORO Ultimate Tweaking Utility"
    Clear-Host
    $Cyan = "Cyan"; $Gray = "DarkGray"; $White = "White"

    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor $Gray
    Write-Host "███████╗ ██████╗ ██████╗  ██████╗ " -ForegroundColor $Cyan
    Write-Host "╚══███╔╝██╔═══██╗██╔══██╗██╔═══██╗" -ForegroundColor $Cyan
    Write-Host "  ███╔╝ ██║   ██║██████╔╝██║   ██║" -ForegroundColor $Cyan
    Write-Host " ███╔╝  ██║   ██║██╔══██╗██║   ██║" -ForegroundColor $Cyan
    Write-Host "███████╗╚██████╔╝██║  ██║╚██████╔╝" -ForegroundColor $Cyan
    Write-Host "╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ " -ForegroundColor $Cyan
    Write-Host "         U L T I M A T E   T W E A K I N G   U T I L I T Y" -ForegroundColor $White
    Write-Host "                       Version $ScriptVersion  |  by zoro ($DiscordName)" -ForegroundColor $Gray
    Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor $Gray

    $s = Get-SystemSnapshot
    Write-Host ""
    Write-Host ("  CPU : {0}" -f $s.CPU) -ForegroundColor $White
    Write-Host ("  RAM : {0}      OS: {1}" -f $s.RAM, $s.OS) -ForegroundColor $White
    Write-Host ("  GPU : {0}   (profile: {1})" -f $s.GPU, $script:GpuProfile) -ForegroundColor $White
    Write-Host ("  PING (8.8.8.8): {0}" -f $s.Ping) -ForegroundColor $White
    Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor $Gray
    return $s
}

# ==============================================================================
#  6. NETWORK OPTIMIZATION
# ==============================================================================
function Test-AvgPing ($target = "8.8.8.8", $count = 4) {
    try {
        $r = Test-Connection -ComputerName $target -Count $count -ErrorAction Stop
        $times = if ($script:PSMajor -ge 6) { $r.Latency } else { $r.ResponseTime }
        return [math]::Round(($times | Measure-Object -Average).Average, 1)
    } catch { return $null }
}

function Set-NagleAlgorithm ([bool]$Disable) {
    $ifRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    $val = if ($Disable) { 1 } else { $null }
    Get-ChildItem $ifRoot -ErrorAction SilentlyContinue | ForEach-Object {
        if ($Disable) {
            Set-RegDword $_.PSPath "TcpAckFrequency" 1 | Out-Null
            Set-RegDword $_.PSPath "TCPNoDelay" 1 | Out-Null
        } else {
            Remove-RegValue $_.PSPath "TcpAckFrequency" | Out-Null
            Remove-RegValue $_.PSPath "TCPNoDelay" | Out-Null
        }
    }
}

# ---- NIC Advanced: power-saving + RSS ----
# Uses only official Set-NetAdapter* cmdlets, which validate against what the
# adapter's driver actually supports. Unsupported adapters are skipped
# (non-fatal) instead of being force-written like raw registry edits.
function Set-NicPowerSaving ([bool]$Disable) {
    $adapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
    if ($adapters.Count -eq 0) { Write-Host "  No active physical adapters found." -ForegroundColor Yellow; return }
    foreach ($a in $adapters) {
        try {
            $mode = if ($Disable) { "Disabled" } else { "Enabled" }
            Set-NetAdapterPowerManagement -Name $a.Name -AllowComputerToTurnOffDevice $mode -ErrorAction Stop
            Write-Host ("  [APPLIED] Power-saving {0} on {1}" -f $mode, $a.Name) -ForegroundColor Green
            Write-Log "NIC power management -> $mode on $($a.Name)"
        } catch {
            Write-Host ("  [SKIPPED] {0} (driver doesn't expose this setting)" -f $a.Name) -ForegroundColor DarkGray
        }
    }
}

function Set-NicRss ([bool]$Enable) {
    $adapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
    if ($adapters.Count -eq 0) { Write-Host "  No active physical adapters found." -ForegroundColor Yellow; return }
    foreach ($a in $adapters) {
        try {
            if ($Enable) { Enable-NetAdapterRss -Name $a.Name -ErrorAction Stop }
            else { Disable-NetAdapterRss -Name $a.Name -ErrorAction Stop }
            Write-Host ("  [APPLIED] RSS {0} on {1}" -f $(if ($Enable) {"enabled"} else {"disabled"}), $a.Name) -ForegroundColor Green
            Write-Log "RSS $(if ($Enable) {'enabled'} else {'disabled'}) on $($a.Name)"
        } catch {
            Write-Host ("  [SKIPPED] {0} (driver doesn't support RSS)" -f $a.Name) -ForegroundColor DarkGray
        }
    }
}

function Show-NetworkMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [1] NETWORK OPTIMIZATION`n" -ForegroundColor Green
        Write-Host " [1] Disable Nagle's Algorithm (lower latency for small packets)"
        Write-Host " [2] TCP Auto-Tuning: Normal (Windows-recommended, fixes some bufferbloat)"
        Write-Host " [3] Enable ECN (Explicit Congestion Notification)"
        Write-Host " [4] NIC Advanced: disable adapter power-saving + enable RSS (fewer random drops/lag)"
        Write-Host " [5] Quick before/after ping test"
        Write-Host " [6] Restore ALL network tweaks to Windows defaults"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" {
                if (Confirm-Action "This edits per-adapter TCP registry values.") {
                    Set-NagleAlgorithm $true
                    Write-Host "[DONE] Nagle's Algorithm disabled on all adapters." -ForegroundColor Green
                }
                Read-Host "Press ENTER..." | Out-Null
            }
            "2" {
                netsh int tcp set global autotuninglevel=normal | Out-Null
                Write-Log "netsh int tcp set global autotuninglevel=normal"
                Write-Host "[DONE] TCP Auto-Tuning set to Normal." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "3" {
                netsh int tcp set global ecncapability=enabled | Out-Null
                Write-Log "netsh int tcp set global ecncapability=enabled"
                Write-Host "[DONE] ECN enabled." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "4" {
                if (Confirm-Action "This changes adapter power-management + RSS via official Set-NetAdapter* cmdlets. Unsupported adapters are skipped safely.") {
                    Write-Host ""
                    Set-NicPowerSaving $true
                    Set-NicRss $true
                    Write-Host "`n[DONE] NIC Advanced tweaks applied where supported." -ForegroundColor Green
                }
                Read-Host "Press ENTER..." | Out-Null
            }
            "5" {
                Write-Host "`nPinging 8.8.8.8 four times..." -ForegroundColor Cyan
                $avg = Test-AvgPing
                if ($null -ne $avg) { Write-Host ("Average latency: {0} ms" -f $avg) -ForegroundColor Green }
                else { Write-Host "Ping failed - check your connection." -ForegroundColor Red }
                Read-Host "Press ENTER..." | Out-Null
            }
            "6" {
                if (Confirm-Action "Revert Nagle/ECN/Auto-Tuning/NIC Advanced tweaks to Windows defaults?") {
                    Set-NagleAlgorithm $false
                    netsh int tcp set global autotuninglevel=normal | Out-Null
                    netsh int tcp set global ecncapability=enabled | Out-Null
                    Write-Host ""
                    Set-NicPowerSaving $false
                    Write-Host "[DONE] Network tweaks reset to defaults." -ForegroundColor Green
                }
                Read-Host "Press ENTER..." | Out-Null
            }
            "0" { return }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ==============================================================================
#  7. DNS OPTIMIZER
# ==============================================================================
$DnsProviders = @(
    @{ Name = "Cloudflare"; Primary = "1.1.1.1"; Secondary = "1.0.0.1" }
    @{ Name = "Google";     Primary = "8.8.8.8"; Secondary = "8.8.4.4" }
    @{ Name = "Quad9";      Primary = "9.9.9.9"; Secondary = "149.112.112.112" }
    @{ Name = "OpenDNS";    Primary = "208.67.222.222"; Secondary = "208.67.220.220" }
)

function Get-ActiveAdapters {
    return @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
}

function Set-DnsOnActiveAdapters ($primary, $secondary) {
    $adapters = Get-ActiveAdapters
    foreach ($a in $adapters) {
        try {
            Set-DnsClientServerAddress -InterfaceAlias $a.Name -ServerAddresses @($primary, $secondary) -ErrorAction Stop
            Write-Host ("  [APPLIED] {0} -> {1}, {2}" -f $a.Name, $primary, $secondary) -ForegroundColor Green
            Write-Log "DNS set on $($a.Name) -> $primary, $secondary"
        } catch {
            Write-Host ("  [FAILED] {0}" -f $a.Name) -ForegroundColor Red
        }
    }
    Clear-DnsClientCache -ErrorAction SilentlyContinue
}

function Invoke-DnsBenchmark {
    Write-Host "`nBenchmarking DNS providers (2 pings each)...`n" -ForegroundColor Cyan
    $results = foreach ($p in $DnsProviders) {
        $avg = Test-AvgPing -target $p.Primary -count 2
        [PSCustomObject]@{ Name = $p.Name; Primary = $p.Primary; Secondary = $p.Secondary; Latency = $avg }
        Write-Host ("  {0,-12} {1,-16} {2}" -f $p.Name, $p.Primary, $(if ($avg) { "$avg ms" } else { "unreachable" }))
    }
    $winner = $results | Where-Object { $null -ne $_.Latency } | Sort-Object Latency | Select-Object -First 1
    if (-not $winner) {
        Write-Host "`nAll providers unreachable - check your connection." -ForegroundColor Red
        return
    }
    Write-Host ("`nFastest: {0} ({1} ms)" -f $winner.Name, $winner.Latency) -ForegroundColor Green
    if (Confirm-Action "Apply $($winner.Name) DNS to all active adapters?") {
        Set-DnsOnActiveAdapters $winner.Primary $winner.Secondary
    }
}

function Show-DnsMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [2] DNS OPTIMIZER`n" -ForegroundColor Green
        Write-Host " [1] Benchmark providers and auto-apply the fastest"
        Write-Host " [2] Quick-set Cloudflare (1.1.1.1)"
        Write-Host " [3] Quick-set Google (8.8.8.8)"
        Write-Host " [4] Flush DNS cache"
        Write-Host " [5] Restore DHCP-assigned DNS (undo any change above)"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { Invoke-DnsBenchmark; Read-Host "`nPress ENTER..." | Out-Null }
            "2" { Set-DnsOnActiveAdapters "1.1.1.1" "1.0.0.1"; Read-Host "`nPress ENTER..." | Out-Null }
            "3" { Set-DnsOnActiveAdapters "8.8.8.8" "8.8.4.4"; Read-Host "`nPress ENTER..." | Out-Null }
            "4" { Clear-DnsClientCache -ErrorAction SilentlyContinue; Write-Host "[DONE] DNS cache cleared." -ForegroundColor Green; Read-Host "Press ENTER..." | Out-Null }
            "5" {
                foreach ($a in Get-ActiveAdapters) {
                    Set-DnsClientServerAddress -InterfaceAlias $a.Name -ResetServerAddresses -ErrorAction SilentlyContinue
                }
                Write-Host "[DONE] DNS reverted to DHCP-assigned on all active adapters." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "0" { return }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ==============================================================================
#  8. WINDOWS TWEAKS (Debloat + Cleanup)
#  Never touches: Windows Defender/Security, Microsoft Store, Edge, Update.
# ==============================================================================
$SafeBloatApps = @(
    "Microsoft.3DBuilder", "Microsoft.Microsoft3DViewer", "Microsoft.MixedReality.Portal",
    "Microsoft.BingWeather", "Microsoft.BingNews", "Microsoft.GetHelp", "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.People",
    "Microsoft.WindowsFeedbackHub", "Microsoft.YourPhone", "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo", "Microsoft.SkypeApp", "Microsoft.Todos", "Clipchamp.Clipchamp",
    "MicrosoftTeams", "Microsoft.PowerAutomateDesktop"
)

function Show-DebloatChecklist {
    Write-Host "`nSafe-to-remove apps (first-party bundled apps only):`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $SafeBloatApps.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $SafeBloatApps[$i])
    }
    Write-Host "`nType comma-separated numbers (e.g. 1,3,5), 'all', or ENTER to cancel."
    $sel = Read-Host "Selection"
    if ([string]::IsNullOrWhiteSpace($sel)) { return }

    $targets = if ($sel.Trim().ToLower() -eq "all") { $SafeBloatApps } else {
        $sel -split "," | ForEach-Object {
            $idx = $_.Trim()
            if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $SafeBloatApps.Count) {
                $SafeBloatApps[[int]$idx - 1]
            }
        }
    }
    if (-not $targets -or $targets.Count -eq 0) { Write-Host "Nothing selected." -ForegroundColor Yellow; return }

    if (-not (Confirm-Action "Remove $($targets.Count) app(s)? This does not affect Defender, Store, or Edge.")) { return }

    foreach ($app in $targets) {
        try {
            Get-AppxPackage -AllUsers -Name $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $app } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            Write-Host ("  [REMOVED] {0}" -f $app) -ForegroundColor Green
            Write-Log "Debloat removed $app"
        } catch {
            Write-Host ("  [SKIPPED] {0} (not installed or already removed)" -f $app) -ForegroundColor DarkGray
        }
    }
}

function Clear-TempFiles {
    $paths = @("$env:TEMP\*", "$env:SystemRoot\Temp\*")
    $freedMb = 0
    foreach ($p in $paths) {
        try {
            $items = Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue
            $freedMb += [math]::Round(($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB, 1)
            Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    Write-Host ("[DONE] Temp files cleaned (~{0} MB freed)." -f $freedMb) -ForegroundColor Green
    Write-Log "Cleaned temp files, ~$freedMb MB"
}

function Show-WindowsMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [3] WINDOWS TWEAKS`n" -ForegroundColor Green
        Write-Host " [1] Debloat (remove selected pre-installed apps)"
        Write-Host " [2] Clean Temp Files"
        Write-Host " [3] Remove startup app launch delay"
        Write-Host " [4] Restore startup delay to Windows default"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { Show-DebloatChecklist; Read-Host "`nPress ENTER..." | Out-Null }
            "2" { Clear-TempFiles; Read-Host "Press ENTER..." | Out-Null }
            "3" {
                Set-RegDword "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0 | Out-Null
                Write-Host "[DONE] Startup delay removed." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "4" {
                Remove-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" | Out-Null
                Write-Host "[DONE] Startup delay restored to default." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "0" { return }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ==============================================================================
#  9. CPU TWEAKS
# ==============================================================================
$GUID_HighPerf = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$GUID_Balanced = "381b4222-f694-41f0-9685-ff5bb260df2e"

function Show-CpuMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [4] CPU TWEAKS`n" -ForegroundColor Green
        Write-Host " [1] Set Power Plan: High Performance"
        Write-Host " [2] Disable CPU Core Parking"
        Write-Host " [3] Restore Power Plan: Balanced (Windows default)"
        Write-Host " [4] Restore CPU Core Parking to default"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" {
                powercfg /setactive $GUID_HighPerf 2>$null
                Write-Log "Power plan set to High Performance"
                Write-Host "[DONE] Power Plan set to High Performance." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "2" {
                if (Confirm-Action "Disables core parking on the active power plan. Can increase idle power draw.") {
                    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
                    powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>$null
                    powercfg -setactive SCHEME_CURRENT 2>$null
                    Write-Log "Core parking disabled (CPMINCORES=100)"
                    Write-Host "[DONE] Core parking disabled." -ForegroundColor Green
                }
                Read-Host "Press ENTER..." | Out-Null
            }
            "3" {
                powercfg /setactive $GUID_Balanced 2>$null
                Write-Host "[DONE] Power Plan restored to Balanced." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "4" {
                powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 5 2>$null
                powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 5 2>$null
                powercfg -setactive SCHEME_CURRENT 2>$null
                Write-Host "[DONE] Core parking restored to default." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "0" { return }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ==============================================================================
#  10. GAMING TWEAKS
# ==============================================================================
function Show-GamingMenu {
    while ($true) {
        $s = Show-Banner
        Write-Host "`n>>> [5] GAMING TWEAKS`n" -ForegroundColor Green
        Write-Host " [1] Enable Hardware-Accelerated GPU Scheduling (needs reboot)"
        Write-Host " [2] Disable Xbox Game Bar / background recording"
        Write-Host " [3] Disable Fullscreen Optimizations (global default)"
        Write-Host " [4] Disable Mouse Acceleration"
        if ($script:GpuProfile -ne "NVIDIA") {
            Write-Host (" [5] AMD-only: Disable AMD External Events Utility service   [GPU profile: {0}]" -f $script:GpuProfile)
        }
        if ($script:GpuProfile -ne "AMD") {
            Write-Host (" [7] NVIDIA-only: Prefer Maximum Performance power mode      [GPU profile: {0}]" -f $script:GpuProfile)
        }
        Write-Host " [6] Restore ALL gaming tweaks to Windows defaults"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" {
                Set-RegDword "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2 | Out-Null
                Write-Host "[DONE] HAGS enabled. Reboot required to take effect." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "2" {
                Set-RegDword "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 | Out-Null
                Set-RegDword "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0 | Out-Null
                if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) {
                    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null
                }
                Set-RegDword "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 | Out-Null
                Write-Host "[DONE] Game Bar / background recording disabled." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "3" {
                Set-RegDword "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2 | Out-Null
                Set-RegDword "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1 | Out-Null
                Write-Host "[DONE] Fullscreen Optimizations disabled globally." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "4" {
                Set-RegDword "HKCU:\Control Panel\Mouse" "MouseSpeed" 0 | Out-Null
                Set-RegDword "HKCU:\Control Panel\Mouse" "MouseThreshold1" 0 | Out-Null
                Set-RegDword "HKCU:\Control Panel\Mouse" "MouseThreshold2" 0 | Out-Null
                Write-Host "[DONE] Mouse acceleration disabled. Sign out/in to apply everywhere." -ForegroundColor Green
                Read-Host "Press ENTER..." | Out-Null
            }
            "5" {
                if ($script:GpuProfile -eq "NVIDIA") {
                    Write-Host "`n[SKIPPED] This tweak is AMD-specific and your GPU profile is set to NVIDIA." -ForegroundColor Yellow
                } else {
                    $svc = Get-Service -Name "*AMD External Events*" -ErrorAction SilentlyContinue
                    if ($svc) {
                        Set-Service -InputObject $svc -StartupType Manual -ErrorAction SilentlyContinue
                        Write-Host "[DONE] AMD External Events Utility set to Manual." -ForegroundColor Green
                        Write-Log "AMD External Events Utility -> Manual"
                    } else {
                        Write-Host "[!] Service not found on this system." -ForegroundColor Yellow
                    }
                }
                Read-Host "Press ENTER..." | Out-Null
            }
            "7" {
                if ($script:GpuProfile -eq "AMD") {
                    Write-Host "`n[SKIPPED] This tweak is NVIDIA-specific and your GPU profile is set to AMD." -ForegroundColor Yellow
                } else {
                    Set-NvidiaPowerMode $true
                    Write-Host "[DONE] NVIDIA Power Mode set to Prefer Maximum Performance." -ForegroundColor Green
                }
                Read-Host "Press ENTER..." | Out-Null
            }
            "6" {
                if (Confirm-Action "Revert all Gaming Tweaks to Windows defaults?") {
                    Remove-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" | Out-Null
                    Set-RegDword "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 1 | Out-Null
                    Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" | Out-Null
                    Remove-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" | Out-Null
                    Remove-RegValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" | Out-Null
                    Set-RegDword "HKCU:\Control Panel\Mouse" "MouseSpeed" 1 | Out-Null
                    Set-RegDword "HKCU:\Control Panel\Mouse" "MouseThreshold1" 6 | Out-Null
                    Set-RegDword "HKCU:\Control Panel\Mouse" "MouseThreshold2" 10 | Out-Null
                    $svc = Get-Service -Name "*AMD External Events*" -ErrorAction SilentlyContinue
                    if ($svc) { Set-Service -InputObject $svc -StartupType Automatic -ErrorAction SilentlyContinue }
                    if ($script:GpuProfile -ne "AMD") { Set-NvidiaPowerMode $false }
                    Write-Host "[DONE] Gaming tweaks restored to defaults." -ForegroundColor Green
                }
                Read-Host "Press ENTER..." | Out-Null
            }
            "0" { return }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ==============================================================================
#  11. MISCELLANEOUS
# ==============================================================================
function New-RestorePointSafe {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "ZORO Utility - before tweaks" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[DONE] System Restore Point created." -ForegroundColor Green
        Write-Log "Restore point created"
    } catch {
        Write-Host "[!] Could not create a restore point (may be disabled by policy, or one was made recently)." -ForegroundColor Yellow
    }
}

function Show-MiscMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [6] MISCELLANEOUS`n" -ForegroundColor Green
        Write-Host " [1] Create a System Restore Point (recommended before tweaking)"
        Write-Host " [2] View change log"
        Write-Host " [3] About / Credits"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { New-RestorePointSafe; Read-Host "`nPress ENTER..." | Out-Null }
            "2" {
                if (Test-Path $LogFile) { Get-Content $LogFile | Select-Object -Last 40 } else { Write-Host "No log entries yet." }
                Read-Host "`nPress ENTER..." | Out-Null
            }
            "3" {
                Write-Host "`nZORO Ultimate Tweaking Utility v$ScriptVersion" -ForegroundColor Cyan
                Write-Host "Made by zoro ($DiscordName)"
                Write-Host "GitHub: $GitHubUrl"
                Read-Host "`nPress ENTER..." | Out-Null
            }
            "0" { return }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ==============================================================================
#  12. BACKUP & RESTORE
#  Exports/imports only the registry locations this tool itself can touch,
#  so any tweak above can be undone even if the "restore default" option
#  for that specific tweak is skipped. Nothing outside those keys is read
#  or written by this section.
# ==============================================================================
$BackupRegTargets = @(
    @{ Path = "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"; File = "Tcpip_Interfaces.reg" },
    @{ Path = "HKCU\System\GameConfigStore";                                        File = "GameConfigStore.reg" },
    @{ Path = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR";              File = "GameDVR.reg" },
    @{ Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR";                    File = "GameDVR_Policy.reg" },
    @{ Path = "HKCU\Control Panel\Mouse";                                            File = "Mouse.reg" },
    @{ Path = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize";   File = "ExplorerSerialize.reg" },
    @{ Path = "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers";               File = "GraphicsDrivers.reg" },
    @{ Path = "HKCU\Control Panel\Desktop";                                          File = "Desktop.reg" },
    @{ Path = "HKLM\SOFTWARE\Microsoft\Windows\Dwm";                                 File = "Dwm.reg" },
    @{ Path = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; File = "MultimediaSystemProfile.reg" },
    @{ Path = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel";        File = "SessionManagerKernel.reg" }
)

function New-TweaksBackup {
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $dest  = Join-Path $BackupRoot $stamp
    New-Item -Path $dest -ItemType Directory -Force | Out-Null

    Write-Host "`nBacking up current values (only keys this tool can change)...`n" -ForegroundColor Cyan
    foreach ($t in $BackupRegTargets) {
        try {
            if (Test-Path "Registry::$($t.Path)") {
                $out = Join-Path $dest $t.File
                reg export "$($t.Path)" "$out" /y 2>$null | Out-Null
                Write-Host ("  [SAVED]    {0}" -f $t.File) -ForegroundColor Green
            } else {
                Write-Host ("  [SKIPPED]  {0} (key not present yet, nothing to back up)" -f $t.File) -ForegroundColor DarkGray
            }
        } catch {
            Write-Host ("  [FAILED]   {0}" -f $t.File) -ForegroundColor Red
        }
    }
    try { powercfg /getactivescheme *> (Join-Path $dest "ActivePowerScheme.txt") } catch {}

    Write-Log "Backup created at $dest"
    Write-Host ("`n[DONE] Backup saved to: {0}" -f $dest) -ForegroundColor Green
    return $dest
}

function Restore-TweaksBackup {
    if (-not (Test-Path $BackupRoot)) {
        Write-Host "No backups found yet. Create one first." -ForegroundColor Yellow
        return
    }
    $backups = @(Get-ChildItem -Path $BackupRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
    if ($backups.Count -eq 0) {
        Write-Host "No backups found yet. Create one first." -ForegroundColor Yellow
        return
    }

    Write-Host "`nAvailable backups (newest first):`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $backups.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $backups[$i].Name)
    }
    $sel = Read-Host "`nSelect a backup number to restore (or ENTER to cancel)"
    if ([string]::IsNullOrWhiteSpace($sel)) { return }
    if ($sel -notmatch '^\d+$' -or [int]$sel -lt 1 -or [int]$sel -gt $backups.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        return
    }
    $chosen = $backups[[int]$sel - 1]
    if (-not (Confirm-Action "Restore all values from '$($chosen.Name)'? This overwrites current values in those specific keys only.")) { return }

    $regFiles = @(Get-ChildItem -Path $chosen.FullName -Filter "*.reg" -ErrorAction SilentlyContinue)
    foreach ($f in $regFiles) {
        try {
            reg import "$($f.FullName)" 2>$null | Out-Null
            Write-Host ("  [RESTORED] {0}" -f $f.Name) -ForegroundColor Green
            Write-Log "Restored $($f.Name) from backup $($chosen.Name)"
        } catch {
            Write-Host ("  [FAILED]   {0}" -f $f.Name) -ForegroundColor Red
        }
    }
    Write-Host "`n[DONE] Restore complete. Sign out/reboot may be needed for every value to take effect." -ForegroundColor Green
}

function Show-BackupMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [7] BACKUP & RESTORE`n" -ForegroundColor Green
        Write-Host " [1] Create a backup of tweakable settings (do this before tweaking!)"
        Write-Host " [2] Restore settings from a previous backup"
        Write-Host " [3] Open the backups folder in Explorer"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { New-TweaksBackup | Out-Null; Read-Host "`nPress ENTER..." | Out-Null }
            "2" { Restore-TweaksBackup; Read-Host "`nPress ENTER..." | Out-Null }
            "3" {
                if (-not (Test-Path $BackupRoot)) { New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null }
                Start-Process explorer.exe $BackupRoot
            }
            "0" { return }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ==============================================================================
#  14. RESPONSIVENESS & GPU TWEAKS
#  (curated PowerShell port of community batch tweaks - the risky, hardware-
#  specific parts were intentionally left out, see chat explanation)
# ==============================================================================
function Set-MultiPlaneOverlay ([bool]$Disable) {
    if ($Disable) { Set-RegDword "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" 5 | Out-Null }
    else { Remove-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" | Out-Null }
}

function Set-UiDelays ([bool]$Reduce) {
    $desk = "HKCU:\Control Panel\Desktop"
    $mouse = "HKCU:\Control Panel\Mouse"
    if ($Reduce) {
        Set-ItemProperty -Path $desk  -Name "MenuShowDelay"  -Value "0"   -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mouse -Name "MouseHoverTime" -Value "100" -Force -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $desk  -Name "MenuShowDelay"  -Value "400" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $mouse -Name "MouseHoverTime" -Value "400" -Force -ErrorAction SilentlyContinue
    }
    Write-Log "UI delays reduced=$Reduce"
}

function Set-GamesMmcssProfile ([bool]$Apply) {
    $p = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    $g = "$p\Tasks\Games"
    if ($Apply) {
        Set-RegDword $p "SystemResponsiveness" 0 | Out-Null
        if (-not (Test-Path $g)) { New-Item -Path $g -Force | Out-Null }
        Set-ItemProperty -Path $g -Name "Affinity"            -Value 0       -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $g -Name "Background Only"     -Value "False" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $g -Name "Clock Rate"          -Value 10000   -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $g -Name "GPU Priority"        -Value 8       -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $g -Name "Priority"            -Value 6       -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $g -Name "Scheduling Category" -Value "High"  -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $g -Name "SFIO Priority"       -Value "High"  -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $g -Name "Latency Sensitive"   -Value "True"  -Force -ErrorAction SilentlyContinue
    } else {
        Remove-RegValue $p "SystemResponsiveness" | Out-Null
        # "Games" is a built-in MMCSS task; instead of deleting it we put back
        # Windows' own shipped defaults for it, which is safer than removing it.
        if (Test-Path $g) {
            Set-ItemProperty -Path $g -Name "GPU Priority"        -Value 8      -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $g -Name "Priority"            -Value 6      -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $g -Name "Scheduling Category" -Value "High" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $g -Name "SFIO Priority"       -Value "High" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $g -Name "Background Only"     -Value "False" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $g -Name "Clock Rate"          -Value 10000  -Type DWord -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "Games MMCSS profile applied=$Apply"
}

function Set-TimerResolution ([bool]$Enable) {
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
    if ($Enable) { Set-RegDword $k "GlobalTimerResolutionRequests" 1 | Out-Null }
    else { Remove-RegValue $k "GlobalTimerResolutionRequests" | Out-Null }
}

function Set-ActiveWindowTracking ([bool]$Enable) {
    Set-RegDword "HKCU:\Control Panel\Mouse" "ActiveWindowTracking" $(if ($Enable) {1} else {0}) | Out-Null
}

# ---- AMD-only tweaks: discover the real GPU registry key instead of
#      hard-coding "\0000", so this never touches the wrong adapter. ----
function Get-AmdDisplayKeys {
    $classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    @(Get-ChildItem $classPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | Where-Object {
        $prov = (Get-ItemProperty -Path $_.PSPath -Name "ProviderName" -ErrorAction SilentlyContinue).ProviderName
        $prov -match "Advanced Micro Devices|ATI Technologies"
    })
}

function Set-AmdShaderCache ([string]$Mode) {
    # Mode: "Off" (0x3000), "Default" (0x3100, AMD-optimized / Windows default), or "AlwaysOn" (0x3200)
    $keys = Get-AmdDisplayKeys
    if ($keys.Count -eq 0) { Write-Host "  No AMD GPU registry key found." -ForegroundColor DarkGray; return }
    $bytes = switch ($Mode) {
        "AlwaysOn" { [byte[]](0x32,0x00) }
        "Off"      { [byte[]](0x30,0x00) }
        default    { [byte[]](0x31,0x00) }
    }
    foreach ($k in $keys) {
        $umd = Join-Path $k.PSPath "UMD"
        if (-not (Test-Path $umd)) { New-Item -Path $umd -Force | Out-Null }
        Set-ItemProperty -Path $umd -Name "ShaderCache" -Value $bytes -Type Binary -Force
        Write-Host ("  [APPLIED] ShaderCache = {0} at {1}" -f $Mode, $umd) -ForegroundColor Green
        Write-Log "AMD ShaderCache -> $Mode at $umd"
    }
}

function Set-AmdUlps ([bool]$Disable) {
    $classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    $keys = @(Get-ChildItem $classPath -Recurse -ErrorAction SilentlyContinue | Where-Object {
        (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).PSObject.Properties.Name -contains "EnableUlps"
    })
    if ($keys.Count -eq 0) { Write-Host "  No AMD ULPS key found (not exposed by this GPU/driver)." -ForegroundColor DarkGray; return }
    $val = if ($Disable) { 0 } else { 1 }
    foreach ($k in $keys) {
        Set-RegDword $k.PSPath "EnableUlps" $val | Out-Null
        Write-Host ("  [APPLIED] EnableUlps = {0} at {1}" -f $val, $k.PSPath) -ForegroundColor Green
    }
}

function Set-AmdCrashDefender ([bool]$Disable) {
    # "AMD Crash Defender Service" ships with recent Adrenalin driver packages
    # and only collects/uploads crash diagnostics - safe to idle, easy to restore.
    $svc = Get-Service -Name "*Crash Defender*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $svc) { Write-Host "  AMD Crash Defender Service not found on this system." -ForegroundColor DarkGray; return }
    $mode = if ($Disable) { "Manual" } else { "Automatic" }
    Set-Service -InputObject $svc -StartupType $mode -ErrorAction SilentlyContinue
    if ($Disable) { Stop-Service -InputObject $svc -Force -ErrorAction SilentlyContinue } else { Start-Service -InputObject $svc -ErrorAction SilentlyContinue }
    Write-Host ("  [APPLIED] {0} -> {1}" -f $svc.Name, $mode) -ForegroundColor Green
    Write-Log "AMD Crash Defender Service -> $mode"
}

function Set-AmdTessellationMode ([string]$Level) {
    # Mirrors Radeon Software's "Tessellation Mode" per-application override.
    # Level: "Optimized" (driver decides, 0), "AppControlled" (1),
    # "Max8x" (2), "Max16x" (3). Some driver builds may not expose this key.
    $keys = Get-AmdDisplayKeys
    if ($keys.Count -eq 0) { Write-Host "  No AMD GPU registry key found." -ForegroundColor DarkGray; return }
    $val = switch ($Level) {
        "AppControlled" { 1 }
        "Max8x"         { 2 }
        "Max16x"        { 3 }
        default         { 0 }
    }
    foreach ($k in $keys) {
        $umd = Join-Path $k.PSPath "UMD"
        if (-not (Test-Path $umd)) { New-Item -Path $umd -Force | Out-Null }
        Set-RegDword $umd "TessellationMode" $val | Out-Null
        Write-Host ("  [APPLIED] TessellationMode = {0} ({1}) at {2}" -f $val, $Level, $umd) -ForegroundColor Green
    }
    Write-Log "AMD Tessellation mode -> $Level ($val)"
}

function Set-AmdFuelService ([bool]$Disable) {
    # "AMD FUEL Service" brokers Radeon Software's overlay/eventing features.
    # It isn't required for the GPU driver itself - safe to idle and restore.
    $svc = Get-Service -Name "*FUEL*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $svc) { Write-Host "  AMD FUEL Service not found on this system." -ForegroundColor DarkGray; return }
    $mode = if ($Disable) { "Manual" } else { "Automatic" }
    Set-Service -InputObject $svc -StartupType $mode -ErrorAction SilentlyContinue
    if ($Disable) { Stop-Service -InputObject $svc -Force -ErrorAction SilentlyContinue } else { Start-Service -InputObject $svc -ErrorAction SilentlyContinue }
    Write-Host ("  [APPLIED] {0} -> {1}" -f $svc.Name, $mode) -ForegroundColor Green
    Write-Log "AMD FUEL Service -> $mode"
}

# ---- NVIDIA-only tweaks: same GUID class as AMD, filtered to the NVIDIA
#      driver provider so this never touches a mixed-GPU system's wrong key. ----
function Get-NvidiaDisplayKeys {
    $classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    @(Get-ChildItem $classPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | Where-Object {
        $prov = (Get-ItemProperty -Path $_.PSPath -Name "ProviderName" -ErrorAction SilentlyContinue).ProviderName
        $prov -match "NVIDIA"
    })
}

function Set-NvidiaPowerMode ([bool]$MaxPerformance) {
    # Mirrors NVIDIA Control Panel's "Power management mode" per-key values.
    # MaxPerformance -> "Prefer Maximum Performance", otherwise back to
    # driver-default adaptive behaviour (values removed, not zeroed).
    $keys = Get-NvidiaDisplayKeys
    if ($keys.Count -eq 0) { Write-Host "  No NVIDIA GPU registry key found." -ForegroundColor DarkGray; return }
    foreach ($k in $keys) {
        if ($MaxPerformance) {
            Set-RegDword $k.PSPath "PowerMizerEnable"   1 | Out-Null
            Set-RegDword $k.PSPath "PowerMizerLevel"    1 | Out-Null
            Set-RegDword $k.PSPath "PowerMizerLevelAC"  1 | Out-Null
            Write-Host ("  [APPLIED] Power Mode = Prefer Maximum Performance at {0}" -f $k.PSPath) -ForegroundColor Green
        } else {
            Remove-RegValue $k.PSPath "PowerMizerEnable"  | Out-Null
            Remove-RegValue $k.PSPath "PowerMizerLevel"   | Out-Null
            Remove-RegValue $k.PSPath "PowerMizerLevelAC" | Out-Null
            Write-Host ("  [APPLIED] Power Mode reset to driver default at {0}" -f $k.PSPath) -ForegroundColor Green
        }
        Write-Log "NVIDIA PowerMizer MaxPerformance=$MaxPerformance at $($k.PSPath)"
    }
}

function Set-NvidiaTelemetry ([bool]$Disable) {
    # "NVIDIA Telemetry Container" (NvTelemetryContainer) only feeds usage
    # stats back to NVIDIA - it is not required for the driver or GeForce
    # Experience's core GPU functions.
    $svc = Get-Service -Name "NvTelemetryContainer" -ErrorAction SilentlyContinue
    if (-not $svc) { $svc = Get-Service -Name "*NVIDIA Telemetry*" -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if (-not $svc) { Write-Host "  NVIDIA Telemetry service not found on this system." -ForegroundColor DarkGray; return }
    $mode = if ($Disable) { "Manual" } else { "Automatic" }
    Set-Service -InputObject $svc -StartupType $mode -ErrorAction SilentlyContinue
    if ($Disable) { Stop-Service -InputObject $svc -Force -ErrorAction SilentlyContinue } else { Start-Service -InputObject $svc -ErrorAction SilentlyContinue }
    Write-Host ("  [APPLIED] {0} -> {1}" -f $svc.Name, $mode) -ForegroundColor Green
    Write-Log "NVIDIA Telemetry service -> $mode"
}

function Set-NvidiaContainerServices ([bool]$Disable) {
    # NvContainerLocalSystem / NvContainerNetworkService back GeForce
    # Experience's overlay, ShadowPlay and update-check features. Neither
    # is required for the display driver to render or for games to run.
    $names = @("NvContainerLocalSystem", "NvContainerNetworkService")
    $found = $false
    foreach ($n in $names) {
        $svc = Get-Service -Name $n -ErrorAction SilentlyContinue
        if (-not $svc) { continue }
        $found = $true
        $mode = if ($Disable) { "Manual" } else { "Automatic" }
        Set-Service -InputObject $svc -StartupType $mode -ErrorAction SilentlyContinue
        if ($Disable) { Stop-Service -InputObject $svc -Force -ErrorAction SilentlyContinue } else { Start-Service -InputObject $svc -ErrorAction SilentlyContinue }
        Write-Host ("  [APPLIED] {0} -> {1}" -f $svc.Name, $mode) -ForegroundColor Green
        Write-Log "NVIDIA Container service $n -> $mode"
    }
    if (-not $found) { Write-Host "  NVIDIA Container services not found on this system." -ForegroundColor DarkGray }
}

# ---- Vendor-neutral: GPU driver TDR (Timeout Detection & Recovery) delay ----
function Set-GpuTdrDelay ([bool]$Extend) {
    # Windows resets a GPU driver that doesn't respond within TdrDelay
    # seconds (default 2). Heavy sustained workloads (long shader compiles,
    # some compute/rendering tasks) can hit that ceiling and trigger a false
    # "display driver stopped responding" recovery. Raising it to 8s gives
    # the driver more room without disabling the safety mechanism entirely.
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    if ($Extend) { Set-RegDword $k "TdrDelay" 8 | Out-Null }
    else { Remove-RegValue $k "TdrDelay" | Out-Null }
    Write-Log "GPU TdrDelay extended=$Extend"
}

# ---- PCIe ASPM / Link State Power Management ----
function Set-AspmPowerSaving ([bool]$Disable) {
    $sub     = "501a4d13-42af-4429-9fd1-a8218c268e20"   # PCI Express subgroup
    $setting = "ee12f906-d277-404b-b6da-e5fa1a576df5"   # Link State Power Management
    $val = if ($Disable) { 0 } else { 1 }               # 0=Off, 1=Moderate (typical Windows default)
    powercfg /setacvalueindex SCHEME_CURRENT $sub $setting $val 2>$null | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT $sub $setting $val 2>$null | Out-Null
    powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
    Write-Log "PCIe ASPM value -> $val"
}

# ---- Hardware-Accelerated GPU Scheduling (vendor-neutral, Windows 10 2004+/build 19041+) ----
function Get-HagsState {
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt 19041) { return "Unsupported on this build" }
    try {
        $v = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction Stop).HwSchMode
        if ($v -eq 2) { return "Enabled" } else { return "Disabled" }
    } catch { return "Disabled (default)" }
}

function Set-HagsMode ([string]$Mode) {
    # HwSchMode: 2=Enabled, 1=Disabled, key absent=let Windows decide.
    # This is the same registry value the Settings app toggle writes to,
    # it just skips the GUI. Needs a restart to take effect either way.
    $build = [System.Environment]::OSVersion.Version.Build
    if ($build -lt 19041) {
        Write-Host "  [SKIPPED] HAGS needs Windows 10 version 2004 (build 19041) or newer." -ForegroundColor Yellow
        return
    }
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    switch ($Mode) {
        "Enable"  { Set-RegDword $k "HwSchMode" 2 | Out-Null }
        "Disable" { Set-RegDword $k "HwSchMode" 1 | Out-Null }
        default   { Remove-RegValue $k "HwSchMode" | Out-Null }
    }
    Write-Log "HAGS (HwSchMode) set to $Mode"
}

# ---- Fullscreen Optimizations (per-user, no admin needed but grouped here for convenience) ----
function Set-FullscreenOptimizations ([bool]$Disable) {
    $k = "HKCU:\System\GameConfigStore"
    if ($Disable) {
        Set-RegDword $k "GameDVR_FSEBehaviorMode" 2 | Out-Null
        Set-RegDword $k "GameDVR_HonorUserFSEBehaviorMode" 1 | Out-Null
    } else {
        Remove-RegValue $k "GameDVR_FSEBehaviorMode" | Out-Null
        Remove-RegValue $k "GameDVR_HonorUserFSEBehaviorMode" | Out-Null
    }
    Write-Log "Fullscreen Optimizations disabled=$Disable"
}

function Restore-AllResponsivenessTweaks {
    Set-MultiPlaneOverlay $false
    Set-UiDelays $false
    Set-GamesMmcssProfile $false
    Set-TimerResolution $false
    Set-ActiveWindowTracking $false
    Set-AspmPowerSaving $false
    Set-GpuTdrDelay $false
    Set-HagsMode "Default"
    Set-FullscreenOptimizations $false
    if ($script:GpuProfile -ne "NVIDIA") {
        Set-AmdShaderCache "Default"
        Set-AmdUlps $false
        Set-AmdTessellationMode "Optimized"
        Set-AmdFuelService $false
    }
    if ($script:GpuProfile -ne "AMD") {
        Set-NvidiaPowerMode $false
        Set-NvidiaTelemetry $false
        Set-NvidiaContainerServices $false
    }
    Write-Host "[DONE] Reverted to defaults." -ForegroundColor Green
}

function Show-ResponsivenessMenu {
    while ($true) {
        Show-Banner | Out-Null

        # Build the menu fresh every loop so it always reflects the current GPU profile.
        $items = @(
            @{ Text = "Disable Multi-Plane Overlay (fixes some flickering/stutter)"; Action = { Set-MultiPlaneOverlay $true; Write-Host "[DONE]" -ForegroundColor Green } }
            @{ Text = "Reduce menu/mouse-hover delay (snappier UI)"; Action = { Set-UiDelays $true; Write-Host "[DONE]" -ForegroundColor Green } }
            @{ Text = "Apply MMCSS 'Games' profile + SystemResponsiveness=0"; Action = { Set-GamesMmcssProfile $true; Write-Host "[DONE]" -ForegroundColor Green } }
            @{ Text = "Enable high-resolution system timer"; Action = { Set-TimerResolution $true; Write-Host "[DONE]" -ForegroundColor Green } }
            @{ Text = "Enable hover-to-focus window tracking"; Action = { Set-ActiveWindowTracking $true; Write-Host "[DONE]" -ForegroundColor Green } }
            @{ Text = "Extend GPU driver TDR delay to 8s (fewer false 'driver crashed' recoveries)"; Action = { Set-GpuTdrDelay $true; Write-Host "[DONE]" -ForegroundColor Green } }
            @{ Text = "Disable PCIe ASPM power saving (also disable in BIOS for full effect)"
               Action = { if (Confirm-Action "For full effect also disable ASPM in BIOS. Apply the Windows-side change now?") { Set-AspmPowerSaving $true; Write-Host "[DONE]" -ForegroundColor Green } } }
            @{ Text = ("Hardware-Accelerated GPU Scheduling: currently {0} - toggle it" -f (Get-HagsState))
               Action = {
                   $state = Get-HagsState
                   if ($state -like "Unsupported*") { Write-Host "  This build of Windows doesn't support HAGS." -ForegroundColor Yellow }
                   elseif ($state -eq "Enabled") { Set-HagsMode "Disable"; Write-Host "[DONE] HAGS disabled - restart to apply." -ForegroundColor Green }
                   else { Set-HagsMode "Enable"; Write-Host "[DONE] HAGS enabled - restart to apply." -ForegroundColor Green }
               } }
            @{ Text = "Disable Fullscreen Optimizations for all games (exclusive fullscreen, lower input lag)"; Action = { Set-FullscreenOptimizations $true; Write-Host "[DONE]" -ForegroundColor Green } }
        )

        if ($script:GpuProfile -ne "NVIDIA") {
            $items += @{ Text = "[AMD] Shader Cache = Always On"; Action = { Set-AmdShaderCache "AlwaysOn"; Write-Host "[DONE]" -ForegroundColor Green } }
            $items += @{ Text = "[AMD] Shader Cache = Off"; Action = { Set-AmdShaderCache "Off"; Write-Host "[DONE]" -ForegroundColor Green } }
            $items += @{ Text = "[AMD] Tessellation override = Max 16x"; Action = { Set-AmdTessellationMode "Max16x"; Write-Host "[DONE]" -ForegroundColor Green } }
            $items += @{ Text = "[AMD] Tessellation override = Application controlled"; Action = { Set-AmdTessellationMode "AppControlled"; Write-Host "[DONE]" -ForegroundColor Green } }
            $items += @{ Text = "[AMD] Disable ULPS (raises idle GPU power/heat)"
                         Action = { if (Confirm-Action "This can raise idle GPU power draw/heat/fan noise. Continue?") { Set-AmdUlps $true; Write-Host "[DONE]" -ForegroundColor Green } } }
            $items += @{ Text = "[AMD] Set AMD FUEL Service to Manual (Radeon overlay/eventing backend)"; Action = { Set-AmdFuelService $true; Write-Host "[DONE]" -ForegroundColor Green } }
        }

        if ($script:GpuProfile -ne "AMD") {
            $items += @{ Text = "[NVIDIA] Power Mode = Prefer Maximum Performance"; Action = { Set-NvidiaPowerMode $true; Write-Host "[DONE]" -ForegroundColor Green } }
            $items += @{ Text = "[NVIDIA] Set NVIDIA Telemetry service to Manual"; Action = { Set-NvidiaTelemetry $true; Write-Host "[DONE]" -ForegroundColor Green } }
            $items += @{ Text = "[NVIDIA] Set NVIDIA Container services to Manual (GFE overlay/telemetry backend)"; Action = { Set-NvidiaContainerServices $true; Write-Host "[DONE]" -ForegroundColor Green } }
        }

        $items += @{ Text = "Restore ALL of the above to Windows defaults"; Action = { if (Confirm-Action "Revert ALL Responsiveness & GPU tweaks to Windows defaults?") { Restore-AllResponsivenessTweaks } } }

        Write-Host ("`n>>> [8] RESPONSIVENESS & GPU TWEAKS   [GPU profile: {0}]`n" -f $script:GpuProfile) -ForegroundColor Green
        for ($i = 0; $i -lt $items.Count; $i++) {
            Write-Host (" [{0}] {1}" -f ($i + 1), $items[$i].Text)
        }
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        if ($c -eq "0") { return }
        if ($c -match '^\d+$' -and [int]$c -ge 1 -and [int]$c -le $items.Count) {
            & $items[[int]$c - 1].Action
            Read-Host "`nPress ENTER..." | Out-Null
        } else {
            Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1
        }
    }
}

# ==============================================================================
#  15. OPTIONAL SERVICE TWEAKS
#  Curated, opt-in only. Each disable is auto-backed-up (.reg) and its
#  original startup type is recorded so it can be restored exactly - not
#  guessed. Deliberately excludes services whose removal risks system
#  stability or security (see chat explanation for the full list/why).
# ==============================================================================
function Get-ServiceStateMap {
    if (Test-Path $ServiceStateFile) {
        try {
            $obj = Get-Content $ServiceStateFile -Raw | ConvertFrom-Json
            $map = @{}
            foreach ($p in $obj.PSObject.Properties) { $map[$p.Name] = $p.Value }
            return $map
        } catch { return @{} }
    }
    return @{}
}

function Save-ServiceStateMap ($map) {
    $map | ConvertTo-Json | Set-Content -Path $ServiceStateFile -Force
}

function Set-ServiceDisabled ($svcName) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Host ("  [SKIPPED] {0} (not present on this system)" -f $svcName) -ForegroundColor DarkGray; return }
    try {
        $map = Get-ServiceStateMap
        if (-not $map.ContainsKey($svcName)) { $map[$svcName] = $svc.StartType.ToString() }
        Save-ServiceStateMap $map

        $bdir = Join-Path $BackupRoot "ServiceBackups"
        if (-not (Test-Path $bdir)) { New-Item -Path $bdir -ItemType Directory -Force | Out-Null }
        reg export "HKLM\SYSTEM\CurrentControlSet\Services\$svcName" (Join-Path $bdir "$svcName.reg") /y 2>$null | Out-Null

        Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svcName -StartupType Disabled -ErrorAction Stop
        Write-Host ("  [DISABLED] {0}" -f $svcName) -ForegroundColor Green
        Write-Log "Service disabled: $svcName (was $($map[$svcName]))"
    } catch {
        Write-Host ("  [FAILED] {0}" -f $svcName) -ForegroundColor Red
    }
}

function Restore-ServiceDefault ($svcName) {
    $map = Get-ServiceStateMap
    $original = if ($map.ContainsKey($svcName)) { $map[$svcName] } else { "Manual" }
    try {
        Set-Service -Name $svcName -StartupType $original -ErrorAction Stop
        if ($original -eq "Automatic") { Start-Service -Name $svcName -ErrorAction SilentlyContinue }
        Write-Host ("  [RESTORED] {0} -> {1}" -f $svcName, $original) -ForegroundColor Green
        Write-Log "Service restored: $svcName -> $original"
        if ($map.ContainsKey($svcName)) { $map.Remove($svcName) | Out-Null; Save-ServiceStateMap $map }
    } catch {
        Write-Host ("  [FAILED] {0}" -f $svcName) -ForegroundColor Red
    }
}

$SafeServices = @(
    @{ Name="DiagTrack";             Desc="Telemetry / usage-data collection" },
    @{ Name="MapsBroker";            Desc="Downloaded Maps Manager (only needed for offline Maps app)" },
    @{ Name="lfsvc";                 Desc="Geolocation Service (only needed for location-based apps)" },
    @{ Name="WPCSvc";                Desc="Parental Controls / Family Safety" },
    @{ Name="Fax";                   Desc="Fax service" },
    @{ Name="RetailDemo";            Desc="Retail Demo Mode (store display units)" },
    @{ Name="CscService";            Desc="Offline Files (domain-joined laptops only)" },
    @{ Name="SEMgrSvc";              Desc="Payments and NFC/SE Manager" },
    @{ Name="lltdsvc";               Desc="Link-Layer Topology Discovery (only the Network Map graphic)" },
    @{ Name="AppVClient";            Desc="Microsoft App-V (enterprise app virtualization)" },
    @{ Name="AssignedAccessManager"; Desc="Kiosk mode manager" },
    @{ Name="WorkFolders";           Desc="Work Folders sync (enterprise)" },
    @{ Name="UevAgentService";       Desc="User Experience Virtualization (enterprise)" },
    @{ Name="MessagingService";      Desc="Text messaging via Phone Link" },
    @{ Name="shpamsvc";              Desc="Shared PC Account Manager (kiosk/shared PCs)" },
    @{ Name="PcaSvc";                Desc="Program Compatibility Assistant popups" },
    @{ Name="WerSvc";                Desc="Windows Error Reporting (stops auto crash-report uploads)" },
    @{ Name="NetTcpPortSharing";     Desc="Net.Tcp Port Sharing (rarely used .NET feature)" },
    @{ Name="QWAVE";                 Desc="Quality Windows A/V Experience (legacy multimedia QoS)" }
)

$CautionServices = @(
    @{ Name="bthserv";               Desc="Bluetooth Support -- BREAKS ALL Bluetooth devices" },
    @{ Name="BluetoothUserService";  Desc="Bluetooth user service -- breaks Bluetooth features" },
    @{ Name="WbioSrvc";              Desc="Windows Biometric -- breaks fingerprint/face Windows Hello sign-in" },
    @{ Name="Spooler";               Desc="Print Spooler -- BREAKS ALL printing, incl. Print to PDF" },
    @{ Name="WSearch";               Desc="Windows Search -- breaks Start Menu/Explorer/Outlook search index" },
    @{ Name="SCardSvr";              Desc="Smart Card -- breaks smart-card/security-key sign-in" },
    @{ Name="TabletInputService";    Desc="Touch keyboard & handwriting panel" },
    @{ Name="PhoneSvc";              Desc="Phone Link service" },
    @{ Name="OneSyncSvc";            Desc="Mail/Calendar/People app syncing" },
    @{ Name="XblAuthManager";        Desc="Xbox Live Auth -- may break Xbox/Game Pass online features" },
    @{ Name="XblGameSave";           Desc="Xbox Live Game Save -- may break cloud game saves" },
    @{ Name="XboxGipSvc";            Desc="Xbox Accessory Management -- may break controller features" },
    @{ Name="XboxNetApiSvc";         Desc="Xbox Live Networking -- may break Xbox multiplayer features" },
    @{ Name="BcastDVRUserService";   Desc="Game DVR/Broadcast (overlaps with Gaming menu's Game Bar tweak)" }
)

function Show-ServiceChecklist ($list, $extraWarning) {
    Write-Host ""
    for ($i = 0; $i -lt $list.Count; $i++) {
        Write-Host ("  [{0}] {1,-24} - {2}" -f ($i + 1), $list[$i].Name, $list[$i].Desc)
    }
    Write-Host "`nType comma-separated numbers (e.g. 1,3,5), 'all', or ENTER to cancel."
    $sel = Read-Host "Selection"
    if ([string]::IsNullOrWhiteSpace($sel)) { return }
    $targets = if ($sel.Trim().ToLower() -eq "all") { $list } else {
        $sel -split "," | ForEach-Object {
            $idx = $_.Trim()
            if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $list.Count) { $list[[int]$idx - 1] }
        }
    }
    if (-not $targets -or $targets.Count -eq 0) { Write-Host "Nothing selected." -ForegroundColor Yellow; return }
    if ($extraWarning) { Write-Host "`n[!] These are CAUTION-level services - re-read the descriptions above." -ForegroundColor Yellow }
    if (-not (Confirm-Action "Disable $($targets.Count) service(s)? Each is backed up first and can be restored from option [3].")) { return }
    foreach ($item in $targets) { Set-ServiceDisabled $item.Name }
}

function Show-ServiceRestoreMenu {
    $map = Get-ServiceStateMap
    if ($map.Count -eq 0) { Write-Host "No ZORO-tweaked services recorded yet." -ForegroundColor Yellow; return }
    $names = @($map.Keys)
    Write-Host "`nServices previously disabled by this tool:`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $names.Count; $i++) { Write-Host ("  [{0}] {1} (was: {2})" -f ($i + 1), $names[$i], $map[$names[$i]]) }
    $sel = Read-Host "`nType numbers to restore, 'all', or ENTER to cancel"
    if ([string]::IsNullOrWhiteSpace($sel)) { return }
    $targets = if ($sel.Trim().ToLower() -eq "all") { $names } else {
        $sel -split "," | ForEach-Object {
            $idx = $_.Trim(); if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $names.Count) { $names[[int]$idx - 1] }
        }
    }
    foreach ($n in $targets) { Restore-ServiceDefault $n }
}

function Show-ServiceTweaksMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [9] OPTIONAL SERVICE TWEAKS`n" -ForegroundColor Green
        Write-Host " Disabling unused background services can shave a little idle CPU/RAM." -ForegroundColor Gray
        Write-Host " Only disable what you're sure you don't use. Everything here is reversible." -ForegroundColor Gray
        Write-Host ""
        Write-Host " [1] Disable low-impact services (safe for most PCs)"
        Write-Host " [2] Disable caution services (read the warnings first!)"
        Write-Host " [3] Restore previously disabled services"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { Show-ServiceChecklist $SafeServices $false; Read-Host "`nPress ENTER..." | Out-Null }
            "2" { Show-ServiceChecklist $CautionServices $true; Read-Host "`nPress ENTER..." | Out-Null }
            "3" { Show-ServiceRestoreMenu; Read-Host "`nPress ENTER..." | Out-Null }
            "0" { return }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ==============================================================================
#  16. SYSTEM REPAIR & RAM
#  Wraps the built-in sfc / DISM repair tools and adds a standby-memory-list
#  purge. Both are read-only-safe in the sense that nothing here can corrupt
#  a working system: SFC/DISM only replace files with known-good copies from
#  the component store or Windows Update, and the RAM cleaner only asks the
#  memory manager to release cached pages it is already free to discard.
# ==============================================================================
function Invoke-SfcScan {
    Write-Host "`n  Running: sfc /scannow  (this can take several minutes, do not close the window)`n" -ForegroundColor Cyan
    Write-Log "SFC scan started"
    sfc /scannow
    Write-Log "SFC scan finished"
}

function Invoke-DismCheckHealth {
    Write-Host "`n  Running: DISM /Online /Cleanup-Image /CheckHealth  (fast, just flags a corrupted image)`n" -ForegroundColor Cyan
    Write-Log "DISM CheckHealth started"
    DISM /Online /Cleanup-Image /CheckHealth
    Write-Log "DISM CheckHealth finished"
}

function Invoke-DismScanHealth {
    Write-Host "`n  Running: DISM /Online /Cleanup-Image /ScanHealth  (thorough scan, several minutes)`n" -ForegroundColor Cyan
    Write-Log "DISM ScanHealth started"
    DISM /Online /Cleanup-Image /ScanHealth
    Write-Log "DISM ScanHealth finished"
}

function Invoke-DismRestoreHealth {
    Write-Host "`n  Running: DISM /Online /Cleanup-Image /RestoreHealth  (repairs via Windows Update, needs internet)`n" -ForegroundColor Cyan
    Write-Log "DISM RestoreHealth started"
    DISM /Online /Cleanup-Image /RestoreHealth
    Write-Log "DISM RestoreHealth finished"
}

function Invoke-FullImageRepair {
    if (-not (Confirm-Action "This runs DISM RestoreHealth then SFC /scannow back to back. It can take 15-30+ minutes and needs internet. Continue?")) { return }
    Invoke-DismRestoreHealth
    Invoke-SfcScan
    Write-Host "`n[DONE] Full repair pass finished. A restart is recommended." -ForegroundColor Green
}

# ---- Standby list (cached RAM) purge ----
# Same OS-level technique Sysinternals RAMMap's "Empty Standby List" button
# uses (NtSetSystemInformation / SystemMemoryListInformation). It only tells
# the memory manager to release pages it was already free to discard, so
# there is nothing here that can lose unsaved data - worst case it simply
# fails (e.g. missing privilege) and nothing changes.
$ZoroMemCleanerSrc = @"
using System;
using System.Runtime.InteropServices;

public static class ZoroMemCleaner
{
    [DllImport("ntdll.dll")]
    private static extern uint NtSetSystemInformation(int infoClass, IntPtr info, int length);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetCurrentProcess();

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern bool OpenProcessToken(IntPtr proc, uint access, out IntPtr token);

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern bool LookupPrivilegeValue(string sys, string name, out LUID luid);

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern bool AdjustTokenPrivileges(IntPtr token, bool disableAll, ref TOKEN_PRIVILEGES newState, uint bufLen, IntPtr prev, IntPtr prevLen);

    [StructLayout(LayoutKind.Sequential)]
    private struct LUID { public uint LowPart; public int HighPart; }

    [StructLayout(LayoutKind.Sequential)]
    private struct LUID_AND_ATTRIBUTES { public LUID Luid; public uint Attributes; }

    [StructLayout(LayoutKind.Sequential)]
    private struct TOKEN_PRIVILEGES { public uint PrivilegeCount; public LUID_AND_ATTRIBUTES Privileges; }

    private const uint TOKEN_ADJUST_PRIVILEGES = 0x0020;
    private const uint TOKEN_QUERY = 0x0008;
    private const uint SE_PRIVILEGE_ENABLED = 0x0002;

    private static bool EnablePrivilege(string name)
    {
        IntPtr token;
        if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out token)) return false;
        LUID luid;
        if (!LookupPrivilegeValue(null, name, out luid)) return false;
        TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
        tp.PrivilegeCount = 1;
        tp.Privileges = new LUID_AND_ATTRIBUTES { Luid = luid, Attributes = SE_PRIVILEGE_ENABLED };
        return AdjustTokenPrivileges(token, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    }

    // 80 = SystemMemoryListInformation, 4 = MemoryPurgeStandbyList
    public static int PurgeStandbyList()
    {
        if (!EnablePrivilege("SeProfileSingleProcessPrivilege")) return -1;
        IntPtr ptr = Marshal.AllocHGlobal(sizeof(int));
        try
        {
            Marshal.WriteInt32(ptr, 4);
            return (int)NtSetSystemInformation(80, ptr, sizeof(int));
        }
        finally { Marshal.FreeHGlobal(ptr); }
    }
}
"@

function Invoke-StandbyListClean {
    try {
        if (-not ("ZoroMemCleaner" -as [type])) {
            Add-Type -TypeDefinition $ZoroMemCleanerSrc -ErrorAction Stop
        }
        $before = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
        $result = [ZoroMemCleaner]::PurgeStandbyList()
        Start-Sleep -Milliseconds 400
        $after = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
        if ($result -eq 0) {
            Write-Host ("  [OK] Standby list purged. Free RAM: {0:N1} GB -> {1:N1} GB" -f ($before / 1MB), ($after / 1MB)) -ForegroundColor Green
            Write-Log "Standby list purged ($before KB -> $after KB free)"
        } else {
            Write-Host "  [FAILED] The OS refused the request (code $result). This can happen if the required privilege isn't available on this system." -ForegroundColor Red
            Write-Log "Standby list purge failed, code $result" "ERROR"
        }
    } catch {
        Write-Host "  [FAILED] $_" -ForegroundColor Red
        Write-Log "Standby list purge exception: $_" "ERROR"
    }
}

function Show-RepairMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [10] SYSTEM REPAIR & RAM`n" -ForegroundColor Green
        Write-Host " System file / component-store repair:" -ForegroundColor Gray
        Write-Host " [1] Quick health check (DISM CheckHealth - a few seconds)"
        Write-Host " [2] Full corruption scan (DISM ScanHealth - a few minutes)"
        Write-Host " [3] Repair Windows image (DISM RestoreHealth - needs internet)"
        Write-Host " [4] System File Checker (sfc /scannow)"
        Write-Host " [5] Full repair pass: RestoreHealth then sfc /scannow (recommended order)"
        Write-Host ""
        Write-Host " RAM:" -ForegroundColor Gray
        Write-Host " [6] Clean standby memory list (frees cached RAM without closing anything)"
        Write-Host ""
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { Invoke-DismCheckHealth; Read-Host "`nPress ENTER..." | Out-Null }
            "2" { Invoke-DismScanHealth; Read-Host "`nPress ENTER..." | Out-Null }
            "3" { if (Confirm-Action "This downloads repair files via Windows Update if needed. Continue?") { Invoke-DismRestoreHealth }; Read-Host "`nPress ENTER..." | Out-Null }
            "4" { Invoke-SfcScan; Read-Host "`nPress ENTER..." | Out-Null }
            "5" { Invoke-FullImageRepair; Read-Host "`nPress ENTER..." | Out-Null }
            "6" { Invoke-StandbyListClean; Read-Host "`nPress ENTER..." | Out-Null }
            "0" { return }
            default { Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    }
}

# ==============================================================================
#  17. MAIN MENU
# ==============================================================================
while ($true) {
    Show-Banner | Out-Null
    Write-Host ""
    Write-Host " [1] Network Optimization      [2] DNS Optimizer"
    Write-Host " [3] Windows Tweaks            [4] CPU Tweaks"
    Write-Host " [5] Gaming Tweaks             [6] Miscellaneous"
    Write-Host " [7] Backup & Restore          [8] Responsiveness & GPU Tweaks"
    Write-Host " [9] Service Tweaks"
    Write-Host "------------------------------------------------------------------------"
    Write-Host " [D] Discord ($DiscordName)    [G] GitHub    [Q] Exit"
    Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    $choice = Read-Host "Choose an option"

    switch ($choice.ToUpper()) {
        "1" { Show-NetworkMenu }
        "2" { Show-DnsMenu }
        "3" { Show-WindowsMenu }
        "4" { Show-CpuMenu }
        "5" { Show-GamingMenu }
        "6" { Show-MiscMenu }
        "7" { Show-BackupMenu }
        "8" { Show-ResponsivenessMenu }
        "9" { Show-ServiceTweaksMenu }
        "D" {
            if ($DiscordInvite) { Start-Process $DiscordInvite } else { Write-Host "`nDiscord: $DiscordName" -ForegroundColor Cyan; Read-Host "Press ENTER..." | Out-Null }
        }
        "G" { Start-Process $GitHubUrl }
        "Q" { Write-Host "`nBye!" -ForegroundColor Cyan; Exit }
        default { Write-Host "`nInvalid selection!" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
}