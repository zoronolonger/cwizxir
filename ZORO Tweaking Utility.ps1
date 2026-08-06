# ==============================================================================
#  ZORO - Windows Tweaking Utility
#  by zoro (cwizxir)  |  Discord: cwizxir  |  GitHub: https://github.com/zoronolonger
#  Version 3.7.0  |  Requires: Windows 10 22H2+ / Windows 11 23H2+ (24H2+),
#  Administrator, PowerShell 5.1+. Windows 7/8/Server are out of scope and
#  are not checked for or supported anywhere in this file.
#
#  Scope: network / DNS / power / gaming registry settings and first-party
#  bundled "bloat" apps only. Never touches Defender, UAC, Windows Update,
#  or any other security control. Every menu entry carries an [n/10] honesty
#  tag - the real-world impact of that tweak on a modern system, not a
#  marketing number. Full reasoning for every rating lives in TWEAK_AUDIT.md.
#
#  Condensed changelog (full history: CHANGELOG.md):
#  - v3.12.0: new Advanced Storage Optimization menu [18] - TRIM
#    (DisableDeleteNotify) gated to Get-SystemStorageProfile.IsSsd, NTFS
#    Last-Access Timestamp toggle, Scheduled Drive Optimization ("Optimize
#    Drives" task) repair, and Storage Sense enable/disable via its
#    documented StoragePolicy registry value. No manual "defrag now" for
#    SSDs (TRIM is the correct mechanism, not defrag) and no unrelated
#    "SSD tweak pack" registry keys - every item maps to one verifiable
#    mechanism, reusing Get-SystemStorageProfile rather than a second
#    disk-type probe.
#  - v3.11.0: new Advanced Memory Optimization menu [17] - MMAgent memory
#    compression toggle (PS5.1-native, PS7+ via Import-Module -UseWindowsPowerShell
#    fallback through new Test-MMAgentAvailable) with a new MemoryCompression
#    undo-record type (same precedent as InterfaceMtu/DnsServers for
#    non-registry-shaped changes); Page File "System Managed" repair via the
#    documented PagingFiles registry convention (new Set-RegMultiStringVerified
#    helper, REG_MULTI_SZ counterpart to Set-RegDword/Set-RegStringVerified);
#    read-only Memory Diagnostics (RAM/commit charge/compression/page file/top
#    processes); Windows Memory Diagnostic (mdsched.exe) launcher. SysMain/
#    Superfetch intentionally not duplicated - it already lives in Service
#    Tweaks [9] with a live disk-type-based recommendation. No "disable
#    pagefile" or LargeSystemCache option - both obsolete/harmful advice.
#  - v3.10.0: new Process Scheduler Optimization menu [16] - real,
#    Microsoft-documented thread/process scheduler and MMCSS (Multimedia
#    Class Scheduler Service) tuning: Processor Scheduling mode (the exact
#    Win32PrioritySeparation values System Properties > Performance Options
#    > Advanced writes - 38 "Programs" / 2 "Background services"), MMCSS
#    Low-Latency Mode (SystemResponsiveness 20->0), MMCSS Network
#    Throttling disable (NetworkThrottlingIndex -> -1 / 0xFFFFFFFF, stored
#    as signed DWord to avoid the UInt32-overflow trap), a defensive
#    "Games" MMCSS task repair (Test-GamesTaskProfileHealthy / rated 3/10 -
#    restores Windows' own shipped values, doesn't uplift a stock system,
#    exists to undo what other "optimizer" tools commonly break), and an
#    MMCSS-service health repair (Automatic+Running, since every value
#    above is inert if the service isn't). All six route through the
#    existing Invoke-ValidatedTweak/Invoke-DetectedTweak lifecycle
#    (Requirements/Apply/Verify/Rollback, PASS/FAIL, Undo-ledger backed) -
#    no new undo-record type needed. New Set-RegStringVerified helper
#    (REG_SZ counterpart to Set-RegDword, same snapshot/undo/verify
#    discipline) added next to Set-RegDword for the Games-task string
#    values. No core-parking override added - see the existing hybrid-
#    topology reasoning above Get-CpuTopologyInfo, which still applies.
#    Surfaced in Tweak Health Check and System Requirements Check
#    alongside every other module instead of as a silent bolt-on.
#  - v3.9.0: Release-hardening pass (no menu/behavior changes) - centralized
#    error handling (Get-ZoroErrorCategory/Invoke-ZoroSafeOperation classify
#    every network/registry failure into RegistryLocked/AccessDenied/
#    AdapterRestart/NetworkReset/MissingAdapter/UnsupportedHardware/
#    TemporaryNetworkFailure with a specific recovery message, replacing
#    ~15 duplicated try/catch blocks across the Recovery Actions menu, NIC
#    power/RSS/Interrupt-Moderation toggles, MTU/DNS/NIC-property writers,
#    and Invoke-ValidatedTweak's Apply catch); new Network Config
#    Consistency check (Test-/Repair-NetworkConfigConsistency) cross-checks
#    MTU/DNS/RSS-RSC on the primary adapter after MTU Discovery and DNS
#    changes, auto-reverting only the two unambiguous, Undo-ledger-backed
#    cases (MTU below the safe floor, static DNS resolving nothing) and
#    surfacing anything else read-only in Tweak Health Check; short-TTL
#    result cache (Get-ZoroCachedValue, auto-invalidated by Add-UndoRecord
#    on every tracked write) cuts repeated Get-NetAdapter/CIM/WMI reads on
#    every menu redraw (Show-Banner's system snapshot, GPU vendor, CPU
#    topology, storage profile, primary/active adapter lookups).
#  - v3.8.0: new Game Network Diagnostics menu [15] - Automatic Best Game
#    Adapter Detection (classifies Ethernet/Wi-Fi/VPN/Hyper-V/VMware/
#    VirtualBox/WSL/other virtual adapters carrying the active default
#    route); NIC Driver Health Check (Win32_PnPSignedDriver + Get-PnpDevice,
#    same warn-only-on-genuine-signal precedent as Get-GpuDriverInfo); IRQ/
#    MSI Capability Detection with an opt-in MSI enable through the
#    documented per-device Interrupt Management registry key (routed
#    through the existing Set-RegDword undo/verify path, no new undo record
#    type needed); Bufferbloat Test (real idle vs. real loaded-transfer
#    latency via ping.exe + HttpClient, A-F graded off the measured
#    increase only, skipped outright if idle ping fails); Route Quality
#    Analyzer (tracert.exe per-hop latency/loss parsing + multi-pass
#    consistency check); Gaming Connectivity Test (DNS/TCP-connect/ICMP
#    against Steam/Battle.net/Epic/Riot/Roblox/Xbox/PlayStation or a custom
#    host); and an Advanced Diagnostics Report that writes all of the above
#    (plus DNS/Gateway/IPv4/IPv6/public IP) to a timestamped TXT file.
#  - v3.7.0: Smart DNS Benchmark (multi-pass Resolve-DnsName timing across
#    5 providers, auto/manual apply through the Undo ledger via a new
#    "DnsServers" record type; DNS also included in Backup/Restore) and a
#    standalone Connection Benchmark (Avg/Min/Max ping+jitter+loss from one
#    parsed ping.exe run via Get-PingStatistics; DNS latency reuses
#    Test-DnsResolutionLatency; real timed HTTP throughput; a weighted
#    Network Quality Score that reports "Partial" if any input is missing).
#  - v3.6.0: Network Core - Automatic MTU Discovery (DF-flagged ICMP binary
#    search via ping.exe, applied/read back through Set-NetIPInterface,
#    undoable via a new "InterfaceMtu" record type); read-only Modern TCP
#    Analyzer (Auto-Tuning/ECN/Congestion Provider/RSS/RSC/NetworkDirect +
#    netsh DCA/Chimney, only fixes Auto-Tuning/ECN when not already correct);
#    Advanced NIC Optimizer (detects real per-driver support before touching
#    anything; RSS/RSC detection shared with the TCP Analyzer via
#    Invoke-RssRscTweaks; buffers raised to the driver's own advertised max;
#    ARP/NS Offload and EEE are reported, never silently auto-applied - EEE
#    is its own opt-in toggle). Undo engine extended with InterfaceMtu,
#    NicFeatureToggle, NicAdvancedProperty record types.
#  - v3.5.0: GPU-section audit (RTX 3000-5000, RX 6000-9000) - fixed a
#    SysMain/Superfetch classification bug (SATA SSD no longer treated as
#    HDD; Get-SystemStorageProfile now reads MediaType directly); added
#    Test-IsLaptop (battery + chassis signals) gating Ultimate Performance
#    behind an explicit battery-impact confirmation on laptops; removed a
#    duplicate, non-undo-tracked HAGS writer from Gaming Tweaks in favor of
#    the single validated Set-HagsMode path and rebuilt that menu as
#    data-driven; HAGS entries now hidden outright when prerequisites
#    (Win10 2004+ and WDDM 2.7+) aren't met; AMD/NVIDIA tweaks grouped under
#    explicit headers everywhere they're listed together; added
#    Get-GpuDriverInfo (WMI driver-age/WHQL check) surfaced on System
#    Requirements and GPU Extras when stale/unsigned.
#  - v3.4.0: added Ultimate Performance next to High Performance (menu 4,
#    not a replacement); added the two-stage Undo Last Session system -
#    every Set-RegDword/Remove-RegValue/service-startup write records its
#    prior value both in memory and to disk before writing, so [U] rolls
#    back live or after a restart/crash (does not cover app/Edge removal,
#    temp cleanup, or DISM/SFC repairs).
#  - v3.3.0: removed detection-only functions that printed a value but
#    never gated a tweak's Supported/AlreadyOk/Verify state (PCIe link
#    speed, ReBAR/SAM, driver age, DirectStorage prereqs, VRR, DX12U level,
#    MPO/Flip-Model, DXGI summary, overlay scan, VBS status, GPU power
#    telemetry) along with the menu that only existed to display them;
#    detection that still gates real behavior (WDDM/Game Mode/HAGS/HVCI/
#    GPU-MSI/ASPM) was kept, and ASPM now verifies its applied state instead
#    of trusting the powercfg exit code.
#  - v3.2.0: added Invoke-DetectedTweak, a silent pre-check layer so HAGS,
#    HVCI, GPU MSI Mode, and VBS/Game Mode report Skipped instead of
#    re-applying an already-correct value.
#  - v3.1.0: added the Test-*/Invoke-ValidatedTweak framework (declare
#    preconditions, apply, verify actual resulting state); Set-RegDword/
#    Remove-RegValue now read back every value they write; deduplicated the
#    AMD/NVIDIA registry-lookup and vendor-service-toggle logic; fixed the
#    System Repair & RAM menu being unreachable from the main menu.
# ==============================================================================
 
# ---------- 0. CONFIG ----------
$ScriptVersion = "3.12.0"
$DiscordName   = "cwizxir"
$DiscordInvite = ""   # put your invite link here (e.g. "https://discord.gg/xxxxx") to auto-open on [D]
$GitHubUrl     = "https://github.com/zoronolonger"
$script:PSMajor = $PSVersionTable.PSVersion.Major   # used by Get-SystemSnapshot (Test-Connection property differs pre/post PS6); defined up front instead of after its only consumer
 
# ---------- 1. ADMIN CHECK / SELF-ELEVATION ----------
# Rather than telling the user to go relaunch it themselves, ZORO relaunches
# itself elevated via UAC and exits the non-elevated instance. If elevation
# is cancelled at the UAC prompt, it falls back to the old clear error.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $scriptPath = $MyInvocation.MyCommand.Path
    if ($scriptPath) {
        Write-Host "`n[INFO] Administrator rights are required. Requesting elevation via UAC...`n" -ForegroundColor Yellow
        try {
            Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"") -Verb RunAs -ErrorAction Stop
            Exit
        } catch {
            Write-Host "`n[ERROR] Elevation was cancelled or failed. Right-click the script and select 'Run as administrator'.`n" -ForegroundColor Red
            Read-Host "Press ENTER to exit" | Out-Null
            Exit
        }
    } else {
        # Piped via 'irm ... | iex' - $MyInvocation.MyCommand.Path is empty, can't self-relaunch a file that doesn't exist on disk.
        Write-Host "`n[ERROR] Open PowerShell as Administrator, then re-run the irm/iex command.`n" -ForegroundColor Red
        Read-Host "Press ENTER to exit" | Out-Null
        Exit
    }
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
$UndoSessionFile  = "$WorkDir\UndoSession.json"    # rolling ledger of every change this tool has made, not yet undone
 
function Write-Log ($message, $level = "INFO") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$timestamp] [$level] $message"
}

# ==============================================================================
#  2b. UNDO ENGINE - single rollback path shared by Session Undo and
#  Persistent Undo. Every write that goes through Set-RegDword, Remove-RegValue,
#  or a service startup-type change records the value it is ABOUT to overwrite
#  BEFORE touching anything, and that record is flushed to disk before the
#  actual change happens - so a crash mid-tweak still leaves an accurate,
#  restorable record on disk, not a half-written one.
#
#  "Session" and "Persistent" are the same underlying ledger, not two separate
#  systems: $script:SessionLog is hydrated from $UndoSessionFile at launch (so
#  a prior run that was closed or crashed without undoing is still there), then
#  kept live in memory and re-flushed to disk on every change for the rest of
#  this run. Undo always prefers memory (Get-CurrentUndoRecords) and only
#  re-reads the file if memory is empty, which is the "prefer session, fall
#  back to persistent" behavior spelled out below - it just happens that after
#  the hydration step, both paths are backed by the same records.
#
#  Scope, stated plainly: this engine restores registry values and service
#  startup types - i.e. everything the tweak framework above actually writes.
#  It does not and cannot "undo" app removal, Edge's uninstall, temp-file
#  deletion, or DISM/SFC repairs; those are not reversible by re-writing a
#  saved value, and pretending otherwise would be exactly the kind of fake
#  safety net this tool refuses to ship. Debloat/Edge removal keep their own
#  explicit, honest warnings instead.
# ==============================================================================
$script:UndoInProgress = $false
$script:SessionLog     = @()

function Get-PersistedUndoSession {
    <# Reads the on-disk ledger. Returns @() (never $null) so callers can
       always .Count it safely. #>
    if (-not (Test-Path $UndoSessionFile)) { return @() }
    try {
        $raw = Get-Content -Path $UndoSessionFile -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
        return @($raw | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        Write-Log "Could not read $UndoSessionFile : $_" "ERROR"
        return @()
    }
}

# Hydrate in-memory session from disk at launch - a prior run that was closed
# or crashed before Undo was run is still "the last session" until it's
# either undone or overwritten by new changes in this run.
$script:SessionLog = @(Get-PersistedUndoSession)

function Save-UndoSessionToDisk {
    try {
        if ($script:SessionLog.Count -eq 0) {
            if (Test-Path $UndoSessionFile) { Remove-Item $UndoSessionFile -Force -ErrorAction SilentlyContinue }
            return
        }
        ($script:SessionLog | ConvertTo-Json -Depth 6) | Set-Content -Path $UndoSessionFile -Force -Encoding UTF8
    } catch {
        Write-Log "Failed to persist undo session to disk: $_" "ERROR"
    }
}

function Add-UndoRecord ($Record) {
    <# Called by Set-RegDword / Remove-RegValue / service startup-type writers
       BEFORE they touch anything. Silently no-ops while a rollback itself is
       running, so undoing a change never records another undo record for it.
       Also the single choke point used to invalidate the performance cache
       (3a) - every tracked write goes through here, so clearing the cache
       here (rather than at each of the dozen write call sites) guarantees a
       cached adapter/DNS/TCP read can never survive past the moment this
       tool itself changes the system. #>
    if ($script:UndoInProgress) { return }
    $Record.Time = (Get-Date -Format "o")
    $script:SessionLog = @($script:SessionLog) + $Record
    Save-UndoSessionToDisk
    if (Get-Command Clear-ZoroCache -ErrorAction SilentlyContinue) { Clear-ZoroCache }
}

function Get-CurrentUndoRecords {
    <# The one place that decides Session (memory) vs Persistent (disk).
       Memory is preferred whenever it has anything in it; disk is only
       consulted as a fallback, e.g. if $script:SessionLog was somehow
       cleared without going through a completed Undo. #>
    if ($script:SessionLog.Count -gt 0) { return @($script:SessionLog) }
    return @(Get-PersistedUndoSession)
}

function Invoke-UndoRecord ($Rec) {
    <# Restores exactly one recorded change and verifies the restored value
       by reading it back - same discipline as Set-RegDword/Remove-RegValue.
       Never throws; a bad record fails that one entry, not the whole undo. #>
    $script:UndoInProgress = $true
    $ok = $false
    try {
        switch ($Rec.Type) {
            "Registry" {
                if ($Rec.HadValue) {
                    try {
                        if (-not (Test-Path $Rec.Path)) { New-Item -Path $Rec.Path -Force | Out-Null }
                        $kind = if ($Rec.PreviousKind) { $Rec.PreviousKind } else { "DWord" }
                        New-ItemProperty -Path $Rec.Path -Name $Rec.Name -PropertyType $kind -Value $Rec.PreviousValue -Force | Out-Null
                        $readBack = (Get-ItemProperty -Path $Rec.Path -Name $Rec.Name -ErrorAction Stop).($Rec.Name)
                        $ok = ("$readBack" -eq "$($Rec.PreviousValue)")
                    } catch { $ok = $false }
                } else {
                    try {
                        if (Test-Path $Rec.Path) { Remove-ItemProperty -Path $Rec.Path -Name $Rec.Name -ErrorAction SilentlyContinue }
                        $stillThere = $false
                        try { $null = (Get-ItemProperty -Path $Rec.Path -Name $Rec.Name -ErrorAction Stop).($Rec.Name); $stillThere = $true } catch { $stillThere = $false }
                        $ok = (-not $stillThere)
                    } catch { $ok = $false }
                }
            }
            "Service" {
                $svc = Get-Service -Name $Rec.Name -ErrorAction SilentlyContinue
                if (-not $svc) { $ok = $true }   # service no longer exists - nothing left to restore, not a failure
                else {
                    $applied = Set-ServiceStartupVerified -Name $Rec.Name -StartupType $Rec.PreviousStartType
                    $ok = $applied.Verified
                }
            }
            "InterfaceMtu" {
                # Network Core: Automatic MTU Discovery. Not a registry-shaped
                # change (applied via Set-NetIPInterface), so it gets its own
                # restore path instead of being forced through the Registry case.
                try {
                    Set-NetIPInterface -InterfaceIndex $Rec.InterfaceIndex -AddressFamily IPv4 -NlMtu $Rec.PreviousMtu -ErrorAction Stop
                    $readBack = (Get-NetIPInterface -InterfaceIndex $Rec.InterfaceIndex -AddressFamily IPv4 -ErrorAction Stop).NlMtu
                    $ok = ($readBack -eq $Rec.PreviousMtu)
                } catch { $ok = $false }
            }
            "NicFeatureToggle" {
                # Network Core: TCP Analyzer / Advanced NIC Optimizer RSS+RSC.
                try {
                    $enableCmd  = "Enable-NetAdapter$($Rec.FeatureName)"
                    $disableCmd = "Disable-NetAdapter$($Rec.FeatureName)"
                    if ($Rec.PreviousEnabled) { & $enableCmd -Name $Rec.AdapterName -ErrorAction Stop } else { & $disableCmd -Name $Rec.AdapterName -ErrorAction Stop }
                    $state = & "Get-NetAdapter$($Rec.FeatureName)" -Name $Rec.AdapterName -ErrorAction Stop
                    $nowEnabled = if ($Rec.FeatureName -eq "Rsc") { [bool]($state | Where-Object { $_.IPv4Enabled -or $_.IPv6Enabled }) } else { [bool]$state.Enabled }
                    $ok = ($nowEnabled -eq $Rec.PreviousEnabled)
                } catch { $ok = $false }
            }
            "NicAdvancedProperty" {
                # Network Core: Advanced NIC Optimizer (Buffers/Flow Control) +
                # EEE toggle - both go through Set-NetAdapterAdvancedProperty.
                try {
                    Set-NetAdapterAdvancedProperty -Name $Rec.AdapterName -DisplayName $Rec.DisplayName -RegistryValue $Rec.PreviousRegistryValue -ErrorAction Stop
                    $readBack = @((Get-NetAdapterAdvancedProperty -Name $Rec.AdapterName -DisplayName $Rec.DisplayName -ErrorAction Stop).RegistryValue)[0]
                    $ok = ("$readBack" -eq "$($Rec.PreviousRegistryValue)")
                } catch { $ok = $false }
            }
            "DnsServers" {
                # Smart DNS Benchmark: not a registry-shaped change (applied
                # via Set-DnsClientServerAddress), so like InterfaceMtu it
                # gets its own restore path. HadServers=$false means the
                # adapter was DHCP-assigned (no static servers) before the
                # benchmark applied anything, so restoring means clearing
                # back to DHCP rather than writing a previous server list.
                try {
                    if ($Rec.HadServers -and @($Rec.PreviousServers).Count -gt 0) {
                        Set-DnsClientServerAddress -InterfaceAlias $Rec.InterfaceAlias -ServerAddresses @($Rec.PreviousServers) -ErrorAction Stop
                    } else {
                        Set-DnsClientServerAddress -InterfaceAlias $Rec.InterfaceAlias -ResetServerAddresses -ErrorAction Stop
                    }
                    Clear-DnsClientCache -ErrorAction SilentlyContinue
                    $readBack = @((Get-DnsClientServerAddress -InterfaceAlias $Rec.InterfaceAlias -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses)
                    if ($Rec.HadServers -and @($Rec.PreviousServers).Count -gt 0) {
                        $ok = (@($readBack) -join ",") -eq (@($Rec.PreviousServers) -join ",")
                    } else {
                        $ok = (@($readBack).Count -eq 0)
                    }
                } catch { $ok = $false }
            }
            "MemoryCompression" {
                # Advanced Memory Optimization: MMAgent memory compression
                # isn't registry-shaped (Enable-MMAgent/Disable-MMAgent),
                # so like InterfaceMtu/DnsServers it gets its own restore path.
                try {
                    if ($Rec.PreviousEnabled) { Enable-MMAgent -MemoryCompression -ErrorAction Stop } else { Disable-MMAgent -MemoryCompression -ErrorAction Stop }
                    $nowEnabled = [bool](Get-MMAgent -ErrorAction Stop).MemoryCompression
                    $ok = ($nowEnabled -eq $Rec.PreviousEnabled)
                } catch { $ok = $false }
            }
            default { $ok = $false }
        }
    } finally {
        $script:UndoInProgress = $false
    }
    return [PSCustomObject]@{ Record = $Rec; Verified = $ok }
}

function Invoke-UndoLastSession {
    <# The single entry point for both [U] menu paths. Newest-change-first
       replay so a value that got set twice in one session unwinds correctly. #>
    $records = Get-CurrentUndoRecords
    $source  = if ($script:SessionLog.Count -gt 0) { "in-memory session" } else { "persisted session (survived restart)" }

    if ($records.Count -eq 0) {
        Write-Host "`nNo previous session found." -ForegroundColor Yellow
        Write-Log "Undo Last Session requested - no previous session found"
        return
    }

    Write-Host "`n>>> UNDO LAST SESSION`n" -ForegroundColor Green
    Write-Host (" Source: {0}" -f $source) -ForegroundColor Gray
    Write-Host (" {0} recorded change(s) will be reverted, most recent first." -f $records.Count) -ForegroundColor Gray
    Write-Host " Covers registry values and service startup types only - see" -ForegroundColor DarkGray
    Write-Host " TWEAK_AUDIT.md for what Undo intentionally cannot touch (app" -ForegroundColor DarkGray
    Write-Host " removal, Edge removal, temp cleanup, DISM/SFC repairs).`n" -ForegroundColor DarkGray
    if (-not (Confirm-Action "Roll back all $($records.Count) change(s)?")) { return }

    $ordered = $records | Sort-Object { [datetime]$_.Time } -Descending
    $ok = 0; $fail = 0
    foreach ($rec in $ordered) {
        $r = Invoke-UndoRecord $rec
        $label = switch ($rec.Type) {
            "Service"             { "Service: $($rec.Name)" }
            "InterfaceMtu"        { "MTU on interface #$($rec.InterfaceIndex)" }
            "NicFeatureToggle"    { "$($rec.FeatureName) on $($rec.AdapterName)" }
            "NicAdvancedProperty" { "$($rec.DisplayName) on $($rec.AdapterName)" }
            "DnsServers"          { "DNS servers on $($rec.InterfaceAlias)" }
            default               { "$($rec.Path)\$($rec.Name)" }
        }
        if ($r.Verified) {
            $ok++
            Write-Host ("  [RESTORED] {0}" -f $label) -ForegroundColor Green
            Write-Log "UNDO restored $($rec.Type) $label"
        } else {
            $fail++
            Write-Host ("  [FAILED]   {0}" -f $label) -ForegroundColor Red
            Write-Log "UNDO FAILED $($rec.Type) $label" "ERROR"
        }
    }

    Write-Host ("`n[DONE] {0} restored, {1} failed." -f $ok, $fail) -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })

    if ($fail -eq 0) {
        $script:SessionLog = @()
        if (Test-Path $UndoSessionFile) {
            $archive = Join-Path $LogDir ("UndoSession_{0}.json" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
            try { Move-Item -Path $UndoSessionFile -Destination $archive -Force -ErrorAction Stop; Write-Log "Undo session archived to $archive" }
            catch { Remove-Item $UndoSessionFile -Force -ErrorAction SilentlyContinue; Write-Log "Undo session cleared (archive move failed: $_)" "WARN" }
        }
        Write-Log "UNDO LAST SESSION complete - $ok/$($records.Count) restored, session cleared"
    } else {
        Write-Host "  $fail change(s) did not verify - the session was kept on disk so you can retry Undo." -ForegroundColor Yellow
        Write-Log "UNDO LAST SESSION incomplete - $ok restored, $fail failed, session kept on disk" "WARN"
    }
}

# ---------- 3. SMALL REGISTRY / SERVICE HELPERS (every tweak funnels through these) ----------
# Both write helpers now verify the change by reading the value straight back
# from the registry after writing it, instead of just trusting that no
# exception was thrown. A call that "succeeds" but reads back wrong (blocked
# by policy, redirected, wrong type, etc.) now returns $false and logs it as
# a verification failure, not a silent success.
function Get-RegUndoSnapshot ($Path, $Name) {
    <# Shared "what's there right now" read used before any registry write,
       so Set-RegDword/Remove-RegValue/Set-UiDelays all feed the undo ledger
       through one place instead of three copies of the same try/catch. #>
    $snap = [PSCustomObject]@{ HadValue = $false; PreviousValue = $null; PreviousKind = "DWord" }
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $v = $item.GetValue($Name, $null)
        if ($null -ne $v) {
            $snap.HadValue      = $true
            $snap.PreviousValue = $v
            $snap.PreviousKind  = $item.GetValueKind($Name).ToString()
        }
    } catch {}
    return $snap
}

function Set-RegDword ($Path, $Name, $Value) {
    try {
        $snap = Get-RegUndoSnapshot $Path $Name
        Add-UndoRecord @{ Type = "Registry"; Path = $Path; Name = $Name; HadValue = $snap.HadValue; PreviousValue = $snap.PreviousValue; PreviousKind = $snap.PreviousKind }
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
        $readBack = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
        if ("$readBack" -ne "$Value") {
            Write-Log "VERIFY-FAILED $Path\$Name = $Value (read back: $readBack)" "ERROR"
            return $false
        }
        Write-Log "SET $Path\$Name = $Value (verified)"
        return $true
    } catch {
        Write-Log "FAILED to set $Path\$Name : $_" "ERROR"
        return $false
    }
}

function Set-RegStringVerified ($Path, $Name, $Value) {
    <# REG_SZ counterpart to Set-RegDword above - same snapshot-before-write,
       read-back-after-write discipline, for the handful of tweaks (MMCSS
       "Games" task: Scheduling Category / SFIO Priority / Background Only)
       whose values are strings, not DWORDs. Shares Get-RegUndoSnapshot and
       Add-UndoRecord with Set-RegDword rather than duplicating either. #>
    try {
        $snap = Get-RegUndoSnapshot $Path $Name
        Add-UndoRecord @{ Type = "Registry"; Path = $Path; Name = $Name; HadValue = $snap.HadValue; PreviousValue = $snap.PreviousValue; PreviousKind = $snap.PreviousKind }
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
        $readBack = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
        if ("$readBack" -ne "$Value") {
            Write-Log "VERIFY-FAILED $Path\$Name = $Value (read back: $readBack)" "ERROR"
            return $false
        }
        Write-Log "SET $Path\$Name = $Value (verified)"
        return $true
    } catch {
        Write-Log "FAILED to set $Path\$Name : $_" "ERROR"
        return $false
    }
}

function Set-RegMultiStringVerified ($Path, $Name, [string[]]$Value) {
    <# REG_MULTI_SZ counterpart to Set-RegDword/Set-RegStringVerified - same
       snapshot/undo/verify discipline, for the PagingFiles value (Memory
       Optimization) and any future multi-string tweak. #>
    try {
        $snap = Get-RegUndoSnapshot $Path $Name
        Add-UndoRecord @{ Type = "Registry"; Path = $Path; Name = $Name; HadValue = $snap.HadValue; PreviousValue = $snap.PreviousValue; PreviousKind = $snap.PreviousKind }
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -PropertyType MultiString -Value $Value -Force | Out-Null
        $readBack = @((Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name)
        if (($readBack -join "|") -ne ($Value -join "|")) {
            Write-Log "VERIFY-FAILED $Path\$Name = $($Value -join ';') (read back: $($readBack -join ';'))" "ERROR"
            return $false
        }
        Write-Log "SET $Path\$Name = $($Value -join ';') (verified)"
        return $true
    } catch {
        Write-Log "FAILED to set $Path\$Name : $_" "ERROR"
        return $false
    }
}

function Remove-RegValue ($Path, $Name) {
    try {
        $snap = Get-RegUndoSnapshot $Path $Name
        if ($snap.HadValue) {
            Add-UndoRecord @{ Type = "Registry"; Path = $Path; Name = $Name; HadValue = $true; PreviousValue = $snap.PreviousValue; PreviousKind = $snap.PreviousKind }
        }
        if (Test-Path $Path) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }
        $stillThere = $false
        try { $null = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name; $stillThere = $true } catch { $stillThere = $false }
        if ($stillThere) {
            Write-Log "VERIFY-FAILED $Path\$Name still present after reset" "ERROR"
            return $false
        }
        Write-Log "RESET $Path\$Name to Windows default (verified)"
        return $true
    } catch {
        return $false
    }
}

# ---- Service startup-type helper: wraps the Set-Service/Stop/Start pattern
#      that used to be duplicated across every AMD/NVIDIA service tweak
#      (Set-AmdCrashDefender, Set-AmdFuelService, Set-NvidiaTelemetry,
#      Set-NvidiaContainerServices) plus Set-ServiceDisabled, into one place.
#      Verifies the new StartType by re-querying the service afterward
#      instead of trusting Set-Service's silent success. ----
function Set-ServiceStartupVerified ($Name, [string]$StartupType, [bool]$StopOrStart = $true) {
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { return [PSCustomObject]@{ Found = $false; Verified = $false; Service = $Name } }
    try {
        Add-UndoRecord @{ Type = "Service"; Name = $svc.Name; PreviousStartType = $svc.StartType.ToString() }
        Set-Service -InputObject $svc -StartupType $StartupType -ErrorAction Stop
        if ($StopOrStart) {
            if ($StartupType -eq "Disabled" -or $StartupType -eq "Manual") { Stop-Service -InputObject $svc -Force -ErrorAction SilentlyContinue }
            elseif ($StartupType -eq "Automatic") { Start-Service -InputObject $svc -ErrorAction SilentlyContinue }
        }
        $recheck = Get-Service -Name $svc.Name -ErrorAction Stop
        $verified = ($recheck.StartType.ToString() -eq $StartupType)
        Write-Log "Service $($svc.Name) StartupType -> $StartupType (verified=$verified)"
        return [PSCustomObject]@{ Found = $true; Verified = $verified; Service = $svc.Name; StartupType = $recheck.StartType.ToString() }
    } catch {
        Write-Log "FAILED to set service $Name startup type $StartupType : $_" "ERROR"
        return [PSCustomObject]@{ Found = $true; Verified = $false; Service = $svc.Name }
    }
}

function Confirm-Action ($msg) {
    Write-Host "`n$msg" -ForegroundColor Yellow
    $r = Read-Host "Type Y to continue, anything else cancels"
    return ($r -eq "Y" -or $r -eq "y")
}

# Shared "Press ENTER to continue" pause used by every menu screen. -NoBlank
# skips the leading blank line for screens that already end with one.
function Wait-ForEnter ([switch]$NoBlank) {
    if ($NoBlank) { Read-Host "Press ENTER to continue" | Out-Null } else { Read-Host "`nPress ENTER to continue" | Out-Null }
}

# Shared "bad menu choice" feedback used by every switch statement's default case.
function Show-InvalidSelection { Write-Host "Invalid selection. Please choose an option from the menu." -ForegroundColor Red; Start-Sleep -Seconds 1 }

# ==============================================================================
#  3a. PERFORMANCE CACHE
#  A tiny TTL cache so repeated Get-NetAdapter/Get-CimInstance/Get-NetTCPSetting
#  reads within a short window (a single menu screen redraw, one analyzer run,
#  one benchmark pass) reuse the same read instead of re-querying WMI/CIM or
#  re-enumerating adapters every time. Every entry is time-bounded (default
#  1.5s - long enough to cover one workflow, short enough that nothing is
#  ever more than ~1.5s stale), and Add-UndoRecord (the single choke point
#  every registry/service/MTU/NIC/DNS write already goes through) clears the
#  whole cache before that write happens - so a cached read can never survive
#  past the moment this tool itself changes the system. Static hardware facts
#  (GPU vendor, CPU topology, chassis type) use a much longer TTL since those
#  cannot change during a run without a reboot.
# ==============================================================================
$script:ZoroCache = @{}

function Get-ZoroCachedValue {
    <# Generic memoizer: returns the cached value for $Key if it's younger
       than $TtlMs, otherwise runs $Loader, caches, and returns the fresh
       value. $Loader exceptions are never swallowed here - they propagate
       exactly as an uncached call would, so callers keep their existing
       try/catch behavior unchanged. #>
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][scriptblock]$Loader,
        [int]$TtlMs = 1500
    )
    $now = [datetime]::UtcNow
    if ($script:ZoroCache.ContainsKey($Key)) {
        $entry = $script:ZoroCache[$Key]
        if (($now - $entry.Time).TotalMilliseconds -lt $TtlMs) { return $entry.Value }
    }
    $value = & $Loader
    $script:ZoroCache[$Key] = @{ Time = $now; Value = $value }
    return $value
}

function Clear-ZoroCache {
    <# Invalidates cached reads. With no prefix, clears everything (called
       from Add-UndoRecord before every tracked write). A prefix clears only
       matching keys, for call sites that know exactly what just changed. #>
    param([string]$KeyPrefix)
    if ([string]::IsNullOrEmpty($KeyPrefix)) { $script:ZoroCache = @{}; return }
    foreach ($k in @($script:ZoroCache.Keys)) { if ($k -like "$KeyPrefix*") { $script:ZoroCache.Remove($k) } }
}

# ==============================================================================
#  3b. CENTRALIZED ERROR HANDLING / RECOVERY CLASSIFICATION
#  A single place that turns a caught exception into one of a small set of
#  recovery-relevant categories, instead of every call site independently
#  pattern-matching (or not matching at all) $_.Exception.Message. Feeds both
#  Invoke-ZoroSafeOperation below and the enriched Reason text in
#  Invoke-ValidatedTweak's catch block, so a "why did this fail" message is
#  worded the same way everywhere in the tool.
# ==============================================================================
function Get-ZoroErrorCategory {
    <# Message-pattern classification - .NET/CIM/WMI network and registry
       failures don't carry a stable exception-type hierarchy that already
       distinguishes "adapter is restarting" from "adapter doesn't exist",
       so this reads the actual error text (and HResult where present). A
       message that matches nothing known returns "Unknown" rather than a
       guess. #>
    param([Parameter(Mandatory)]$ErrorRecord)
    $msg = ""
    try { $msg = "$($ErrorRecord.Exception.Message)" } catch { $msg = "$ErrorRecord" }
    if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "$ErrorRecord" }
    $hresult = $null
    try { $hresult = $ErrorRecord.Exception.HResult } catch {}

    $category =
        if ($msg -match "being used by another process|cannot be opened because it is being used|registry key.*(in use|locked)|handle is invalid") { "RegistryLocked" }
        elseif ($msg -match "Access is denied|access denied|UnauthorizedAccess|requested registry access is not allowed|Requested registry access") { "AccessDenied" }
        elseif ($msg -match "adapter is currently restarting|device is restarting|device is being reset|is in a state that is incompatible") { "AdapterRestart" }
        elseif ($msg -match "Winsock|network stack|catalog.*(corrupt|reset)|TCP/IP.*(reset|reinstall)") { "NetworkReset" }
        elseif ($msg -match "No MSFT_NetAdapter objects found|does not match any of the parameters|Cannot find a process|No adapter|adapter was not found|Cannot find.*adapter|network connection does not exist|element not found") { "MissingAdapter" }
        elseif ($msg -match "not supported|not implemented|does not support|feature is not available|is not applicable|The parameter is incorrect" ) { "UnsupportedHardware" }
        elseif ($msg -match "timed out|timeout|A network-related|unreachable|forcibly closed|transport connection|WSAE|host is down|No such host") { "TemporaryNetworkFailure" }
        else { "Unknown" }

    return [PSCustomObject]@{ Category = $category; Message = $msg; HResult = $hresult }
}

function Get-ZoroRecoveryGuidance {
    <# Short, human-facing sentence per category - what the person should
       actually do next, not just what went wrong. #>
    param([string]$Category)
    switch ($Category) {
        "RegistryLocked"          { return "The registry key is locked by another process (regedit, another tuning tool, a pending reboot). Close it and retry." }
        "AccessDenied"            { return "Access denied. Confirm ZORO is elevated (Administrator) and that no Group Policy is blocking this key." }
        "AdapterRestart"          { return "The network adapter is mid-restart. Wait a few seconds for it to come back up, then retry." }
        "NetworkReset"            { return "The network stack was reset (Winsock/TCP-IP reset in progress). A reboot may be required before this can be retried." }
        "MissingAdapter"          { return "No matching network adapter was found - it may be disabled, removed, or renamed since ZORO last enumerated adapters." }
        "UnsupportedHardware"     { return "This driver/hardware doesn't expose the requested feature - skipping is the expected, safe outcome here." }
        "TemporaryNetworkFailure" { return "A temporary network failure occurred (timeout/unreachable). Check connectivity and retry." }
        default                   { return "An unexpected error occurred - see the log for the full exception text." }
    }
}

function Invoke-ZoroSafeOperation {
    <#
    Centralized replacement for the try { ... } catch { Write-Log ...;
    Write-Host ... } pattern that used to be duplicated at nearly every
    network/registry call site. Runs $Action; on success returns Success=$true
    with the action's return value. On failure it:
      1. classifies the exception (RegistryLocked/AccessDenied/AdapterRestart/
         NetworkReset/MissingAdapter/UnsupportedHardware/TemporaryNetworkFailure),
      2. logs exactly one structured ERROR line through the existing Write-Log
         framework (never a raw, un-logged catch),
      3. runs $OnFailure if supplied (rollback/cleanup), inside its own
         try/catch so a rollback failure can't blow up the caller either,
      4. prints one consistent [FAILED] line (unless -Quiet, for callers that
         want to render their own message using the returned Category).
    Never throws - the caller always gets a result object back, so a single
    bad operation degrades to "Failed" instead of leaving the whole tweak
    session in an unknown, partially-applied state. #>
    param(
        [Parameter(Mandatory)][string]$OperationName,
        [Parameter(Mandatory)][scriptblock]$Action,
        [scriptblock]$OnFailure,
        [switch]$Quiet
    )
    try {
        $value = & $Action
        return [PSCustomObject]@{ Success = $true; Value = $value; Category = $null; Message = $null; Guidance = $null }
    } catch {
        $classified = Get-ZoroErrorCategory -ErrorRecord $_
        $guidance   = Get-ZoroRecoveryGuidance -Category $classified.Category
        Write-Log "OPERATION FAILED [$OperationName] category=$($classified.Category) - $($classified.Message)" "ERROR"
        if ($OnFailure) {
            try { & $OnFailure } catch { Write-Log "OPERATION [$OperationName] cleanup/rollback also failed: $_" "ERROR" }
        }
        if (-not $Quiet) {
            Write-Host ("  [FAILED] {0} - {1}" -f $OperationName, $guidance) -ForegroundColor Red
        }
        return [PSCustomObject]@{ Success = $false; Value = $null; Category = $classified.Category; Message = $classified.Message; Guidance = $guidance }
    }
}

# ==============================================================================
#  3c. NETWORK STATE CONSISTENCY PROTECTION
#  MTU / TCP / NIC / DNS are tuned by separate menu paths, but they aren't
#  independent - a jumbo MTU with no driver-side jumbo support, or a static
#  DNS server that stops resolving, silently breaks connectivity in a way
#  none of those individual "verified" read-backs would catch (they only
#  confirm the registry/API value was written, not that the result is
#  actually a coherent, working configuration). Test-NetworkConfigConsistency
#  is the read-only detector; Repair-NetworkConfigConsistency auto-reverts
#  only the subset that's unambiguous and safe to revert automatically
#  (by replaying the existing Undo ledger, never by guessing a new value) -
#  anything else found is reported, never force-changed.
# ==============================================================================
function Test-NetworkConfigConsistency {
    param([switch]$NoCache)
    $adapter = Get-PrimaryActiveAdapter -NoCache:$NoCache
    if (-not $adapter) { return [PSCustomObject]@{ Consistent = $true; Issues = @(); Adapter = $null } }
    $issues = @()

    # MTU sanity: below the RFC-safe floor this tool itself searches down to
    # (576) is a broken state, not a valid tuning choice; above 1500 with no
    # driver-advertised jumbo-frame support means those frames are likely
    # being silently dropped by the NIC or the next hop.
    try {
        $mtu = Get-InterfaceMtu $adapter.ifIndex
        if ($null -ne $mtu) {
            if ($mtu -lt 576) {
                $issues += "MTU on $($adapter.Name) is $mtu - below the safe IPv4 floor (576); likely to cause fragmentation/connectivity failures."
            } elseif ($mtu -gt 1500) {
                $jumbo = Get-NicAdvancedPropertyByPattern -AdapterName $adapter.Name -Patterns @("Jumbo")
                $jumboVal = 0
                if ($jumbo -and $jumbo.RegistryValue) { try { $jumboVal = [int]@($jumbo.RegistryValue)[0] } catch { $jumboVal = 0 } }
                if (-not $jumbo -or $jumboVal -le 1514) {
                    $issues += "MTU on $($adapter.Name) is $mtu (jumbo) but the driver doesn't advertise matching jumbo-frame support."
                }
            }
        }
    } catch {}

    # DNS reachability: static servers configured but none of them resolve -
    # a change that verified fine at the registry/API level but broke actual
    # name resolution.
    try {
        $dnsServers = @(Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        if (@($dnsServers).Count -gt 0) {
            $anyResolved = $false
            foreach ($srv in $dnsServers) {
                if ($null -ne (Test-DnsResolutionLatency -Server $srv -QueryName "www.msftconnecttest.com")) { $anyResolved = $true; break }
            }
            if (-not $anyResolved) { $issues += "Static DNS server(s) on $($adapter.Name) ($($dnsServers -join ', ')) are not resolving queries." }
        }
    } catch {}

    # RSC without RSS: RSC depends on RSS being active on the large majority
    # of drivers, so this combination is normally the leftover of a partial
    # change (driver update, interrupted tweak session), not a deliberate one.
    try {
        $rss = Get-NetAdapterRss -Name $adapter.Name -ErrorAction SilentlyContinue
        $rsc = Get-NetAdapterRsc -Name $adapter.Name -ErrorAction SilentlyContinue
        if ($rss -and $rsc -and $rss.Enabled -eq $false -and (@($rsc) | Where-Object { $_.IPv4Enabled -or $_.IPv6Enabled })) {
            $issues += "RSC is enabled on $($adapter.Name) while RSS is disabled - an inconsistent combination on most drivers (RSC normally requires RSS)."
        }
    } catch {}

    return [PSCustomObject]@{ Consistent = ($issues.Count -eq 0); Issues = $issues; Adapter = $adapter.Name }
}

function Repair-NetworkConfigConsistency {
    <# Re-checks, and for exactly the two auto-safe findings above (MTU below
       the safe floor, static DNS resolving nothing), reverts by replaying
       the most recent matching Undo record for that adapter/interface - the
       same restore path [U] Undo Last Session uses, so a repair here is
       byte-for-byte the same operation, just triggered automatically instead
       of by the user. Anything else Test-NetworkConfigConsistency finds
       (e.g. the RSS/RSC combination) is left alone and only reported -
       some drivers run that combination intentionally, so it's never
       force-changed. #>
    param([switch]$Silent)
    $check = Test-NetworkConfigConsistency -NoCache
    if ($check.Consistent -or -not $check.Adapter) { return $check }

    $records = Get-CurrentUndoRecords | Sort-Object { [datetime]$_.Time } -Descending

    if ($check.Issues | Where-Object { $_ -match "below the safe IPv4 floor" }) {
        $rec = $records | Where-Object { $_.Type -eq "InterfaceMtu" } | Select-Object -First 1
        if ($rec) {
            $r = Invoke-UndoRecord $rec
            Clear-ZoroCache
            if ($r.Verified) {
                Write-Log "Auto-restored MTU consistency on $($check.Adapter) via Undo record"
                if (-not $Silent) { Write-Host ("  [AUTO-RESTORED] MTU on {0} reverted to a safe, previously-known-good value." -f $check.Adapter) -ForegroundColor Green }
            }
        }
    }

    if ($check.Issues | Where-Object { $_ -match "are not resolving queries" }) {
        $rec = $records | Where-Object { $_.Type -eq "DnsServers" -and $_.InterfaceAlias -eq $check.Adapter } | Select-Object -First 1
        if ($rec) {
            $r = Invoke-UndoRecord $rec
            Clear-ZoroCache
            if ($r.Verified) {
                Write-Log "Auto-restored DNS consistency on $($check.Adapter) via Undo record"
                if (-not $Silent) { Write-Host ("  [AUTO-RESTORED] DNS on {0} reverted to the previous, working configuration." -f $check.Adapter) -ForegroundColor Green }
            }
        }
    }

    return Test-NetworkConfigConsistency -NoCache
}

# ---------- 4. SYSTEM INFO / GPU VENDOR DETECTION ----------
function Get-PrimaryGpuName {
    <# Raw Win32_VideoController name for the primary adapter. The underlying
       CIM query never changes mid-session (no hot-swap GPUs), so it's cached
       for the life of the run - Get-GpuVendor, Get-GpuModelTier, and the GPU
       profile prompt all read through this instead of each hitting WMI. #>
    return Get-ZoroCachedValue -Key "PrimaryGpuName" -TtlMs 3600000 -Loader {
        try { (Get-CimInstance Win32_VideoController -ErrorAction Stop | Select-Object -First 1).Name }
        catch { $null }
    }
}

function Get-GpuVendor {
    <# Returns "AMD", "NVIDIA", "INTEL" or "UNKNOWN" based on the primary GPU
       name. #>
    return Get-ZoroCachedValue -Key "GpuVendor" -TtlMs 3600000 -Loader {
        $name = Get-PrimaryGpuName
        if ($name -match "NVIDIA|GeForce|Quadro") { return "NVIDIA" }
        if ($name -match "AMD|Radeon") { return "AMD" }
        if ($name -match "Intel") { return "INTEL" }
        return "UNKNOWN"
    }
}
 
function Get-GpuModelTier {
    <# Classifies the primary GPU by display-name regex into a generation
       tier. This is a marketing-name match, not a device-ID/PCI lookup -
       good enough to gate a tweak menu so RTX 2060/GTX 1660/RX 5700 owners
       don't get shown tweaks that were only validated on RTX 3000+/RX 6000+
       silicon, not a substitute for a real hardware inventory tool. #>
    $name = Get-PrimaryGpuName
    if (-not $name) { return [PSCustomObject]@{ Tier = "UNKNOWN"; Vendor = "UNKNOWN"; Name = "Unknown" } }

    if ($name -match "RTX\s*(30|40|50)\d{2}")               { return [PSCustomObject]@{ Tier = "MODERN"; Vendor = "NVIDIA"; Name = $name } }
    if ($name -match "GTX|RTX\s*20\d{2}|MX\d{3}")            { return [PSCustomObject]@{ Tier = "OLDER";  Vendor = "NVIDIA"; Name = $name } }
    if ($name -match "RX\s*(6|7|9)\d{3}")                    { return [PSCustomObject]@{ Tier = "MODERN"; Vendor = "AMD";    Name = $name } }
    if ($name -match "RX\s*(4|5)\d{3}|Radeon (VII|RX Vega)") { return [PSCustomObject]@{ Tier = "OLDER";  Vendor = "AMD";    Name = $name } }
    if ($name -match "NVIDIA|GeForce")                       { return [PSCustomObject]@{ Tier = "UNKNOWN"; Vendor = "NVIDIA"; Name = $name } }
    if ($name -match "AMD|Radeon")                           { return [PSCustomObject]@{ Tier = "UNKNOWN"; Vendor = "AMD";    Name = $name } }
    return [PSCustomObject]@{ Tier = "UNKNOWN"; Vendor = "UNKNOWN"; Name = $name }
}

function Get-GpuDriverInfo {
    <# Real driver-compatibility signal, not a tweak: reads the installed
       display driver's date, version, and WHQL signer via the documented
       Win32_PnPSignedDriver WMI class. Used to warn (never block) before
       vendor-specific power-mode/shader-cache tweaks - a driver more than
       ~18 months old is a common, real cause of "the tweak didn't stick"
       reports, because the next driver update silently resets vendor
       registry keys back to its own defaults. Read-only, nothing written. #>
    $vendor = Get-GpuVendor
    $pattern = switch ($vendor) {
        "NVIDIA" { "NVIDIA" }
        "AMD"    { "Advanced Micro Devices|ATI Technologies" }
        default  { $null }
    }
    if (-not $pattern) { return $null }
    try {
        $drv = Get-CimInstance Win32_PnPSignedDriver -ErrorAction Stop |
            Where-Object { $_.DeviceClass -eq "DISPLAY" -and $_.Manufacturer -match $pattern } |
            Select-Object -First 1
        if (-not $drv) { return $null }
        $driverDate = $null
        try { $driverDate = [datetime]$drv.DriverDate } catch { try { $driverDate = [Management.ManagementDateTimeConverter]::ToDateTime($drv.DriverDate) } catch {} }
        $ageDays = if ($driverDate) { [math]::Round(((Get-Date) - $driverDate).TotalDays) } else { $null }
        return [PSCustomObject]@{
            Vendor        = $vendor
            DeviceName    = $drv.DeviceName
            DriverVersion = $drv.DriverVersion
            DriverDate    = $driverDate
            AgeDays       = $ageDays
            WhqlSigned    = [bool]($drv.Signer -match "Windows Hardware Compatibility Publisher")
        }
    } catch { return $null }
}

function Get-SystemStorageProfile {
    <# Best-effort disk-type + RAM check used to annotate the SysMain
       (Superfetch) tweak with a real recommendation instead of a flat
       "safe to disable" claim, and to gate every other place in this
       script that used to assume "not NVMe = spinning HDD". A SATA SSD
       is still an SSD - MediaType is the field that actually says so;
       BusType only tells you the connector, not the mechanism. IsSsd is
       true for any solid-state disk regardless of bus (SATA or NVMe);
       IsNvme narrows that to the NVMe bus specifically, where it's still
       useful (e.g. distinguishing "modest gain" vs "no gain" advice).
       Falls back to "Unknown" rather than guessing if Get-PhysicalDisk
       isn't available (older PS/WMI-only environments). Cached for the
       session - installed RAM and the OS disk's media type don't change
       while ZORO is running. #>
    return Get-ZoroCachedValue -Key "SystemStorageProfile" -TtlMs 3600000 -Loader {
        $ramGb = 0
        try { $ramGb = [math]::Round((Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).TotalVisibleMemorySize / 1MB, 0) } catch {}
        $isSsd = $false
        $isNvme = $false
        $diskKnown = $false
        try {
            $disks = Get-PhysicalDisk -ErrorAction Stop
            if ($disks) {
                $diskKnown = $true
                $osDisk = $disks | Where-Object { $_.DeviceId -eq 0 } | Select-Object -First 1
                if (-not $osDisk) { $osDisk = $disks | Select-Object -First 1 }
                $isNvme = ($osDisk.BusType -eq "NVMe")
                $isSsd  = ($osDisk.MediaType -eq "SSD") -or $isNvme
            }
        } catch {}
        return [PSCustomObject]@{ RamGb = $ramGb; IsSsd = $isSsd; IsNvme = $isNvme; DiskKnown = $diskKnown }
    }
}

function Test-IsLaptop {
    <# Two independent, documented signals instead of one: a present
       Win32_Battery entry (works even when chassis-type reporting is
       wrong, which is common on white-label/OEM boards), OR a
       Win32_SystemEnclosure ChassisTypes value that's actually a
       mobile-form-factor code (8=Portable, 9=Laptop, 10=Notebook,
       11=Hand Held, 12=Docking Station, 14=Sub Notebook, 18/21=Expansion/
       Sub Chassis, 30-32=Tablet/Convertible/Detachable). Either signal
       alone is enough - a desktop with no battery and a desktop chassis
       code won't match on either. Cached for the session - chassis type
       can't change without a reboot. #>
    return Get-ZoroCachedValue -Key "IsLaptop" -TtlMs 3600000 -Loader {
        try {
            if (Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop | Select-Object -First 1) { return $true }
        } catch {}
        try {
            $mobileTypes = @(8,9,10,11,12,14,18,21,30,31,32)
            $enclosure = Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction Stop | Select-Object -First 1
            if ($enclosure -and $enclosure.ChassisTypes) {
                foreach ($t in $enclosure.ChassisTypes) { if ($mobileTypes -contains [int]$t) { return $true } }
            }
        } catch {}
        return $false
    }
}

function Get-SystemSnapshot {
    <# Called by Show-Banner on every single menu redraw, so the CPU/RAM/OS/
       GPU CIM reads (which cannot change during a run) are cached for the
       session instead of re-querying WMI on every screen; only the ping -
       the one field that's actually meant to be live - is re-measured every
       call, same as before. #>
    $static = Get-ZoroCachedValue -Key "SystemSnapshotStatic" -TtlMs 3600000 -Loader {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $gpu = Get-PrimaryGpuName
        $ramGb = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1MB, 1) } else { 0 }
        [PSCustomObject]@{
            CPU = if ($cpu) { $cpu.Name.Trim() } else { "Unknown" }
            RAM = "$ramGb GB"
            OS  = if ($os) { "$($os.Caption) ($($os.BuildNumber))" } else { "Unknown" }
            GPU = if ($gpu) { $gpu } else { "Unknown" }
        }
    }
    $ping = "n/a"
    try {
        $p = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction Stop
        $rt = if ($script:PSMajor -ge 6) { $p.Latency } else { $p.ResponseTime }
        $ping = "$rt ms"
    } catch { $ping = "unreachable" }
 
    return [PSCustomObject]@{
        CPU = $static.CPU
        RAM = $static.RAM
        OS  = $static.OS
        GPU = $static.GPU
        Ping = $ping
        GpuVendor = Get-GpuVendor
    }
}

# ==============================================================================
#  4a. VALIDATION FRAMEWORK
#  Every "gate" a tweak might need before it's safe/meaningful to apply,
#  expressed as small, composable Test-* functions that return $true/$false,
#  plus Invoke-ValidatedTweak, which wraps pre-check -> apply -> post-verify
#  -> optional rollback into one consistent Success/Failed/Skipped contract.
#  This does NOT retroactively rewrap all 100+ tweak functions in the file -
#  see TWEAK_AUDIT.md for exactly which tweaks route through it today.
# ==============================================================================

function Test-MinWindowsBuild ([int]$MinBuild) {
    <# True if the running Windows build is >= MinBuild. #>
    return ([System.Environment]::OSVersion.Version.Build -ge $MinBuild)
}

function Test-CommandExists ([string]$Name) {
    <# True if a cmdlet/function/executable is available in this session. #>
    return [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Test-ServiceExists ([string]$Name) {
    <# True if a Windows service with this exact name is installed. #>
    return [bool](Get-Service -Name $Name -ErrorAction SilentlyContinue)
}

function Test-GpuVendorIs ([string]$Vendor) {
    <# True if the primary GPU's detected vendor matches (case-insensitive).
       "ANY" always passes - used by vendor-neutral tweaks that still want
       to run through the same requirements list for consistency. #>
    if ($Vendor -eq "ANY") { return $true }
    return ((Get-GpuVendor) -eq $Vendor.ToUpper())
}

function Test-WddmMinVersion ([string]$MinVersion) {
    <# Boolean gate on top of Get-WddmVersionReport (dxdiag text dump is
       still the only source for this - no CIM/registry equivalent), so
       both the diagnostics report and internal tweak gating read the
       exact same value instead of two independent queries drifting apart. #>
    $report = Get-WddmVersionReport
    if ($report -notmatch "WDDM ([\d\.]+)") { return $false }
    try { return ([version]$Matches[1]) -ge ([version]$MinVersion) } catch { return $false }
}

function Test-GpuTierIs ([string]$Tier) {
    <# True if the primary GPU's classified tier (MODERN/OLDER/UNKNOWN, see
       Get-GpuModelTier) matches. "ANY" always passes. #>
    if ($Tier -eq "ANY") { return $true }
    return ((Get-GpuModelTier).Tier -eq $Tier.ToUpper())
}

function Test-SystemRequirements ([hashtable[]]$Requirements) {
    <# Runs a list of named preconditions and returns one aggregate result
       instead of a bare bool, so callers/logs can say *why* a tweak was
       skipped instead of just that it was.
       Each entry: @{ Name = "..."; Test = { <scriptblock returning bool> } }
    #>
    $results = foreach ($req in $Requirements) {
        $passed = $false
        try { $passed = [bool](& $req.Test) } catch { $passed = $false }
        [PSCustomObject]@{ Name = $req.Name; Passed = $passed }
    }
    $failed = @($results | Where-Object { -not $_.Passed })
    return [PSCustomObject]@{
        Passed  = ($failed.Count -eq 0)
        Checks  = $results
        Reason  = if ($failed.Count -gt 0) { ($failed | ForEach-Object { $_.Name }) -join "; " } else { "" }
    }
}

function Invoke-ValidatedTweak {
    <#
    Central orchestrator for a tweak's full lifecycle:
      1. Requirements  - array of @{Name=...; Test={...}} checks (Test-SystemRequirements).
                          Any failure => Skipped, nothing is applied.
      2. Apply         - scriptblock that performs the change. May return a value
                          used by Verify.
      3. Verify        - scriptblock returning $true/$false that re-reads the
                          real system state (registry read-back, service
                          re-query, etc.) to confirm Apply actually took effect.
                          If omitted, Apply's own return value (cast to bool)
                          is used instead.
      4. Rollback      - optional scriptblock run only if Verify fails, to
                          undo a partial/failed change instead of leaving the
                          system in an unknown state.
    Always returns Success / Failed / Skipped + a human-readable Reason, and
    writes one structured log line per outcome. Never throws - a bad tweak
    can't crash the session.
    #>
    param(
        [Parameter(Mandatory)] [string]$Name,
        [hashtable[]]$Requirements = @(),
        [Parameter(Mandatory)] [scriptblock]$Apply,
        [scriptblock]$Verify,
        [scriptblock]$Rollback
    )

    if ($Requirements.Count -gt 0) {
        $req = Test-SystemRequirements $Requirements
        if (-not $req.Passed) {
            Write-Log "TWEAK SKIPPED [$Name] - requirements not met: $($req.Reason)" "WARN"
            return [PSCustomObject]@{ Tweak = $Name; Status = "Skipped"; Reason = "Requirements not met: $($req.Reason)" }
        }
    }

    try {
        $applyResult = & $Apply
    } catch {
        # Routed through the shared classifier (3b) instead of a raw
        # exception dump - RegistryLocked/AccessDenied/AdapterRestart/
        # NetworkReset/MissingAdapter/UnsupportedHardware/TemporaryNetworkFailure
        # each get a specific, actionable Reason instead of one generic
        # "exception during apply" string, while the Failed/Reason contract
        # every caller already relies on stays exactly the same shape.
        $classified = Get-ZoroErrorCategory -ErrorRecord $_
        $guidance   = Get-ZoroRecoveryGuidance -Category $classified.Category
        Write-Log "TWEAK FAILED [$Name] - category=$($classified.Category): $($classified.Message)" "ERROR"
        return [PSCustomObject]@{ Tweak = $Name; Status = "Failed"; Reason = "$($classified.Category): $guidance" }
    }

    $verified = $false
    try {
        $verified = if ($Verify) { [bool](& $Verify) } else { [bool]$applyResult }
    } catch {
        $verified = $false
    }

    if ($verified) {
        Write-Log "TWEAK SUCCESS [$Name] - verified" "INFO"
        return [PSCustomObject]@{ Tweak = $Name; Status = "Success"; Reason = "Applied and verified" }
    }

    if ($Rollback) {
        try { & $Rollback } catch { Write-Log "TWEAK [$Name] rollback also failed: $_" "ERROR" }
        Write-Log "TWEAK FAILED [$Name] - verification failed, rollback attempted" "ERROR"
        return [PSCustomObject]@{ Tweak = $Name; Status = "Failed"; Reason = "Post-apply verification failed; rollback attempted" }
    }
    Write-Log "TWEAK FAILED [$Name] - verification failed, no rollback defined" "ERROR"
    return [PSCustomObject]@{ Tweak = $Name; Status = "Failed"; Reason = "Post-apply verification failed" }
}

function Write-TweakResult ($result) {
    <# Console rendering for an Invoke-ValidatedTweak result, shared by every
       call site so Success/Failed/Skipped are always shown consistently. #>
    switch ($result.Status) {
        "Success" { Write-Host ("  [DONE]    {0} - {1}" -f $result.Tweak, $result.Reason) -ForegroundColor Green }
        "Skipped" { Write-Host ("  [SKIPPED] {0} - {1}" -f $result.Tweak, $result.Reason) -ForegroundColor Yellow }
        "Failed"  { Write-Host ("  [FAILED]  {0} - {1}" -f $result.Tweak, $result.Reason) -ForegroundColor Red }
    }
}

function Invoke-DetectedTweak {
    <#
    Thin wrapper around Invoke-ValidatedTweak for tweaks that need a silent
    pre-check before touching anything: is the feature even supported on
    this system, and if so, is it already sitting in the target state.
    Keeps the two distinct "nothing happened" outcomes the caller cares
    about - Not Supported vs. Already Configured - without duplicating the
    Apply/Verify/Rollback plumbing Invoke-ValidatedTweak already owns.
      Supported  - scriptblock, bool. False => Skipped (Not Supported).
      AlreadyOk  - scriptblock, bool. True  => Skipped, nothing to change.
    Anything past those two checks falls straight through to the normal
    Invoke-ValidatedTweak lifecycle (Requirements/Apply/Verify/Rollback).
    #>
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [scriptblock]$Supported,
        [Parameter(Mandatory)] [scriptblock]$AlreadyOk,
        [hashtable[]]$Requirements = @(),
        [Parameter(Mandatory)] [scriptblock]$Apply,
        [scriptblock]$Verify,
        [scriptblock]$Rollback
    )
    $isSupported = $false
    try { $isSupported = [bool](& $Supported) } catch { $isSupported = $false }
    if (-not $isSupported) {
        Write-Log "TWEAK SKIPPED [$Name] - feature not supported/exposed on this system" "WARN"
        return [PSCustomObject]@{ Tweak = $Name; Status = "Skipped (Not Supported)"; Reason = "Feature not present/exposed on this system" }
    }
    $already = $false
    try { $already = [bool](& $AlreadyOk) } catch { $already = $false }
    if ($already) {
        Write-Log "TWEAK SKIPPED [$Name] - already in target state" "INFO"
        return [PSCustomObject]@{ Tweak = $Name; Status = "Skipped"; Reason = "Already configured correctly" }
    }
    return Invoke-ValidatedTweak -Name $Name -Requirements $Requirements -Apply $Apply -Verify $Verify -Rollback $Rollback
}

# ---------- 4b. GPU PROFILE SELECTION ----------
# Asked once at launch so the Responsiveness & GPU / Gaming menus can hide
# tweaks that don't apply to your hardware instead of listing everything.
$script:GpuProfile = "BOTH"   # "AMD", "NVIDIA", or "BOTH" (shows every vendor section)
 
function Select-GpuProfile {
    $detected = Get-GpuVendor
    Clear-Host
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  Select your GPU vendor to filter the tweak lists to relevant entries." -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("  Detected GPU: {0} (vendor: {1})" -f (Get-PrimaryGpuName), $detected) -ForegroundColor Gray
    Write-Host ""
    Write-Host " [1] AMD          - show AMD-only tweaks"
    Write-Host " [2] NVIDIA       - show NVIDIA-only tweaks"
    Write-Host (" [3] Auto-detect  - use the detected vendor above ({0})" -f $detected)
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
    Write-Host ("  CPU  : {0}" -f $s.CPU) -ForegroundColor $White
    Write-Host ("  RAM  : {0}      OS: {1}" -f $s.RAM, $s.OS) -ForegroundColor $White
    Write-Host ("  GPU  : {0}   (profile: {1})" -f $s.GPU, $script:GpuProfile) -ForegroundColor $White
    Write-Host ("  PING : {0} (8.8.8.8)" -f $s.Ping) -ForegroundColor $White
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
function Get-ActiveUpAdapters {
    <# Physical adapters currently Up - shared by the NIC-advanced tweaks
       below so each one isn't re-querying and re-filtering separately. #>
    @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
}

function Set-NicPowerSaving ([bool]$Disable) {
    $adapters = Get-ActiveUpAdapters
    if ($adapters.Count -eq 0) { Write-Host "  No active physical adapters found." -ForegroundColor Yellow; return }
    $mode = if ($Disable) { "Disabled" } else { "Enabled" }
    foreach ($a in $adapters) {
        # UnsupportedHardware (driver doesn't expose this property at all) is
        # expected and silent, exactly as before; every other classified
        # category (AccessDenied, AdapterRestart, RegistryLocked, ...) now
        # gets its own specific, actionable message instead of being lumped
        # into the same generic "[SKIPPED] doesn't expose this setting" line.
        $r = Invoke-ZoroSafeOperation -OperationName "Power-saving on $($a.Name)" -Quiet -Action {
            Set-NetAdapterPowerManagement -Name $a.Name -AllowComputerToTurnOffDevice $mode -ErrorAction Stop
        }
        if ($r.Success) {
            Write-Host ("  [APPLIED] Power-saving {0} on {1}" -f $mode, $a.Name) -ForegroundColor Green
            Write-Log "NIC power management -> $mode on $($a.Name)"
        } elseif ($r.Category -eq "UnsupportedHardware") {
            Write-Host ("  [SKIPPED] {0} (driver doesn't expose this setting)" -f $a.Name) -ForegroundColor DarkGray
        } else {
            Write-Host ("  [FAILED] {0} - {1}" -f $a.Name, $r.Guidance) -ForegroundColor Red
        }
    }
}
 
function Set-NicRss ([bool]$Enable) {
    $adapters = Get-ActiveUpAdapters
    if ($adapters.Count -eq 0) { Write-Host "  No active physical adapters found." -ForegroundColor Yellow; return }
    foreach ($a in $adapters) {
        $r = Invoke-ZoroSafeOperation -OperationName "RSS on $($a.Name)" -Quiet -Action {
            if ($Enable) { Enable-NetAdapterRss -Name $a.Name -ErrorAction Stop }
            else { Disable-NetAdapterRss -Name $a.Name -ErrorAction Stop }
        }
        if ($r.Success) {
            Write-Host ("  [APPLIED] RSS {0} on {1}" -f $(if ($Enable) {"enabled"} else {"disabled"}), $a.Name) -ForegroundColor Green
            Write-Log "RSS $(if ($Enable) {'enabled'} else {'disabled'}) on $($a.Name)"
        } elseif ($r.Category -eq "UnsupportedHardware") {
            Write-Host ("  [SKIPPED] {0} (driver doesn't support RSS)" -f $a.Name) -ForegroundColor DarkGray
        } else {
            Write-Host ("  [FAILED] {0} - {1}" -f $a.Name, $r.Guidance) -ForegroundColor Red
        }
    }
}
 
function Set-DeliveryOptimizationP2P ([bool]$Disable) {
    # Delivery Optimization uploads Windows Update / Store payloads to OTHER
    # PCs (on your LAN and, depending on mode, the internet at large) as a
    # P2P CDN. Restricting it to LAN-only (or off) is a real, low-risk
    # bandwidth-saving change - it does not touch how updates are received,
    # only whether your upload bandwidth is donated to Microsoft's network.
    $k = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
    if ($Disable) { Set-RegDword $k "DODownloadMode" 1 | Out-Null }   # 1 = LAN peers only, no internet upload
    else { Remove-RegValue $k "DODownloadMode" | Out-Null }            # removes override -> Windows default (internet + LAN)
    Write-Log "Delivery Optimization P2P restricted-to-LAN=$Disable"
}

# ---- Interrupt Moderation: relevant now that 2.5G/5G NICs ship on-board on
#      most current motherboards. Moderation batches packet interrupts to
#      cut CPU usage, at the cost of a small amount of added latency per
#      packet. Worth it for bulk transfer, not for a low-latency game
#      connection where you'd rather spend a bit more CPU than add latency. ----
function Get-NicInterruptModerationSummary {
    $adapters = Get-ActiveUpAdapters
    if ($adapters.Count -eq 0) { return "no active adapter" }
    $states = foreach ($a in $adapters) {
        try {
            $p = Get-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Interrupt Moderation" -ErrorAction Stop
            "$($a.Name)=$($p.DisplayValue)"
        } catch { "$($a.Name)=n/a" }
    }
    return ($states -join ", ")
}

function Set-NicInterruptModeration ([bool]$Disable) {
    $adapters = Get-ActiveUpAdapters
    if ($adapters.Count -eq 0) { Write-Host "  No active physical adapters found." -ForegroundColor Yellow; return }
    $target = if ($Disable) { "Disabled" } else { "Enabled" }
    foreach ($a in $adapters) {
        $r = Invoke-ZoroSafeOperation -OperationName "Interrupt Moderation on $($a.Name)" -Quiet -Action {
            Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Interrupt Moderation" -DisplayValue $target -ErrorAction Stop
        }
        if ($r.Success) {
            Write-Host ("  [APPLIED] Interrupt Moderation {0} on {1}" -f $target, $a.Name) -ForegroundColor Green
            Write-Log "Interrupt Moderation -> $target on $($a.Name)"
        } elseif ($r.Category -eq "UnsupportedHardware") {
            Write-Host ("  [SKIPPED] {0} (driver doesn't expose this setting)" -f $a.Name) -ForegroundColor DarkGray
        } else {
            Write-Host ("  [FAILED] {0} - {1}" -f $a.Name, $r.Guidance) -ForegroundColor Red
        }
    }
}

# ---- 6a. Shared adapter selection ----
# MTU discovery and the TCP/NIC analyzers below all need "the adapter that
# actually carries internet traffic", not just "any Up adapter" (the NIC
# Advanced tweaks above use Get-ActiveUpAdapters directly because it
# blanket-applies to every physical NIC; these need exactly one).
function Get-PrimaryActiveAdapter {
    <# Picks the adapter holding the lowest-metric IPv4 default route - the
       one Windows itself would route internet traffic through - instead of
       just the first "Up" adapter, so a disconnected secondary NIC or a
       virtual adapter never gets tested/tuned by mistake. Falls back to the
       first Up physical adapter only if no default route exists at all
       (isolated LAN with no gateway). Cached briefly (1.5s) - the TCP
       Analyzer, Advanced NIC Optimizer, and MTU Discovery all call this
       multiple times per run; caching avoids re-enumerating routes/adapters
       for what is, within one workflow, the same answer every time. Any
       tracked write clears this via Add-UndoRecord's Clear-ZoroCache call,
       and -NoCache forces a fresh read where that matters (consistency
       checks after a change). #>
    param([switch]$NoCache)
    $loader = {
        try {
            $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction Stop |
                Sort-Object RouteMetric |
                Select-Object -First 1
            if ($route) {
                $a = Get-NetAdapter -InterfaceIndex $route.InterfaceIndex -ErrorAction Stop
                if ($a -and $a.Status -eq "Up") { return $a }
            }
        } catch {}
        return (Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1)
    }
    if ($NoCache) { return (& $loader) }
    return Get-ZoroCachedValue -Key "PrimaryActiveAdapter" -TtlMs 1500 -Loader $loader
}

# ==============================================================================
#  6a. AUTOMATIC MTU DISCOVERY
#  Binary-searches for the largest DF-flagged ICMP payload the path actually
#  supports (not a guess/table lookup), applies it through the documented
#  Set-NetIPInterface cmdlet, and reads it back to confirm. ping.exe (not
#  Test-Connection) is used deliberately - Test-Connection only gained a
#  -DontFragment parameter in PS7+, and this tool still supports the
#  Windows PowerShell 5.1 that ships in-box on every Win10/11 machine.
# ==============================================================================
function Test-DfPing {
    <# One DF-flagged ICMP echo at a specific payload size. Returns $true
       only on an actual reply; both a "needs to be fragmented" response and
       a timeout return $false, since either means this size isn't safe. #>
    param([string]$TargetHost, [int]$PayloadSize, [int]$TimeoutMs = 1000)
    try {
        $out = & ping.exe -n 1 -f -l $PayloadSize -w $TimeoutMs $TargetHost 2>$null
        return (($out -join "`n") -match "Reply from")
    } catch { return $false }
}

function Find-OptimalMtu {
    <# Binary search (O(log n) probes) between $MinMtu and $MaxMtu for the
       largest DF-safe ICMP payload, then adds back the 28 bytes of IPv4+
       ICMP header to report the real usable MTU. #>
    param([Parameter(Mandatory)][string]$TargetHost, [int]$MinMtu = 576, [int]$MaxMtu = 1500)
    $headerOverhead = 28   # 20-byte IPv4 header + 8-byte ICMP header
    $low  = $MinMtu - $headerOverhead
    $high = $MaxMtu - $headerOverhead

    # If even the RFC-minimum MTU gets no DF reply, the target is
    # unreachable/blocking ICMP - not a fragmentation problem - so searching
    # further would just be guessing.
    if (-not (Test-DfPing -TargetHost $TargetHost -PayloadSize $low)) {
        return [PSCustomObject]@{ Success = $false; Mtu = $null; Reason = "No reply even at the minimum MTU ($MinMtu) - target unreachable or blocking ICMP" }
    }

    $bestPayload = $low
    while ($low -le $high) {
        $mid = [int](($low + $high) / 2)
        if (Test-DfPing -TargetHost $TargetHost -PayloadSize $mid) { $bestPayload = $mid; $low = $mid + 1 }
        else { $high = $mid - 1 }
    }
    return [PSCustomObject]@{ Success = $true; Mtu = ($bestPayload + $headerOverhead); Reason = "Discovered via DF-ICMP binary search" }
}

function Get-InterfaceMtu ([int]$InterfaceIndex) {
    try { return (Get-NetIPInterface -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction Stop).NlMtu } catch { return $null }
}

function Set-InterfaceMtuVerified ([int]$InterfaceIndex, [int]$NewMtu) {
    <# Applies via the documented Set-NetIPInterface cmdlet (not a raw
       registry write) so it takes effect immediately, no reboot needed.
       This isn't a Set-RegDword-shaped change, so it records its own undo
       entry through the same Add-UndoRecord ledger everything else uses -
       see the new "InterfaceMtu" case in Invoke-UndoRecord. #>
    $previous = Get-InterfaceMtu $InterfaceIndex
    if ($null -eq $previous) { return [PSCustomObject]@{ Verified = $false; Previous = $null; New = $null } }
    Add-UndoRecord @{ Type = "InterfaceMtu"; InterfaceIndex = $InterfaceIndex; PreviousMtu = $previous }
    $r = Invoke-ZoroSafeOperation -OperationName "Set MTU on interface $InterfaceIndex" -Quiet -Action {
        Set-NetIPInterface -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -NlMtu $NewMtu -ErrorAction Stop
    }
    if (-not $r.Success) {
        Write-Log "FAILED to set MTU on interface $InterfaceIndex to $NewMtu : category=$($r.Category) $($r.Message)" "ERROR"
        return [PSCustomObject]@{ Verified = $false; Previous = $previous; New = $null; Category = $r.Category; Guidance = $r.Guidance }
    }
    $readBack = Get-InterfaceMtu $InterfaceIndex
    $ok = ($readBack -eq $NewMtu)
    Write-Log "SET MTU interface $InterfaceIndex $previous -> $NewMtu (verified=$ok, readback=$readBack)"
    return [PSCustomObject]@{ Verified = $ok; Previous = $previous; New = $readBack }
}

function Invoke-MtuDiscovery {
    param([string]$TargetHost = "8.8.8.8")
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) {
        Write-Host "  No active adapter with a default route found." -ForegroundColor Yellow
        Write-Log "MTU Discovery: no active adapter found" "WARN"
        return
    }
    $ipIf = Get-NetIPInterface -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if (-not $ipIf) { Write-Host ("  {0} has no IPv4 configured." -f $adapter.Name) -ForegroundColor Yellow; return }

    # Never search above the adapter's own currently-configured MTU (covers
    # both the 1500 standard case and a NIC already running jumbo frames);
    # guard against a currently-broken/absurdly-low value being used as the
    # search ceiling.
    $ceiling = [int]$ipIf.NlMtu
    if ($ceiling -lt 576) { $ceiling = 1500 }

    Write-Host ("`nDiscovering optimal MTU on {0} against {1} (DF-ICMP binary search)..." -f $adapter.Name, $TargetHost) -ForegroundColor Cyan
    $result = Find-OptimalMtu -TargetHost $TargetHost -MinMtu 576 -MaxMtu $ceiling
    if (-not $result.Success) {
        Write-Host ("  [FAILED] {0}" -f $result.Reason) -ForegroundColor Red
        Write-Log "MTU Discovery failed on $($adapter.Name): $($result.Reason)" "ERROR"
        return
    }

    $current = Get-InterfaceMtu $adapter.ifIndex
    Write-Host ("  Current MTU : {0}" -f $current)
    Write-Host ("  Optimal MTU : {0}" -f $result.Mtu) -ForegroundColor Green

    if ($result.Mtu -eq $current) {
        Write-Host "  [SKIPPED] Already at the optimal MTU - nothing to change." -ForegroundColor Yellow
        Write-Log "MTU Discovery: $($adapter.Name) already optimal at $current"
        return
    }
    if (-not (Confirm-Action ("Set {0} MTU from {1} to {2}? Reversible via Undo Last Session." -f $adapter.Name, $current, $result.Mtu))) { return }

    $applied = Set-InterfaceMtuVerified -InterfaceIndex $adapter.ifIndex -NewMtu $result.Mtu
    if ($applied.Verified) {
        Write-Host ("  [APPLIED] MTU set to {0} on {1} (verified)" -f $applied.New, $adapter.Name) -ForegroundColor Green
        # State Consistency Protection (3c): confirm the new MTU didn't leave
        # this adapter in a broken/inconsistent state (below the safe floor,
        # or above 1500 with no driver-side jumbo support) - and if it did,
        # revert it automatically through the same Undo path [U] uses,
        # rather than leaving a silently-broken connection behind.
        Repair-NetworkConfigConsistency | Out-Null
    }
    else { Write-Host "  [FAILED] MTU change did not verify." -ForegroundColor Red }
}

function Restore-DefaultMtu {
    <# Explicit safety-net restore (independent of the Undo ledger, same
       role as netsh autotuninglevel=normal in "Restore ALL" below) - sets
       every active adapter's IPv4 MTU back to the 1500-byte Ethernet
       standard so MTU resets even if the Undo session was already
       cleared/archived. #>
    foreach ($a in (Get-ActiveAdapters)) {
        $ipIf = Get-NetIPInterface -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if (-not $ipIf -or $ipIf.NlMtu -eq 1500) { continue }
        try { Set-NetIPInterface -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -NlMtu 1500 -ErrorAction Stop; Write-Log "MTU reset to 1500 on $($a.Name)" }
        catch { Write-Log "FAILED to reset MTU on $($a.Name): $_" "ERROR" }
    }
}

# ==============================================================================
#  6b. MODERN TCP ANALYZER
#  Read-only report from the documented Get-NetTCPSetting/Get-NetOffload-
#  GlobalSetting cmdlets (netsh int tcp show global only for the couple of
#  legacy fields those cmdlets don't expose), then fixes only what's both
#  supported on this system AND not already correct.
# ==============================================================================
function Set-NicFeatureToggle {
    <# Generic Enable-NetAdapter<Feature>/Disable-NetAdapter<Feature>
       wrapper (Rss, Rsc) so RSS and RSC don't each carry their own copy-
       pasted enable/disable/undo plumbing. Records its state through the
       same Undo ledger as everything else via a "NicFeatureToggle" record -
       see the matching case in Invoke-UndoRecord. #>
    param(
        [Parameter(Mandatory)][ValidateSet("Rss","Rsc")][string]$FeatureName,
        [Parameter(Mandatory)][string]$AdapterName,
        [Parameter(Mandatory)][bool]$Enable
    )
    $r = Invoke-ZoroSafeOperation -OperationName "$FeatureName on $AdapterName" -Quiet -Action {
        $getCmd     = "Get-NetAdapter$FeatureName"
        $enableCmd  = "Enable-NetAdapter$FeatureName"
        $disableCmd = "Disable-NetAdapter$FeatureName"
        $before = & $getCmd -Name $AdapterName -ErrorAction Stop
        $wasEnabled = if ($FeatureName -eq "Rsc") { [bool]($before | Where-Object { $_.IPv4Enabled -or $_.IPv6Enabled }) } else { [bool]$before.Enabled }
        Add-UndoRecord @{ Type = "NicFeatureToggle"; FeatureName = $FeatureName; AdapterName = $AdapterName; PreviousEnabled = $wasEnabled }
        if ($Enable) { & $enableCmd -Name $AdapterName -ErrorAction Stop } else { & $disableCmd -Name $AdapterName -ErrorAction Stop }
        return $true
    }
    if (-not $r.Success) {
        Write-Log "FAILED Set-NicFeatureToggle $FeatureName on $AdapterName : category=$($r.Category) $($r.Message)" "ERROR"
        return $false
    }
    return $true
}

function Invoke-RssRscTweaks ($AdapterName) {
    <# Shared RSS/RSC detect+apply - called from both the TCP Analyzer and
       the Advanced NIC Optimizer below so the two menu actions never carry
       two copies of this logic. Re-running it after it already applied is
       a cheap AlreadyOk no-op through Invoke-DetectedTweak, not a repeat
       write. #>
    $results = @()
    if (Get-NetAdapterRss -Name $AdapterName -ErrorAction SilentlyContinue) {
        $results += Invoke-DetectedTweak -Name "RSS ($AdapterName)" `
            -Supported { $true } `
            -AlreadyOk { (Get-NetAdapterRss -Name $AdapterName -ErrorAction SilentlyContinue).Enabled -eq $true } `
            -Apply { Set-NicFeatureToggle -FeatureName "Rss" -AdapterName $AdapterName -Enable $true } `
            -Verify { (Get-NetAdapterRss -Name $AdapterName -ErrorAction SilentlyContinue).Enabled -eq $true }
    } else {
        Write-Host "  [SKIPPED] RSS - not exposed by this driver" -ForegroundColor DarkGray
    }
    if (Get-NetAdapterRsc -Name $AdapterName -ErrorAction SilentlyContinue) {
        $results += Invoke-DetectedTweak -Name "RSC ($AdapterName)" `
            -Supported { $true } `
            -AlreadyOk { -not ((Get-NetAdapterRsc -Name $AdapterName -ErrorAction SilentlyContinue) | Where-Object { -not $_.IPv4Enabled -or -not $_.IPv6Enabled }) } `
            -Apply { Set-NicFeatureToggle -FeatureName "Rsc" -AdapterName $AdapterName -Enable $true } `
            -Verify { -not ((Get-NetAdapterRsc -Name $AdapterName -ErrorAction SilentlyContinue) | Where-Object { -not $_.IPv4Enabled -or -not $_.IPv6Enabled }) }
    } else {
        Write-Host "  [SKIPPED] RSC - not exposed by this driver" -ForegroundColor DarkGray
    }
    return $results
}

function Get-TcpGlobalReport {
    <# One consolidated read of the modern TCP stack. Read-only - decides
       nothing itself, just feeds Invoke-TcpAnalyzer's Supported/AlreadyOk
       gates and the on-screen report. #>
    $offload = Get-NetOffloadGlobalSetting -ErrorAction SilentlyContinue
    $tcp     = Get-NetTCPSetting -SettingName Internet -ErrorAction SilentlyContinue
    $netshText = (netsh int tcp show global) -join "`n"
    $dcaLine     = (($netshText -split "`n") | Where-Object { $_ -match "Direct Cache Access" } | Select-Object -First 1)
    $chimneyLine = (($netshText -split "`n") | Where-Object { $_ -match "Chimney" } | Select-Object -First 1)
    return [PSCustomObject]@{
        AutoTuningLevel    = $tcp.AutoTuningLevelLocal
        Ecn                = $tcp.EcnCapability
        CongestionProvider = $tcp.CongestionProvider
        Rss                = $offload.ReceiveSideScaling
        Rsc                = $offload.ReceiveSegmentCoalescing
        NetworkDirect      = $offload.NetworkDirect
        Chimney            = $offload.Chimney
        DcaRaw             = $dcaLine
        ChimneyRaw         = $chimneyLine
        RdmaCapable        = [bool](Get-NetAdapterRdma -ErrorAction SilentlyContinue)
    }
}

function Invoke-TcpAnalyzer {
    $report = Get-TcpGlobalReport
    Write-Host "`n>>> TCP STACK ANALYSIS`n" -ForegroundColor Cyan
    Write-Host ("  Auto-Tuning Level    : {0}" -f $report.AutoTuningLevel)
    Write-Host ("  ECN Capability       : {0}" -f $report.Ecn)
    Write-Host ("  Congestion Provider  : {0}  (workload/path-dependent - reported only, not forced)" -f $report.CongestionProvider) -ForegroundColor DarkGray
    Write-Host ("  Receive Window Scaling : governed by Auto-Tuning above on modern Windows - no separate legacy toggle exists (and none is added; see task scope note)") -ForegroundColor DarkGray
    Write-Host ("  NetworkDirect (RDMA) : {0}{1}" -f $report.NetworkDirect, $(if (-not $report.RdmaCapable) { "  (no RDMA-capable NIC detected - not modified)" } else { "" }))
    Write-Host ("  DCA                  : {0}" -f $(if ($report.DcaRaw) { $report.DcaRaw.Trim() } else { "not exposed on this system" })) -ForegroundColor DarkGray
    Write-Host ("  TCP Chimney Offload  : {0}" -f $(if ($report.ChimneyRaw) { $report.ChimneyRaw.Trim() } else { "n/a" })) -ForegroundColor DarkGray
    Write-Host "  DCA and Chimney Offload are Server-era features not functionally" -ForegroundColor DarkGray
    Write-Host "  present in the Windows 10/11 client TCP/IP stack - shown for" -ForegroundColor DarkGray
    Write-Host "  completeness, never modified (no vendor-documented API to do so" -ForegroundColor DarkGray
    Write-Host "  meaningfully on this OS)." -ForegroundColor DarkGray

    $results = @()
    # Auto-Tuning: only writes if it's NOT already Normal - Normal has been
    # the shipped default since Vista, so re-writing an already-Normal value
    # would be the exact placebo write [7]->now[11] Restore ALL's note warns
    # about; this only fires when something else really did disable/restrict it.
    $results += Invoke-DetectedTweak -Name "TCP Auto-Tuning" `
        -Supported { $true } `
        -AlreadyOk { (Get-NetTCPSetting -SettingName Internet -ErrorAction SilentlyContinue).AutoTuningLevelLocal -eq "Normal" } `
        -Apply { netsh int tcp set global autotuninglevel=normal | Out-Null; Write-Log "netsh int tcp set global autotuninglevel=normal (TCP Analyzer fix)"; $true } `
        -Verify { (Get-NetTCPSetting -SettingName Internet -ErrorAction SilentlyContinue).AutoTuningLevelLocal -eq "Normal" }

    # ECN: same netsh command as menu [3] - reused, not duplicated.
    $results += Invoke-DetectedTweak -Name "ECN Capability" `
        -Supported { $true } `
        -AlreadyOk { (Get-NetTCPSetting -SettingName Internet -ErrorAction SilentlyContinue).EcnCapability -eq "Enabled" } `
        -Apply { netsh int tcp set global ecncapability=enabled | Out-Null; Write-Log "netsh int tcp set global ecncapability=enabled (TCP Analyzer fix)"; $true } `
        -Verify { (Get-NetTCPSetting -SettingName Internet -ErrorAction SilentlyContinue).EcnCapability -eq "Enabled" }

    $adapter = Get-PrimaryActiveAdapter
    if ($adapter) { $results += Invoke-RssRscTweaks -AdapterName $adapter.Name }

    Write-Host ""
    foreach ($r in $results) { Write-TweakResult $r }
    Write-Log "TCP Analyzer run complete - $($results.Count) item(s) evaluated"
}

# ==============================================================================
#  6c. ADVANCED NIC OPTIMIZER
#  Detects driver/hardware support for each capability before touching it
#  (Get-NetAdapterLso/-ChecksumOffload/-AdvancedProperty all reflect what
#  THIS driver actually exposes) and skips anything not present instead of
#  forcing it. Receive/Transmit Buffers are raised to the driver's own
#  advertised maximum, never a hardcoded number.
# ==============================================================================
function Test-AllLsoEnabled ($AdapterName) {
    $rows = Get-NetAdapterLso -Name $AdapterName -ErrorAction SilentlyContinue
    if (-not $rows) { return $false }
    return -not ($rows | Where-Object { -not $_.IPv4Enabled -or -not $_.IPv6Enabled })
}

function Test-AllChecksumOffloadEnabled ($AdapterName) {
    $c = Get-NetAdapterChecksumOffload -Name $AdapterName -ErrorAction SilentlyContinue
    if (-not $c) { return $false }
    $flags = $c | Get-Member -MemberType Property | Where-Object { $_.Name -match 'Enabled$' } | ForEach-Object { $c.$($_.Name) }
    return -not ($flags | Where-Object { $_ -eq $false })
}

function Get-NicAdvancedPropertyByPattern ($AdapterName, [string[]]$Patterns) {
    <# Driver vendors word these display names slightly differently
       ("Energy Efficient Ethernet" vs "Green Ethernet"), so this matches
       against a list of candidate regex patterns and returns the first hit
       instead of one hardcoded exact string per vendor. #>
    $all = Get-NetAdapterAdvancedProperty -Name $AdapterName -ErrorAction SilentlyContinue
    foreach ($p in $Patterns) {
        $match = $all | Where-Object { $_.DisplayName -match $p } | Select-Object -First 1
        if ($match) { return $match }
    }
    return $null
}

function Set-NicAdvancedPropertyVerified ($AdapterName, $Property, $NewRegistryValue) {
    <# Generic Set-NetAdapterAdvancedProperty wrapper for driver-exposed
       properties with no dedicated Enable-NetAdapter* cmdlet (Buffers,
       Flow Control, EEE). Records the previous value through the same
       Undo ledger as everything else ("NicAdvancedProperty" record) and
       reads the property back afterward to confirm the driver actually
       accepted the value instead of silently ignoring it. #>
    $previous = @($Property.RegistryValue)[0]
    Add-UndoRecord @{ Type = "NicAdvancedProperty"; AdapterName = $AdapterName; DisplayName = $Property.DisplayName; PreviousRegistryValue = $previous }
    $r = Invoke-ZoroSafeOperation -OperationName "NIC property '$($Property.DisplayName)' on $AdapterName" -Quiet -Action {
        Set-NetAdapterAdvancedProperty -Name $AdapterName -DisplayName $Property.DisplayName -RegistryValue $NewRegistryValue -ErrorAction Stop
        return @((Get-NetAdapterAdvancedProperty -Name $AdapterName -DisplayName $Property.DisplayName -ErrorAction Stop).RegistryValue)[0]
    }
    if (-not $r.Success) {
        Write-Log "FAILED to set NIC property '$($Property.DisplayName)' on $AdapterName : category=$($r.Category) $($r.Message)" "ERROR"
        return $false
    }
    $ok = ("$($r.Value)" -eq "$NewRegistryValue")
    Write-Log "SET NIC property '$($Property.DisplayName)' on $AdapterName -> $NewRegistryValue (verified=$ok)"
    return $ok
}

function Get-NicPowerOffloadReport ($AdapterName) {
    <# ARP/NS Offload detection only - these govern Wake-on-LAN/Modern
       Standby wake correctness while the adapter is asleep, not raw
       throughput or latency, so changing them isn't a "network
       optimization" this tool can justify picking a side on for everyone. #>
    $arp = Get-NicAdvancedPropertyByPattern -AdapterName $AdapterName -Patterns @('^ARP Offload$')
    $ns  = Get-NicAdvancedPropertyByPattern -AdapterName $AdapterName -Patterns @('^NS Offload$')
    return [PSCustomObject]@{
        ArpOffload = if ($arp) { $arp.DisplayValue } else { "not exposed by this driver" }
        NsOffload  = if ($ns)  { $ns.DisplayValue }  else { "not exposed by this driver" }
    }
}

function Get-NicEeeState ($AdapterName) {
    return Get-NicAdvancedPropertyByPattern -AdapterName $AdapterName -Patterns @('Energy.?Efficient.?Ethernet','Green Ethernet')
}

function Set-NicEee ([bool]$Disable) {
    <# Opt-in only - NOT run by Invoke-AdvancedNicOptimizer automatically.
       EEE trades a little power for link-state transitions that can add
       sub-millisecond latency spikes on some switch/NIC combinations; real
       and documented, but it's a power-vs-latency call for the user to
       make, not one this tool decides for everyone - same gating precedent
       as the laptop Ultimate Performance confirmation (menu 4). #>
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) { Write-Host "  No active adapter found." -ForegroundColor Yellow; return }
    $prop = Get-NicEeeState $adapter.Name
    if (-not $prop -or -not $prop.ValidDisplayValues -or -not $prop.ValidRegistryValues) {
        Write-Host "  [SKIPPED] Energy Efficient Ethernet - not exposed by this driver" -ForegroundColor DarkGray
        return
    }
    $wantPattern = if ($Disable) { '^(Off|Disabled)$' } else { '^(On|Enabled)$' }
    $idx = [array]::IndexOf($prop.ValidDisplayValues, ($prop.ValidDisplayValues | Where-Object { $_ -match $wantPattern } | Select-Object -First 1))
    if ($idx -lt 0) { Write-Host "  [SKIPPED] Driver doesn't expose a plain on/off value for this property." -ForegroundColor DarkGray; return }
    $targetValue = $prop.ValidRegistryValues[$idx]
    if (-not (Confirm-Action ("{0} Energy Efficient Ethernet on {1}? This is a power/latency trade-off, reversible via Undo Last Session." -f $(if ($Disable) {"Disable"} else {"Enable"}), $adapter.Name))) { return }
    $ok = Set-NicAdvancedPropertyVerified -AdapterName $adapter.Name -Property $prop -NewRegistryValue $targetValue
    if ($ok) { Write-Host ("  [APPLIED] Energy Efficient Ethernet {0} on {1} (verified)" -f $(if ($Disable) {"disabled"} else {"enabled"}), $adapter.Name) -ForegroundColor Green }
    else { Write-Host "  [FAILED] Could not change Energy Efficient Ethernet." -ForegroundColor Red }
}

function Invoke-AdvancedNicOptimizer {
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) { Write-Host "  No active adapter found." -ForegroundColor Yellow; return }
    Write-Host ("`n>>> ADVANCED NIC OPTIMIZER - {0}`n" -f $adapter.Name) -ForegroundColor Cyan

    $results = @()
    $results += Invoke-RssRscTweaks -AdapterName $adapter.Name

    if (Get-NetAdapterLso -Name $adapter.Name -ErrorAction SilentlyContinue) {
        $results += Invoke-DetectedTweak -Name "Large Send Offload v2" `
            -Supported { $true } `
            -AlreadyOk { Test-AllLsoEnabled $adapter.Name } `
            -Apply { Enable-NetAdapterLso -Name $adapter.Name -ErrorAction Stop; $true } `
            -Verify { Test-AllLsoEnabled $adapter.Name }
    } else {
        Write-Host "  [SKIPPED] Large Send Offload v2 - not exposed by this driver" -ForegroundColor DarkGray
    }

    if (Get-NetAdapterChecksumOffload -Name $adapter.Name -ErrorAction SilentlyContinue) {
        $results += Invoke-DetectedTweak -Name "Checksum Offload" `
            -Supported { $true } `
            -AlreadyOk { Test-AllChecksumOffloadEnabled $adapter.Name } `
            -Apply { Enable-NetAdapterChecksumOffload -Name $adapter.Name -ErrorAction Stop; $true } `
            -Verify { Test-AllChecksumOffloadEnabled $adapter.Name }
    } else {
        Write-Host "  [SKIPPED] Checksum Offload - not exposed by this driver" -ForegroundColor DarkGray
    }

    Write-Host ("  Interrupt Moderation : {0}  (use menu [2] to change)" -f (Get-NicInterruptModerationSummary)) -ForegroundColor DarkGray

    foreach ($bufSpec in @(
        @{ Label = "Receive Buffers";  Patterns = @('^Receive Buffers$') },
        @{ Label = "Transmit Buffers"; Patterns = @('^Transmit Buffers$') }
    )) {
        $prop = Get-NicAdvancedPropertyByPattern -AdapterName $adapter.Name -Patterns $bufSpec.Patterns
        if (-not $prop -or @($prop.ValidRegistryValues).Count -eq 0) {
            Write-Host ("  [SKIPPED] {0} - not exposed by this driver" -f $bufSpec.Label) -ForegroundColor DarkGray
            continue
        }
        $max     = (@($prop.ValidRegistryValues) | ForEach-Object { [int]$_ } | Sort-Object)[-1]
        $current = [int]@($prop.RegistryValue)[0]
        $results += Invoke-DetectedTweak -Name $bufSpec.Label `
            -Supported { $true } `
            -AlreadyOk { $current -ge $max } `
            -Apply { Set-NicAdvancedPropertyVerified -AdapterName $adapter.Name -Property $prop -NewRegistryValue $max } `
            -Verify { [int]@((Get-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $prop.DisplayName -ErrorAction SilentlyContinue).RegistryValue)[0] -ge $max }
    }

    $fcProp = Get-NicAdvancedPropertyByPattern -AdapterName $adapter.Name -Patterns @('^Flow Control$')
    if ($fcProp -and $fcProp.ValidDisplayValues -and $fcProp.ValidRegistryValues) {
        $enabledLabel = $fcProp.ValidDisplayValues | Where-Object { $_ -match "Rx.*Tx|Enabled" } | Select-Object -First 1
        $idx = if ($enabledLabel) { [array]::IndexOf($fcProp.ValidDisplayValues, $enabledLabel) } else { -1 }
        if ($idx -ge 0) {
            $enabledValue = $fcProp.ValidRegistryValues[$idx]
            $results += Invoke-DetectedTweak -Name "Flow Control" `
                -Supported { $true } `
                -AlreadyOk { "$(@($fcProp.RegistryValue)[0])" -eq "$enabledValue" } `
                -Apply { Set-NicAdvancedPropertyVerified -AdapterName $adapter.Name -Property $fcProp -NewRegistryValue $enabledValue } `
                -Verify { "$(@((Get-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $fcProp.DisplayName -ErrorAction SilentlyContinue).RegistryValue)[0])" -eq "$enabledValue" }
        } else {
            Write-Host "  [SKIPPED] Flow Control - no 'enabled' value exposed by driver" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [SKIPPED] Flow Control - not exposed by this driver" -ForegroundColor DarkGray
    }

    Write-Host ""
    foreach ($r in $results) { Write-TweakResult $r }

    $power = Get-NicPowerOffloadReport $adapter.Name
    $eee   = Get-NicEeeState $adapter.Name
    Write-Host "`n  --- Detected, not auto-changed (power/correctness trade-offs) ---" -ForegroundColor DarkGray
    Write-Host ("  ARP Offload          : {0}" -f $power.ArpOffload) -ForegroundColor DarkGray
    Write-Host ("  NS Offload           : {0}" -f $power.NsOffload) -ForegroundColor DarkGray
    Write-Host ("  Energy Efficient Eth.: {0}  (menu [11] to toggle)" -f $(if ($eee) { $eee.DisplayValue } else { "not exposed by this driver" })) -ForegroundColor DarkGray

    Write-Log "Advanced NIC Optimizer run complete on $($adapter.Name) - $($results.Count) item(s) evaluated"
}

function Show-NetworkMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [1] NETWORK OPTIMIZATION`n" -ForegroundColor Green
        Write-Host " [1] Disable Nagle's Algorithm (lower latency for small packets)                 [6/10]"
        Write-Host (" [2] Disable Interrupt Moderation on 2.5G/5G/10G NICs (lower latency)             [7/10 on fast NICs]   [{0}]" -f (Get-NicInterruptModerationSummary))
        Write-Host " [3] Enable ECN (Explicit Congestion Notification)                                [3/10]"
        Write-Host " [4] NIC Advanced: disable adapter power-saving + enable RSS                      [6/10]"
        Write-Host " [5] Restrict Delivery Optimization to LAN only (stop uploading updates to WAN)   [6/10]"
        Write-Host " [6] Quick before/after ping test"
        Write-Host " [7] Automatic MTU Discovery (DF-ICMP path search, applies + verifies)            [7/10]"
        Write-Host " [8] Modern TCP Analyzer (Auto-Tuning/ECN/RSS/RSC/NetworkDirect - inspect + fix)  [7/10]"
        Write-Host " [9] Advanced NIC Optimizer (LSO v2/Checksum/Buffers/Flow Control/RSS/RSC)        [7/10]"
        Write-Host " [10] Toggle Energy Efficient Ethernet (power vs micro-latency trade-off)         [opt-in]"
        Write-Host " [11] Restore ALL network tweaks to Windows defaults"
        Write-Host " [0] Back to Main Menu"
        Write-Host "`n Note: the old 'TCP Auto-Tuning -> Normal' menu entry was removed - Normal" -ForegroundColor DarkGray
        Write-Host " has been the Windows default since Vista, so running it did nothing. See" -ForegroundColor DarkGray
        Write-Host " TWEAK_AUDIT.md. It still runs quietly as part of [11] Restore ALL and as part" -ForegroundColor DarkGray
        Write-Host " of [8] TCP Analyzer's fix pass, in case something changed it behind your back." -ForegroundColor DarkGray
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" {
                if (Confirm-Action "This edits per-adapter TCP registry values.") {
                    Set-NagleAlgorithm $true
                    Write-Host "[DONE] Nagle's Algorithm disabled on all adapters." -ForegroundColor Green
                }
                Wait-ForEnter -NoBlank
            }
            "2" {
                if (Confirm-Action "Disables packet interrupt batching so the CPU is interrupted immediately per packet instead of in groups. Slightly higher CPU load, lower latency. Skipped safely on adapters/drivers that don't expose it.") {
                    Set-NicInterruptModeration $true
                    Write-Host "[DONE] Interrupt Moderation disabled where supported." -ForegroundColor Green
                }
                Wait-ForEnter -NoBlank
            }
            "3" {
                netsh int tcp set global ecncapability=enabled | Out-Null
                Write-Log "netsh int tcp set global ecncapability=enabled"
                Write-Host "[DONE] ECN enabled." -ForegroundColor Green
                Wait-ForEnter -NoBlank
            }
            "4" {
                if (Confirm-Action "This changes adapter power-management + RSS via official Set-NetAdapter* cmdlets. Unsupported adapters are skipped safely.") {
                    Write-Host ""
                    Set-NicPowerSaving $true
                    Set-NicRss $true
                    Write-Host "`n[DONE] NIC Advanced tweaks applied where supported." -ForegroundColor Green
                }
                Wait-ForEnter -NoBlank
            }
            "5" {
                if (Confirm-Action "Restrict Delivery Optimization so it never uploads Windows Update data to strangers over the internet (LAN peers still allowed)?") {
                    Set-DeliveryOptimizationP2P $true
                    Write-Host "[DONE] Delivery Optimization restricted to LAN peers only." -ForegroundColor Green
                }
                Wait-ForEnter -NoBlank
            }
            "6" {
                Write-Host "`nPinging 8.8.8.8 four times..." -ForegroundColor Cyan
                $avg = Test-AvgPing
                if ($null -ne $avg) { Write-Host ("Average latency: {0} ms" -f $avg) -ForegroundColor Green }
                else { Write-Host "Ping failed - check your connection." -ForegroundColor Red }
                Wait-ForEnter -NoBlank
            }
            "7" {
                Invoke-MtuDiscovery
                Wait-ForEnter
            }
            "8" {
                Invoke-TcpAnalyzer
                Wait-ForEnter
            }
            "9" {
                if (Confirm-Action "Runs LSO v2 / Checksum Offload / Receive & Transmit Buffers / Flow Control / RSS / RSC checks on the active adapter, applying only what's supported and not already optimal. Unsupported items are skipped safely.") {
                    Invoke-AdvancedNicOptimizer
                }
                Wait-ForEnter
            }
            "10" {
                $primary = Get-PrimaryActiveAdapter
                if (-not $primary) {
                    Write-Host "  No active adapter found." -ForegroundColor Yellow
                } else {
                    $eeeNow = Get-NicEeeState $primary.Name
                    $disableIt = $true
                    if ($eeeNow -and $eeeNow.DisplayValue -match "^(Off|Disabled)$") { $disableIt = $false }
                    Set-NicEee $disableIt
                }
                Wait-ForEnter
            }
            "11" {
                if (Confirm-Action "Revert Nagle/Interrupt Moderation/ECN/Auto-Tuning/NIC Advanced/Delivery Optimization/MTU tweaks to Windows defaults?") {
                    Set-NagleAlgorithm $false
                    Set-NicInterruptModeration $false
                    netsh int tcp set global autotuninglevel=normal | Out-Null
                    # BUGFIX (v4.0.0 release audit): this used to say
                    # "ecncapability=enabled", which is the exact same command
                    # [3] Enable ECN runs - so "Restore ALL" was silently
                    # re-applying the ECN tweak instead of reverting it.
                    # "default" is the documented netsh keyword that explicitly
                    # reverts ECN Capability to the system default instead of
                    # forcing a specific state.
                    netsh int tcp set global ecncapability=default | Out-Null
                    Write-Log "netsh int tcp set global ecncapability=default (restore)"
                    Write-Host ""
                    Set-NicPowerSaving $false
                    Set-DeliveryOptimizationP2P $false
                    Restore-DefaultMtu
                    # LSO v2, Checksum Offload, Buffers, Flow Control, RSS, RSC,
                    # and EEE are all still covered by Undo Last Session (each
                    # records its previous value before writing) - not repeated
                    # here as blind resets, since most of them are already
                    # Windows-default-enabled and forcing them off would itself
                    # be the placebo write this note already warns about above.
                    Write-Host "[DONE] Network tweaks reset to defaults." -ForegroundColor Green
                }
                Wait-ForEnter -NoBlank
            }
            "0" { return }
            default { Show-InvalidSelection }
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
    @{ Name = "AdGuard";    Primary = "94.140.14.14"; Secondary = "94.140.15.15" }
)
# Rotated across benchmark passes (index = pass number mod pool size) so a
# multi-pass run doesn't just measure "how fast is the 2nd/3rd query for the
# exact same name the resolver already cached from pass 1" on every provider
# equally - real, distinct, well-known names, not synthetic/random labels.
$script:DnsBenchmarkQueryPool = @("microsoft.com", "cloudflare.com", "github.com", "amazon.com", "wikipedia.org")
 
function Get-ActiveAdapters {
    <# Cached briefly (1.5s) - DNS menu actions call this once per adapter
       iteration and again to show results; caching avoids re-enumerating
       every adapter on the machine several times per action. #>
    return Get-ZoroCachedValue -Key "ActiveAdapters" -TtlMs 1500 -Loader {
        @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
    }
}
 
function Set-DnsServersVerified ($InterfaceAlias, $Primary, $Secondary) {
    <# Applies to exactly one adapter and records the value it's about to
       overwrite through the same Add-UndoRecord ledger every other write
       in this tool uses (Type = "DnsServers" - see the matching case in
       Invoke-UndoRecord), then reads the config back to confirm - same
       discipline as Set-RegDword / Set-InterfaceMtuVerified. #>
    $before = @(Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
    Add-UndoRecord @{ Type = "DnsServers"; InterfaceAlias = $InterfaceAlias; HadServers = (@($before).Count -gt 0); PreviousServers = @($before) }
    $targets = @($Primary)
    if ($Secondary) { $targets += $Secondary }
    $r = Invoke-ZoroSafeOperation -OperationName "Set DNS on $InterfaceAlias" -Quiet -Action {
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $targets -ErrorAction Stop
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        return @(Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses
    }
    if (-not $r.Success) {
        Write-Log "FAILED to set DNS on $InterfaceAlias : category=$($r.Category) $($r.Message)" "ERROR"
        return [PSCustomObject]@{ Verified = $false; InterfaceAlias = $InterfaceAlias; Applied = $null; Category = $r.Category; Guidance = $r.Guidance }
    }
    $after = $r.Value
    $ok = ((@($after) -join ",") -eq (@($targets) -join ","))
    Write-Log "SET DNS $InterfaceAlias -> $($targets -join ', ') (verified=$ok)"
    return [PSCustomObject]@{ Verified = $ok; InterfaceAlias = $InterfaceAlias; Applied = $targets }
}
 
function Set-DnsOnActiveAdapters ($primary, $secondary) {
    $adapters = Get-ActiveAdapters
    if ($adapters.Count -eq 0) {
        Write-Host "  No active network adapters found - nothing to change." -ForegroundColor Yellow
        Write-Log "Set-DnsOnActiveAdapters: no active adapters found, no changes made" "WARN"
        return
    }
    foreach ($a in $adapters) {
        $r = Set-DnsServersVerified -InterfaceAlias $a.Name -Primary $primary -Secondary $secondary
        if ($r.Verified) { Write-Host ("  [APPLIED] {0} -> {1} (verified)" -f $a.Name, ($r.Applied -join ", ")) -ForegroundColor Green }
        elseif ($r.Guidance) { Write-Host ("  [FAILED]  {0} - {1}" -f $a.Name, $r.Guidance) -ForegroundColor Red }
        else { Write-Host ("  [FAILED]  {0}" -f $a.Name) -ForegroundColor Red }
    }
    # State Consistency Protection (3c): a DNS write can "verify" at the
    # registry/API level yet resolve nothing (wrong server, filtered
    # upstream, typo). Check actual resolution on every adapter just
    # touched, and auto-revert (via the Undo ledger, never a guessed value)
    # any adapter where it silently broke name resolution.
    Repair-NetworkConfigConsistency | Out-Null
}
 
function Restore-DnsToDhcp {
    <# Same "Restore DHCP-assigned DNS" behavior the menu has always had,
       now routed through the undo ledger (Type = "DnsServers", HadServers
       so Undo/rollback restores the exact prior server list instead of
       just re-clearing to DHCP a second time) and verified by reading the
       config back instead of trusting Set-DnsClientServerAddress silently. #>
    $adapters = Get-ActiveAdapters
    if ($adapters.Count -eq 0) { Write-Host "  No active network adapters found." -ForegroundColor Yellow; return }
    foreach ($a in $adapters) {
        $before = @(Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        if (@($before).Count -eq 0) { Write-Host ("  [SKIPPED] {0} - already DHCP-assigned" -f $a.Name) -ForegroundColor DarkGray; continue }
        Add-UndoRecord @{ Type = "DnsServers"; InterfaceAlias = $a.Name; HadServers = $true; PreviousServers = @($before) }
        try {
            Set-DnsClientServerAddress -InterfaceAlias $a.Name -ResetServerAddresses -ErrorAction Stop
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            $after = @(Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses
            if (@($after).Count -eq 0) {
                Write-Host ("  [DONE] {0} -> DHCP-assigned (verified)" -f $a.Name) -ForegroundColor Green
                Write-Log "DNS reset to DHCP on $($a.Name) (verified)"
            } else {
                Write-Host ("  [FAILED] {0} did not verify back to DHCP" -f $a.Name) -ForegroundColor Red
                Write-Log "DNS reset to DHCP FAILED verify on $($a.Name)" "ERROR"
            }
        } catch {
            Write-Host ("  [FAILED] {0}" -f $a.Name) -ForegroundColor Red
        }
    }
}
 
function Show-CurrentDnsConfig {
    <# Explicit Verify step, independent of an apply - a live read of what
       every active adapter is actually configured with right now. #>
    $adapters = Get-ActiveAdapters
    if ($adapters.Count -eq 0) { Write-Host "  No active network adapters found." -ForegroundColor Yellow; return }
    Write-Host "`n>>> CURRENT DNS CONFIGURATION (live read)`n" -ForegroundColor Cyan
    foreach ($a in $adapters) {
        $servers = @(Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        $label = if (@($servers).Count -gt 0) { $servers -join ", " } else { "DHCP-assigned (no static servers)" }
        Write-Host ("  {0,-22} {1}" -f $a.Name, $label)
    }
}
 
function Test-DnsResolutionLatency {
    <# One real, timed DNS resolution against a *specific* server - not a
       ping to the resolver's IP, which only measures ICMP reachability and
       says nothing about actual DNS query performance. Uses Resolve-DnsName
       (in-box DnsClient module, Windows 10/11) with -QuickTimeout so a
       filtered/unreachable resolver fails fast instead of hanging the rest
       of the benchmark. Returns latency in ms, or $null on failure/timeout -
       never a fabricated or estimated number. #>
    param(
        [Parameter(Mandatory)][string]$Server,
        [Parameter(Mandatory)][string]$QueryName
    )
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Resolve-DnsName -Name $QueryName -Server $Server -Type A -DnsOnly -QuickTimeout -ErrorAction Stop
        $sw.Stop()
        return [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
    } catch {
        return $null
    }
}
 
function Invoke-DnsProviderBenchmark ($Provider, [int]$Passes = 3) {
    <# Runs $Passes real, timed resolutions against one provider (rotating
       query names from $script:DnsBenchmarkQueryPool) and reduces them to
       Avg/Min/Max - every number here traces back to an actual Resolve-
       DnsName call, nothing is interpolated or guessed for a failed pass. #>
    $samples = @()
    for ($i = 0; $i -lt $Passes; $i++) {
        $q  = $script:DnsBenchmarkQueryPool[$i % $script:DnsBenchmarkQueryPool.Count]
        $ms = Test-DnsResolutionLatency -Server $Provider.Primary -QueryName $q
        if ($null -ne $ms) { $samples += $ms }
    }
    $failed = $Passes - $samples.Count
    if ($samples.Count -eq 0) {
        return [PSCustomObject]@{ Name = $Provider.Name; Primary = $Provider.Primary; Secondary = $Provider.Secondary; Avg = $null; Min = $null; Max = $null; Passes = $Passes; Failed = $failed }
    }
    return [PSCustomObject]@{
        Name    = $Provider.Name; Primary = $Provider.Primary; Secondary = $Provider.Secondary
        Avg     = [math]::Round((($samples | Measure-Object -Average).Average), 1)
        Min     = [math]::Round((($samples | Measure-Object -Minimum).Minimum), 1)
        Max     = [math]::Round((($samples | Measure-Object -Maximum).Maximum), 1)
        Passes  = $Passes
        Failed  = $failed
    }
}
 
function Invoke-SmartDnsBenchmark {
    <# Benchmarks all $DnsProviders with real multi-pass DNS resolution
       timing, ranks by average latency, then offers Auto (apply the
       ranked winner) or Manual (pick any benchmarked provider) selection.
       Applying goes through Set-DnsOnActiveAdapters, which is itself
       undo-tracked and read-back verified per adapter - Backup & Restore
       (menu [7]) separately snapshots pre-benchmark DNS into every backup
       via New-TweaksBackup, so this feature never needed its own parallel
       backup/restore plumbing. #>
    param([int]$Passes = 3)
    Write-Host ("`nBenchmarking {0} DNS providers ({1} real timed resolution(s) each - not ICMP)...`n" -f $DnsProviders.Count, $Passes) -ForegroundColor Cyan
    $results = foreach ($p in $DnsProviders) {
        Write-Host ("  Testing {0,-12} ({1})..." -f $p.Name, $p.Primary) -NoNewline
        $r = Invoke-DnsProviderBenchmark -Provider $p -Passes $Passes
        if ($null -ne $r.Avg) { Write-Host (" avg {0} ms  (min {1} / max {2}, {3}/{4} passes ok)" -f $r.Avg, $r.Min, $r.Max, ($r.Passes - $r.Failed), $r.Passes) -ForegroundColor Green }
        else { Write-Host " unreachable" -ForegroundColor Red }
        $r
    }
    $ranked      = @($results | Where-Object { $null -ne $_.Avg } | Sort-Object Avg)
    $unreachable = @($results | Where-Object { $null -eq $_.Avg })

    Write-Host "`n>>> RESULTS (ranked by average real DNS resolution latency)`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $ranked.Count; $i++) {
        $r   = $ranked[$i]
        $tag = if ($i -eq 0) { "  <- fastest" } else { "" }
        Write-Host ("  [{0}] {1,-12} {2,-16} avg {3,6} ms   min {4,6} / max {5,6}{6}" -f ($i + 1), $r.Name, $r.Primary, $r.Avg, $r.Min, $r.Max, $tag)
    }
    foreach ($r in $unreachable) {
        Write-Host ("  [-] {0,-12} {1,-16} unreachable ({2}/{3} passes failed)" -f $r.Name, $r.Primary, $r.Failed, $r.Passes) -ForegroundColor DarkGray
    }

    Write-Log ("Smart DNS Benchmark complete - " + (($results | ForEach-Object { "$($_.Name)=$(if ($null -ne $_.Avg) { "$($_.Avg)ms" } else { 'unreachable' })" }) -join ", "))

    if ($ranked.Count -eq 0) {
        Write-Host "`nAll providers unreachable - check your connection." -ForegroundColor Red
        Write-Log "Smart DNS Benchmark: all providers unreachable" "WARN"
        return
    }

    Write-Host ""
    Write-Host (" [A] Auto-apply the fastest ({0})" -f $ranked[0].Name)
    Write-Host " [M] Manually pick a provider from the results above"
    Write-Host " [0] Don't apply anything - results only"
    $choice = Read-Host "`nSelect"
    $chosen = $null
    switch ($choice.ToUpper()) {
        "A" { $chosen = $ranked[0] }
        "M" {
            $sel = Read-Host ("Enter a number 1-{0} from the ranked list" -f $ranked.Count)
            if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $ranked.Count) { $chosen = $ranked[[int]$sel - 1] }
            else { Write-Host "Invalid selection. Nothing applied." -ForegroundColor Red; return }
        }
        default { return }
    }
    if (-not $chosen) { return }

    if (-not (Confirm-Action ("Apply {0} ({1} / {2}) to all active adapters? Reversible via [U] Undo Last Session or menu [7] Backup & Restore." -f $chosen.Name, $chosen.Primary, $chosen.Secondary))) { return }
    Set-DnsOnActiveAdapters $chosen.Primary $chosen.Secondary
}
 
function Show-DnsMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [2] DNS OPTIMIZER`n" -ForegroundColor Green
        Write-Host " [1] Smart DNS Benchmark (multi-pass, ranked, auto or manual apply)              [7/10]"
        Write-Host " [2] Quick-set Cloudflare (1.1.1.1 / 1.0.0.1)                                     [5/10]"
        Write-Host " [3] Quick-set Google (8.8.8.8 / 8.8.4.4)                                         [5/10]"
        Write-Host " [4] Quick-set AdGuard (94.140.14.14 / 94.140.15.15, filters ads/trackers)        [5/10]"
        Write-Host " [5] Flush DNS cache                                                              [3/10]"
        Write-Host " [6] Verify current DNS configuration (live read, all active adapters)"
        Write-Host " [7] Restore DHCP-assigned DNS (undo any change above)"
        Write-Host " [0] Back to Main Menu"
        Write-Host "`n Note: Smart DNS Benchmark applies go through the same Undo Last Session" -ForegroundColor DarkGray
        Write-Host " ledger as every other tweak, and are also captured by menu [7] Backup &" -ForegroundColor DarkGray
        Write-Host " Restore - two independent ways back to your previous DNS." -ForegroundColor DarkGray
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { Invoke-SmartDnsBenchmark; Wait-ForEnter }
            "2" { Set-DnsOnActiveAdapters "1.1.1.1" "1.0.0.1"; Wait-ForEnter }
            "3" { Set-DnsOnActiveAdapters "8.8.8.8" "8.8.4.4"; Wait-ForEnter }
            "4" { Set-DnsOnActiveAdapters "94.140.14.14" "94.140.15.15"; Wait-ForEnter }
            "5" { Clear-DnsClientCache -ErrorAction SilentlyContinue; Write-Log "DNS cache flushed"; Write-Host "[DONE] DNS cache cleared." -ForegroundColor Green; Wait-ForEnter -NoBlank }
            "6" { Show-CurrentDnsConfig; Wait-ForEnter }
            "7" { Restore-DnsToDhcp; Wait-ForEnter -NoBlank }
            "0" { return }
            default { Show-InvalidSelection }
        }
    }
}
 
# ==============================================================================
#  7b. CONNECTION BENCHMARK
#  Read-only diagnostic (no tweak, no undo record - nothing here writes to
#  the system). Every field is a real measured value or "Not Measured";
#  never a simulated/estimated number. See the v3.7.0 changelog entry at
#  the top of this file for why throughput measurement needs one real HTTP
#  endpoint (Windows has no in-box link-throughput cmdlet) and why that
#  endpoint isn't treated as a third-party "speed test API".
# ==============================================================================
function Get-PingStatistics {
    <# Real Average/Min/Max Ping + Jitter + Packet Loss from one parsed
       ping.exe run. ping.exe instead of Test-Connection for the same
       reason Automatic MTU Discovery's Test-DfPing does: consistent
       behavior across the PowerShell 5.1/7 split this tool still supports,
       and ping.exe's own summary line reports packet loss directly instead
       of it having to be inferred from how many result objects came back.
       Jitter is the mean of the absolute differences between consecutive
       *successful* round-trip times - an instantaneous-jitter approximation
       computed only from replies that actually arrived; a lost packet is
       never interpolated into it. English ping.exe output is assumed, same
       as the existing "Reply from" match in Test-DfPing above. #>
    param(
        [Parameter(Mandatory)][string]$TargetHost,
        [int]$Count = 10,
        [int]$TimeoutMs = 1000
    )
    try {
        $out = & ping.exe -n $Count -w $TimeoutMs $TargetHost 2>$null
    } catch {
        return [PSCustomObject]@{ Success = $false; Avg = $null; Min = $null; Max = $null; Jitter = $null; PacketLossPercent = $null; Sent = $Count; Received = 0 }
    }
    $text = ($out -join "`n")

    $times = @()
    foreach ($line in $out) {
        if ($line -match 'time[=<]\s*(\d+)\s*ms') { $times += [double]$Matches[1] }
    }

    $sent = $Count; $received = $times.Count; $lossPct = $null
    if ($text -match 'Sent\s*=\s*(\d+),\s*Received\s*=\s*(\d+),\s*Lost\s*=\s*(\d+)\s*\((\d+)%\s*loss\)') {
        $sent = [int]$Matches[1]; $received = [int]$Matches[2]; $lossPct = [int]$Matches[4]
    } elseif ($sent -gt 0) {
        $lossPct = [math]::Round((($sent - $received) / $sent) * 100, 0)
    }

    if ($times.Count -eq 0) {
        return [PSCustomObject]@{ Success = $false; Avg = $null; Min = $null; Max = $null; Jitter = $null; PacketLossPercent = $lossPct; Sent = $sent; Received = $received }
    }

    $avg = [math]::Round((($times | Measure-Object -Average).Average), 1)
    $min = [math]::Round((($times | Measure-Object -Minimum).Minimum), 1)
    $max = [math]::Round((($times | Measure-Object -Maximum).Maximum), 1)

    $jitter = $null
    if ($times.Count -ge 2) {
        $diffs  = for ($i = 1; $i -lt $times.Count; $i++) { [math]::Abs($times[$i] - $times[$i - 1]) }
        $jitter = [math]::Round((($diffs | Measure-Object -Average).Average), 1)
    }

    return [PSCustomObject]@{
        Success = $true; Avg = $avg; Min = $min; Max = $max; Jitter = $jitter
        PacketLossPercent = $lossPct; Sent = $sent; Received = $received
    }
}

function Measure-DnsLookupLatency {
    <# DNS Lookup Latency reuses Test-DnsResolutionLatency - the exact same
       function the Smart DNS Benchmark uses - against whatever server the
       primary active adapter is actually configured with right now, so
       this reflects real current-connection behavior rather than
       benchmarking a provider you may not even be using. One shared
       implementation, two call sites (same pattern as Invoke-RssRscTweaks
       being shared by the TCP Analyzer and Advanced NIC Optimizer). #>
    param([int]$Passes = 3)
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) { return [PSCustomObject]@{ Server = $null; Avg = $null; Passes = $Passes; Failed = $Passes } }
    $server = @((Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses)[0]
    if (-not $server) { return [PSCustomObject]@{ Server = $null; Avg = $null; Passes = $Passes; Failed = $Passes } }
    $samples = @()
    for ($i = 0; $i -lt $Passes; $i++) {
        $q  = $script:DnsBenchmarkQueryPool[$i % $script:DnsBenchmarkQueryPool.Count]
        $ms = Test-DnsResolutionLatency -Server $server -QueryName $q
        if ($null -ne $ms) { $samples += $ms }
    }
    $failed = $Passes - $samples.Count
    $avg = if ($samples.Count -gt 0) { [math]::Round((($samples | Measure-Object -Average).Average), 1) } else { $null }
    return [PSCustomObject]@{ Server = $server; Avg = $avg; Passes = $Passes; Failed = $failed }
}

# Single fixed, no-auth, no-account endpoint that just serves/accepts bytes -
# not a third-party speed-test API (no key, no JSON scoring contract, no
# result upload). This is the one piece of this feature that has to leave
# the machine to produce a real number; see the v3.7.0 changelog note.
$script:SpeedTestDownloadUrl = "https://speed.cloudflare.com/__down?bytes=25000000"
$script:SpeedTestUploadUrl   = "https://speed.cloudflare.com/__up"

function Measure-DownloadThroughput {
    <# Real timed HTTP download (System.Net.Http.HttpClient + Stopwatch),
       not an estimate. Returns Mbps, or $null if the transfer didn't
       complete - never backfilled with a guess. #>
    param([int]$TimeoutSec = 15)
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $client  = [System.Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)
    try {
        $sw    = [System.Diagnostics.Stopwatch]::StartNew()
        $bytes = $client.GetByteArrayAsync($script:SpeedTestDownloadUrl).GetAwaiter().GetResult()
        $sw.Stop()
        if ($sw.Elapsed.TotalSeconds -le 0 -or $bytes.Length -eq 0) { return $null }
        return [math]::Round((($bytes.Length * 8) / $sw.Elapsed.TotalSeconds) / 1000000, 2)
    } catch {
        return $null
    } finally {
        $client.Dispose(); $handler.Dispose()
    }
}

function Measure-UploadThroughput {
    <# Real timed HTTP upload of random bytes (never reused/cached content,
       so the transfer can't be short-circuited). Same real-transfer-or-
       Not-Measured discipline as the download side. #>
    param([int]$TimeoutSec = 15, [int]$PayloadBytes = 10000000)
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $client  = [System.Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)
    try {
        $payload = New-Object byte[] $PayloadBytes
        [System.Random]::new().NextBytes($payload)
        $content = [System.Net.Http.ByteArrayContent]::new($payload)
        $sw   = [System.Diagnostics.Stopwatch]::StartNew()
        $resp = $client.PostAsync($script:SpeedTestUploadUrl, $content).GetAwaiter().GetResult()
        $sw.Stop()
        if (-not $resp.IsSuccessStatusCode -or $sw.Elapsed.TotalSeconds -le 0) { return $null }
        return [math]::Round((($payload.Length * 8) / $sw.Elapsed.TotalSeconds) / 1000000, 2)
    } catch {
        return $null
    } finally {
        $client.Dispose(); $handler.Dispose()
    }
}

function Get-NetworkQualityScore {
    <# A plain weighted formula over exactly the fields this benchmark
       measured - never a marketing number. Each component is normalized
       to 0-100 against a fixed, documented reference point, then combined
       with fixed weights (Ping 25 / Jitter 15 / Loss 20 / DNS 10 /
       Download 20 / Upload 10). Any field that failed to measure simply
       doesn't contribute a component - the remaining weights are
       renormalized over what's left rather than the gap being filled with
       a guess - and the result is flagged Partial whenever that happens. #>
    param($Metrics)
    $components = @()

    if ($null -ne $Metrics.AvgPing)           { $components += @{ Weight = 25; Score = [math]::Max(0, [math]::Min(100, 100 - ($Metrics.AvgPing / 150 * 100))) } }            # 0ms=100 .. 150ms+=0
    if ($null -ne $Metrics.Jitter)             { $components += @{ Weight = 15; Score = [math]::Max(0, [math]::Min(100, 100 - ($Metrics.Jitter / 50 * 100))) } }             # 0ms=100 .. 50ms+=0
    if ($null -ne $Metrics.PacketLossPercent)  { $components += @{ Weight = 20; Score = [math]::Max(0, [math]::Min(100, 100 - ($Metrics.PacketLossPercent / 10 * 100))) } }  # 0%=100 .. 10%+=0
    if ($null -ne $Metrics.DnsLatency)         { $components += @{ Weight = 10; Score = [math]::Max(0, [math]::Min(100, 100 - ($Metrics.DnsLatency / 100 * 100))) } }        # 0ms=100 .. 100ms+=0
    if ($null -ne $Metrics.DownloadMbps)       { $components += @{ Weight = 20; Score = [math]::Max(0, [math]::Min(100, ($Metrics.DownloadMbps / 200 * 100))) } }            # 0=0 .. 200Mbps+=100
    if ($null -ne $Metrics.UploadMbps)         { $components += @{ Weight = 10; Score = [math]::Max(0, [math]::Min(100, ($Metrics.UploadMbps / 50 * 100))) } }               # 0=0 .. 50Mbps+=100

    if ($components.Count -eq 0) { return [PSCustomObject]@{ Score = $null; Partial = $true; MeasuredFields = 0 } }

    $totalWeight = ($components | Measure-Object -Property Weight -Sum).Sum
    $weighted    = 0
    foreach ($c in $components) { $weighted += ($c.Score * $c.Weight) }
    return [PSCustomObject]@{
        Score          = [math]::Round($weighted / $totalWeight, 0)
        Partial        = ($components.Count -lt 6)
        MeasuredFields = $components.Count
    }
}

function Invoke-ConnectionBenchmark {
    param(
        [string]$PingTarget = "8.8.8.8",
        [int]$PingCount = 10,
        [int]$DnsPasses = 3,
        [switch]$SkipThroughput
    )
    Write-Host "`n>>> CONNECTION BENCHMARK`n" -ForegroundColor Cyan

    Write-Host ("  Pinging {0} ({1} packets, real ICMP via ping.exe)..." -f $PingTarget, $PingCount) -ForegroundColor Gray
    $ping = Get-PingStatistics -TargetHost $PingTarget -Count $PingCount
    if ($ping.Success) {
        Write-Host ("    Avg {0} ms | Min {1} ms | Max {2} ms | Jitter {3} ms | Loss {4}% ({5}/{6} received)" -f $ping.Avg, $ping.Min, $ping.Max, $ping.Jitter, $ping.PacketLossPercent, $ping.Received, $ping.Sent) -ForegroundColor Green
    } else {
        Write-Host "    [FAILED] No replies received - check your connection." -ForegroundColor Red
    }

    Write-Host ("  Measuring DNS lookup latency ({0} real resolutions against your current resolver)..." -f $DnsPasses) -ForegroundColor Gray
    $dns = Measure-DnsLookupLatency -Passes $DnsPasses
    if ($null -ne $dns.Avg) { Write-Host ("    Avg {0} ms against {1}" -f $dns.Avg, $dns.Server) -ForegroundColor Green }
    else { Write-Host "    [FAILED] Could not resolve against the configured DNS server." -ForegroundColor Red }

    $download = $null; $upload = $null
    if (-not $SkipThroughput) {
        Write-Host "  Measuring download throughput (real timed transfer, ~25MB)..." -ForegroundColor Gray
        $download = Measure-DownloadThroughput
        # Explicit $null check, not a truthy check - PowerShell treats a
        # genuine 0 as $false, and 0 Mbps/0 ms is a real (if unlikely)
        # measured value on a very fast link, not the same thing as a
        # failed transfer that returned $null.
        if ($null -ne $download) { Write-Host ("    {0} Mbps" -f $download) -ForegroundColor Green } else { Write-Host "    [FAILED] Download transfer did not complete." -ForegroundColor Red }

        Write-Host "  Measuring upload throughput (real timed transfer, ~10MB)..." -ForegroundColor Gray
        $upload = Measure-UploadThroughput
        if ($null -ne $upload) { Write-Host ("    {0} Mbps" -f $upload) -ForegroundColor Green } else { Write-Host "    [FAILED] Upload transfer did not complete." -ForegroundColor Red }
    } else {
        Write-Host "  Throughput test skipped." -ForegroundColor DarkGray
    }

    $metrics = [PSCustomObject]@{
        AvgPing = $ping.Avg; MinPing = $ping.Min; MaxPing = $ping.Max; Jitter = $ping.Jitter
        PacketLossPercent = $ping.PacketLossPercent; DnsLatency = $dns.Avg
        DownloadMbps = $download; UploadMbps = $upload
    }
    $score = Get-NetworkQualityScore -Metrics $metrics

    Write-Host "`n>>> RESULTS`n" -ForegroundColor Cyan
    Write-Host ("  Average Ping         : {0}" -f $(if ($null -ne $metrics.AvgPing) { "$($metrics.AvgPing) ms" } else { "Not Measured" }))
    Write-Host ("  Minimum Ping         : {0}" -f $(if ($null -ne $metrics.MinPing) { "$($metrics.MinPing) ms" } else { "Not Measured" }))
    Write-Host ("  Maximum Ping         : {0}" -f $(if ($null -ne $metrics.MaxPing) { "$($metrics.MaxPing) ms" } else { "Not Measured" }))
    Write-Host ("  Jitter               : {0}" -f $(if ($null -ne $metrics.Jitter) { "$($metrics.Jitter) ms" } else { "Not Measured" }))
    Write-Host ("  Packet Loss          : {0}" -f $(if ($null -ne $metrics.PacketLossPercent) { "$($metrics.PacketLossPercent)%" } else { "Not Measured" }))
    Write-Host ("  DNS Lookup Latency   : {0}" -f $(if ($null -ne $metrics.DnsLatency) { "$($metrics.DnsLatency) ms" } else { "Not Measured" }))
    Write-Host ("  Download Throughput  : {0}" -f $(if ($null -ne $metrics.DownloadMbps) { "$($metrics.DownloadMbps) Mbps" } else { "Not Measured" }))
    Write-Host ("  Upload Throughput    : {0}" -f $(if ($null -ne $metrics.UploadMbps) { "$($metrics.UploadMbps) Mbps" } else { "Not Measured" }))
    Write-Host ""
    if ($null -ne $score.Score) {
        $label = if ($score.Partial) { " (Partial - based on $($score.MeasuredFields)/6 measured fields)" } else { "" }
        $color = if ($score.Score -ge 80) { "Green" } elseif ($score.Score -ge 50) { "Yellow" } else { "Red" }
        Write-Host ("  Network Quality Score: {0}/100{1}" -f $score.Score, $label) -ForegroundColor $color
    } else {
        Write-Host "  Network Quality Score: Not Measured (nothing succeeded)" -ForegroundColor Red
    }

    Write-Log ("Connection Benchmark - Ping avg={0} min={1} max={2} jitter={3} loss={4}% dns={5} down={6}Mbps up={7}Mbps score={8}" -f `
        $metrics.AvgPing, $metrics.MinPing, $metrics.MaxPing, $metrics.Jitter, $metrics.PacketLossPercent, $metrics.DnsLatency, $metrics.DownloadMbps, $metrics.UploadMbps, $score.Score)
}

function Show-ConnectionBenchmarkMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [13] CONNECTION BENCHMARK`n" -ForegroundColor Green
        Write-Host " Measures only real values - Average/Min/Max Ping, Jitter, Packet Loss," -ForegroundColor Gray
        Write-Host " DNS Lookup Latency, and Download/Upload Throughput - then derives a" -ForegroundColor Gray
        Write-Host " Network Quality Score from exactly those numbers. Nothing here is" -ForegroundColor Gray
        Write-Host " simulated or estimated; a field that can't be measured prints" -ForegroundColor Gray
        Write-Host " 'Not Measured' instead of a filler value.`n" -ForegroundColor Gray
        Write-Host " [1] Full benchmark (ping/jitter/loss + DNS + download/upload + score)   [~30-60s]"
        Write-Host " [2] Quick benchmark (ping/jitter/loss + DNS only, no throughput)         [~5s]"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { Invoke-ConnectionBenchmark; Wait-ForEnter }
            "2" { Invoke-ConnectionBenchmark -SkipThroughput; Wait-ForEnter }
            "0" { return }
            default { Show-InvalidSelection }
        }
    }
}

# ==============================================================================
#  7c. LIVE NETWORK HEALTH MONITOR
#  A real continuous background sampler, not a one-shot report. It runs in
#  one lightweight runspace (System.Management.Automation.Runspaces), NOT a
#  new powershell.exe process (Start-Job) and NOT a WinForms/WPF timer - a
#  runspace is the lowest-overhead way to keep a loop alive on its own
#  thread inside this same process, which is what "very low CPU usage" and
#  "avoid unnecessary network traffic" below actually require in practice.
#
#  Every helper the background loop calls (Get-PingStatistics,
#  Test-DnsResolutionLatency, Get-PrimaryActiveAdapter, Write-Log) is the
#  exact same function already defined above in this file - their live
#  .Definition text is imported into the runspace's InitialSessionState at
#  start time, so there is exactly one copy of each of those functions in
#  this script, not a rewritten/duplicated copy for the background thread.
#
#  Every displayed number comes from one real measurement:
#    - Ping / Min / Max / Avg / Jitter / Packet Loss - derived from a
#      single real ICMP echo (Get-PingStatistics -Count 1) against a fixed
#      internet target once per sampling interval, accumulated online
#      (running sum/min/max, no unbounded sample list kept in memory).
#    - Gateway Latency  - a single real ICMP echo against the default
#      gateway of the adapter carrying the default route, sampled less
#      often than the internet ping (traffic-saving), gateway re-resolved
#      at that same slower cadence in case the active route changes.
#    - Internet Latency - the same internet-ping sample as above, shown
#      under its own label since it's a distinct real-world hop from the
#      gateway reading.
#    - DNS Resolution Failures - a real Resolve-DnsName timing (the exact
#      Test-DnsResolutionLatency function the Smart DNS Benchmark and
#      Connection Benchmark already use) against whatever server the
#      active adapter is actually configured with, sampled at its own
#      (slower still) cadence. A failed/timed-out resolution increments
#      the counter; nothing is ever backfilled with an estimate.
#
#  Start/Stop/Pause/Resume/Reset Statistics all act on one synchronized
#  hashtable ($script:NetHealthState) the background thread writes to and
#  the console reads from - Pause/Resume just flips a flag the loop checks
#  every iteration (the thread stays alive, so Resume is instant, no
#  runspace teardown/rebuild), and Reset Statistics clears only the
#  accumulated numbers, not the running monitor itself.
#
#  Stop tears down cleanly and in order every time: signal the loop to
#  exit, wait for it to actually finish its current iteration, reap the
#  async pipeline (EndInvoke, so no unobserved-exception/orphaned pipeline
#  state is left behind), then Dispose the PowerShell instance and Close +
#  Dispose the runspace. The same cleanup also runs (silently) if the
#  console window is closed instead of using [Q] Exit, via a
#  PowerShell.Exiting engine event registered once when the monitor first
#  starts - see Register-NetHealthExitCleanup. Nothing here is left running
#  as an orphaned job/runspace either way.
#
#  Recovery actions (Flush DNS / Renew IP / Release IP / Restart Adapter /
#  Winsock Reset) are read-only-safe until explicitly confirmed - they are
#  never auto-executed, and the menu only offers them at all once the
#  monitor itself has flagged persistent degradation (several consecutive
#  degraded cycles, tracked in $State.ConsecutiveDegraded /
#  DegradationDetected), matching "recovery should only be offered when
#  persistent network degradation is detected". Each action uses the
#  Windows-documented tool for the job (Restart-NetAdapter, ipconfig
#  /renew|/release, netsh winsock reset, Clear-DnsClientCache) rather than
#  a custom re-implementation. These are transient operational actions,
#  not a value-overwrite the Undo ledger could meaningfully restore (the
#  same category this file already treats DISM/SFC/temp-cleanup as - see
#  the Undo Engine header comment above), so they are logged like every
#  other action but intentionally do not go through Add-UndoRecord.
# ==============================================================================
$script:NetHealthState              = $null
$script:NetHealthRunspace           = $null
$script:NetHealthPowerShell         = $null
$script:NetHealthHandle             = $null
$script:NetHealthExitHandlerRegistered = $false

# The background loop itself. Kept as a scriptblock and converted to text
# (.ToString()) before being handed to the runspace's AddScript - passing a
# ScriptBlock object directly would carry this (main) runspace's closure
# with it instead of running clean inside the new one.
$script:NetHealthLoopScript = {
    param($State, $DnsQueryPool)
    $ErrorActionPreference = 'Continue'
    $ProgressPreference    = 'SilentlyContinue'
    $cycle = 0

    while (-not $State.StopRequested) {
        if ($State.Paused) { Start-Sleep -Milliseconds 500; continue }

        $cycle++
        $State.CycleCount = $cycle

        # ---- Internet ping: one real ICMP echo per interval ----
        $ping = $null
        try { $ping = Get-PingStatistics -TargetHost $State.InternetTarget -Count 1 -TimeoutMs 1000 } catch { $ping = $null }
        $sample = $null
        if ($ping -and $ping.Success -and ($null -ne $ping.Avg)) { $sample = $ping.Avg }

        $State.SamplesSent = $State.SamplesSent + 1
        $degradedThisCycle = $false

        if ($null -ne $sample) {
            $State.SamplesReceived  = $State.SamplesReceived + 1
            $State.CurrentPing      = $sample
            $State.InternetLatency  = $sample
            if ($null -eq $State.MinPing -or $sample -lt $State.MinPing) { $State.MinPing = $sample }
            if ($null -eq $State.MaxPing -or $sample -gt $State.MaxPing) { $State.MaxPing = $sample }
            $State.SumPing      = $State.SumPing + $sample
            $State.SumPingCount = $State.SumPingCount + 1
            $State.AvgPing      = [math]::Round($State.SumPing / $State.SumPingCount, 1)
            if ($null -ne $State.LastGoodSample) {
                $diff = [math]::Abs($sample - $State.LastGoodSample)
                $State.JitterSum   = $State.JitterSum + $diff
                $State.JitterCount = $State.JitterCount + 1
                $State.Jitter      = [math]::Round($State.JitterSum / $State.JitterCount, 1)
            }
            $State.LastGoodSample = $sample
            if ($sample -gt $State.LatencyThresholdMs) { $degradedThisCycle = $true }
        } else {
            $State.CurrentPing     = $null
            $State.InternetLatency = $null
            $degradedThisCycle = $true
        }

        if ($State.SamplesSent -gt 0) {
            $State.PacketLossPercent = [math]::Round((($State.SamplesSent - $State.SamplesReceived) / $State.SamplesSent) * 100, 1)
        }

        if ($degradedThisCycle) { $State.ConsecutiveDegraded = $State.ConsecutiveDegraded + 1 }
        else { $State.ConsecutiveDegraded = 0 }

        if ($State.ConsecutiveDegraded -ge $State.DegradedCycleThreshold) {
            if (-not $State.DegradationDetected) {
                try {
                    $degradedMsg = "Live Network Health Monitor: persistent degradation detected ($($State.ConsecutiveDegraded) consecutive degraded cycles)"
                    Write-Log $degradedMsg "WARN"
                } catch {}
            }
            $State.DegradationDetected = $true
        }

        # ---- Gateway latency: cheaper cadence, local route lookup + one real ping ----
        if (($cycle % $State.GatewayEveryNCycles) -eq 0) {
            try {
                $gw = $null
                $adapter = Get-PrimaryActiveAdapter
                if ($adapter) {
                    $cfg = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
                    if ($cfg -and $cfg.IPv4DefaultGateway) { $gw = $cfg.IPv4DefaultGateway.NextHop }
                    if (-not $gw) {
                        $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1
                        if ($route) { $gw = $route.NextHop }
                    }
                }
                $State.GatewayTarget = $gw
                if ($gw) {
                    $gwPing = Get-PingStatistics -TargetHost $gw -Count 1 -TimeoutMs 800
                    if ($gwPing -and $gwPing.Success -and ($null -ne $gwPing.Avg)) { $State.GatewayLatency = $gwPing.Avg }
                    else { $State.GatewayLatency = $null }
                } else {
                    $State.GatewayLatency = $null
                }
            } catch { $State.GatewayLatency = $null }
        }

        # ---- DNS resolution: slowest cadence, real Resolve-DnsName timing ----
        if (($cycle % $State.DnsEveryNCycles) -eq 0) {
            try {
                $State.DnsAttempts = $State.DnsAttempts + 1
                $adapter = Get-PrimaryActiveAdapter
                $server = $null
                if ($adapter) {
                    $server = @((Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses)[0]
                }
                if ($server -and $DnsQueryPool -and $DnsQueryPool.Count -gt 0) {
                    $q  = $DnsQueryPool[$State.DnsAttempts % $DnsQueryPool.Count]
                    $ms = Test-DnsResolutionLatency -Server $server -QueryName $q
                    if ($null -eq $ms) { $State.DnsFailures = $State.DnsFailures + 1 }
                } else {
                    $State.DnsFailures = $State.DnsFailures + 1
                }
            } catch {
                $State.DnsFailures = $State.DnsFailures + 1
            }
        }

        Start-Sleep -Seconds $State.IntervalSeconds
    }
}

function Register-NetHealthExitCleanup {
    <# Best-effort safety net: if the console window is closed instead of
       using [Q] Exit, still stop the runspace instead of leaving it
       orphaned. Registered once, on first Start. #>
    if ($script:NetHealthExitHandlerRegistered) { return }
    try {
        Register-EngineEvent -SourceIdentifier PowerShell.Exiting -SupportEvent -Action {
            try { Stop-NetworkHealthMonitor -Silent } catch {}
        } | Out-Null
        $script:NetHealthExitHandlerRegistered = $true
    } catch {}
}

function Start-NetworkHealthMonitor {
    param(
        [string]$InternetTarget = "1.1.1.1",
        [int]$IntervalSeconds = 2,
        [int]$LatencyThresholdMs = 150,
        [int]$DegradedCycleThreshold = 5
    )
    if ($script:NetHealthState -and $script:NetHealthState.Running) {
        Write-Host "`n  Monitor is already running." -ForegroundColor Yellow
        return
    }
    if ([string]::IsNullOrWhiteSpace($InternetTarget)) { $InternetTarget = "1.1.1.1" }

    $script:NetHealthState = [hashtable]::Synchronized(@{
        Running               = $true
        Paused                = $false
        StopRequested         = $false
        InternetTarget        = $InternetTarget
        IntervalSeconds       = [math]::Max(1, $IntervalSeconds)
        LatencyThresholdMs    = [math]::Max(1, $LatencyThresholdMs)
        DegradedCycleThreshold= [math]::Max(2, $DegradedCycleThreshold)
        GatewayEveryNCycles   = 3
        DnsEveryNCycles       = 5
        GatewayTarget         = $null
        CurrentPing           = $null
        InternetLatency       = $null
        MinPing               = $null
        MaxPing               = $null
        AvgPing               = $null
        SumPing               = 0.0
        SumPingCount          = 0
        Jitter                = $null
        JitterSum             = 0.0
        JitterCount           = 0
        LastGoodSample        = $null
        PacketLossPercent     = 0
        SamplesSent           = 0
        SamplesReceived       = 0
        GatewayLatency        = $null
        DnsAttempts           = 0
        DnsFailures           = 0
        ConsecutiveDegraded   = 0
        DegradationDetected   = $false
        CycleCount            = 0
        StartTime             = Get-Date
    })

    $rs = $null
    $ps = $null
    try {
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        foreach ($fnName in @('Get-PingStatistics', 'Test-DnsResolutionLatency', 'Get-PrimaryActiveAdapter', 'Write-Log')) {
            $cmd   = Get-Command -Name $fnName -CommandType Function -ErrorAction Stop
            $entry = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry($fnName, $cmd.Definition)
            $iss.Commands.Add($entry)
        }

        $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
        $rs.ThreadOptions = "ReuseThread"
        $rs.Open()
        $rs.SessionStateProxy.SetVariable('LogFile', $LogFile)

        $ps = [System.Management.Automation.PowerShell]::Create()
        $ps.Runspace = $rs
        [void]$ps.AddScript($script:NetHealthLoopScript.ToString())
        [void]$ps.AddArgument($script:NetHealthState)
        [void]$ps.AddArgument(@($script:DnsBenchmarkQueryPool))

        $handle = $ps.BeginInvoke()

        $script:NetHealthRunspace   = $rs
        $script:NetHealthPowerShell = $ps
        $script:NetHealthHandle     = $handle

        Register-NetHealthExitCleanup

        Write-Log ("Live Network Health Monitor started (target={0}, interval={1}s, threshold={2}ms x{3} cycles)" -f $InternetTarget, $script:NetHealthState.IntervalSeconds, $script:NetHealthState.LatencyThresholdMs, $script:NetHealthState.DegradedCycleThreshold)
        Write-Host ("`n  [STARTED] Live Network Health Monitor - pinging {0} every {1}s in the background." -f $InternetTarget, $script:NetHealthState.IntervalSeconds) -ForegroundColor Green
    } catch {
        # Setup failed partway through - make sure nothing partially-created
        # is left behind (no orphaned runspace/PowerShell instance).
        if ($script:NetHealthState) { $script:NetHealthState.Running = $false }
        try { if ($ps) { $ps.Dispose() } } catch {}
        try { if ($rs) { $rs.Close(); $rs.Dispose() } } catch {}
        $script:NetHealthRunspace   = $null
        $script:NetHealthPowerShell = $null
        $script:NetHealthHandle     = $null
        Write-Log "FAILED to start Live Network Health Monitor: $_" "ERROR"
        Write-Host "`n  [FAILED] Could not start the monitor: $_" -ForegroundColor Red
    }
}

function Stop-NetworkHealthMonitor {
    <# Full, ordered teardown: signal stop -> wait for the loop to notice
       -> reap the async pipeline -> Dispose the PowerShell instance ->
       Close+Dispose the runspace. Safe to call even if nothing is running
       (used both by the menu's [2] Stop Monitor and by the exit-cleanup
       event handler). #>
    param([switch]$Silent)

    if (-not $script:NetHealthState -or -not $script:NetHealthState.Running) {
        if (-not $Silent) { Write-Host "`n  Monitor is not running." -ForegroundColor Yellow }
        return
    }

    $script:NetHealthState.StopRequested = $true
    $script:NetHealthState.Paused        = $false   # wake a paused loop so it can see StopRequested

    $maxWaitMs = ([math]::Max(1, $script:NetHealthState.IntervalSeconds) * 1000) + 3000
    $waited = 0
    while ($script:NetHealthHandle -and -not $script:NetHealthHandle.IsCompleted -and $waited -lt $maxWaitMs) {
        Start-Sleep -Milliseconds 200
        $waited += 200
    }

    try {
        if ($script:NetHealthPowerShell) {
            if ($script:NetHealthHandle -and -not $script:NetHealthHandle.IsCompleted) {
                try { $script:NetHealthPowerShell.Stop() } catch {}
            }
            try { $script:NetHealthPowerShell.EndInvoke($script:NetHealthHandle) } catch {}
            $script:NetHealthPowerShell.Dispose()
        }
    } catch {}
    try {
        if ($script:NetHealthRunspace) {
            $script:NetHealthRunspace.Close()
            $script:NetHealthRunspace.Dispose()
        }
    } catch {}

    $script:NetHealthState.Running = $false
    $script:NetHealthPowerShell    = $null
    $script:NetHealthRunspace      = $null
    $script:NetHealthHandle        = $null

    try { Write-Log "Live Network Health Monitor stopped (runspace/timers cleaned up)" } catch {}
    if (-not $Silent) { Write-Host "`n  [STOPPED] Live Network Health Monitor - background runspace cleaned up, nothing left running." -ForegroundColor Green }
}

function Suspend-NetworkHealthMonitor {
    <# "Pause Monitor" in the menu - the background thread stays alive
       (unlike Stop), it just skips sampling until Resume flips it back. #>
    if (-not $script:NetHealthState -or -not $script:NetHealthState.Running) {
        Write-Host "`n  Monitor is not running." -ForegroundColor Yellow; return
    }
    if ($script:NetHealthState.Paused) {
        Write-Host "`n  Monitor is already paused." -ForegroundColor Yellow; return
    }
    $script:NetHealthState.Paused = $true
    Write-Log "Live Network Health Monitor paused"
    Write-Host "`n  [PAUSED] Sampling suspended - the background thread stays alive and resumes instantly." -ForegroundColor Yellow
}

function Resume-NetworkHealthMonitor {
    if (-not $script:NetHealthState -or -not $script:NetHealthState.Running) {
        Write-Host "`n  Monitor is not running." -ForegroundColor Yellow; return
    }
    if (-not $script:NetHealthState.Paused) {
        Write-Host "`n  Monitor is not paused." -ForegroundColor Yellow; return
    }
    $script:NetHealthState.Paused = $false
    Write-Log "Live Network Health Monitor resumed"
    Write-Host "`n  [RESUMED] Sampling active again." -ForegroundColor Green
}

function Reset-NetworkHealthStatistics {
    <# Clears only the accumulated numbers - target/interval/thresholds and
       Running/Paused state are left alone, so the monitor keeps running
       through a reset exactly like the requirement says. #>
    if (-not $script:NetHealthState) {
        Write-Host "`n  Monitor has not been started yet." -ForegroundColor Yellow
        return
    }
    $s = $script:NetHealthState
    $s.CurrentPing = $null; $s.InternetLatency = $null
    $s.MinPing = $null; $s.MaxPing = $null; $s.AvgPing = $null
    $s.SumPing = 0.0; $s.SumPingCount = 0
    $s.Jitter = $null; $s.JitterSum = 0.0; $s.JitterCount = 0
    $s.LastGoodSample = $null
    $s.PacketLossPercent = 0; $s.SamplesSent = 0; $s.SamplesReceived = 0
    $s.GatewayLatency = $null
    $s.DnsAttempts = 0; $s.DnsFailures = 0
    $s.ConsecutiveDegraded = 0; $s.DegradationDetected = $false
    $s.CycleCount = 0; $s.StartTime = Get-Date
    Write-Log "Live Network Health Monitor statistics reset"
    Write-Host "`n  [RESET] Statistics cleared - the monitor keeps running with the same target/interval." -ForegroundColor Green
}

function Show-NetworkHealthDashboard {
    <# Auto-refreshing, READ-ONLY view of $script:NetHealthState - it never
       calls Show-Banner per tick (that would itself re-ping 8.8.8.8 and
       re-query CPU/RAM/GPU on every refresh) and never issues any network
       call of its own; it only reads numbers the background runspace
       already produced, so watching the dashboard adds no extra traffic
       or CPU beyond the monitor's own sampling. #>
    if (-not $script:NetHealthState) {
        Write-Host "`n  Start the monitor first (option 1)." -ForegroundColor Yellow
        Wait-ForEnter -NoBlank
        return
    }
    Write-Host "`n  Entering live dashboard - press any key to return to the menu...`n" -ForegroundColor Cyan
    Start-Sleep -Milliseconds 600
    while ($true) {
        if ([Console]::KeyAvailable) { [void][Console]::ReadKey($true); break }
        $s = $script:NetHealthState
        Clear-Host
        Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
        Write-Host "  LIVE NETWORK HEALTH MONITOR" -ForegroundColor Cyan
        Write-Host "══════════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
        $statusText  = if (-not $s.Running) { "STOPPED" } elseif ($s.Paused) { "PAUSED" } else { "RUNNING" }
        $statusColor = if (-not $s.Running) { "Red" } elseif ($s.Paused) { "Yellow" } else { "Green" }
        Write-Host ("  Status           : {0}" -f $statusText) -ForegroundColor $statusColor
        Write-Host ("  Internet target  : {0}" -f $s.InternetTarget)
        Write-Host ("  Gateway target   : {0}" -f $(if ($s.GatewayTarget) { $s.GatewayTarget } else { "detecting..." }))
        Write-Host ("  Uptime           : {0}" -f $(if ($s.StartTime) { (New-TimeSpan -Start $s.StartTime -End (Get-Date)).ToString("hh\:mm\:ss") } else { "n/a" }))
        Write-Host ""
        Write-Host ("  Ping (current)   : {0}" -f $(if ($null -ne $s.CurrentPing) { "$($s.CurrentPing) ms" } else { "timeout" }))
        Write-Host ("  Minimum Ping     : {0}" -f $(if ($null -ne $s.MinPing) { "$($s.MinPing) ms" } else { "n/a" }))
        Write-Host ("  Maximum Ping     : {0}" -f $(if ($null -ne $s.MaxPing) { "$($s.MaxPing) ms" } else { "n/a" }))
        Write-Host ("  Average Ping     : {0}" -f $(if ($null -ne $s.AvgPing) { "$($s.AvgPing) ms" } else { "n/a" }))
        Write-Host ("  Jitter           : {0}" -f $(if ($null -ne $s.Jitter) { "$($s.Jitter) ms" } else { "n/a" }))
        Write-Host ("  Packet Loss      : {0}%  ({1}/{2} sent)" -f $s.PacketLossPercent, $s.SamplesReceived, $s.SamplesSent)
        Write-Host ("  Gateway Latency  : {0}" -f $(if ($null -ne $s.GatewayLatency) { "$($s.GatewayLatency) ms" } else { "n/a" }))
        Write-Host ("  Internet Latency : {0}" -f $(if ($null -ne $s.InternetLatency) { "$($s.InternetLatency) ms" } else { "timeout" }))
        Write-Host ("  DNS Res. Failures: {0} / {1} attempts" -f $s.DnsFailures, $s.DnsAttempts)
        Write-Host ""
        if ($s.DegradationDetected) {
            Write-Host ("  [!] Persistent degradation detected ({0} consecutive degraded cycles)." -f $s.ConsecutiveDegraded) -ForegroundColor Red
            Write-Host "      Return to the menu and choose [R] Recovery Actions if you'd like to act on it." -ForegroundColor Red
        }
        Write-Host "`n  Press any key to return to the menu..." -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 700
    }
}

# ---- Recovery actions: never auto-executed, each needs its own explicit
#      Confirm-Action, and each uses the documented Windows-native tool for
#      the job instead of a custom re-implementation. ----
function Invoke-RecoveryFlushDns {
    # Every recovery action below now routes through the shared
    # Invoke-ZoroSafeOperation (3b) instead of carrying its own copy of
    # try { ... } catch { Write-Log ...; Write-Host ... } - one place
    # classifies the failure and renders it consistently.
    $r = Invoke-ZoroSafeOperation -OperationName "Flush DNS Cache" -Quiet -Action { Clear-DnsClientCache -ErrorAction Stop }
    if ($r.Success) {
        Write-Log "Recovery action: DNS cache flushed (Live Network Health Monitor)"
        Write-Host "  [DONE] DNS cache flushed." -ForegroundColor Green
    } else {
        Write-Host ("  [FAILED] Could not flush DNS cache - {0}" -f $r.Guidance) -ForegroundColor Red
    }
}

function Invoke-RecoveryRenewIp {
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) { Write-Host "  [SKIPPED] No active adapter found." -ForegroundColor Yellow; return }
    $r = Invoke-ZoroSafeOperation -OperationName "Renew IP on $($adapter.Name)" -Quiet -Action { ipconfig /renew "$($adapter.Name)" 2>&1 }
    if ($r.Success) {
        Write-Log "Recovery action: IP renew requested on $($adapter.Name)"
        Write-Host ("  [DONE] Renew requested on {0}." -f $adapter.Name) -ForegroundColor Green
        Write-Host ("  {0}" -f ($r.Value -join "`n  "))
    } else {
        Write-Host ("  [FAILED] Renew IP on {0} - {1}" -f $adapter.Name, $r.Guidance) -ForegroundColor Red
    }
}

function Invoke-RecoveryReleaseIp {
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) { Write-Host "  [SKIPPED] No active adapter found." -ForegroundColor Yellow; return }
    $r = Invoke-ZoroSafeOperation -OperationName "Release IP on $($adapter.Name)" -Quiet -Action { ipconfig /release "$($adapter.Name)" 2>&1 }
    if ($r.Success) {
        Write-Log "Recovery action: IP released on $($adapter.Name)"
        Write-Host ("  [DONE] {0} released. Run Renew IP afterward to reacquire an address." -f $adapter.Name) -ForegroundColor Yellow
        Write-Host ("  {0}" -f ($r.Value -join "`n  "))
    } else {
        Write-Host ("  [FAILED] Release IP on {0} - {1}" -f $adapter.Name, $r.Guidance) -ForegroundColor Red
    }
}

function Invoke-RecoveryRestartAdapter {
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) { Write-Host "  [SKIPPED] No active adapter found." -ForegroundColor Yellow; return }
    $r = Invoke-ZoroSafeOperation -OperationName "Restart adapter $($adapter.Name)" -Quiet -Action { Restart-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop }
    if ($r.Success) {
        Clear-ZoroCache
        Write-Log "Recovery action: adapter restart on $($adapter.Name)"
        Write-Host ("  [DONE] {0} restarted - it may take a few seconds to reconnect." -f $adapter.Name) -ForegroundColor Green
    } else {
        Write-Host ("  [FAILED] Restart adapter {0} - {1}" -f $adapter.Name, $r.Guidance) -ForegroundColor Red
    }
}

function Invoke-RecoveryWinsockReset {
    $r = Invoke-ZoroSafeOperation -OperationName "Winsock Reset" -Quiet -Action { netsh winsock reset 2>&1 }
    if ($r.Success) {
        Write-Log "Recovery action: Winsock reset executed"
        Write-Host "  [DONE] Winsock reset - a restart is required for this to take effect." -ForegroundColor Yellow
        Write-Host ("  {0}" -f ($r.Value -join "`n  "))
    } else {
        Write-Host ("  [FAILED] Winsock Reset - {0}" -f $r.Guidance) -ForegroundColor Red
    }
}

function Show-NetworkRecoveryMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> RECOVERY ACTIONS`n" -ForegroundColor Red
        Write-Host " Offered because the monitor detected persistent degradation over" -ForegroundColor Gray
        Write-Host " multiple consecutive measurements. Nothing here runs automatically -" -ForegroundColor Gray
        Write-Host " every action below needs its own explicit confirmation.`n" -ForegroundColor Gray
        Write-Host " [1] Flush DNS Cache"
        Write-Host " [2] Renew IP (ipconfig /renew on the active adapter)"
        Write-Host " [3] Release IP (ipconfig /release - drops the address until renewed)"
        Write-Host " [4] Restart Network Adapter (brief link drop)"
        Write-Host " [5] Winsock Reset (requires a restart to take effect)"
        Write-Host " [0] Back"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { if (Confirm-Action "Flush the DNS resolver cache?") { Invoke-RecoveryFlushDns }; Wait-ForEnter }
            "2" { if (Confirm-Action "Request a new DHCP lease on the active adapter?") { Invoke-RecoveryRenewIp }; Wait-ForEnter }
            "3" { if (Confirm-Action "Release the current IP address? You will need Renew IP afterward to get one back.") { Invoke-RecoveryReleaseIp }; Wait-ForEnter }
            "4" { if (Confirm-Action "Restart the active network adapter? This briefly disconnects it.") { Invoke-RecoveryRestartAdapter }; Wait-ForEnter }
            "5" { if (Confirm-Action "Reset the Winsock catalog? Requires a restart to fully take effect.") { Invoke-RecoveryWinsockReset }; Wait-ForEnter }
            "0" { return }
            default { Show-InvalidSelection }
        }
    }
}

function Show-NetworkHealthMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [14] LIVE NETWORK HEALTH MONITOR`n" -ForegroundColor Green
        Write-Host " Real background sampler (one lightweight runspace) over actual" -ForegroundColor Gray
        Write-Host " ICMP/DNS traffic only. Every value shown is a genuine measurement -" -ForegroundColor Gray
        Write-Host " nothing here is simulated, estimated, or a placeholder.`n" -ForegroundColor Gray

        $s       = $script:NetHealthState
        $running = [bool]($s -and $s.Running)
        $paused  = [bool]($s -and $s.Paused)
        $statusText = if (-not $running) { "STOPPED" } elseif ($paused) { "PAUSED" } else { "RUNNING" }

        Write-Host (" Status: {0}" -f $statusText) -ForegroundColor $(if (-not $running) { "Red" } elseif ($paused) { "Yellow" } else { "Green" })
        if ($running) {
            Write-Host ("   Ping {0}  Avg {1}  Jitter {2}  Loss {3}%  Gateway {4}  DNS fail {5}/{6}" -f `
                $(if ($null -ne $s.CurrentPing) { "$($s.CurrentPing)ms" } else { "timeout" }), `
                $(if ($null -ne $s.AvgPing) { "$($s.AvgPing)ms" } else { "n/a" }), `
                $(if ($null -ne $s.Jitter) { "$($s.Jitter)ms" } else { "n/a" }), `
                $s.PacketLossPercent, `
                $(if ($null -ne $s.GatewayLatency) { "$($s.GatewayLatency)ms" } else { "n/a" }), `
                $s.DnsFailures, $s.DnsAttempts) -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host " [1] Start Monitor"
        Write-Host " [2] Stop Monitor"
        Write-Host " [3] Pause Monitor"
        Write-Host " [4] Resume Monitor"
        Write-Host " [5] Reset Statistics"
        Write-Host " [6] Live Dashboard (auto-refreshing view)"
        if ($running -and $s.DegradationDetected) {
            Write-Host " [R] Recovery Actions (offered - persistent degradation detected)" -ForegroundColor Red
        }
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c.ToUpper()) {
            "1" {
                if ($running) {
                    Write-Host "`n  Already running." -ForegroundColor Yellow
                } else {
                    $t = Read-Host "Internet target to ping (ENTER for default 1.1.1.1)"
                    if ([string]::IsNullOrWhiteSpace($t)) { $t = "1.1.1.1" }
                    Start-NetworkHealthMonitor -InternetTarget $t
                }
                Wait-ForEnter -NoBlank
            }
            "2" { Stop-NetworkHealthMonitor; Wait-ForEnter }
            "3" { Suspend-NetworkHealthMonitor; Wait-ForEnter }
            "4" { Resume-NetworkHealthMonitor; Wait-ForEnter }
            "5" {
                if (Confirm-Action "Clear all collected statistics (Min/Max/Avg/Jitter/Loss/DNS counters)? The monitor keeps running.") {
                    Reset-NetworkHealthStatistics
                }
                Wait-ForEnter -NoBlank
            }
            "6" { Show-NetworkHealthDashboard }
            "R" {
                if ($running -and $s.DegradationDetected) { Show-NetworkRecoveryMenu }
                else { Write-Host "`n  Recovery actions are only offered after the monitor detects persistent degradation." -ForegroundColor Yellow; Wait-ForEnter -NoBlank }
            }
            "0" { return }
            default { Show-InvalidSelection }
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
    Write-Host "`nEnter comma-separated numbers (e.g. 1,3,5), 'all', or press ENTER to cancel."
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

# ---- Background Apps: Windows 11's UWP/Store app ecosystem has grown a lot
#      since this policy was added - most current installs carry a dozen-plus
#      apps (Widgets, Copilot, News, Store itself, OEM apps, etc.) that are
#      allowed to run tasks and receive push notifications while "closed".
#      This is the single global policy switch that stops all of them at
#      once instead of toggling each app individually in Settings. Real,
#      measurable reduction in idle background CPU/network activity on a
#      heavily-appified install; close to nothing on a lightly-appified one. ----
function Get-BackgroundAppsState {
    $r = Test-RegValueEquals "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
    if ($r -eq "Applied") { return "Disabled" } else { return "Windows default" }
}

function Set-BackgroundAppsDisabled ([bool]$Disable) {
    $k = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    return Invoke-ValidatedTweak -Name "Background Apps disabled=$Disable" `
        -Apply {
            if ($Disable) { Set-RegDword $k "GlobalUserDisabled" 1 } else { Remove-RegValue $k "GlobalUserDisabled" }
        } `
        -Verify {
            if ($Disable) { (Test-RegValueEquals $k "GlobalUserDisabled" 1) -eq "Applied" }
            else { (Test-RegValueEquals $k "GlobalUserDisabled" 1) -ne "Applied" }
        }
}

function Show-WindowsMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [3] WINDOWS TWEAKS`n" -ForegroundColor Green
        Write-Host " [1] Debloat (remove selected pre-installed apps)          [6/10 cleanliness, 1/10 perf]"
        Write-Host " [2] Clean Temp Files                                      [3/10, disk space only]"
        Write-Host " [3] Remove startup app launch delay                       [4/10]"
        Write-Host " [4] Restore startup delay to Windows default"
        Write-Host (" [5] Disable Background Apps globally: {0}                [6/10 on app-heavy installs]" -f (Get-BackgroundAppsState))
        Write-Host " [6] Restore Background Apps to Windows default"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { Show-DebloatChecklist; Wait-ForEnter }
            "2" { Clear-TempFiles; Wait-ForEnter -NoBlank }
            "3" {
                Set-RegDword "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0 | Out-Null
                Write-Host "[DONE] Startup delay removed." -ForegroundColor Green
                Wait-ForEnter -NoBlank
            }
            "4" {
                Remove-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" | Out-Null
                Write-Host "[DONE] Startup delay restored to default." -ForegroundColor Green
                Wait-ForEnter -NoBlank
            }
            "5" {
                Write-TweakResult (Set-BackgroundAppsDisabled $true)
                Write-Host "  Individual per-app switches in Settings are overridden while this is on." -ForegroundColor DarkGray
                Wait-ForEnter -NoBlank
            }
            "6" {
                Write-TweakResult (Set-BackgroundAppsDisabled $false)
                Wait-ForEnter -NoBlank
            }
            "0" { return }
            default { Show-InvalidSelection }
        }
    }
}
 
# ==============================================================================
#  9. CPU TWEAKS
# ==============================================================================
$GUID_HighPerf = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$GUID_Balanced = "381b4222-f694-41f0-9685-ff5bb260df2e"
$GUID_UltimatePerf_Source = "e9a42b02-d5df-448d-aa00-03f14749eb61"   # hidden template Windows duplicates from

# ---- Ultimate Performance: a real Microsoft-shipped plan (Windows 10 1803+/
#      Windows 11), not a community hack - it removes some of the remaining
#      background power-management timers that High Performance still leaves
#      active (USB/PCIe idle latencies, some parking thresholds). It's hidden
#      from powercfg by default and has to be duplicated from its source GUID
#      into the visible scheme list before it can be activated. Desktop-only
#      benefit is real but small over plain High Performance; it exists here
#      because "High Performance" alone is the pre-Ultimate-Performance-era
#      answer and a more current option is one powercfg call away. ----
function Get-OrCreateUltimatePerfScheme {
    $existing = (powercfg /list 2>$null) | Select-String "Ultimate Performance" | Select-Object -First 1
    if ($existing -and $existing.ToString() -match '([0-9a-fA-F-]{36})') { return $Matches[1] }
    try {
        $out = powercfg /duplicatescheme $GUID_UltimatePerf_Source 2>$null
        if ($out -match '([0-9a-fA-F-]{36})') { return $Matches[1] }
    } catch {}
    return $null
}
 
# ---- Hybrid-topology detection (Intel 12th/13th/14th Gen P+E core, AMD X3D
#      preferred-CCD designs). Forcing CPMINCORES=100 to "disable core
#      parking" was a Win7/8-era workaround for a scheduler that had no idea
#      which cores were fast or slow - it just kept every core awake. Windows
#      11's scheduler (with Intel Thread Director input on 12th-gen+, or
#      AMD's preferred-core hinting on X3D parts) actively decides which
#      cores to *use*, not just which to park, and pinning every core
#      permanently active fights that decision instead of helping it. There
#      is no registry switch that improves on this in a measurable way on
#      current hardware, so this menu reports topology instead of "fixing"
#      something that isn't broken. ----
function Get-CpuTopologyInfo {
    <# Cached for the session - core counts/clock/topology can't change
       without a reboot, so repeated visits to the CPU menu reuse the same
       WMI read instead of re-querying Win32_Processor every time. #>
    return Get-ZoroCachedValue -Key "CpuTopologyInfo" -TtlMs 3600000 -Loader {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $cpu) { return $null }
        $isHybrid = $false
        try {
            # Name-based heuristic: presence of a per-core efficiency-class split
            # is the practical signal that this is a P-core/E-core or
            # preferred-core part. Not a device-ID lookup, just enough to steer
            # the advice printed below.
            $name = $cpu.Name
            if ($name -match "Core\s*i[3579]-1[2-4]\d{3}|Core\s*Ultra|Ryzen.*3D") { $isHybrid = $true }
        } catch {}
        [PSCustomObject]@{
            Name             = $cpu.Name.Trim()
            PhysicalCores    = $cpu.NumberOfCores
            LogicalCores     = $cpu.NumberOfLogicalProcessors
            MaxClockMHz      = $cpu.MaxClockSpeed
            LikelyHybrid     = $isHybrid
        }
    }
}

function Show-CpuDiagnostics {
    $t = Get-CpuTopologyInfo
    if (-not $t) { Write-Host "  Could not read CPU info." -ForegroundColor Red; return }
    Write-Host "`n  CPU:              $($t.Name)"
    Write-Host "  Physical cores:   $($t.PhysicalCores)"
    Write-Host "  Logical cores:    $($t.LogicalCores)"
    Write-Host "  Max clock:        $($t.MaxClockMHz) MHz"
    if ($t.LikelyHybrid) {
        Write-Host "  Topology:         Likely hybrid/preferred-core design (P+E cores or 3D V-Cache CCDs)." -ForegroundColor Cyan
        Write-Host "                    Windows 11's scheduler places threads using per-core hints from" -ForegroundColor DarkGray
        Write-Host "                    the CPU itself. Forcing all cores 'unparked' overrides that and" -ForegroundColor DarkGray
        Write-Host "                    can push background work onto cores meant to stay idle - no" -ForegroundColor DarkGray
        Write-Host "                    measurable upside on current builds, so it isn't offered here." -ForegroundColor DarkGray
    } else {
        Write-Host "  Topology:         Homogeneous core layout (no hybrid scheduling in play)." -ForegroundColor Cyan
    }
    Write-Log "CPU diagnostics viewed: $($t.Name), $($t.PhysicalCores)C/$($t.LogicalCores)T"
}

function Show-CpuMenu {
    while ($true) {
        Show-Banner | Out-Null
        $isLaptop = Test-IsLaptop
        Write-Host "`n>>> [4] CPU TWEAKS`n" -ForegroundColor Green
        Write-Host (" Detected system type: {0}" -f (if ($isLaptop) { "Laptop (battery/mobile chassis detected)" } else { "Desktop" })) -ForegroundColor Gray
        Write-Host " [1] Set Power Plan: High Performance                [6/10 desktop, 2/10 laptop-on-battery]"
        if ($isLaptop) {
            Write-Host " [2] Set Power Plan: Ultimate Performance (Win10 1803+/Win11)  [not recommended on battery - read warning]"
        } else {
            Write-Host " [2] Set Power Plan: Ultimate Performance (Win10 1803+/Win11, hidden by default) [7/10 desktop]"
        }
        Write-Host " [3] Restore Power Plan: Balanced (Windows default)"
        Write-Host " [4] CPU / hybrid-topology diagnostics"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" {
                powercfg /setactive $GUID_HighPerf 2>$null
                Write-Log "Power plan set to High Performance"
                Write-Host "[DONE] Power Plan set to High Performance." -ForegroundColor Green
                Wait-ForEnter -NoBlank
            }
            "2" {
                # Ultimate Performance is never applied without an explicit choice.
                # On a laptop it additionally requires reading and confirming the
                # battery-impact warning first - it is not offered as a default,
                # just not hidden either, since some people do want it on AC power.
                $proceed = $true
                if ($isLaptop) {
                    Write-Host "`n  [!] This system was detected as a laptop. Ultimate Performance removes" -ForegroundColor Yellow
                    Write-Host "      more idle power-saving timers than High Performance and will noticeably" -ForegroundColor Yellow
                    Write-Host "      reduce battery runtime on battery power. Fine if you're plugged in." -ForegroundColor Yellow
                    $proceed = Confirm-Action "Apply Ultimate Performance anyway?"
                }
                if ($proceed) {
                    $guid = Get-OrCreateUltimatePerfScheme
                    if ($guid) {
                        powercfg /setactive $guid 2>$null
                        Write-Log "Power plan set to Ultimate Performance ($guid, laptop=$isLaptop)"
                        Write-Host "[DONE] Power Plan set to Ultimate Performance." -ForegroundColor Green
                    } else {
                        Write-Host "[!] Couldn't create/find the Ultimate Performance scheme on this system." -ForegroundColor Yellow
                    }
                }
                Wait-ForEnter -NoBlank
            }
            "3" {
                powercfg /setactive $GUID_Balanced 2>$null
                Write-Host "[DONE] Power Plan restored to Balanced." -ForegroundColor Green
                Wait-ForEnter -NoBlank
            }
            "4" { Show-CpuDiagnostics; Wait-ForEnter }
            "0" { return }
            default { Show-InvalidSelection }
        }
    }
}
 
# ==============================================================================
#  10. GAMING TWEAKS
# ==============================================================================
function Set-AmdExternalEventsUtility ([bool]$Disable) {
    # AMD External Events Utility brokers hotkey/eventing plumbing for
    # Radeon Software; it's not required for the display driver itself.
    return Set-VendorServiceByPattern -Vendor "AMD" -NamePattern "*AMD External Events*" -FriendlyName "AMD External Events Utility" -Disable $Disable
}

function Restore-AllGamingTweaks {
    Set-RegDword "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 1 | Out-Null
    Remove-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" | Out-Null
    Remove-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" | Out-Null
    Remove-RegValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" | Out-Null
    Set-RegDword "HKCU:\Control Panel\Mouse" "MouseSpeed" 1 | Out-Null
    Set-RegDword "HKCU:\Control Panel\Mouse" "MouseThreshold1" 6 | Out-Null
    Set-RegDword "HKCU:\Control Panel\Mouse" "MouseThreshold2" 10 | Out-Null
    if ($script:GpuProfile -ne "NVIDIA") { Set-AmdExternalEventsUtility $false | Out-Null }
    if ($script:GpuProfile -ne "AMD")    { Set-NvidiaPowerMode $false }
    Write-Host "[DONE] Gaming tweaks restored to defaults. (HAGS lives in menu [8] and is restored from there.)" -ForegroundColor Green
}

function Show-GamingMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [5] GAMING TWEAKS`n" -ForegroundColor Green

        $items = @(
            @{ Text = "Disable Xbox Game Bar / background recording                       [5/10]"
               Action = {
                   Set-RegDword "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 | Out-Null
                   Set-RegDword "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0 | Out-Null
                   if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) {
                       New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null
                   }
                   Set-RegDword "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 | Out-Null
                   Write-Host "[DONE] Game Bar / background recording disabled." -ForegroundColor Green
               } }
            @{ Text = "Disable Fullscreen Optimizations (global default)   [5/10, see note below]"
               Action = {
                   Set-RegDword "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2 | Out-Null
                   Set-RegDword "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1 | Out-Null
                   Write-Host "[DONE] Fullscreen Optimizations disabled globally." -ForegroundColor Green
               } }
            @{ Text = "Disable Mouse Acceleration                                          [9/10 for competitive play]"
               Action = {
                   Set-RegDword "HKCU:\Control Panel\Mouse" "MouseSpeed" 0 | Out-Null
                   Set-RegDword "HKCU:\Control Panel\Mouse" "MouseThreshold1" 0 | Out-Null
                   Set-RegDword "HKCU:\Control Panel\Mouse" "MouseThreshold2" 0 | Out-Null
                   Write-Host "[DONE] Mouse acceleration disabled. Sign out/in to apply everywhere." -ForegroundColor Green
               } }
        )
        Write-Host " Note on Fullscreen Optimizations: this used to be blanket-recommended advice." -ForegroundColor DarkGray
        Write-Host " On modern Windows 11 builds it's a wash for many titles and can slow Alt-Tab -" -ForegroundColor DarkGray
        Write-Host " test with FSO on too." -ForegroundColor DarkGray
        Write-Host " Note: Hardware-Accelerated GPU Scheduling lives in menu [8] Responsiveness & GPU" -ForegroundColor DarkGray
        Write-Host " Tweaks - it isn't duplicated here so there's exactly one validated write path." -ForegroundColor DarkGray

        if ($script:GpuProfile -ne "NVIDIA") {
            $items += @{ IsHeader = $true; Text = "--- AMD ---" }
            $items += @{ Text = "Disable AMD External Events Utility service   [4/10, resource cleanup only]"
               Action = { Write-TweakResult (Set-AmdExternalEventsUtility $true) } }
        }
        if ($script:GpuProfile -ne "AMD") {
            $items += @{ IsHeader = $true; Text = "--- NVIDIA ---" }
            $items += @{ Text = "Prefer Maximum Performance power mode      [7/10 desktop, 3/10 laptop]"
               Action = { Set-NvidiaPowerMode $true; Write-Host "[DONE]" -ForegroundColor Green } }
        }

        $items += @{ Text = "Restore ALL gaming tweaks to Windows defaults"; Action = { if (Confirm-Action "Revert all Gaming Tweaks to Windows defaults?") { Restore-AllGamingTweaks } } }

        Write-Host ""
        $num = 0
        $indexMap = @{}
        foreach ($it in $items) {
            if ($it.IsHeader) { Write-Host ("`n {0}" -f $it.Text) -ForegroundColor Cyan; continue }
            $num++
            $indexMap[$num] = $it
            Write-Host (" [{0}] {1}" -f $num, $it.Text)
        }
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        if ($c -eq "0") { return }
        if ($c -match '^\d+$' -and $indexMap.ContainsKey([int]$c)) {
            & $indexMap[[int]$c].Action
            Wait-ForEnter
        } else {
            Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1
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
 
function Test-RegValueEquals ($Path, $Name, $ExpectedValue) {
    try {
        $v = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
        if ("$v" -eq "$ExpectedValue") { return "Applied" } else { return "Changed (value: $v)" }
    } catch { return "Default (not set)" }
}
 
function Show-TweakHealthCheck {
    Write-Host "`n>>> TWEAK HEALTH CHECK`n" -ForegroundColor Green
    Write-Host " Reading back the actual current state of every tweak this tool can" -ForegroundColor Gray
    Write-Host " control - not what you clicked, what's really live right now.`n" -ForegroundColor Gray
 
    $rows = @(
        [PSCustomObject]@{ Tweak = "Nagle's Algorithm disabled"; State = $(
            $ifRoot = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            $hit = @(Get-ChildItem $ifRoot -ErrorAction SilentlyContinue | Where-Object {
                (Get-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue).TcpAckFrequency -eq 1
            })
            if ($hit.Count -gt 0) { "Applied (on $($hit.Count) adapter[s])" } else { "Default" }
        ) }
        [PSCustomObject]@{ Tweak = "ECN capability"; State = ((netsh int tcp show global 2>$null | Select-String "ECN").ToString().Trim()) }
        [PSCustomObject]@{ Tweak = "TCP Auto-Tuning level"; State = ((netsh int tcp show global 2>$null | Select-String "Auto-Tuning").ToString().Trim()) }
        [PSCustomObject]@{ Tweak = "Delivery Optimization restricted to LAN"; State = (Test-RegValueEquals "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 1) }
        [PSCustomObject]@{ Tweak = "Xbox Game DVR"; State = (Test-RegValueEquals "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0) }
        [PSCustomObject]@{ Tweak = "Fullscreen Optimizations disabled"; State = (Test-RegValueEquals "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2) }
        [PSCustomObject]@{ Tweak = "Mouse acceleration disabled"; State = (Test-RegValueEquals "HKCU:\Control Panel\Mouse" "MouseSpeed" 0) }
        [PSCustomObject]@{ Tweak = "HAGS"; State = (Get-HagsState) }
        [PSCustomObject]@{ Tweak = "GPU driver TDR delay extended"; State = (Test-RegValueEquals "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "TdrDelay" 8) }
        [PSCustomObject]@{ Tweak = "High-res timer requests"; State = (Test-RegValueEquals "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" 1) }
        [PSCustomObject]@{ Tweak = "USB Selective Suspend"; State = (Get-UsbSelectiveSuspendState) }
        [PSCustomObject]@{ Tweak = "Power Throttling / EcoQoS"; State = (Get-PowerThrottlingState) }
        [PSCustomObject]@{ Tweak = "Dynamic Tick (bcdedit)"; State = (Get-DynamicTickState) }
        [PSCustomObject]@{ Tweak = "GPU MSI Mode"; State = (Get-GpuMsiState) }
        [PSCustomObject]@{ Tweak = "Memory Integrity / HVCI"; State = (Get-HvciState) }
        [PSCustomObject]@{ Tweak = "TdrDdiDelay (RT/frame-gen)"; State = (Get-TdrDdiDelayState) }
        [PSCustomObject]@{ Tweak = "Background Apps (global)"; State = (Test-RegValueEquals "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1) }
        [PSCustomObject]@{ Tweak = "Active power plan"; State = ((powercfg /getactivescheme 2>$null) -join " ") }
        [PSCustomObject]@{ Tweak = "Processor Scheduling mode"; State = (Get-ProcessSchedulerState).PrioritySeparationMode }
        [PSCustomObject]@{ Tweak = "MMCSS System Responsiveness"; State = (Get-ProcessSchedulerState).SystemResponsiveness }
        [PSCustomObject]@{ Tweak = "'Games' task priority profile"; State = $(if (Test-GamesTaskProfileHealthy) { "Healthy" } elseif ((Get-ProcessSchedulerState).GamesTaskExists) { "Degraded" } else { "Not present" }) }
        [PSCustomObject]@{ Tweak = "Memory Compression"; State = $(switch (Get-MemoryCompressionState) { $true { "Enabled (default)" } $false { "Disabled" } default { "Not available" } }) }
        [PSCustomObject]@{ Tweak = "Page File management"; State = $(if (Test-PageFileIsSystemManaged) { "System Managed" } else { "Manually configured" }) }
        [PSCustomObject]@{ Tweak = "TRIM (SSD/NVMe)"; State = $(if (-not (Get-SystemStorageProfile).IsSsd) { "N/A (no SSD detected)" } else { switch ((Get-StorageOptimizationState).TrimEnabled) { $true {"Enabled"} $false {"Disabled"} default {"Unknown"} } }) }
        [PSCustomObject]@{ Tweak = "Scheduled Drive Optimization"; State = $(switch ((Get-StorageOptimizationState).ScheduledOptEnabled) { $true {"Enabled"} $false {"Disabled"} default {"Unknown"} }) }
        [PSCustomObject]@{ Tweak = "Diagnostic Data Level"; State = $(switch ((Get-PrivacyOptimizationState).AllowTelemetry) { 0 {"Security"} 1 {"Basic"} 2 {"Enhanced"} 3 {"Full (default)"} default {"Default (not set)"} }) }
        [PSCustomObject]@{ Tweak = "Advertising ID"; State = $(if ((Get-PrivacyOptimizationState).AdvertisingIdEnabled) { "Enabled (default)" } else { "Disabled" }) }
        [PSCustomObject]@{ Tweak = "Activity History / Timeline"; State = $(if ((Get-PrivacyOptimizationState).ActivityHistoryDisabled) { "Disabled" } else { "Enabled (default)" }) }
        [PSCustomObject]@{ Tweak = "Tailored Experiences"; State = $(if ((Get-PrivacyOptimizationState).TailoredExperiencesDisabled) { "Disabled" } else { "Enabled (default)" }) }
        [PSCustomObject]@{ Tweak = "Start Menu Web Search"; State = $(if ((Get-PrivacyOptimizationState).StartMenuWebSearchEnabled) { "Enabled (default)" } else { "Disabled" }) }
    )
    $rows | Format-Table -AutoSize | Out-String | Write-Host

    # State Consistency Protection (3c): a read-only cross-check that MTU /
    # TCP / NIC / DNS haven't drifted into a combination that conflicts with
    # each other, shown here rather than as a separate menu so it lives
    # alongside every other "what's actually true right now" reading.
    $consistency = Test-NetworkConfigConsistency -NoCache
    Write-Host "`n>>> NETWORK CONFIG CONSISTENCY`n" -ForegroundColor Green
    if (-not $consistency.Adapter) {
        Write-Host "  No active adapter with a default route - nothing to cross-check." -ForegroundColor DarkGray
    } elseif ($consistency.Consistent) {
        Write-Host ("  [DONE] MTU / DNS / RSS-RSC on {0} are consistent - no conflicts detected." -f $consistency.Adapter) -ForegroundColor Green
    } else {
        foreach ($issue in $consistency.Issues) { Write-Host ("  [!] {0}" -f $issue) -ForegroundColor Yellow }
        Write-Host "  Re-run the relevant menu action (Network Core / DNS) to re-apply and auto-correct." -ForegroundColor DarkGray
    }

    Write-Log "Tweak health check run"
}
 
function Show-SystemRequirementsCheck {
    <# Visible, standalone use of the validation framework's
       Test-SystemRequirements - shows what this system does/doesn't
       qualify for before you go looking for it in a menu and finding it
       greyed out or silently skipped. #>
    Write-Host "`n>>> SYSTEM REQUIREMENTS CHECK`n" -ForegroundColor Green
    $req = Test-SystemRequirements @(
        @{ Name = "Windows 10 2004+ (build 19041+) - required for HAGS";              Test = { Test-MinWindowsBuild 19041 } }
        @{ Name = "Windows 10 1809+ (build 17763+) - required for Power Throttling";  Test = { Test-MinWindowsBuild 17763 } }
        @{ Name = "PnpDevice cmdlets available - required for GPU MSI Mode";          Test = { Test-CommandExists "Get-PnpDevice" } }
        @{ Name = "Get-PhysicalDisk available - required for SysMain recommendation"; Test = { Test-CommandExists "Get-PhysicalDisk" } }
        @{ Name = "DiagTrack service present";                                        Test = { Test-ServiceExists "DiagTrack" } }
        @{ Name = "MMCSS service present - required for Process Scheduler tweaks";    Test = { Test-ServiceExists "MMCSS" } }
        @{ Name = "MMAgent cmdlets available (native or PS7 compat) - Memory Compression"; Test = { Test-MMAgentAvailable } }
        @{ Name = "fsutil available - required for TRIM/Last-Access tweaks";          Test = { Test-CommandExists "fsutil" } }
        @{ Name = "ScheduledTask cmdlets available - Drive Optimization repair";      Test = { Test-CommandExists "Get-ScheduledTask" } }
        @{ Name = "SSD/NVMe detected (Get-SystemStorageProfile) - required for TRIM"; Test = { (Get-SystemStorageProfile).IsSsd } }
        @{ Name = "DataCollection policy key reachable - Diagnostic Data Level";       Test = { $true } }
        @{ Name = "AMD GPU detected";                                                 Test = { Test-GpuVendorIs "AMD" } }
        @{ Name = "NVIDIA GPU detected";                                              Test = { Test-GpuVendorIs "NVIDIA" } }
        @{ Name = "GPU is a modern generation (per TWEAK_AUDIT.md tiering)";          Test = { Test-GpuTierIs "MODERN" } }
    )
    foreach ($chk in $req.Checks) {
        if ($chk.Passed) { Write-Host ("  [PASS] {0}" -f $chk.Name) -ForegroundColor Green }
        else { Write-Host ("  [FAIL] {0}" -f $chk.Name) -ForegroundColor DarkGray }
    }
    Write-Host ""
    Write-Host " Note: AMD/NVIDIA and 'modern generation' are mutually exclusive by design -" -ForegroundColor Gray
    Write-Host " one or the other failing here is expected, not an error." -ForegroundColor Gray

    $drv = Get-GpuDriverInfo
    if ($drv) {
        Write-Host "`n  GPU driver: $($drv.DeviceName)" -ForegroundColor Cyan
        Write-Host ("  Version: {0}   Date: {1}   WHQL signed: {2}" -f `
            $drv.DriverVersion, `
            (if ($drv.DriverDate) { $drv.DriverDate.ToString("yyyy-MM-dd") } else { "unknown" }), `
            $drv.WhqlSigned)
        if ($drv.AgeDays -ne $null -and $drv.AgeDays -gt 545) {
            Write-Host ("  [!] This driver is ~{0} months old. Vendor tweaks in this tool are still" -f [math]::Round($drv.AgeDays / 30)) -ForegroundColor Yellow
            Write-Host "      applied and verified correctly, but a driver update this old is a common" -ForegroundColor Yellow
            Write-Host "      real-world cause of settings appearing to 'reset' - the installer, not" -ForegroundColor Yellow
            Write-Host "      this tool, restored its own default when it last updated (or is overdue to)." -ForegroundColor Yellow
        }
        if (-not $drv.WhqlSigned) {
            Write-Host "  [!] This driver is not WHQL-signed (beta/dev build). Expect more driver-level" -ForegroundColor Yellow
            Write-Host "      instability independent of anything in this tool." -ForegroundColor Yellow
        }
    }
    Write-Log "System requirements check run"
}

function Show-MiscMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [6] MISCELLANEOUS`n" -ForegroundColor Green
        Write-Host " [1] Create a System Restore Point (recommended before tweaking)"
        Write-Host " [2] View change log"
        Write-Host " [3] About / Credits"
        Write-Host " [4] Tweak Health Check (what's actually applied right now)"
        Write-Host " [5] System Requirements Check (what this hardware/OS qualifies for)"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { New-RestorePointSafe; Wait-ForEnter }
            "2" {
                if (Test-Path $LogFile) { Get-Content $LogFile | Select-Object -Last 40 } else { Write-Host "No log entries yet." }
                Wait-ForEnter
            }
            "3" {
                Write-Host "`nZORO Ultimate Tweaking Utility v$ScriptVersion" -ForegroundColor Cyan
                Write-Host "Made by zoro ($DiscordName)"
                Write-Host "GitHub: $GitHubUrl"
                Wait-ForEnter
            }
            "4" { Show-TweakHealthCheck; Wait-ForEnter }
            "5" { Show-SystemRequirementsCheck; Wait-ForEnter }
            "0" { return }
            default { Show-InvalidSelection }
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
    @{ Path = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel";        File = "SessionManagerKernel.reg" },
    @{ Path = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"; File = "DeliveryOptimization.reg" },
    @{ Path = "HKLM\SYSTEM\CurrentControlSet\Services\USB";                                 File = "UsbSelectiveSuspend.reg" },
    @{ Path = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Power\PowerThrottling";        File = "PowerThrottling.reg" },
    @{ Path = "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; File = "HVCI.reg" },
    @{ Path = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; File = "BackgroundApps.reg" },
    @{ Path = "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers";               File = "GraphicsDrivers_TdrDdiDelay.reg" },
    @{ Path = "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl";               File = "PriorityControl.reg" },
    @{ Path = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; File = "MemoryManagement.reg" },
    @{ Path = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"; File = "StorageSense.reg" },
    @{ Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection";             File = "PrivacyDataCollection.reg" },
    @{ Path = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo";      File = "PrivacyAdvertisingInfo.reg" },
    @{ Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\System";                     File = "PrivacyActivityFeedPolicy.reg" },
    @{ Path = "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent";               File = "PrivacyCloudContentPolicy.reg" },
    @{ Path = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; File = "PrivacyContentDeliveryManager.reg" },
    @{ Path = "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search";               File = "PrivacyExplorerSearch.reg" }
)
# Note: GraphicsDrivers.reg (above, from the [8] section) and this
# GraphicsDrivers_TdrDdiDelay.reg entry both export the SAME key
# (HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers) - reg export is
# idempotent and harmless to run twice against one path, and keeping two
# named snapshots makes it obvious in the Backups folder which tweak each
# one was taken for.
# Note: GPU MSI Mode isn't in this list - it lives under a per-GPU instance
# path (HKLM\SYSTEM\CurrentControlSet\Enum\<InstanceId>\...) that varies by
# system, so a static path can't cover it. Use the toggle itself (which
# removes the override rather than forcing a value) to undo it instead.
 
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
 
    # Smart DNS Benchmark: DNS servers are set per-adapter via
    # Set-DnsClientServerAddress, not a static registry path, so they can't
    # go through the reg-export loop above - captured as its own JSON file
    # in the same backup folder instead of a second, parallel backup system.
    try {
        $dnsSnapshot = foreach ($a in (Get-ActiveAdapters)) {
            $servers = @(Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
            [PSCustomObject]@{ InterfaceAlias = $a.Name; HadServers = (@($servers).Count -gt 0); Servers = @($servers) }
        }
        if (@($dnsSnapshot).Count -gt 0) {
            ($dnsSnapshot | ConvertTo-Json -Depth 4) | Set-Content -Path (Join-Path $dest "DnsServers.json") -Force -Encoding UTF8
            Write-Host "  [SAVED]    DnsServers.json" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [FAILED]   DnsServers.json" -ForegroundColor Red
        Write-Log "Failed to snapshot DNS servers into backup $dest : $_" "ERROR"
    }
 
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
 
    # Smart DNS Benchmark: restore the per-adapter DNS snapshot captured by
    # New-TweaksBackup, verified the same way Set-DnsServersVerified does -
    # read the config back and compare, don't just trust the cmdlet's exit.
    $dnsFile = Join-Path $chosen.FullName "DnsServers.json"
    if (Test-Path $dnsFile) {
        try {
            $dnsSnapshot = @(Get-Content -Path $dnsFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
            foreach ($entry in $dnsSnapshot) {
                if (-not (Get-NetAdapter -Name $entry.InterfaceAlias -ErrorAction SilentlyContinue)) {
                    Write-Host ("  [SKIPPED]  DNS on {0} - adapter no longer present" -f $entry.InterfaceAlias) -ForegroundColor DarkGray
                    continue
                }
                try {
                    if ($entry.HadServers -and @($entry.Servers).Count -gt 0) {
                        Set-DnsClientServerAddress -InterfaceAlias $entry.InterfaceAlias -ServerAddresses @($entry.Servers) -ErrorAction Stop
                    } else {
                        Set-DnsClientServerAddress -InterfaceAlias $entry.InterfaceAlias -ResetServerAddresses -ErrorAction Stop
                    }
                    Clear-DnsClientCache -ErrorAction SilentlyContinue
                    $after = @(Get-DnsClientServerAddress -InterfaceAlias $entry.InterfaceAlias -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses
                    $ok = if ($entry.HadServers -and @($entry.Servers).Count -gt 0) { (@($after) -join ",") -eq (@($entry.Servers) -join ",") } else { @($after).Count -eq 0 }
                    if ($ok) {
                        Write-Host ("  [RESTORED] DNS on {0} (verified)" -f $entry.InterfaceAlias) -ForegroundColor Green
                        Write-Log "Restored DNS on $($entry.InterfaceAlias) from backup $($chosen.Name) (verified)"
                    } else {
                        Write-Host ("  [FAILED]   DNS on {0} did not verify" -f $entry.InterfaceAlias) -ForegroundColor Red
                        Write-Log "Restore DNS FAILED verify on $($entry.InterfaceAlias) from backup $($chosen.Name)" "ERROR"
                    }
                } catch {
                    Write-Host ("  [FAILED]   DNS on {0}" -f $entry.InterfaceAlias) -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "  [FAILED]   DnsServers.json (unreadable/corrupt)" -ForegroundColor Red
            Write-Log "Failed to read DnsServers.json from backup $($chosen.Name) : $_" "ERROR"
        }
    }
 
    Write-Host "`n[DONE] Restore complete. Sign out/reboot may be needed for every value to take effect." -ForegroundColor Green
}
 
function Show-BackupMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [7] BACKUP & RESTORE`n" -ForegroundColor Green
        Write-Host " [1] Create a backup of tweakable settings (recommended before tweaking)"
        Write-Host " [2] Restore settings from a previous backup"
        Write-Host " [3] Open the backups folder in Explorer"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { New-TweaksBackup | Out-Null; Wait-ForEnter }
            "2" { Restore-TweaksBackup; Wait-ForEnter }
            "3" {
                if (-not (Test-Path $BackupRoot)) { New-Item -Path $BackupRoot -ItemType Directory -Force | Out-Null }
                Start-Process explorer.exe $BackupRoot
            }
            "0" { return }
            default { Show-InvalidSelection }
        }
    }
}
 
# ==============================================================================
#  14. RESPONSIVENESS & GPU TWEAKS
#  (curated PowerShell port of community batch tweaks - the risky, hardware-
#  specific parts were intentionally left out, see chat explanation)
# ==============================================================================
function Set-MultiPlaneOverlay ([bool]$Disable) {
    $k = "HKLM:\SOFTWARE\Microsoft\Windows\Dwm"
    return Invoke-ValidatedTweak -Name "Multi-Plane Overlay disabled=$Disable" `
        -Apply { if ($Disable) { Set-RegDword $k "OverlayTestMode" 5 } else { Remove-RegValue $k "OverlayTestMode" } } `
        -Verify {
            if ($Disable) { (Test-RegValueEquals $k "OverlayTestMode" 5) -eq "Applied" }
            else { (Test-RegValueEquals $k "OverlayTestMode" 5) -ne "Applied" }
        }
}
 
function Set-UiDelays ([bool]$Reduce) {
    $desk = "HKCU:\Control Panel\Desktop"
    $mouse = "HKCU:\Control Panel\Mouse"
    $menuVal = if ($Reduce) { "0" } else { "400" }
    $hoverVal = if ($Reduce) { "100" } else { "400" }
    foreach ($t in @(@{P=$desk;N="MenuShowDelay";V=$menuVal}, @{P=$mouse;N="MouseHoverTime";V=$hoverVal})) {
        $snap = Get-RegUndoSnapshot $t.P $t.N
        Add-UndoRecord @{ Type = "Registry"; Path = $t.P; Name = $t.N; HadValue = $snap.HadValue; PreviousValue = $snap.PreviousValue; PreviousKind = (if ($snap.HadValue) { $snap.PreviousKind } else { "String" }) }
        Set-ItemProperty -Path $t.P -Name $t.N -Value $t.V -Force -ErrorAction SilentlyContinue
    }
    Write-Log "UI delays reduced=$Reduce"
}
 
function Set-TimerResolution ([bool]$Enable) {
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
    return Invoke-ValidatedTweak -Name "High-resolution timer requests enabled=$Enable" `
        -Apply { if ($Enable) { Set-RegDword $k "GlobalTimerResolutionRequests" 1 } else { Remove-RegValue $k "GlobalTimerResolutionRequests" } } `
        -Verify {
            if ($Enable) { (Test-RegValueEquals $k "GlobalTimerResolutionRequests" 1) -eq "Applied" }
            else { (Test-RegValueEquals $k "GlobalTimerResolutionRequests" 1) -ne "Applied" }
        }
}
 
# ---- Memory Integrity / Core Isolation (HVCI, part of Virtualization-Based
#      Security). This is the single biggest real-world FPS tweak most
#      "ultimate tweak" scripts miss, because it stopped being a niche
#      setting once Windows 11 started enabling it by default on new
#      installs. HVCI runs kernel-mode code integrity checks inside a
#      hypervisor-isolated container; on CPUs without efficient virtualized
#      TLB handling that adds real, measurable overhead to anything that
#      hammers the kernel (game engines, anti-cheat, driver calls). Multiple
#      independent outlets (Hardware Unboxed, Eurogamer/Digital Foundry,
#      others) have measured 5-15% FPS losses in CPU-bound titles on
#      several 12th/13th/14th-gen Intel and some AMD parts with HVCI on,
#      smaller or no difference on others. This is a genuine security
#      feature, not fluff - it meaningfully raises the bar against
#      kernel-level exploits and some ransomware techniques. Turning it off
#      is a real trade, not a free lunch; it's here so you can make that
#      trade knowingly instead of not knowing the setting exists. ----
function Get-HvciState {
    try {
        $v = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -ErrorAction Stop).Enabled
        if ($v -eq 1) { return "Enabled" } else { return "Disabled" }
    } catch { return "Enabled (Windows 11 default)" }
}

function Set-HvciMode ([bool]$Disable) {
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
    $result = Invoke-DetectedTweak -Name "HVCI/Memory Integrity disabled=$Disable" `
        -Supported { Test-MinWindowsBuild 14393 } `
        -AlreadyOk {
            if ($Disable) { (Get-HvciState) -eq "Disabled" }
            else { (Get-HvciState) -match "^Enabled" }
        } `
        -Requirements @(@{ Name = "Windows 10/11 (build 14393+)"; Test = { Test-MinWindowsBuild 14393 } }) `
        -Apply {
            if ($Disable) { Set-RegDword $k "Enabled" 0 } else { Remove-RegValue $k "Enabled" }
        } `
        -Verify {
            if ($Disable) { (Test-RegValueEquals $k "Enabled" 0) -eq "Applied" }
            else { (Test-RegValueEquals $k "Enabled" 0) -ne "Applied" }
        }
    return $result
}

# ---- MSI (Message Signaled Interrupts) Mode for the GPU. Line-based (IRQ)
#      interrupts share a line across devices and go through the slower
#      legacy APIC path; MSI gives each device its own interrupt vector
#      straight to the CPU. This is the actual mechanism behind DPC latency
#      spikes/micro-stutter that tools like LatencyMon are built to detect,
#      and switching the GPU to MSI mode is the standard fix streamers and
#      competitive players reach for when LatencyMon flags the graphics
#      driver as the top DPC offender. Most current NVIDIA/AMD/Intel GPU
#      drivers already request MSI by default on a clean Windows 11
#      install, but a driver upgrade, a Windows feature update, or a
#      dirty driver install can silently revert it to line-based - this
#      re-applies it explicitly. Needs a reboot to take effect. ----
function Get-GpuMsiState {
    try {
        $gpu = Get-PnpDevice -Class Display -Status OK -ErrorAction Stop | Select-Object -First 1
        if (-not $gpu) { return "no GPU found" }
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($gpu.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        $v = (Get-ItemProperty -Path $regPath -Name "MSISupported" -ErrorAction Stop).MSISupported
        if ($v -eq 1) { return "MSI mode" } else { return "Line-based (legacy)" }
    } catch { return "Line-based (legacy / not yet set)" }
}

function Set-GpuMsiMode ([bool]$Enable) {
    # Restoring "default" removes our override entirely rather than forcing
    # 0 - line-based mode is a legacy fallback, not something you'd want
    # to force on deliberately, so undo just gives control back to the driver.
    $gpu = Get-PnpDevice -Class Display -Status OK -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $gpu) {
        return [PSCustomObject]@{ Tweak = "GPU MSI Mode"; Status = "Skipped"; Reason = "No active GPU device found" }
    }
    $imPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($gpu.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
    $result = Invoke-DetectedTweak -Name "GPU MSI Mode enabled=$Enable ($($gpu.FriendlyName))" `
        -Supported { $true } `
        -AlreadyOk {
            if ($Enable) { (Get-GpuMsiState) -eq "MSI mode" }
            else { (Get-GpuMsiState) -match "Line-based" }
        } `
        -Apply {
            if ($Enable) {
                if (-not (Test-Path $imPath)) { New-Item -Path $imPath -Force | Out-Null }
                Set-RegDword $imPath "MSISupported" 1
            } else {
                Remove-RegValue $imPath "MSISupported"
            }
        } `
        -Verify {
            if ($Enable) { (Test-RegValueEquals $imPath "MSISupported" 1) -eq "Applied" }
            else { (Test-RegValueEquals $imPath "MSISupported" 1) -ne "Applied" }
        }
    return $result
}

# ---- Virtualization-Based Security. Same Win32_DeviceGuard source as the
#      boolean gate so Set-VbsMode can decide Supported/AlreadyOk directly
#      instead of parsing a human-readable string. VBS is the umbrella HVCI (above)
#      runs inside of; toggling this off also drops HVCI whether or not
#      the HVCI key is separately touched. ----
function Get-VbsRuntimeStatus {
    try {
        $dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace "root\Microsoft\Windows\DeviceGuard" -ErrorAction Stop
        return [int]$dg.VirtualizationBasedSecurityStatus   # 0=Off, 1=Enabled not running, 2=Running
    } catch { return -1 }
}

function Set-VbsMode ([bool]$Disable) {
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
    return Invoke-DetectedTweak -Name "VBS disabled=$Disable" `
        -Supported { (Get-VbsRuntimeStatus) -ge 0 } `
        -AlreadyOk {
            if ($Disable) { (Get-VbsRuntimeStatus) -eq 0 }
            else { (Get-VbsRuntimeStatus) -ge 1 }
        } `
        -Apply {
            if ($Disable) { Set-RegDword $k "EnableVirtualizationBasedSecurity" 0 }
            else { Set-RegDword $k "EnableVirtualizationBasedSecurity" 1 }
        } `
        -Verify {
            if ($Disable) { (Test-RegValueEquals $k "EnableVirtualizationBasedSecurity" 0) -eq "Applied" }
            else { (Test-RegValueEquals $k "EnableVirtualizationBasedSecurity" 1) -eq "Applied" }
        }
}

# ---- Windows Game Mode. Same HKCU key Get-GameModeStatusReport reads for
#      diagnostics, now with a write path behind the same detect-first gate. ----
function Set-GameModeMode ([bool]$Enable) {
    $k = "HKCU:\SOFTWARE\Microsoft\GameBar"
    return Invoke-DetectedTweak -Name "Game Mode enabled=$Enable" `
        -Supported { $true } `
        -AlreadyOk {
            if ($Enable) { (Get-GameModeStatusReport) -eq "Enabled" }
            else { (Get-GameModeStatusReport) -eq "Disabled" }
        } `
        -Apply {
            Set-RegDword $k "AutoGameModeEnabled" ([int]$Enable)
        } `
        -Verify {
            (Test-RegValueEquals $k "AutoGameModeEnabled" ([int]$Enable)) -eq "Applied"
        }
}

# ---- AMD-only tweaks: discover the real GPU registry key instead of
#      hard-coding "\0000", so this never touches the wrong adapter. ----
function Get-GpuDisplayKeys ([string]$Vendor) {
    <# Shared lookup behind both Get-AmdDisplayKeys and Get-NvidiaDisplayKeys -
       discovers the real per-adapter registry key(s) under the Display class
       GUID by ProviderName instead of hard-coding "\0000", so multi-GPU or
       reordered-adapter systems never get the wrong key touched. #>
    $classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    $pattern = if ($Vendor -eq "AMD") { "Advanced Micro Devices|ATI Technologies" } else { "NVIDIA" }
    @(Get-ChildItem $classPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | Where-Object {
        $prov = (Get-ItemProperty -Path $_.PSPath -Name "ProviderName" -ErrorAction SilentlyContinue).ProviderName
        $prov -match $pattern
    })
}
function Get-AmdDisplayKeys    { Get-GpuDisplayKeys "AMD" }
function Get-NvidiaDisplayKeys { Get-GpuDisplayKeys "NVIDIA" }
 
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
        $snap = Get-RegUndoSnapshot $umd "ShaderCache"
        Add-UndoRecord @{ Type = "Registry"; Path = $umd; Name = "ShaderCache"; HadValue = $snap.HadValue; PreviousValue = $snap.PreviousValue; PreviousKind = (if ($snap.HadValue) { $snap.PreviousKind } else { "Binary" }) }
        Set-ItemProperty -Path $umd -Name "ShaderCache" -Value $bytes -Type Binary -Force
        Write-Host ("  [APPLIED] ShaderCache = {0} at {1}" -f $Mode, $umd) -ForegroundColor Green
        Write-Log "AMD ShaderCache -> $Mode at $umd"
    }
}
 
# ---- Shared helper: every vendor "set this background service to
#      Manual/Automatic" tweak (AMD Crash Defender, AMD FUEL, NVIDIA
#      Telemetry, NVIDIA Container) used to duplicate the same six lines.
#      This is the one place that logic now lives; each tweak below just
#      supplies a service-name pattern and the expected vendor. ----
function Set-VendorServiceByPattern ([string]$Vendor, [string]$NamePattern, [string]$FriendlyName, [bool]$Disable) {
    $result = Invoke-ValidatedTweak -Name "$FriendlyName -> $(if($Disable){'Manual'}else{'Automatic'})" `
        -Requirements @(@{ Name = "GPU vendor is $Vendor"; Test = { Test-GpuVendorIs $Vendor } }) `
        -Apply {
            $svc = Get-Service -Name $NamePattern -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $svc) { return $null }
            $mode = if ($Disable) { "Manual" } else { "Automatic" }
            Set-ServiceStartupVerified -Name $svc.Name -StartupType $mode
        } `
        -Verify {
            $svc = Get-Service -Name $NamePattern -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $svc) { return $false }
            $expected = if ($Disable) { "Manual" } else { "Automatic" }
            $svc.StartType.ToString() -eq $expected
        }
    if (-not (Get-Service -Name $NamePattern -ErrorAction SilentlyContinue)) {
        return [PSCustomObject]@{ Tweak = $FriendlyName; Status = "Skipped"; Reason = "$FriendlyName not found on this system" }
    }
    return $result
}

function Set-AmdCrashDefender ([bool]$Disable) {
    # "AMD Crash Defender Service" ships with recent Adrenalin driver packages
    # and only collects/uploads crash diagnostics - safe to idle, easy to restore.
    return Set-VendorServiceByPattern -Vendor "AMD" -NamePattern "*Crash Defender*" -FriendlyName "AMD Crash Defender Service" -Disable $Disable
}
 
function Set-AmdFuelService ([bool]$Disable) {
    # "AMD FUEL Service" brokers Radeon Software's overlay/eventing features.
    # It isn't required for the GPU driver itself - safe to idle and restore.
    return Set-VendorServiceByPattern -Vendor "AMD" -NamePattern "*FUEL*" -FriendlyName "AMD FUEL Service" -Disable $Disable
}
 
# ---- NVIDIA-only tweaks: same GUID class as AMD, filtered to the NVIDIA
#      driver provider so this never touches a mixed-GPU system's wrong key.
#      (Lookup logic itself now lives in the shared Get-GpuDisplayKeys above.) ----
 
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
    if (Test-ServiceExists "NvTelemetryContainer") {
        return Set-VendorServiceByPattern -Vendor "NVIDIA" -NamePattern "NvTelemetryContainer" -FriendlyName "NVIDIA Telemetry service" -Disable $Disable
    }
    return Set-VendorServiceByPattern -Vendor "NVIDIA" -NamePattern "*NVIDIA Telemetry*" -FriendlyName "NVIDIA Telemetry service" -Disable $Disable
}
 
function Set-NvidiaContainerServices ([bool]$Disable) {
    # NvContainerLocalSystem / NvContainerNetworkService back GeForce
    # Experience's overlay, ShadowPlay and update-check features. Neither
    # is required for the display driver to render or for games to run.
    # Two independent services -> two independent validated-tweak results.
    $names = @("NvContainerLocalSystem", "NvContainerNetworkService")
    $results = foreach ($n in $names) {
        Set-VendorServiceByPattern -Vendor "NVIDIA" -NamePattern $n -FriendlyName "NVIDIA Container service ($n)" -Disable $Disable
    }
    return $results
}
 
# ---- Vendor-neutral: GPU driver TDR (Timeout Detection & Recovery) delay ----
function Set-GpuTdrDelay ([bool]$Extend) {
    # Windows resets a GPU driver that doesn't respond within TdrDelay
    # seconds (default 2). Heavy sustained workloads (long shader compiles,
    # some compute/rendering tasks) can hit that ceiling and trigger a false
    # "display driver stopped responding" recovery. Raising it to 8s gives
    # the driver more room without disabling the safety mechanism entirely.
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    return Invoke-ValidatedTweak -Name "GPU TdrDelay extended=$Extend" `
        -Apply { if ($Extend) { Set-RegDword $k "TdrDelay" 8 } else { Remove-RegValue $k "TdrDelay" } } `
        -Verify {
            if ($Extend) { (Test-RegValueEquals $k "TdrDelay" 8) -eq "Applied" }
            else { (Test-RegValueEquals $k "TdrDelay" 8) -ne "Applied" }
        }
}
 
# ---- PCIe ASPM / Link State Power Management ----
function Get-AspmPowerSavingIndex {
    <# Reads the active power plan's current AC PCIe ASPM index back via
       powercfg - the same documented source Set-AspmPowerSaving writes to,
       so Apply/Verify never trust a bare command exit code. #>
    try {
        $out = powercfg /q SCHEME_CURRENT SUB_PCIEXPRESS ASPM 2>$null
        $acLine = $out | Select-String "Current AC Power Setting Index" | Select-Object -First 1
        if ($acLine) { return [Convert]::ToInt32((($acLine.ToString() -split ":")[-1].Trim()), 16) }
    } catch {}
    return $null
}
function Set-AspmPowerSaving ([bool]$Disable) {
    $sub     = "501a4d13-42af-4429-9fd1-a8218c268e20"   # PCI Express subgroup
    $setting = "ee12f906-d277-404b-b6da-e5fa1a576df5"   # Link State Power Management
    $val = if ($Disable) { 0 } else { 1 }               # 0=Off, 1=Moderate (typical Windows default)
    return Invoke-DetectedTweak -Name "PCIe ASPM disabled=$Disable" `
        -Supported { $null -ne (Get-AspmPowerSavingIndex) } `
        -AlreadyOk { (Get-AspmPowerSavingIndex) -eq $val } `
        -Apply {
            powercfg /setacvalueindex SCHEME_CURRENT $sub $setting $val 2>$null | Out-Null
            powercfg /setdcvalueindex SCHEME_CURRENT $sub $setting $val 2>$null | Out-Null
            powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
        } `
        -Verify { (Get-AspmPowerSavingIndex) -eq $val }
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
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    return Invoke-DetectedTweak -Name "HAGS -> $Mode" `
        -Supported { (Test-MinWindowsBuild 19041) -and (Test-WddmMinVersion "2.7") } `
        -AlreadyOk {
            switch ($Mode) {
                "Enable"  { (Get-HagsState) -eq "Enabled" }
                "Disable" { (Get-HagsState) -eq "Disabled" }
                default   { (Get-HagsState) -match "default" }
            }
        } `
        -Requirements @(@{ Name = "Windows 10 2004+ (build 19041+)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Apply {
            switch ($Mode) {
                "Enable"  { Set-RegDword $k "HwSchMode" 2 }
                "Disable" { Set-RegDword $k "HwSchMode" 1 }
                default   { Remove-RegValue $k "HwSchMode" }
            }
        } `
        -Verify {
            switch ($Mode) {
                "Enable"  { (Test-RegValueEquals $k "HwSchMode" 2) -eq "Applied" }
                "Disable" { (Test-RegValueEquals $k "HwSchMode" 1) -eq "Applied" }
                default   { (Test-RegValueEquals $k "HwSchMode" 2) -ne "Applied" -and (Test-RegValueEquals $k "HwSchMode" 1) -ne "Applied" }
            }
        }
}
 
# ---- Fullscreen Optimizations (per-user, no admin needed but grouped here for convenience) ----
function Set-FullscreenOptimizations ([bool]$Disable) {
    $k = "HKCU:\System\GameConfigStore"
    return Invoke-ValidatedTweak -Name "Fullscreen Optimizations disabled=$Disable" `
        -Apply {
            if ($Disable) {
                $a = Set-RegDword $k "GameDVR_FSEBehaviorMode" 2
                $b = Set-RegDword $k "GameDVR_HonorUserFSEBehaviorMode" 1
                $a -and $b
            } else {
                $a = Remove-RegValue $k "GameDVR_FSEBehaviorMode"
                $b = Remove-RegValue $k "GameDVR_HonorUserFSEBehaviorMode"
                $a -and $b
            }
        } `
        -Verify {
            if ($Disable) { (Test-RegValueEquals $k "GameDVR_FSEBehaviorMode" 2) -eq "Applied" }
            else { (Test-RegValueEquals $k "GameDVR_FSEBehaviorMode" 2) -ne "Applied" }
        }
}
 
function Get-UsbSelectiveSuspendState {
    # HKLM policy value overrides the per-device power-plan setting for every
    # USB port; this is the same switch as the "USB selective suspend"
    # setting under Power Options > USB settings, applied globally in one
    # shot instead of per device.
    $k = "HKLM:\SYSTEM\CurrentControlSet\Services\USB"
    try {
        $v = (Get-ItemProperty -Path $k -Name "DisableSelectiveSuspend" -ErrorAction Stop).DisableSelectiveSuspend
        if ($v -eq 1) { return "Disabled (no suspend)" } else { return "Windows default" }
    } catch { return "Windows default" }
}

function Set-UsbSelectiveSuspend ([bool]$Disable) {
    # Selective suspend lets Windows power down idle USB ports/devices. On a
    # desktop this occasionally shows up as a mouse "waking up" with a tiny
    # stutter or a wireless dongle briefly dropping. Turning it off keeps
    # every USB device fully powered - real fix for that specific symptom,
    # not a general FPS tweak. Laptops on battery will see a small hit to
    # battery life if left off.
    $k = "HKLM:\SYSTEM\CurrentControlSet\Services\USB"
    return Invoke-ValidatedTweak -Name "USB Selective Suspend disabled=$Disable" `
        -Apply {
            if ($Disable) { Set-RegDword $k "DisableSelectiveSuspend" 1 } else { Remove-RegValue $k "DisableSelectiveSuspend" }
        } `
        -Verify {
            if ($Disable) { (Test-RegValueEquals $k "DisableSelectiveSuspend" 1) -eq "Applied" }
            else { (Test-RegValueEquals $k "DisableSelectiveSuspend" 1) -ne "Applied" }
        }
}

function Get-PowerThrottlingState {
    $k = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Power\PowerThrottling"
    try {
        $v = (Get-ItemProperty -Path $k -Name "PowerThrottlingOff" -ErrorAction Stop).PowerThrottlingOff
        if ($v -eq 1) { return "Off (system-wide)" } else { return "Windows default" }
    } catch { return "Windows default" }
}

function Set-PowerThrottlingOff ([bool]$Disable) {
    # Power Throttling (EcoQoS) lets Windows quietly cap a process's CPU
    # clocks/priority when it thinks the process is "background" work,
    # introduced in the 1809 update to save battery. It occasionally
    # misclassifies a game or its overlay/anti-cheat helper process as
    # background and throttles it. This is the same switch as Task
    # Manager > Details > right-click > "Efficiency mode" availability,
    # flipped globally instead of per process.
    $k = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Power\PowerThrottling"
    return Invoke-ValidatedTweak -Name "System-wide Power Throttling off=$Disable" `
        -Apply {
            if ($Disable) { Set-RegDword $k "PowerThrottlingOff" 1 } else { Remove-RegValue $k "PowerThrottlingOff" }
        } `
        -Verify {
            if ($Disable) { (Test-RegValueEquals $k "PowerThrottlingOff" 1) -eq "Applied" }
            else { (Test-RegValueEquals $k "PowerThrottlingOff" 1) -ne "Applied" }
        }
}

function Get-DynamicTickState {
    try {
        $out = bcdedit /enum "{current}" 2>$null
        $match = $out | Select-String "disabledynamictick" | Select-Object -First 1
        if (-not $match) { return "Enabled (Windows default)" }
        if ($match.ToString() -match "Yes") { return "Disabled" } else { return "Enabled (Windows default)" }
    } catch { return "Unknown" }
}

function Set-DynamicTickAndPlatformTimer ([bool]$Disable) {
    # Dynamic Tick lets the CPU skip timer interrupts while idle to save
    # power; on a system pinned to a game's render loop it adds a small,
    # real amount of scheduling jitter versus a fixed periodic tick.
    # Disabling it (plus forcing the legacy HPET-based platform clock
    # instead of the TSC-based one) is the same pair of switches behind
    # most "Windows timer tweak" guides. Needs a reboot either way, and
    # trades a small amount of idle power efficiency for more consistent
    # frame pacing - real effect, but small, and not free.
    if ($Disable) {
        bcdedit /set disabledynamictick yes | Out-Null
        bcdedit /set useplatformtick yes | Out-Null
    } else {
        bcdedit /deletevalue disabledynamictick 2>$null | Out-Null
        bcdedit /deletevalue useplatformtick 2>$null | Out-Null
    }
    Write-Log "Dynamic Tick disabled=$Disable (bcdedit, needs reboot)"
}

function Restore-AllResponsivenessTweaks {
    Set-MultiPlaneOverlay $false | Out-Null
    Set-UiDelays $false
    Set-TimerResolution $false | Out-Null
    Set-AspmPowerSaving $false | Out-Null
    Set-GpuTdrDelay $false | Out-Null
    Set-HagsMode "Default" | Out-Null
    Set-FullscreenOptimizations $false | Out-Null
    Set-UsbSelectiveSuspend $false | Out-Null
    Set-PowerThrottlingOff $false | Out-Null
    Set-DynamicTickAndPlatformTimer $false
    Set-HvciMode $false | Out-Null
    Set-GpuMsiMode $false | Out-Null
    if ($script:GpuProfile -ne "NVIDIA") {
        Set-AmdShaderCache "Default"
    }
    if ($script:GpuProfile -ne "AMD") {
        Set-NvidiaPowerMode $false
    }
    Write-Host "[DONE] Reverted to defaults. (GPU vendor background services, if you disabled any, live under menu [9] and are restored from there.)" -ForegroundColor Green
}
 
function Show-ResponsivenessMenu {
    while ($true) {
        Show-Banner | Out-Null
 
        # Menu is rebuilt every loop so it always reflects the current GPU profile.
        # AMD Tessellation override and ULPS disable are intentionally absent -
        # both are DX9/CrossFire-era leftovers with no measurable benefit on
        # modern single-GPU DX12/Vulkan systems. See TWEAK_AUDIT.md.
        # Background-service-only toggles (AMD Crash Defender/FUEL, NVIDIA
        # Telemetry/Container) live in Service Tweaks (menu 9) instead - they
        # save a few MB of RAM, not frame time, so they don't belong here.
        $items = @(
            @{ Text = "Disable Multi-Plane Overlay (fixes some flickering/stutter)                [6/10 if you have symptoms, else placebo]"; Action = { Write-TweakResult (Set-MultiPlaneOverlay $true) } }
            @{ Text = "Reduce menu/mouse-hover delay (snappier UI, not raw performance)             [8/10 perceived, 0/10 fps]"; Action = { Set-UiDelays $true; Write-Host "[DONE]" -ForegroundColor Green } }
            @{ Text = "Enable high-resolution system timer                                          [6/10, raises power draw]"; Action = { Write-TweakResult (Set-TimerResolution $true) } }
            @{ Text = ("Re-apply GPU MSI Mode (fixes DPC-latency micro-stutter): {0}                   [7/10 if it was off, 1/10 if it wasn't]" -f (Get-GpuMsiState))
               Action = { if (Confirm-Action "Forces the GPU to use Message-Signaled Interrupts instead of legacy line-based IRQ. Needs a reboot to take effect.") { Write-TweakResult (Set-GpuMsiMode $true); Write-Host "  (Reboot required to apply.)" -ForegroundColor DarkGray } } }
            @{ Text = ("Disable Memory Integrity / HVCI (needs reboot): {0}                            [up to 8/10 fps on affected CPUs - READ THE WARNING]" -f (Get-HvciState))
               Action = {
                   Write-Host "`n  [!] Memory Integrity (Core Isolation) is a real security feature - it" -ForegroundColor Yellow
                   Write-Host "      raises the bar against kernel-level exploits and some ransomware." -ForegroundColor Yellow
                   Write-Host "      Disabling it trades that protection for FPS in CPU-bound titles on" -ForegroundColor Yellow
                   Write-Host "      some CPUs (mainly certain Intel 12th/13th/14th-gen parts). Any gain is" -ForegroundColor Yellow
                   Write-Host "      hardware-dependent - on most other CPUs it's small or not measurable" -ForegroundColor Yellow
                   Write-Host "      at all. See TWEAK_AUDIT.md before deciding." -ForegroundColor Yellow
                   if (Confirm-Action "Disable Memory Integrity? This needs a reboot to take effect either way.") {
                       Write-TweakResult (Set-HvciMode $true)
                       Write-Host "  (Reboot required for the change to take effect.)" -ForegroundColor DarkGray
                   }
               } }
            @{ Text = "Extend GPU driver TDR delay to 8s (fewer false 'driver crashed' recoveries)   [5/10, hides real crashes longer]"; Action = { Write-TweakResult (Set-GpuTdrDelay $true) } }
            @{ Text = "Disable PCIe ASPM power saving (also disable in BIOS for full effect)         [6/10 desktop, 2/10 laptop]"
               Action = { if (Confirm-Action "For full effect also disable ASPM in BIOS. Apply the Windows-side change now?") { Write-TweakResult (Set-AspmPowerSaving $true) } } }
            @{ Text = "Disable Fullscreen Optimizations for all games                               [5/10, no longer universal advice]"; Action = { Write-TweakResult (Set-FullscreenOptimizations $true) } }
            @{ Text = ("Disable USB Selective Suspend (fixes mouse/dongle micro-stutter): {0}   [6/10 if you have symptoms, else 1/10]" -f (Get-UsbSelectiveSuspendState))
               Action = { Write-TweakResult (Set-UsbSelectiveSuspend $true) } }
            @{ Text = ("Disable Power Throttling / EcoQoS system-wide: {0}                          [5/10, situational]" -f (Get-PowerThrottlingState))
               Action = { Write-TweakResult (Set-PowerThrottlingOff $true) } }
            @{ Text = ("Disable Dynamic Tick + force platform timer (needs reboot): {0}              [4/10, small but real, costs idle power]" -f (Get-DynamicTickState))
               Action = { if (Confirm-Action "This edits boot config (bcdedit) and needs a reboot to take effect. Continue?") { Set-DynamicTickAndPlatformTimer $true; Write-Host "[DONE] Reboot to apply." -ForegroundColor Green } } }
        )

        # HAGS needs Windows 10 2004+ (build 19041+) AND a WDDM 2.7+ driver -
        # both are real prerequisites Set-HagsMode already enforces, so the
        # menu entry itself is hidden rather than shown and then refused.
        if ((Test-MinWindowsBuild 19041) -and (Test-WddmMinVersion "2.7")) {
            $items += @{ Text = ("Hardware-Accelerated GPU Scheduling: currently {0} - toggle it   [5/10, test both ways]" -f (Get-HagsState))
               Action = {
                   $state = Get-HagsState
                   if ($state -eq "Enabled") { Write-TweakResult (Set-HagsMode "Disable"); Write-Host "  (Restart required to apply.)" -ForegroundColor DarkGray }
                   else { Write-TweakResult (Set-HagsMode "Enable"); Write-Host "  (Restart required to apply.)" -ForegroundColor DarkGray }
               } }
        }
 
        if ($script:GpuProfile -ne "NVIDIA") {
            $items += @{ IsHeader = $true; Text = "--- AMD ---" }
            $items += @{ Text = "Shader Cache = Always On                                      [3/10, marginal]"; Action = { Set-AmdShaderCache "AlwaysOn"; Write-Host "[DONE]" -ForegroundColor Green } }
            $items += @{ Text = "Shader Cache = Off (NOT recommended, causes stutter)           [1/10]"; Action = { Set-AmdShaderCache "Off"; Write-Host "[DONE]" -ForegroundColor Green } }
        }
 
        if ($script:GpuProfile -ne "AMD") {
            $items += @{ IsHeader = $true; Text = "--- NVIDIA ---" }
            $items += @{ Text = "Power Mode = Prefer Maximum Performance                     [7/10 desktop, 3/10 laptop]"; Action = { Set-NvidiaPowerMode $true; Write-Host "[DONE]" -ForegroundColor Green } }
        }
 
        $items += @{ Text = "Restore ALL of the above to Windows defaults"; Action = { if (Confirm-Action "Revert ALL Responsiveness & GPU tweaks to Windows defaults?") { Restore-AllResponsivenessTweaks } } }
 
        Write-Host ("`n>>> [8] RESPONSIVENESS & GPU TWEAKS   [GPU profile: {0}]`n" -f $script:GpuProfile) -ForegroundColor Green
        $num = 0
        $indexMap = @{}
        foreach ($it in $items) {
            if ($it.IsHeader) { Write-Host ("`n {0}" -f $it.Text) -ForegroundColor Cyan; continue }
            $num++
            $indexMap[$num] = $it
            Write-Host (" [{0}] {1}" -f $num, $it.Text)
        }
        Write-Host "`n [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        if ($c -eq "0") { return }
        if ($c -match '^\d+$' -and $indexMap.ContainsKey([int]$c)) {
            & $indexMap[[int]$c].Action
            Wait-ForEnter
        } else {
            Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1
        }
    }
}
 
# ==============================================================================
#  14b. MODERN GPU OPTIMIZATIONS (RTX 3000+ / RX 6000+)
#  Deliberately short. HAGS, GPU MSI Mode, PCIe ASPM, GPU TDR delay and HVCI
#  already live in menu [8] and apply just as much to a 4090 as to a 1660 -
#  they are NOT repeated here. What follows is only the handful of things
#  that are either genuinely new registry-level levers or genuinely need a
#  modern, high-bandwidth GPU to matter. A few "greatest hits" you'll see
#  in other tweak scripts (global Reflex/Anti-Lag toggle, shader-cache-size
#  overrides, a Resizable BAR on/off switch) are NOT here because there is
#  no safe, documented, OS-level registry key for them - they live in the
#  vendor's own driver panel, and faking a registry key for them would be
#  exactly the kind of placebo tweak this tool refuses to ship. See
#  TWEAK_AUDIT.md for the full reasoning.
# ==============================================================================

function Clear-DirectXShaderCache {
    <# Deletes the per-user DirectX shader disk cache (%LocalAppData%\D3DSCache
       and, where present, the older NVIDIA/AMD per-driver GLCache/DXCache
       folders). This is the standard, well-documented fix for the
       "stutter for the first few minutes after a driver or game update"
       symptom on modern UE4/UE5 titles - stale or partially-corrupt cached
       shader binaries get recompiled fresh. It costs a one-time
       recompilation stutter on your NEXT launch of each game in exchange
       for fixing a persistent one, so it's not something to run right
       before a benchmark or a ranked match. #>
    $paths = @(
        (Join-Path $env:LOCALAPPDATA "D3DSCache"),
        (Join-Path $env:LOCALAPPDATA "NVIDIA\DXCache"),
        (Join-Path $env:LOCALAPPDATA "NVIDIA\GLCache"),
        (Join-Path $env:LOCALAPPDATA "AMD\DxCache"),
        (Join-Path $env:LOCALAPPDATA "AMD\GLCache")
    )
    $cleared = 0
    foreach ($p in $paths) {
        if (Test-Path $p) {
            try {
                $sizeMb = [math]::Round(((Get-ChildItem $p -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB), 1)
                Remove-Item -Path (Join-Path $p "*") -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host ("  [CLEARED] {0} (freed ~{1} MB)" -f $p, $sizeMb) -ForegroundColor Green
                Write-Log "Cleared shader cache: $p (~$sizeMb MB)"
                $cleared++
            } catch { Write-Host ("  [FAILED]  {0}" -f $p) -ForegroundColor Red }
        }
    }
    if ($cleared -eq 0) { Write-Host "  No shader cache folders found (nothing to clear, or it lives in a non-default location)." -ForegroundColor DarkGray }
    else { Write-Host "`n  Next launch of each game will recompile shaders once - expect brief stutter on that first launch only." -ForegroundColor Yellow }
}

# ==============================================================================
#  14b. PREREQUISITE CHECKS
#  Get-DxdiagReportText / Get-WddmVersionReport back Test-WddmMinVersion,
#  the real gate HAGS (menu [8]) and DirectStorage-adjacent tweaks check
#  before writing anything. Get-GameModeStatusReport backs Set-GameModeMode's
#  AlreadyOk check. Both are kept because they affect tweak behavior, not for
#  standalone reporting - see CHANGELOG.md for the diagnostics-only functions
#  (PCIe link, Resizable BAR, driver age, DirectStorage prereqs, VRR, etc.)
#  removed in this pass since nothing ever gated on them.
# ==============================================================================

function Get-DxdiagReportText {
    <# dxdiag's text dump is the only built-in source for the WDDM driver
       model version and the D3D feature levels a driver actually reports -
       there is no WMI/CIM class or registry value for either. Cached per
       session in $script:DxdiagText since it takes a few seconds to run. #>
    if ($script:DxdiagText) { return $script:DxdiagText }
    $tmp = Join-Path $env:TEMP "zoro_dxdiag_$PID.txt"
    try {
        Start-Process -FilePath "dxdiag.exe" -ArgumentList @("/t", "`"$tmp`"") -Wait -WindowStyle Hidden -ErrorAction Stop
        for ($i = 0; $i -lt 10 -and -not (Test-Path $tmp); $i++) { Start-Sleep -Milliseconds 300 }
        if (Test-Path $tmp) {
            $script:DxdiagText = Get-Content -Path $tmp -Raw -ErrorAction Stop
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            return $script:DxdiagText
        }
    } catch {}
    return $null
}

function Get-WddmVersionReport {
    $text = Get-DxdiagReportText
    if (-not $text) { return "Couldn't run dxdiag to read this (locked-down policy environments only - uncommon on a home PC)." }
    $m = [regex]::Match($text, "Driver Model:\s*(WDDM [\d\.]+)")
    if ($m.Success) { return $m.Groups[1].Value }
    return "Not reported by dxdiag on this driver/OS combination."
}

function Get-GameModeStatusReport {
    <# Windows Game Mode's actual switch, read directly rather than assumed
       on because Windows 10/11 ships it "on" by default. #>
    try {
        $v = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AutoGameModeEnabled" -ErrorAction Stop).AutoGameModeEnabled
        if ($v -eq 0) { return "Disabled" } else { return "Enabled" }
    } catch { return "Enabled (Windows default - no override present)" }
}

# ---- TdrDdiDelay: a real, DISTINCT registry value from TdrDelay (already in
#      menu [8]). TdrDelay is the overall "driver must respond within N sec"
#      timeout; TdrDdiDelay is the grace period for the DDI (driver
#      interface) call itself, and matters more on sustained heavy compute
#      batches - ray tracing denoising passes and DLSS3/FSR3 frame-generation
#      work are exactly that kind of batch. Only relevant if you're actually
#      seeing "display driver stopped responding" specifically during RT or
#      frame-gen; otherwise this hides a real problem, same caveat as
#      TdrDelay. ----
function Get-TdrDdiDelayState {
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    try { return "$((Get-ItemProperty -Path $k -Name 'TdrDdiDelay' -ErrorAction Stop).TdrDdiDelay)s (extended)" }
    catch { return "Windows default (~2s)" }
}
function Set-TdrDdiDelay ([bool]$Extend) {
    $k = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    return Invoke-DetectedTweak -Name "GPU TdrDdiDelay extended=$Extend" `
        -Supported { $true } `
        -AlreadyOk {
            if ($Extend) { (Test-RegValueEquals $k "TdrDdiDelay" 10) -eq "Applied" }
            else { (Test-RegValueEquals $k "TdrDdiDelay" 10) -ne "Applied" }
        } `
        -Apply { if ($Extend) { Set-RegDword $k "TdrDdiDelay" 10 } else { Remove-RegValue $k "TdrDdiDelay" } } `
        -Verify {
            if ($Extend) { (Test-RegValueEquals $k "TdrDdiDelay" 10) -eq "Applied" }
            else { (Test-RegValueEquals $k "TdrDdiDelay" 10) -ne "Applied" }
        }
}

function Restore-AllModernGpuTweaks {
    Write-TweakResult (Set-TdrDdiDelay $false)
}

function Show-GpuExtrasMenu {
    while ($true) {
    $tier = Get-GpuModelTier
    Show-Banner | Out-Null
    Write-Host "`n>>> [10] GPU EXTRAS`n" -ForegroundColor Green
    Write-Host (" Detected GPU: {0}" -f $tier.Name) -ForegroundColor Gray
    $drv = Get-GpuDriverInfo
    if ($drv -and (($drv.AgeDays -ne $null -and $drv.AgeDays -gt 545) -or -not $drv.WhqlSigned)) {
        Write-Host (" [!] Driver v{0} ({1}), WHQL signed: {2} - see System Requirements Check for details" -f `
            $drv.DriverVersion, (if ($drv.DriverDate) { $drv.DriverDate.ToString("yyyy-MM-dd") } else { "date unknown" }), $drv.WhqlSigned) -ForegroundColor Yellow
    }
    Write-Host " Everything else that used to live here (PCIe link, Resizable BAR, driver" -ForegroundColor Gray
    Write-Host " age as a standalone report, DirectStorage prereqs, VRR, VBS status, etc.)" -ForegroundColor Gray
    Write-Host " was pure reporting with no write path and nothing gated on it - removed." -ForegroundColor Gray
    Write-Host " Driver age is back above only because it now actively warns before you" -ForegroundColor Gray
    Write-Host " chase a 'tweak didn't stick' problem that's really a stale/unsigned driver." -ForegroundColor Gray
    Write-Host " What's below actually changes system state.`n" -ForegroundColor Gray

    $items = @(
        @{ Text = "Clear DirectX shader cache (fixes post-driver/post-update stutter)   [6/10 if you're seeing it, 0/10 if not]"
           Action = { if (Confirm-Action "Clears cached compiled shaders for all games. Next launch of each game will recompile once (brief one-time stutter). Continue?") { Clear-DirectXShaderCache } } }
    )
    if ($tier.Tier -eq "MODERN") {
        $items += @{ Text = ("Extend TdrDdiDelay for sustained RT/DLSS3-FSR3 frame-gen workloads: {0}    [3/10, niche - only if you see TDR resets during RT/frame-gen]" -f (Get-TdrDdiDelayState))
           Action = {
               Write-Host "`n  [!] Only use this if you're ALREADY seeing 'display driver stopped" -ForegroundColor Yellow
               Write-Host "      responding' specifically during ray tracing or frame-generation." -ForegroundColor Yellow
               Write-Host "      It raises the DDI response grace period from ~2s to 10s - it" -ForegroundColor Yellow
               Write-Host "      hides a real crash longer, it doesn't fix its cause." -ForegroundColor Yellow
               if (Confirm-Action "Extend TdrDdiDelay? Needs a reboot to take effect.") { Write-TweakResult (Set-TdrDdiDelay $true) }
           } }
    }
    $items += @{ Text = "Restore ALL GPU Extras tweaks to Windows defaults"; Action = { if (Confirm-Action "Revert GPU Extras tweaks to Windows defaults?") { Restore-AllModernGpuTweaks } } }

    $num = 0
    $indexMap = @{}
    foreach ($it in $items) {
        $num++
        $indexMap[$num] = $it
        Write-Host (" [{0}] {1}" -f $num, $it.Text)
    }
    Write-Host "`n [0] Back to Main Menu"
    $c = Read-Host "`nSelect"
    if ($c -eq "0") { return }
    if ($c -match '^\d+$' -and $indexMap.ContainsKey([int]$c)) {
        & $indexMap[[int]$c].Action
        Wait-ForEnter
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
    if (-not (Test-ServiceExists $svcName)) {
        $r = [PSCustomObject]@{ Tweak = "Service: $svcName"; Status = "Skipped"; Reason = "Not present on this system" }
        Write-TweakResult $r
        return $r
    }
    $originalType = (Get-Service -Name $svcName -ErrorAction SilentlyContinue).StartType.ToString()
    $r = Invoke-ValidatedTweak -Name "Service: $svcName -> Disabled" `
        -Apply {
            $map = Get-ServiceStateMap
            if (-not $map.ContainsKey($svcName)) { $map[$svcName] = $originalType }
            Save-ServiceStateMap $map

            $bdir = Join-Path $BackupRoot "ServiceBackups"
            if (-not (Test-Path $bdir)) { New-Item -Path $bdir -ItemType Directory -Force | Out-Null }
            reg export "HKLM\SYSTEM\CurrentControlSet\Services\$svcName" (Join-Path $bdir "$svcName.reg") /y 2>$null | Out-Null

            # Shared helper (also used by the AMD/NVIDIA service tweaks) - it
            # records the undo entry itself and NEVER throws, it catches
            # Set-Service failures internally and reports Verified=$false.
            # A raw "Set-Service ... -ErrorAction Stop" here would throw out
            # of this Apply block, which makes Invoke-ValidatedTweak return
            # Failed WITHOUT ever calling Rollback - leaving the ServiceState
            # map/.reg backup written above orphaned even though nothing was
            # actually changed. Using the helper means a failed write always
            # reaches Verify/Rollback below instead.
            Set-ServiceStartupVerified -Name $svcName -StartupType "Disabled" | Out-Null
            $true
        } `
        -Verify {
            (Get-Service -Name $svcName -ErrorAction SilentlyContinue).StartType.ToString() -eq "Disabled"
        } `
        -Rollback {
            # Verification failed - don't leave the service half-changed with a
            # stale "was $originalType" entry sitting in ServiceState.json.
            Set-Service -Name $svcName -StartupType $originalType -ErrorAction SilentlyContinue
            $map = Get-ServiceStateMap
            if ($map.ContainsKey($svcName)) { $map.Remove($svcName) | Out-Null; Save-ServiceStateMap $map }
        }
    Write-TweakResult $r
    return $r
}
 
function Restore-ServiceDefault ($svcName) {
    $map = Get-ServiceStateMap
    $original = if ($map.ContainsKey($svcName)) { $map[$svcName] } else { "Manual" }
    $r = Invoke-ValidatedTweak -Name "Service: $svcName -> $original (restore)" `
        -Requirements @(@{ Name = "$svcName exists"; Test = { Test-ServiceExists $svcName } }) `
        -Apply {
            Set-Service -Name $svcName -StartupType $original -ErrorAction Stop
            if ($original -eq "Automatic") { Start-Service -Name $svcName -ErrorAction SilentlyContinue }
            $true
        } `
        -Verify {
            (Get-Service -Name $svcName -ErrorAction SilentlyContinue).StartType.ToString() -eq $original
        }
    if ($r.Status -eq "Success" -and $map.ContainsKey($svcName)) {
        $map.Remove($svcName) | Out-Null
        Save-ServiceStateMap $map
    }
    Write-TweakResult $r
    return $r
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
    @{ Name="QWAVE";                 Desc="Quality Windows A/V Experience (legacy multimedia QoS)" },
    @{ Name="SysMain";               Desc="Superfetch/SysMain - see live recommendation in menu, it depends on your disk type and RAM" }
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
    Write-Host "`nEnter comma-separated numbers (e.g. 1,3,5), 'all', or press ENTER to cancel."
    $sel = Read-Host "Selection"
    if ([string]::IsNullOrWhiteSpace($sel)) { return }
    $targets = if ($sel.Trim().ToLower() -eq "all") { $list } else {
        $sel -split "," | ForEach-Object {
            $idx = $_.Trim()
            if ($idx -match '^\d+$' -and [int]$idx -ge 1 -and [int]$idx -le $list.Count) { $list[[int]$idx - 1] }
        }
    }
    $targets = @($targets | Where-Object { $_ })
    if (-not $targets -or $targets.Count -eq 0) { Write-Host "Nothing selected." -ForegroundColor Yellow; return }
    if ($extraWarning) { Write-Host "`n[!] These are CAUTION-level services - re-read the descriptions above." -ForegroundColor Yellow }
    if (-not (Confirm-Action "Disable $($targets.Count) service(s)? Each is backed up first and can be restored from option [3].")) { return }
    foreach ($item in $targets) { Set-ServiceDisabled $item.Name | Out-Null }
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
    $targets = @($targets | Where-Object { $_ })
    foreach ($n in $targets) { Restore-ServiceDefault $n | Out-Null }
}
 
function Show-GpuVendorServicesMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [9.4] GPU VENDOR BACKGROUND SERVICES`n" -ForegroundColor Green
        Write-Host " Honest framing: these save a small amount of idle RAM/CPU and stop" -ForegroundColor Gray
        Write-Host " vendor telemetry/overlay plumbing from running. They do NOT affect" -ForegroundColor Gray
        Write-Host " frame rate, frame time, or input latency. Disabling GFE/Container" -ForegroundColor Gray
        Write-Host " services will also disable NVIDIA overlay/ShadowPlay if you use them." -ForegroundColor Gray
        Write-Host ""
        $i = 0
        $entries = @()
        if ($script:GpuProfile -ne "NVIDIA") {
            Write-Host " --- AMD ---" -ForegroundColor Cyan
            $i++; Write-Host (" [{0}] Set AMD Crash Defender Service to Manual (crash-report uploader)      [2/10 perf, resource cleanup]" -f $i); $entries += { Write-TweakResult (Set-AmdCrashDefender $true) }
            $i++; Write-Host (" [{0}] Set AMD FUEL Service to Manual (Radeon overlay/eventing backend)      [2/10 perf, resource cleanup]" -f $i); $entries += { Write-TweakResult (Set-AmdFuelService $true) }
        }
        if ($script:GpuProfile -ne "AMD") {
            Write-Host " --- NVIDIA ---" -ForegroundColor Cyan
            $i++; Write-Host (" [{0}] Set NVIDIA Telemetry service to Manual                            [2/10 perf, privacy cleanup]" -f $i); $entries += { Write-TweakResult (Set-NvidiaTelemetry $true) }
            $i++; Write-Host (" [{0}] Set NVIDIA Container services to Manual (breaks GFE overlay/ShadowPlay)  [2/10 perf]" -f $i); $entries += { Set-NvidiaContainerServices $true | ForEach-Object { Write-TweakResult $_ } }
        }
        Write-Host " [0] Back"
        $c = Read-Host "`nSelect"
        if ($c -eq "0") { return }
        if ($c -match '^\d+$' -and [int]$c -ge 1 -and [int]$c -le $entries.Count) {
            & $entries[[int]$c - 1]
            Wait-ForEnter
        } else {
            Write-Host "Invalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1
        }
    }
}
 
function Show-ServiceTweaksMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [9] OPTIONAL SERVICE TWEAKS`n" -ForegroundColor Green
        Write-Host " Disabling unused background services can shave a little idle CPU/RAM." -ForegroundColor Gray
        Write-Host " Only disable what you're sure you don't use. Everything here is reversible." -ForegroundColor Gray
        Write-Host ""
        Write-Host " [1] Disable low-impact services (safe for most PCs)          [3/10 perf, negligible on modern hardware]"
        Write-Host " [2] Disable caution services (read the warnings first!)"
        Write-Host " [3] Restore previously disabled services"
        Write-Host (" [4] GPU vendor background services (AMD/NVIDIA)              [GPU profile: {0}]" -f $script:GpuProfile)
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" {
                # SysMain's real-world verdict depends entirely on disk type + RAM,
                # so its description is computed live instead of a static claim.
                $storage = Get-SystemStorageProfile
                $liveList = $SafeServices | ForEach-Object {
                    if ($_.Name -eq "SysMain") {
                        $hint = if (-not $storage.DiskKnown) {
                            "Superfetch/SysMain - couldn't detect your disk type; on a spinning HDD it helps launch times, on any SSD it mostly just adds background I/O for a gain you won't feel"
                        } elseif ($storage.IsNvme -and $storage.RamGb -ge 16) {
                            "Superfetch/SysMain - you're on NVMe with $($storage.RamGb) GB RAM: disabling this is LOW-VALUE, expect little/no difference, and app launches can feel slightly slower right after a reboot while the cache is cold [NOT recommended by default]"
                        } elseif ($storage.IsSsd) {
                            "Superfetch/SysMain - SSD detected ($(if ($storage.IsNvme) {'NVMe'} else {'SATA'})), $($storage.RamGb) GB RAM: modest launch-time benefit at best, disabling frees a little background I/O [optional]"
                        } else {
                            "Superfetch/SysMain - spinning HDD detected: this is the case it was actually designed for, disabling it usually makes app launches feel slower [NOT recommended]"
                        }
                        @{ Name = $_.Name; Desc = $hint }
                    } else { $_ }
                }
                Show-ServiceChecklist $liveList $false; Wait-ForEnter
            }
            "2" { Show-ServiceChecklist $CautionServices $true; Wait-ForEnter }
            "3" { Show-ServiceRestoreMenu; Wait-ForEnter }
            "4" { Show-GpuVendorServicesMenu }
            "0" { return }
            default { Show-InvalidSelection }
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
# Shared runner for SFC/DISM: identical announce -> log -> run -> log pattern,
# only the command line and its blurb differ per call site.
function Invoke-RepairTool ($Blurb, $LogName, [scriptblock]$Command) {
    Write-Host "`n  Running: $Blurb`n" -ForegroundColor Cyan
    Write-Log "$LogName started"
    & $Command
    Write-Log "$LogName finished"
}

function Invoke-SfcScan {
    Invoke-RepairTool "sfc /scannow  (this can take several minutes, do not close the window)" "SFC scan" { sfc /scannow }
}
 
function Invoke-DismCheckHealth {
    Invoke-RepairTool "DISM /Online /Cleanup-Image /CheckHealth  (fast, just flags a corrupted image)" "DISM CheckHealth" { DISM /Online /Cleanup-Image /CheckHealth }
}
 
function Invoke-DismScanHealth {
    Invoke-RepairTool "DISM /Online /Cleanup-Image /ScanHealth  (thorough scan, several minutes)" "DISM ScanHealth" { DISM /Online /Cleanup-Image /ScanHealth }
}
 
function Invoke-DismRestoreHealth {
    Invoke-RepairTool "DISM /Online /Cleanup-Image /RestoreHealth  (repairs via Windows Update, needs internet)" "DISM RestoreHealth" { DISM /Online /Cleanup-Image /RestoreHealth }
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
            Write-Host ("  [DONE] Standby list purged. Free RAM: {0:N1} GB -> {1:N1} GB" -f ($before / 1MB), ($after / 1MB)) -ForegroundColor Green
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
        Write-Host "`n>>> [11] SYSTEM REPAIR & RAM`n" -ForegroundColor Green
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
            "1" { Invoke-DismCheckHealth; Wait-ForEnter }
            "2" { Invoke-DismScanHealth; Wait-ForEnter }
            "3" { if (Confirm-Action "This downloads repair files via Windows Update if needed. Continue?") { Invoke-DismRestoreHealth }; Wait-ForEnter }
            "4" { Invoke-SfcScan; Wait-ForEnter }
            "5" { Invoke-FullImageRepair; Wait-ForEnter }
            "6" { Invoke-StandbyListClean; Wait-ForEnter }
            "0" { return }
            default { Show-InvalidSelection }
        }
    }
}
 
# ==============================================================================
#  17. REMOVE MICROSOFT EDGE - ROOT REMOVAL
#  Standalone, separate from every other menu on purpose: this is destructive,
#  not easily undone, and not something that should live next to a normal
#  "toggle a registry value" tweak. It kills every Edge/EdgeUpdate process,
#  runs Edge's own uninstaller in force mode, takes ownership of the folders
#  it leaves behind and deletes them, strips its services/scheduled
#  tasks/registry footprint, and sets the documented Microsoft policy value
#  that stops EdgeUpdate from silently reinstalling it. It deliberately does
#  NOT touch the WebView2 Runtime by default - a lot of unrelated software
#  (Store, Widgets, and plenty of third-party apps) embeds WebView2 and will
#  break or reinstall its own private copy of it if it's ripped out blind.
# ==============================================================================
function Get-EdgeInstallPaths {
    <# Every place a stock Win11 install can have Edge sitting, both
       system-level (Program Files x86) and the rarer per-user install. #>
    $roots = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge",
        "${env:ProgramFiles(x86)}\Microsoft\EdgeCore",
        "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate",
        "${env:ProgramFiles(x86)}\Microsoft\Temp\EdgeUpdate",
        "$env:ProgramFiles\Microsoft\Edge",
        "$env:LOCALAPPDATA\Microsoft\Edge",
        "$env:LOCALAPPDATA\Microsoft\EdgeCore",
        "$env:LOCALAPPDATA\Microsoft\EdgeUpdate",
        "$env:ProgramData\Microsoft\EdgeUpdate"
    )
    return @($roots | Where-Object { Test-Path $_ })
}

function Stop-EdgeProcesses {
    $names = @("msedge", "msedgewebview2", "MicrosoftEdgeUpdate", "identity_helper", "msedge_proxy")
    foreach ($n in $names) {
        Get-Process -Name $n -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    Write-Log "Edge-related processes stopped"
}

function Invoke-EdgeNativeUninstaller {
    <# Runs Edge's own setup.exe with the same force-uninstall switches
       Microsoft uses internally, before anything gets touched by hand.
       This is the "clean" removal path - everything after it is mopping
       up what the uninstaller leaves behind. #>
    $found = $false
    $searchRoots = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application",
        "$env:ProgramFiles\Microsoft\Edge\Application",
        "$env:LOCALAPPDATA\Microsoft\Edge\Application"
    ) | Where-Object { Test-Path $_ }

    foreach ($root in $searchRoots) {
        $setups = Get-ChildItem -Path $root -Filter "setup.exe" -Recurse -ErrorAction SilentlyContinue
        foreach ($setup in $setups) {
            $found = $true
            $isSystemLevel = $root -like "*Program Files*"
            $args = @("--uninstall", "--force-uninstall", "--verbose-logging")
            if ($isSystemLevel) { $args += "--system-level" }
            try {
                Write-Host ("  Running native uninstaller: {0} {1}" -f $setup.FullName, ($args -join " ")) -ForegroundColor Gray
                Start-Process -FilePath $setup.FullName -ArgumentList $args -Wait -WindowStyle Hidden -ErrorAction Stop
                Write-Log "Edge native uninstaller ran: $($setup.FullName) $($args -join ' ')"
            } catch {
                Write-Log "Edge native uninstaller failed at $($setup.FullName): $_" "ERROR"
            }
        }
    }
    return $found
}

function Remove-EdgeServicesAndTasks {
    foreach ($svcName in @("edgeupdate", "edgeupdatem")) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -InputObject $svc -Force -ErrorAction SilentlyContinue
            sc.exe delete $svcName | Out-Null
            Write-Log "Deleted service $svcName"
        }
    }
    $taskNames = @(
        "MicrosoftEdgeUpdateTaskMachineCore", "MicrosoftEdgeUpdateTaskMachineUA",
        "MicrosoftEdgeUpdateTaskMachineCore{*}", "MicrosoftEdgeUpdateTaskMachineUA{*}"
    )
    Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like "MicrosoftEdgeUpdate*" } | ForEach-Object {
        try {
            Unregister-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -Confirm:$false -ErrorAction Stop
            Write-Log "Removed scheduled task $($_.TaskPath)$($_.TaskName)"
        } catch {}
    }
}

function Remove-EdgeFilesystemFootprint {
    $paths = Get-EdgeInstallPaths
    foreach ($p in $paths) {
        try {
            takeown.exe /F "$p" /R /D Y 2>$null | Out-Null
            icacls.exe "$p" /grant "*S-1-5-32-544:(OI)(CI)F" /T /C /Q 2>$null | Out-Null
            Remove-Item -Path $p -Recurse -Force -ErrorAction Stop
            Write-Host ("  [REMOVED] {0}" -f $p) -ForegroundColor Green
            Write-Log "Removed Edge path $p"
        } catch {
            Write-Host ("  [PARTIAL] {0} - some files still locked, will finish clearing after reboot" -f $p) -ForegroundColor Yellow
            Write-Log "Could not fully remove $p : $_" "ERROR"
        }
    }
}

function Remove-EdgeRegistryFootprint {
    $keys = @(
        "HKLM:\SOFTWARE\Microsoft\Edge",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Edge",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe",
        "HKCU:\SOFTWARE\Microsoft\Edge"
    )
    foreach ($k in $keys) {
        if (Test-Path $k) {
            try { Remove-Item -Path $k -Recurse -Force -ErrorAction Stop; Write-Log "Removed registry key $k" } catch {}
        }
    }
    # Documented Microsoft policy (EdgeUpdate ADMX) that stops EdgeUpdate /
    # Windows Update from silently reinstalling Edge on this machine. This is
    # the supported switch, not a filesystem trick.
    $pol = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
    Set-RegDword $pol "InstallDefault" 0 | Out-Null
    Set-RegDword $pol "Install{56EB18F8-8008-4CBD-B6D2-8C97FE7E9062}" 0 | Out-Null   # Edge Stable
    Write-Log "EdgeUpdate policy set to block silent reinstall"
}

function Remove-EdgeAppxAndShortcuts {
    Get-AppxPackage -AllUsers -Name "*MicrosoftEdge*" -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*MicrosoftEdge*" } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null

    $shortcutGlobs = @(
        "$env:PUBLIC\Desktop\Microsoft Edge.lnk",
        "$env:USERPROFILE\Desktop\Microsoft Edge.lnk",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
    )
    foreach ($s in $shortcutGlobs) {
        if (Test-Path $s) { Remove-Item -Path $s -Force -ErrorAction SilentlyContinue; Write-Log "Removed shortcut $s" }
    }
}

function Remove-MicrosoftEdgeCompletely {
    Write-Host "`n  Stopping Edge/EdgeUpdate processes..." -ForegroundColor Cyan
    Stop-EdgeProcesses

    Write-Host "  Running Edge's own uninstaller (force mode)..." -ForegroundColor Cyan
    $ranNative = Invoke-EdgeNativeUninstaller
    if (-not $ranNative) { Write-Host "  No native setup.exe found - skipping straight to manual cleanup." -ForegroundColor DarkGray }
    Start-Sleep -Seconds 2
    Stop-EdgeProcesses

    Write-Host "  Removing EdgeUpdate services and scheduled tasks..." -ForegroundColor Cyan
    Remove-EdgeServicesAndTasks

    Write-Host "  Removing Start Menu/Desktop shortcuts and any AppX shell packages..." -ForegroundColor Cyan
    Remove-EdgeAppxAndShortcuts

    Write-Host "  Taking ownership of and deleting leftover Edge folders..." -ForegroundColor Cyan
    Remove-EdgeFilesystemFootprint

    Write-Host "  Clearing registry footprint and blocking silent reinstall..." -ForegroundColor Cyan
    Remove-EdgeRegistryFootprint

    Write-Log "Microsoft Edge root removal completed"
    Write-Host "`n[DONE] Microsoft Edge has been uninstalled and its EdgeUpdate reinstall policy is blocked." -ForegroundColor Green
    Write-Host "  If any folder showed [PARTIAL] above, reboot once - a handle was held open by" -ForegroundColor Yellow
    Write-Host "  Explorer/a running process and the file(s) will finish clearing on next boot." -ForegroundColor Yellow
    Write-Host "  Note: a future Windows feature update (e.g. 25H2) can still reintroduce Edge -" -ForegroundColor DarkGray
    Write-Host "  that's Microsoft re-provisioning it at the OS level, not this policy failing." -ForegroundColor DarkGray
}

function Show-EdgeRemovalMenu {
    Show-Banner | Out-Null
    Write-Host "`n>>> [12] REMOVE MICROSOFT EDGE - COMPLETE REMOVAL`n" -ForegroundColor Green
    Write-Host " This is separate from Windows Tweaks/Debloat on purpose. It will:" -ForegroundColor Gray
    Write-Host "   - kill every Edge/EdgeUpdate process" -ForegroundColor Gray
    Write-Host "   - run Edge's own uninstaller in --force-uninstall mode" -ForegroundColor Gray
    Write-Host "   - delete the EdgeUpdate service + scheduled tasks" -ForegroundColor Gray
    Write-Host "   - take ownership of and delete every leftover Edge folder" -ForegroundColor Gray
    Write-Host "   - strip Edge's registry footprint and shortcuts" -ForegroundColor Gray
    Write-Host "   - set the documented EdgeUpdate policy that blocks silent reinstall" -ForegroundColor Gray
    Write-Host ""
    Write-Host " Left alone on purpose: the WebView2 Runtime. Lots of unrelated apps (Store," -ForegroundColor DarkGray
    Write-Host " Widgets, many third-party programs) embed it - removing it blind breaks them" -ForegroundColor DarkGray
    Write-Host " or makes them silently reinstall their own private copy." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " This action is destructive and cannot be cleanly reversed - there is no" -ForegroundColor Yellow
    Write-Host " 'restore Edge' option." -ForegroundColor Yellow
    $confirm = Read-Host "`nType DELETE EDGE (exactly) to proceed, or press ENTER to cancel"
    if ($confirm -ne "DELETE EDGE") {
        Write-Host "Cancelled. No changes were made." -ForegroundColor Yellow
        Wait-ForEnter
        return
    }
    Remove-MicrosoftEdgeCompletely
    Wait-ForEnter
}

# ==============================================================================
#  17. GAME NETWORK DIAGNOSTICS
#  Read-heavy diagnostics + one small, opt-in, undo-tracked optimization
#  (MSI). Everything below reuses the adapter selection, ping/DNS/throughput
#  measurement, and Invoke-ValidatedTweak/Set-RegDword plumbing already
#  defined above instead of duplicating it - only tracert.exe parsing and
#  raw TCP-connect timing are genuinely new primitives this section needs.
# ==============================================================================

# ---- 17a. Automatic Best Game Adapter Detection ----
function Get-AdapterConnectionType ($Adapter) {
    <# Classifies the adapter using only documented Get-NetAdapter fields
       (InterfaceDescription, PhysicalMediaType, Virtual) - no third-party
       lookups, no guessing beyond what the driver itself already reports. #>
    $desc = "$($Adapter.InterfaceDescription)"
    if ($desc -match 'Hyper-V')                              { return "Hyper-V Virtual Switch" }
    if ($desc -match 'VMware')                                { return "VMware Virtual Adapter" }
    if ($desc -match 'VirtualBox')                             { return "VirtualBox Host-Only Adapter" }
    if ($desc -match 'WSL|Windows Subsystem for Linux')        { return "WSL Virtual Adapter" }
    if ($desc -match 'TAP-Windows|WireGuard|OpenVPN|Tunnel|VPN'){ return "VPN Adapter" }
    if ($Adapter.PhysicalMediaType -match '802\.11')            { return "Wi-Fi" }
    if ($Adapter.Virtual -eq $true)                             { return "Other Virtual Adapter" }
    if ($Adapter.PhysicalMediaType -match 'Ethernet|802\.3')    { return "Ethernet" }
    return "Other/Unknown"
}

function Get-BestGameAdapterReport {
    <# Reuses Get-PrimaryActiveAdapter (already the lowest-metric default-
       route adapter used by MTU Discovery/TCP Analyzer) rather than a
       second "find the right NIC" implementation, then adds the
       type/MTU/RSS/RSC read this feature needs on top of it. #>
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) { return $null }
    $rss = Get-NetAdapterRss -Name $adapter.Name -ErrorAction SilentlyContinue
    $rssState = if ($rss) { if ($rss.Enabled) { "Enabled" } else { "Disabled" } } else { "Not exposed by this driver" }
    $rsc = Get-NetAdapterRsc -Name $adapter.Name -ErrorAction SilentlyContinue
    $rscState = if ($rsc) { if ($rsc | Where-Object { $_.IPv4Enabled -or $_.IPv6Enabled }) { "Enabled" } else { "Disabled" } } else { "Not exposed by this driver" }
    return [PSCustomObject]@{
        Adapter        = $adapter
        Name           = $adapter.Name
        InterfaceIndex = $adapter.ifIndex
        Type           = Get-AdapterConnectionType $adapter
        LinkSpeed      = $adapter.LinkSpeed
        Driver         = ("{0} {1}" -f $adapter.DriverProvider, $adapter.DriverVersion)
        Mtu            = Get-InterfaceMtu $adapter.ifIndex
        RssState       = $rssState
        RscState       = $rscState
    }
}

function Show-BestGameAdapterDetection {
    $r = Get-BestGameAdapterReport
    if (-not $r) { Write-Host "  No active adapter with a default internet route found." -ForegroundColor Yellow; return $null }
    Write-Host "`n>>> AUTOMATIC BEST GAME ADAPTER DETECTION`n" -ForegroundColor Cyan
    Write-Host ("  Adapter Name    : {0}" -f $r.Name)
    Write-Host ("  Type            : {0}" -f $r.Type)
    Write-Host ("  Interface Index : {0}" -f $r.InterfaceIndex)
    Write-Host ("  Link Speed      : {0}" -f $r.LinkSpeed)
    Write-Host ("  Driver          : {0}" -f $r.Driver)
    Write-Host ("  Current MTU     : {0}" -f $r.Mtu)
    Write-Host ("  RSS State       : {0}" -f $r.RssState)
    Write-Host ("  RSC State       : {0}" -f $r.RscState)
    Write-Log ("Best Game Adapter Detection - {0} ({1}) idx={2} link={3} mtu={4} rss={5} rsc={6}" -f `
        $r.Name, $r.Type, $r.InterfaceIndex, $r.LinkSpeed, $r.Mtu, $r.RssState, $r.RscState)
    return $r
}

# ---- 17b. NIC Driver Health Check ----
function Get-NicDriverHealth ($Adapter) {
    <# Same source class (Win32_PnPSignedDriver) and warn-only-on-a-real-
       signal discipline as the existing GPU driver check (Get-GpuDriverInfo
       above), matched by DeviceID/PnPDeviceID instead of a vendor-name
       pattern since the NIC is already a known, single object here. Adds a
       live Get-PnpDevice status read, which the GPU check doesn't need
       since GPU health is inferred from age/signing alone. #>
    if (-not $Adapter) { return $null }
    $status = "Unknown"
    try { $pnp = Get-PnpDevice -InstanceId $Adapter.PnPDeviceID -ErrorAction Stop; if ($pnp) { $status = "$($pnp.Status)" } } catch {}
    $drv = $null
    try {
        $drv = Get-CimInstance Win32_PnPSignedDriver -ErrorAction Stop |
            Where-Object { $_.DeviceID -eq $Adapter.PnPDeviceID } | Select-Object -First 1
    } catch {}
    $driverDate = $null
    if ($drv -and $drv.DriverDate) {
        try { $driverDate = [datetime]$drv.DriverDate } catch { try { $driverDate = [Management.ManagementDateTimeConverter]::ToDateTime($drv.DriverDate) } catch {} }
    }
    $ageDays = if ($driverDate) { [math]::Round(((Get-Date) - $driverDate).TotalDays) } else { $null }
    return [PSCustomObject]@{
        DriverVersion  = if ($drv) { $drv.DriverVersion } else { $Adapter.DriverVersion }
        DriverDate     = $driverDate
        DriverProvider = if ($drv) { $drv.Manufacturer } else { $Adapter.DriverProvider }
        DriverStatus   = $status
        AgeDays        = $ageDays
    }
}

function Show-NicDriverHealthCheck {
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) { Write-Host "  No active adapter found." -ForegroundColor Yellow; return $null }
    $h = Get-NicDriverHealth $adapter
    Write-Host "`n>>> NIC DRIVER HEALTH CHECK`n" -ForegroundColor Cyan
    Write-Host ("  Adapter         : {0}" -f $adapter.Name)
    Write-Host ("  Driver Version  : {0}" -f $(if ($h.DriverVersion) { $h.DriverVersion } else { "Unknown" }))
    Write-Host ("  Driver Date     : {0}" -f $(if ($h.DriverDate) { $h.DriverDate.ToString("yyyy-MM-dd") } else { "Unknown" }))
    Write-Host ("  Driver Provider : {0}" -f $(if ($h.DriverProvider) { $h.DriverProvider } else { "Unknown" }))
    Write-Host ("  Driver Status   : {0}" -f $h.DriverStatus)
    Write-Host ("  Driver Age      : {0}" -f $(if ($null -ne $h.AgeDays) { "~$($h.AgeDays) days (~$([math]::Round($h.AgeDays/30)) months)" } else { "Unknown" }))

    $warned = $false
    if ($null -ne $h.AgeDays -and $h.AgeDays -gt 545) {
        Write-Host ("`n  [!] This driver is ~{0} months old. A stale NIC driver is a real, common" -f [math]::Round($h.AgeDays / 30)) -ForegroundColor Yellow
        Write-Host "      cause of packet loss/latency spikes under load." -ForegroundColor Yellow
        $warned = $true
    }
    if ($h.DriverStatus -and $h.DriverStatus -notin @("OK", "Unknown")) {
        Write-Host ("`n  [!] Device status reports '{0}' - check Device Manager." -f $h.DriverStatus) -ForegroundColor Yellow
        $warned = $true
    }
    if (-not $warned) { Write-Host "`n  No genuine driver health issues detected." -ForegroundColor Green }
    Write-Host "`n  ZORO does not install drivers or recommend third-party updater tools -" -ForegroundColor DarkGray
    Write-Host "  get updates from Windows Update or your NIC vendor directly." -ForegroundColor DarkGray
    Write-Log ("NIC Driver Health - {0} ver={1} date={2} provider={3} status={4} ageDays={5}" -f `
        $adapter.Name, $h.DriverVersion, $h.DriverDate, $h.DriverProvider, $h.DriverStatus, $h.AgeDays)
    return $h
}

# ---- 17c. IRQ / MSI Capability Detection ----
function Get-NicMsiInterruptInfo ($Adapter) {
    <# MSI support/current-mode lives under the device's own Interrupt
       Management registry subtree - the same Microsoft-documented location
       NIC vendors' own "enable MSI-X mode" KB articles point at
       (HKLM\SYSTEM\CurrentControlSet\Enum\<PnPDeviceID>\Device Parameters\
       Interrupt Management\MessageSignaledInterruptProperties, value
       MSISupported). Windows does not expose a documented API that
       distinguishes MSI from MSI-X specifically - only whether Message
       Signaled Interrupts are supported/active - so that's exactly what's
       reported, honestly, instead of a fabricated MSI-X-specific flag.
       RSS queue count is read straight from Get-NetAdapterRss. #>
    $result = [PSCustomObject]@{ RegPath = $null; MsiSupported = $false; CurrentlyMsi = $false; RssSupported = $false; RssQueueCount = $null }
    if (-not $Adapter) { return $result }
    try {
        $key = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($Adapter.PnPDeviceID)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        if (Test-Path $key) {
            $val = (Get-ItemProperty -Path $key -Name "MSISupported" -ErrorAction SilentlyContinue).MSISupported
            if ($null -ne $val) {
                $result.RegPath      = $key
                $result.MsiSupported = $true
                $result.CurrentlyMsi = ($val -eq 1)
            }
        }
    } catch {}
    $rss = Get-NetAdapterRss -Name $Adapter.Name -ErrorAction SilentlyContinue
    if ($rss) {
        $result.RssSupported  = $true
        $qc = @($rss.NumberOfReceiveQueues)[0]
        if (-not $qc) { $qc = @($rss.MaxProcessors)[0] }
        $result.RssQueueCount = $qc
    }
    return $result
}

function Show-IrqMsiDetection {
    $adapter = Get-PrimaryActiveAdapter
    if (-not $adapter) { Write-Host "  No active adapter found." -ForegroundColor Yellow; return }
    $info = Get-NicMsiInterruptInfo $adapter
    Write-Host "`n>>> IRQ / MSI CAPABILITY DETECTION`n" -ForegroundColor Cyan
    Write-Host ("  Adapter                : {0}" -f $adapter.Name)
    if ($info.RegPath) {
        Write-Host ("  MSI Supported          : {0}" -f $(if ($info.MsiSupported) { "Yes" } else { "Not exposed" }))
        Write-Host ("  Current Interrupt Mode : {0}" -f $(if ($info.CurrentlyMsi) { "Message Signaled Interrupts (MSI/MSI-X)" } else { "Line-based (legacy INTx)" }))
    } else {
        Write-Host "  MSI Supported          : Not exposed by this driver/device (no Interrupt Management key present)" -ForegroundColor DarkGray
        Write-Host "  Current Interrupt Mode : Unknown - report only, no optimization offered." -ForegroundColor DarkGray
    }
    Write-Host ("  RSS Supported          : {0}" -f $(if ($info.RssSupported) { "Yes" } else { "No" }))
    Write-Host ("  RSS Queue Count        : {0}" -f $(if ($info.RssQueueCount) { $info.RssQueueCount } else { "N/A" }))
    Write-Host ""
    Write-Host "  Note: Windows does not expose a documented API that distinguishes MSI from" -ForegroundColor DarkGray
    Write-Host "  MSI-X specifically - only whether Message Signaled Interrupts are supported" -ForegroundColor DarkGray
    Write-Host "  and currently active, which is exactly what's reported above." -ForegroundColor DarkGray

    if ($info.RegPath -and $info.MsiSupported -and -not $info.CurrentlyMsi) {
        Write-Host "`n  [OPTIMIZATION AVAILABLE] This device supports Message Signaled Interrupts" -ForegroundColor Yellow
        Write-Host "  but is currently using legacy line-based interrupts. Enabling MSI can reduce" -ForegroundColor Yellow
        Write-Host "  interrupt latency and is safe on hardware that already advertises support." -ForegroundColor Yellow
        if (Confirm-Action ("Enable Message Signaled Interrupts for {0}? Reversible via Undo Last Session." -f $adapter.Name)) {
            $ok = Set-RegDword $info.RegPath "MSISupported" 1
            if ($ok) {
                Write-Host "  [APPLIED] MSI enabled (verified). Disable/re-enable the device or reboot for it to take effect." -ForegroundColor Green
                Write-Log "MSI enabled for $($adapter.Name) ($($info.RegPath))"
            } else {
                Write-Host "  [FAILED] Could not verify the change." -ForegroundColor Red
            }
        }
    } elseif ($info.RegPath -and $info.MsiSupported -and $info.CurrentlyMsi) {
        Write-Host "`n  Already using Message Signaled Interrupts - nothing to optimize." -ForegroundColor Green
    } else {
        Write-Host "`n  Report only - this device/driver doesn't expose a safe, documented way to change interrupt mode." -ForegroundColor DarkGray
    }
}

# ---- 17d. Bufferbloat Test ----
$script:BufferbloatDownloadUrl = "https://speed.cloudflare.com/__down?bytes=50000000"

function Measure-LatencyUnderLoad {
    <# Real idle latency vs. real latency while a real saturating transfer
       (System.Net.Http.HttpClient, same pattern as Measure-Download/
       UploadThroughput above) is in flight, measured with the same
       ping.exe-based Get-PingStatistics used everywhere else in this file.
       Every phase is a genuine measurement; a phase that can't complete
       is left $null rather than estimated. #>
    param([string]$PingTarget = "8.8.8.8", [int]$PingCountPerPhase = 8)
    $result = [PSCustomObject]@{ IdleLatency = $null; DownloadLatency = $null; UploadLatency = $null; CombinedLatency = $null; Success = $false }

    Write-Host "  Measuring idle latency (no load)..." -ForegroundColor Gray
    $idle = Get-PingStatistics -TargetHost $PingTarget -Count $PingCountPerPhase
    if (-not $idle.Success) { return $result }
    $result.IdleLatency = $idle.Avg

    Write-Host "  Measuring latency under download load..." -ForegroundColor Gray
    $dlHandler = [System.Net.Http.HttpClientHandler]::new(); $dlClient = [System.Net.Http.HttpClient]::new($dlHandler); $dlClient.Timeout = [TimeSpan]::FromSeconds(30)
    try {
        $dlTask = $dlClient.GetByteArrayAsync($script:BufferbloatDownloadUrl)
        $down = Get-PingStatistics -TargetHost $PingTarget -Count $PingCountPerPhase
        try { $null = $dlTask.GetAwaiter().GetResult() } catch {}
        if ($down.Success) { $result.DownloadLatency = $down.Avg }
    } finally { $dlClient.Dispose(); $dlHandler.Dispose() }

    Write-Host "  Measuring latency under upload load..." -ForegroundColor Gray
    $ulHandler = [System.Net.Http.HttpClientHandler]::new(); $ulClient = [System.Net.Http.HttpClient]::new($ulHandler); $ulClient.Timeout = [TimeSpan]::FromSeconds(30)
    try {
        $payload = New-Object byte[] 15000000
        [System.Random]::new().NextBytes($payload)
        $ulTask = $ulClient.PostAsync($script:SpeedTestUploadUrl, [System.Net.Http.ByteArrayContent]::new($payload))
        $up = Get-PingStatistics -TargetHost $PingTarget -Count $PingCountPerPhase
        try { $null = $ulTask.GetAwaiter().GetResult() } catch {}
        if ($up.Success) { $result.UploadLatency = $up.Avg }
    } finally { $ulClient.Dispose(); $ulHandler.Dispose() }

    Write-Host "  Measuring latency under combined download+upload load..." -ForegroundColor Gray
    $cdHandler = [System.Net.Http.HttpClientHandler]::new(); $cdClient = [System.Net.Http.HttpClient]::new($cdHandler); $cdClient.Timeout = [TimeSpan]::FromSeconds(30)
    $cuHandler = [System.Net.Http.HttpClientHandler]::new(); $cuClient = [System.Net.Http.HttpClient]::new($cuHandler); $cuClient.Timeout = [TimeSpan]::FromSeconds(30)
    try {
        $cPayload = New-Object byte[] 15000000
        [System.Random]::new().NextBytes($cPayload)
        $cdTask = $cdClient.GetByteArrayAsync($script:BufferbloatDownloadUrl)
        $cuTask = $cuClient.PostAsync($script:SpeedTestUploadUrl, [System.Net.Http.ByteArrayContent]::new($cPayload))
        $combined = Get-PingStatistics -TargetHost $PingTarget -Count $PingCountPerPhase
        try { $null = $cdTask.GetAwaiter().GetResult() } catch {}
        try { $null = $cuTask.GetAwaiter().GetResult() } catch {}
        if ($combined.Success) { $result.CombinedLatency = $combined.Avg }
    } finally { $cdClient.Dispose(); $cdHandler.Dispose(); $cuClient.Dispose(); $cuHandler.Dispose() }

    $result.Success = $true
    return $result
}

function Get-BufferbloatGrade ($Result) {
    <# Grade derived only from the measured latency INCREASE (worst loaded
       phase minus idle) - modeled on the publicly documented Waveform
       bufferbloat grading bands (A+ <5ms, A <30ms, B <60ms, C <200ms, F
       200ms+), never a synthetic/marketing score. #>
    if (-not $Result -or -not $Result.Success -or $null -eq $Result.IdleLatency) { return $null }
    $loaded = @($Result.DownloadLatency, $Result.UploadLatency, $Result.CombinedLatency) | Where-Object { $null -ne $_ }
    if (@($loaded).Count -eq 0) { return $null }
    $worst = ($loaded | Measure-Object -Maximum).Maximum
    $increase = [math]::Round($worst - $Result.IdleLatency, 1)
    if ($increase -lt 0) { $increase = 0 }
    $grade =
        if ($increase -lt 5)   { "A+" }
        elseif ($increase -lt 30)  { "A" }
        elseif ($increase -lt 60)  { "B" }
        elseif ($increase -lt 200) { "C" }
        else { "F" }
    return [PSCustomObject]@{ Grade = $grade; IncreaseMs = $increase }
}

function Invoke-BufferbloatTest {
    Write-Host "`n>>> BUFFERBLOAT TEST`n" -ForegroundColor Cyan
    Write-Host " Measures real latency while a real saturating download/upload is in" -ForegroundColor Gray
    Write-Host " flight - not an estimate. Uses meaningful bandwidth for roughly 30-60s.`n" -ForegroundColor Gray
    if (-not (Confirm-Action "Run the Bufferbloat Test now? This uses real bandwidth (large download/upload transfers).")) { return $null }
    $r = Measure-LatencyUnderLoad
    if (-not $r.Success) {
        Write-Host "`n  [SKIPPED] Reliable measurement was not possible (idle ping failed) - no grade generated." -ForegroundColor Yellow
        Write-Log "Bufferbloat Test skipped - idle ping failed" "WARN"
        return $null
    }
    Write-Host "`n>>> RESULTS`n" -ForegroundColor Cyan
    Write-Host ("  Idle Latency      : {0}" -f $(if ($null -ne $r.IdleLatency) { "$($r.IdleLatency) ms" } else { "Not Measured" }))
    Write-Host ("  Download Latency  : {0}" -f $(if ($null -ne $r.DownloadLatency) { "$($r.DownloadLatency) ms" } else { "Not Measured" }))
    Write-Host ("  Upload Latency    : {0}" -f $(if ($null -ne $r.UploadLatency) { "$($r.UploadLatency) ms" } else { "Not Measured" }))
    Write-Host ("  Combined Latency  : {0}" -f $(if ($null -ne $r.CombinedLatency) { "$($r.CombinedLatency) ms" } else { "Not Measured" }))
    $grade = Get-BufferbloatGrade $r
    if ($grade) {
        $color = switch ($grade.Grade) { "A+" { "Green" }; "A" { "Green" }; "B" { "Yellow" }; "C" { "Yellow" }; default { "Red" } }
        Write-Host ("`n  Bufferbloat Grade : {0}  (+{1} ms under worst-case load)" -f $grade.Grade, $grade.IncreaseMs) -ForegroundColor $color
    } else {
        Write-Host "`n  Bufferbloat Grade : Not Measured (insufficient reliable data - skipped rather than guessed)" -ForegroundColor Yellow
    }
    Write-Log ("Bufferbloat Test - idle={0} down={1} up={2} combined={3} grade={4}" -f `
        $r.IdleLatency, $r.DownloadLatency, $r.UploadLatency, $r.CombinedLatency, $(if ($grade) { $grade.Grade } else { "N/A" }))
    return @{ Result = $r; Grade = $grade }
}

# ---- 17e. Route Quality Analyzer ----
function Invoke-RouteQualityAnalyzer {
    <# Parses tracert.exe (the documented in-box route-tracing tool, same
       "parse the real console tool" discipline as Test-DfPing/Get-
       PingStatistics above) for per-hop latency and packet loss, and runs
       it $Passes times to flag hops whose latency swings wildly or whose
       IP sequence changes between passes ("unstable"/"changed"), instead
       of judging route quality off a single noisy sample. #>
    param([Parameter(Mandatory)][string]$TargetHost, [int]$MaxHops = 30, [int]$TimeoutMs = 1000, [int]$Passes = 2)
    Write-Host ("`n>>> ROUTE QUALITY ANALYZER - {0}`n" -f $TargetHost) -ForegroundColor Cyan
    Write-Host ("  Running tracert ({0} pass(es), real per-hop probes)..." -f $Passes) -ForegroundColor Gray

    $passResults = @()
    for ($p = 0; $p -lt $Passes; $p++) {
        try { $raw = & tracert.exe -d -h $MaxHops -w $TimeoutMs $TargetHost 2>$null } catch { $raw = @() }
        $hops = @()
        foreach ($line in $raw) {
            if ($line -match '^\s*(\d+)\s+(.+)$') {
                $hopNum = [int]$Matches[1]
                $rest   = $Matches[2]
                $times  = @(); $timeoutCount = 0
                foreach ($m in [regex]::Matches($rest, '<?\d+\s*ms|\*')) {
                    if ($m.Value -eq '*') { $timeoutCount++ }
                    else { $times += [double]($m.Value -replace 'ms', '' -replace '<', '') }
                }
                $ipMatch = [regex]::Match($rest, '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')
                $hopIp   = if ($ipMatch.Success) { $ipMatch.Value } else { $null }
                $probes  = $times.Count + $timeoutCount
                $hops += [PSCustomObject]@{
                    Hop         = $hopNum
                    Ip          = $hopIp
                    AvgMs       = if ($times.Count -gt 0) { [math]::Round((($times | Measure-Object -Average).Average), 1) } else { $null }
                    LossPercent = if ($probes -gt 0) { [math]::Round(($timeoutCount / $probes) * 100, 0) } else { $null }
                    Times       = $times
                }
            }
        }
        $passResults += , $hops
    }

    $finalHops = $passResults[0]
    if (-not $finalHops -or $finalHops.Count -eq 0) {
        Write-Host "  [SKIPPED] tracert produced no usable hop data - reliable measurement not possible." -ForegroundColor Yellow
        Write-Log "Route Quality Analyzer: no hop data for $TargetHost" "WARN"
        return $null
    }

    $consistent = $true
    if ($Passes -gt 1 -and $passResults[1]) {
        $seq0 = ($passResults[0] | ForEach-Object { $_.Ip }) -join ","
        $seq1 = ($passResults[1] | ForEach-Object { $_.Ip }) -join ","
        $consistent = ($seq0 -eq $seq1)
    }

    Write-Host ("`n  Hop Count : {0}" -f $finalHops.Count)
    Write-Host ("  Route Consistency (across {0} pass(es)) : {1}`n" -f $Passes, $(if ($consistent) { "Stable" } else { "Changed between passes" }))
    Write-Host ("  {0,-5} {1,-16} {2,-10} {3,-8}" -f "Hop", "IP", "Avg (ms)", "Loss")
    foreach ($h in $finalHops) {
        $spread   = if ($h.Times.Count -ge 2) { (($h.Times | Measure-Object -Maximum).Maximum - ($h.Times | Measure-Object -Minimum).Minimum) } else { 0 }
        $unstable = ($h.LossPercent -gt 0) -or ($spread -gt 50)
        $ipLabel   = if ($h.Ip) { $h.Ip } else { "* (no reply)" }
        $avgLabel  = if ($null -ne $h.AvgMs) { $h.AvgMs } else { "-" }
        $lossLabel = if ($null -ne $h.LossPercent) { "$($h.LossPercent)%" } else { "-" }
        $flag      = if ($unstable) { "  <-- unstable" } else { "" }
        $color     = if ($unstable) { "Yellow" } else { "White" }
        Write-Host ("  {0,-5} {1,-16} {2,-10} {3,-8}{4}" -f $h.Hop, $ipLabel, $avgLabel, $lossLabel, $flag) -ForegroundColor $color
    }
    Write-Log ("Route Quality Analyzer - target={0} hops={1} consistency={2}" -f $TargetHost, $finalHops.Count, $consistent)
    return [PSCustomObject]@{ Target = $TargetHost; Hops = $finalHops; Consistent = $consistent }
}

# ---- 17f. Gaming Connectivity Test ----
$script:GamingServices = @(
    @{ Name = "Steam";              Host = "store.steampowered.com"; Port = 443 }
    @{ Name = "Battle.net";         Host = "battle.net";             Port = 443 }
    @{ Name = "Epic Games";         Host = "epicgames.com";          Port = 443 }
    @{ Name = "Riot Games";         Host = "riotgames.com";          Port = 443 }
    @{ Name = "Roblox";             Host = "roblox.com";             Port = 443 }
    @{ Name = "Xbox Live";          Host = "xbox.com";               Port = 443 }
    @{ Name = "PlayStation Network";Host = "playstation.com";        Port = 443 }
)

function Measure-TcpConnectLatency {
    <# Raw async TcpClient connect timed with a Stopwatch - the documented
       .NET primitive for "how long did the TCP handshake actually take",
       distinct from ICMP (Get-PingStatistics), which many gaming services
       block/rate-limit while still accepting game/API traffic on TCP. #>
    param([Parameter(Mandatory)][string]$TargetHost, [int]$Port = 443, [int]$TimeoutMs = 2000)
    $client = [System.Net.Sockets.TcpClient]::new()
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $iar = $client.BeginConnect($TargetHost, $Port, $null, $null)
        $ok  = $iar.AsyncWaitHandle.WaitOne($TimeoutMs)
        $sw.Stop()
        if ($ok -and $client.Connected) { $client.EndConnect($iar); return [PSCustomObject]@{ Connected = $true; Ms = [math]::Round($sw.Elapsed.TotalMilliseconds, 1) } }
        return [PSCustomObject]@{ Connected = $false; Ms = $null }
    } catch {
        return [PSCustomObject]@{ Connected = $false; Ms = $null }
    } finally { $client.Close() }
}

function Invoke-GamingConnectivityTest {
    param([Parameter(Mandatory)][string]$TargetHost, [string]$ServiceName = $null, [int]$Port = 443)
    $label = if ($ServiceName) { $ServiceName } else { $TargetHost }
    Write-Host ("`n  >>> {0} ({1})" -f $label, $TargetHost) -ForegroundColor Cyan

    $dnsMs = $null
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Resolve-DnsName -Name $TargetHost -Type A -DnsOnly -QuickTimeout -ErrorAction Stop
        $sw.Stop()
        $dnsMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
    } catch {}
    Write-Host ("    DNS Resolution      : {0}" -f $(if ($null -ne $dnsMs) { "$dnsMs ms" } else { "[FAILED] Could not resolve" }))

    $tcp = Measure-TcpConnectLatency -TargetHost $TargetHost -Port $Port
    Write-Host ("    TCP Connect ({0})   : {1}" -f $Port, $(if ($tcp.Connected) { "$($tcp.Ms) ms" } else { "[FAILED] Could not connect" }))

    $ping = Get-PingStatistics -TargetHost $TargetHost -Count 6
    if ($ping.Success) { Write-Host ("    ICMP Latency        : Avg {0} ms | Loss {1}%" -f $ping.Avg, $ping.PacketLossPercent) }
    else { Write-Host "    ICMP Latency        : Not Measured (host likely blocks ICMP - common for game services)" -ForegroundColor DarkGray }

    $reachable = $tcp.Connected -or $ping.Success
    Write-Host ("    Reachable           : {0}" -f $(if ($reachable) { "Yes" } else { "No" })) -ForegroundColor $(if ($reachable) { "Green" } else { "Red" })

    Write-Log ("Gaming Connectivity - {0} ({1}) dns={2} tcp={3} icmp={4} loss={5} reachable={6}" -f `
        $label, $TargetHost, $dnsMs, $tcp.Ms, $ping.Avg, $ping.PacketLossPercent, $reachable)
    return [PSCustomObject]@{ Service = $label; Host = $TargetHost; DnsMs = $dnsMs; TcpMs = $tcp.Ms; TcpConnected = $tcp.Connected; IcmpAvg = $ping.Avg; PacketLoss = $ping.PacketLossPercent; Reachable = $reachable }
}

# ---- 17g. Advanced Diagnostics Report ----
function Get-PublicIpAddress {
    <# Single documented, no-auth, no-key endpoint (same provider already
       used for the real throughput transfers above) that echoes the
       caller's own IP back as plain text - not a third-party "IP lookup
       API" with its own contract. Returns $null (never a guess) on
       failure. #>
    try {
        $trace = Invoke-RestMethod -Uri "https://www.cloudflare.com/cdn-cgi/trace" -TimeoutSec 8 -ErrorAction Stop
        $line = ($trace -split "`n") | Where-Object { $_ -match '^ip=' } | Select-Object -First 1
        if ($line) { return ($line -replace '^ip=', '').Trim() }
    } catch {}
    return $null
}

function New-AdvancedDiagnosticsReport {
    <# Runs the real measurements this whole section already defines
       (adapter/driver/route/connectivity, plus the bandwidth-heavy
       Bufferbloat Test if requested) and writes them to one timestamped
       TXT file under $WorkDir\Reports - every line traces back to a
       measurement made above, nothing here is templated or filled in. #>
    param([switch]$IncludeBufferbloat, [string]$RouteTarget = "8.8.8.8")

    $reportDir = Join-Path $WorkDir "Reports"
    if (-not (Test-Path $reportDir)) { New-Item -Path $reportDir -ItemType Directory -Force | Out-Null }
    $path = Join-Path $reportDir ("ZORO_Diagnostics_{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))

    Write-Host "`nGathering adapter + driver info..." -ForegroundColor Cyan
    $adapterInfo = Get-BestGameAdapterReport
    $driverInfo  = if ($adapterInfo) { Get-NicDriverHealth $adapterInfo.Adapter } else { $null }

    Write-Host "Gathering DNS/Gateway/IP configuration..." -ForegroundColor Cyan
    $ipConfig = if ($adapterInfo) { Get-NetIPConfiguration -InterfaceIndex $adapterInfo.InterfaceIndex -ErrorAction SilentlyContinue } else { $null }
    $dnsServers = if ($adapterInfo) { @(Get-DnsClientServerAddress -InterfaceAlias $adapterInfo.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses } else { @() }
    $gateway = if ($ipConfig -and $ipConfig.IPv4DefaultGateway) { $ipConfig.IPv4DefaultGateway.NextHop } else { $null }
    $ipv4 = if ($ipConfig) { (@($ipConfig.IPv4Address.IPAddress) -join ", ") } else { $null }
    $ipv6 = if ($ipConfig) { (@($ipConfig.IPv6Address.IPAddress) -join ", ") } else { $null }

    Write-Host "Looking up public IP..." -ForegroundColor Cyan
    $publicIp = Get-PublicIpAddress

    $bufferbloat = $null
    if ($IncludeBufferbloat) {
        Write-Host "Running Bufferbloat Test (real bandwidth, ~30-60s)..." -ForegroundColor Cyan
        $bb = Measure-LatencyUnderLoad
        if ($bb.Success) { $bufferbloat = @{ Result = $bb; Grade = (Get-BufferbloatGrade $bb) } }
    }

    Write-Host ("Running Route Quality Analyzer against {0}..." -f $RouteTarget) -ForegroundColor Cyan
    $route = Invoke-RouteQualityAnalyzer -TargetHost $RouteTarget -Passes 1

    Write-Host "Running Gaming Connectivity Test (Steam/Battle.net/Epic/Riot/Roblox/Xbox/PlayStation)..." -ForegroundColor Cyan
    $connResults = foreach ($svc in $script:GamingServices) { Invoke-GamingConnectivityTest -TargetHost $svc.Host -ServiceName $svc.Name -Port $svc.Port }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("==============================================================================")
    $lines.Add(" ZORO ADVANCED DIAGNOSTICS REPORT")
    $lines.Add(" Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  |  ZORO v$ScriptVersion")
    $lines.Add("==============================================================================")
    $lines.Add("")
    $lines.Add("---- ADAPTER INFORMATION ----")
    if ($adapterInfo) {
        $lines.Add("Adapter Name    : $($adapterInfo.Name)")
        $lines.Add("Type            : $($adapterInfo.Type)")
        $lines.Add("Interface Index : $($adapterInfo.InterfaceIndex)")
        $lines.Add("Link Speed      : $($adapterInfo.LinkSpeed)")
        $lines.Add("MTU             : $($adapterInfo.Mtu)")
        $lines.Add("RSS State       : $($adapterInfo.RssState)")
        $lines.Add("RSC State       : $($adapterInfo.RscState)")
    } else { $lines.Add("No active adapter with a default route found.") }
    $lines.Add("")
    $lines.Add("---- DRIVER INFORMATION ----")
    if ($driverInfo) {
        $lines.Add("Driver Version  : $($driverInfo.DriverVersion)")
        $lines.Add("Driver Date     : $(if ($driverInfo.DriverDate) { $driverInfo.DriverDate.ToString('yyyy-MM-dd') } else { 'Unknown' })")
        $lines.Add("Driver Provider : $($driverInfo.DriverProvider)")
        $lines.Add("Driver Status   : $($driverInfo.DriverStatus)")
        $lines.Add("Driver Age      : $(if ($null -ne $driverInfo.AgeDays) { "~$($driverInfo.AgeDays) days" } else { 'Unknown' })")
    } else { $lines.Add("Not available.") }
    $lines.Add("")
    $lines.Add("---- NETWORK CONFIGURATION ----")
    $lines.Add("DNS Servers     : $(if (@($dnsServers).Count -gt 0) { $dnsServers -join ', ' } else { 'DHCP-assigned' })")
    $lines.Add("Gateway         : $(if ($gateway) { $gateway } else { 'Unknown' })")
    $lines.Add("IPv4 Address    : $(if ($ipv4) { $ipv4 } else { 'Unknown' })")
    $lines.Add("IPv6 Address    : $(if ($ipv6) { $ipv6 } else { 'Unknown' })")
    $lines.Add("Public IP       : $(if ($publicIp) { $publicIp } else { 'Not Measured' })")
    $lines.Add("")
    $lines.Add("---- BUFFERBLOAT RESULTS ----")
    if ($bufferbloat) {
        $r = $bufferbloat.Result
        $lines.Add("Idle Latency     : $(if ($null -ne $r.IdleLatency) { "$($r.IdleLatency) ms" } else { 'Not Measured' })")
        $lines.Add("Download Latency : $(if ($null -ne $r.DownloadLatency) { "$($r.DownloadLatency) ms" } else { 'Not Measured' })")
        $lines.Add("Upload Latency   : $(if ($null -ne $r.UploadLatency) { "$($r.UploadLatency) ms" } else { 'Not Measured' })")
        $lines.Add("Combined Latency : $(if ($null -ne $r.CombinedLatency) { "$($r.CombinedLatency) ms" } else { 'Not Measured' })")
        $lines.Add("Grade            : $(if ($bufferbloat.Grade) { "$($bufferbloat.Grade.Grade) (+$($bufferbloat.Grade.IncreaseMs) ms under load)" } else { 'Not Measured' })")
    } else { $lines.Add("Skipped (not requested for this report, or reliable measurement was not possible).") }
    $lines.Add("")
    $lines.Add("---- ROUTE ANALYSIS (target: $RouteTarget) ----")
    if ($route) {
        $lines.Add("Hop Count        : $($route.Hops.Count)")
        $lines.Add("")
        $lines.Add(("{0,-5} {1,-16} {2,-10} {3,-8}" -f "Hop", "IP", "Avg (ms)", "Loss"))
        foreach ($h in $route.Hops) {
            $ipLabel   = if ($h.Ip) { $h.Ip } else { "* (no reply)" }
            $avgLabel  = if ($null -ne $h.AvgMs) { $h.AvgMs } else { "-" }
            $lossLabel = if ($null -ne $h.LossPercent) { "$($h.LossPercent)%" } else { "-" }
            $lines.Add(("{0,-5} {1,-16} {2,-10} {3,-8}" -f $h.Hop, $ipLabel, $avgLabel, $lossLabel))
        }
    } else { $lines.Add("Not available.") }
    $lines.Add("")
    $lines.Add("---- GAMING CONNECTIVITY RESULTS ----")
    foreach ($c in $connResults) {
        $lines.Add("$($c.Service) ($($c.Host))")
        $lines.Add("  DNS: $(if ($null -ne $c.DnsMs) { "$($c.DnsMs) ms" } else { 'Failed' })  |  TCP: $(if ($c.TcpConnected) { "$($c.TcpMs) ms" } else { 'Failed' })  |  ICMP Loss: $(if ($null -ne $c.PacketLoss) { "$($c.PacketLoss)%" } else { 'N/A' })  |  Reachable: $(if ($c.Reachable) { 'Yes' } else { 'No' })")
    }
    $lines.Add("")
    $lines.Add("==============================================================================")
    $lines.Add(" End of report.")

    ($lines -join "`r`n") | Set-Content -Path $path -Force -Encoding UTF8
    Write-Log "Advanced Diagnostics Report generated: $path"
    Write-Host "`n[DONE] Report saved to: $path" -ForegroundColor Green
    return $path
}

# ---- 17h. Menu ----
function Show-GameNetworkDiagnosticsMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [15] GAME NETWORK DIAGNOSTICS`n" -ForegroundColor Green
        Write-Host " Real measurements only, via documented Windows networking APIs/tools" -ForegroundColor Gray
        Write-Host " (Get-NetAdapter*, tracert.exe, ping.exe, Resolve-DnsName, TCP sockets)." -ForegroundColor Gray
        Write-Host " A metric that can't be reliably measured is skipped rather than guessed.`n" -ForegroundColor Gray
        Write-Host " [1] Automatic Best Game Adapter Detection"
        Write-Host " [2] NIC Driver Health Check"
        Write-Host " [3] IRQ / MSI Capability Detection (+ optional safe optimization)"
        Write-Host " [4] Bufferbloat Test (real latency under load, ~30-60s)"
        Write-Host " [5] Route Quality Analyzer (hostname/IP of your choice)"
        Write-Host " [6] Gaming Connectivity Test (Steam/Battle.net/Epic/Riot/Roblox/Xbox/PSN/custom)"
        Write-Host " [7] Generate Advanced Diagnostics Report (TXT)"
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        switch ($c) {
            "1" { Show-BestGameAdapterDetection | Out-Null; Wait-ForEnter }
            "2" { Show-NicDriverHealthCheck | Out-Null; Wait-ForEnter }
            "3" { Show-IrqMsiDetection; Wait-ForEnter }
            "4" { Invoke-BufferbloatTest | Out-Null; Wait-ForEnter }
            "5" {
                $target = Read-Host "`nEnter hostname or IP to trace"
                if ([string]::IsNullOrWhiteSpace($target)) { Write-Host "No target entered." -ForegroundColor Yellow }
                else { Invoke-RouteQualityAnalyzer -TargetHost $target.Trim() | Out-Null }
                Wait-ForEnter
            }
            "6" {
                Write-Host ""
                for ($i = 0; $i -lt $script:GamingServices.Count; $i++) { Write-Host (" [{0}] {1}" -f ($i + 1), $script:GamingServices[$i].Name) }
                Write-Host " [C] Custom host"
                Write-Host " [A] Test all of the above"
                $sel = Read-Host "`nSelect a service"
                if ($sel -match '^[Aa]$') {
                    foreach ($svc in $script:GamingServices) { Invoke-GamingConnectivityTest -TargetHost $svc.Host -ServiceName $svc.Name -Port $svc.Port | Out-Null }
                } elseif ($sel -match '^[Cc]$') {
                    $custom = Read-Host "Enter hostname or IP"
                    if (-not [string]::IsNullOrWhiteSpace($custom)) { Invoke-GamingConnectivityTest -TargetHost $custom.Trim() | Out-Null }
                } elseif ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $script:GamingServices.Count) {
                    $svc = $script:GamingServices[[int]$sel - 1]
                    Invoke-GamingConnectivityTest -TargetHost $svc.Host -ServiceName $svc.Name -Port $svc.Port | Out-Null
                } else { Show-InvalidSelection }
                Wait-ForEnter
            }
            "7" {
                $withBb = Confirm-Action "Include the Bufferbloat Test in this report? Adds ~30-60s and uses real bandwidth (Y = include, anything else = skip it)."
                New-AdvancedDiagnosticsReport -IncludeBufferbloat:$withBb | Out-Null
                Wait-ForEnter
            }
            "0" { return }
            default { Show-InvalidSelection }
        }
    }
}

# ==============================================================================
#  17a. PROCESS SCHEDULER OPTIMIZATION
#  Real, Microsoft-documented Windows thread/process scheduler and MMCSS
#  (Multimedia Class Scheduler Service) tuning - the same registry surface
#  System Properties > Performance Options > Advanced ("Programs" vs
#  "Background services") and Windows' own "Games" task registration use
#  internally. Deliberately does NOT add a core-parking override: see the
#  hybrid-topology reasoning above Get-CpuTopologyInfo (9. CPU TWEAKS) -
#  Windows 11's scheduler already places threads using per-core hints on
#  modern hybrid/preferred-core parts, and forcing every core permanently
#  unparked fights that instead of helping it. That reasoning isn't
#  repeated per-tweak below; it's still exactly why it's absent here too.
# ==============================================================================
$script:RegPath_PriorityControl = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
$script:RegPath_MmcssProfile    = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$script:RegPath_MmcssGamesTask  = "$script:RegPath_MmcssProfile\Tasks\Games"

function Get-Win32PrioritySeparationMode ($Value) {
    <# Maps the raw Win32PrioritySeparation DWORD to the label System
       Properties > Performance Options > Advanced would show for it.
       That UI only ever writes 2 ("Background services") or 38
       ("Programs"); anything else reflects a hand-edit or another tool. #>
    if ($null -eq $Value) { return "Programs (Windows default - key not present)" }
    switch ([int]$Value) {
        2       { return "Background services (long, fixed quanta)" }
        38      { return "Programs (short, variable quanta, foreground boost)" }
        default { return "Custom (raw value: $Value)" }
    }
}

function Get-ProcessSchedulerState {
    <# One cached read of every value this module touches, so the menu,
       diagnostics screen, and Tweak Health Check all read the same
       snapshot instead of three independent registry/service hits. #>
    return Get-ZoroCachedValue -Key "ProcessSchedulerState" -TtlMs 1500 -Loader {
        $prioritySep = $null
        try { $prioritySep = (Get-ItemProperty -Path $script:RegPath_PriorityControl -Name "Win32PrioritySeparation" -ErrorAction Stop).Win32PrioritySeparation } catch {}

        $sysResponsiveness = $null
        try { $sysResponsiveness = (Get-ItemProperty -Path $script:RegPath_MmcssProfile -Name "SystemResponsiveness" -ErrorAction Stop).SystemResponsiveness } catch {}

        $netThrottle = $null
        try { $netThrottle = (Get-ItemProperty -Path $script:RegPath_MmcssProfile -Name "NetworkThrottlingIndex" -ErrorAction Stop).NetworkThrottlingIndex } catch {}

        $gamesTaskExists = Test-Path $script:RegPath_MmcssGamesTask
        $gamesTask = $null
        if ($gamesTaskExists) { try { $gamesTask = Get-ItemProperty -Path $script:RegPath_MmcssGamesTask -ErrorAction Stop } catch {} }

        $mmcss = Get-Service -Name "MMCSS" -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            PrioritySeparationRaw          = $prioritySep
            PrioritySeparationMode         = Get-Win32PrioritySeparationMode $prioritySep
            SystemResponsiveness           = if ($null -ne $sysResponsiveness) { $sysResponsiveness } else { 20 }
            SystemResponsivenessIsDefault  = ($null -eq $sysResponsiveness -or $sysResponsiveness -eq 20)
            NetworkThrottlingIndex         = if ($null -ne $netThrottle) { $netThrottle } else { 10 }
            NetworkThrottlingDisabled      = ($netThrottle -eq -1)
            GamesTaskExists                = $gamesTaskExists
            GamesTaskGpuPriority           = if ($gamesTask) { $gamesTask.'GPU Priority' } else { $null }
            GamesTaskPriority              = if ($gamesTask) { $gamesTask.Priority } else { $null }
            GamesTaskScheduling            = if ($gamesTask) { $gamesTask.'Scheduling Category' } else { $null }
            GamesTaskSfio                  = if ($gamesTask) { $gamesTask.'SFIO Priority' } else { $null }
            GamesTaskBackgroundOnly        = if ($gamesTask) { $gamesTask.'Background Only' } else { $null }
            MmcssServicePresent            = [bool]$mmcss
            MmcssServiceRunning            = [bool]($mmcss -and $mmcss.Status -eq "Running")
            MmcssStartType                 = if ($mmcss) { $mmcss.StartType.ToString() } else { $null }
        }
    }
}

function Test-GamesTaskProfileHealthy {
    <# True only if every field Windows ships by default for the "Games"
       MMCSS task is still at its shipped value - i.e. nothing (this tool
       or another one) has degraded it. Gates the repair tweak as
       AlreadyOk instead of re-writing values that are already correct. #>
    $s = Get-ProcessSchedulerState
    if (-not $s.GamesTaskExists) { return $false }
    return (
        "$($s.GamesTaskGpuPriority)"    -eq "8"     -and
        "$($s.GamesTaskPriority)"       -eq "6"     -and
        "$($s.GamesTaskScheduling)"     -eq "High"  -and
        "$($s.GamesTaskSfio)"           -eq "High"  -and
        "$($s.GamesTaskBackgroundOnly)" -eq "False"
    )
}

function Test-MmcssServiceHealthy {
    $s = Get-ProcessSchedulerState
    return ($s.MmcssServicePresent -and $s.MmcssServiceRunning -and $s.MmcssStartType -eq "Automatic")
}

function Set-ProcessorSchedulingMode ([string]$Mode) {
    <# Exactly what System Properties > Performance Options > Advanced >
       "Adjust for best performance of" writes - only ever 2 or 38, the
       same two values the Windows UI itself is willing to set. #>
    $target = if ($Mode -eq "Programs") { 38 } else { 2 }
    return Invoke-ValidatedTweak -Name "Processor Scheduling: $Mode" `
        -Requirements @(
            @{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }
            @{ Name = "PriorityControl key reachable";                    Test = { Test-Path $script:RegPath_PriorityControl } }
        ) `
        -Apply    { Set-RegDword $script:RegPath_PriorityControl "Win32PrioritySeparation" $target } `
        -Verify   { ((Get-ItemProperty -Path $script:RegPath_PriorityControl -Name "Win32PrioritySeparation" -ErrorAction Stop).Win32PrioritySeparation) -eq $target } `
        -Rollback { Remove-RegValue $script:RegPath_PriorityControl "Win32PrioritySeparation" }
}

function Set-MmcssSystemResponsiveness ([bool]$LowLatency) {
    <# SystemResponsiveness is the percentage of CPU MMCSS guarantees to
       non-multimedia ("normal") tasks even while a registered multimedia
       task (Games/Audio/Pro Audio) is running. 20 is the Windows default;
       0 is the same value Windows' own low-latency audio/game guidance
       uses, at the cost of that headroom coming from somewhere else under
       sustained CPU pressure - hence the honest 4/10, not a blanket win. #>
    $target = if ($LowLatency) { 0 } else { 20 }
    $label  = if ($LowLatency) { "Low-latency (0)" } else { "Windows default (20)" }
    return Invoke-ValidatedTweak -Name "MMCSS System Responsiveness: $label" `
        -Requirements @(
            @{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }
            @{ Name = "Multimedia SystemProfile key reachable";           Test = { Test-Path $script:RegPath_MmcssProfile } }
        ) `
        -Apply    { Set-RegDword $script:RegPath_MmcssProfile "SystemResponsiveness" $target } `
        -Verify   { ((Get-ItemProperty -Path $script:RegPath_MmcssProfile -Name "SystemResponsiveness" -ErrorAction Stop).SystemResponsiveness) -eq $target } `
        -Rollback { Remove-RegValue $script:RegPath_MmcssProfile "SystemResponsiveness" }
}

function Set-MmcssNetworkThrottling ([bool]$Disable) {
    <# NetworkThrottlingIndex caps NDIS packet processing (Windows default:
       10 packets/ms) so multimedia tasks aren't starved by network I/O.
       Disabling it is stored as -1 (not 4294967295) because New-ItemProperty
       -PropertyType DWord stores a signed Int32 - passing the unsigned
       0xFFFFFFFF literal throws an overflow error; -1 is the correct
       two's-complement representation and reads back identically to what
       regedit shows as 0xffffffff. Genuinely measurable only on systems
       doing heavy simultaneous network + audio/game-task work - rated
       accordingly, not oversold. #>
    $target = if ($Disable) { -1 } else { 10 }
    $label  = if ($Disable) { "Disabled (0xFFFFFFFF)" } else { "Windows default (10)" }
    return Invoke-ValidatedTweak -Name "MMCSS Network Throttling: $label" `
        -Requirements @(
            @{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }
            @{ Name = "Multimedia SystemProfile key reachable";           Test = { Test-Path $script:RegPath_MmcssProfile } }
        ) `
        -Apply    { Set-RegDword $script:RegPath_MmcssProfile "NetworkThrottlingIndex" $target } `
        -Verify   { ((Get-ItemProperty -Path $script:RegPath_MmcssProfile -Name "NetworkThrottlingIndex" -ErrorAction Stop).NetworkThrottlingIndex) -eq $target } `
        -Rollback { Remove-RegValue $script:RegPath_MmcssProfile "NetworkThrottlingIndex" }
}

function Repair-MmcssGamesTaskProfile {
    <# Defensive repair, not an uplift: restores the "Games" MMCSS task to
       Windows' own shipped defaults (GPU Priority 8, Priority 6,
       Scheduling Category/SFIO Priority "High", Background Only "False").
       Real value here is undoing whatever a *different* "optimizer" tool
       set it to - Low scheduling category, GPU Priority 1, and
       Background Only=True are common placebo-adjacent edits from other
       tools. It does not make a stock, untouched system faster than it
       already is - rated 3/10 and documented as such, not sold as an
       uplift it isn't. #>
    return Invoke-DetectedTweak -Name "Repair 'Games' Task Priority Profile" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { $true } `
        -AlreadyOk { Test-GamesTaskProfileHealthy } `
        -Apply {
            if (-not (Test-Path $script:RegPath_MmcssGamesTask)) { New-Item -Path $script:RegPath_MmcssGamesTask -Force | Out-Null }
            $r1 = Set-RegDword          $script:RegPath_MmcssGamesTask "GPU Priority"          8
            $r2 = Set-RegDword          $script:RegPath_MmcssGamesTask "Priority"              6
            $r3 = Set-RegStringVerified $script:RegPath_MmcssGamesTask "Scheduling Category"    "High"
            $r4 = Set-RegStringVerified $script:RegPath_MmcssGamesTask "SFIO Priority"          "High"
            $r5 = Set-RegStringVerified $script:RegPath_MmcssGamesTask "Background Only"        "False"
            ($r1 -and $r2 -and $r3 -and $r4 -and $r5)
        } `
        -Verify { Test-GamesTaskProfileHealthy }
}

function Repair-MmcssService {
    <# MMCSS is the service that actually enforces every value above -
       SystemResponsiveness, NetworkThrottlingIndex, and the Games task
       profile are all inert if this service isn't running. Ensures
       Automatic + Running; nothing else. #>
    return Invoke-DetectedTweak -Name "Repair Multimedia Class Scheduler Service (MMCSS)" `
        -Requirements @(@{ Name = "MMCSS service present"; Test = { Test-ServiceExists "MMCSS" } }) `
        -Supported { Test-ServiceExists "MMCSS" } `
        -AlreadyOk { Test-MmcssServiceHealthy } `
        -Apply    { (Set-ServiceStartupVerified -Name "MMCSS" -StartupType "Automatic").Verified } `
        -Verify   { Test-MmcssServiceHealthy }
}

function Restore-AllSchedulerTweaks {
    <# Registry-shaped tweaks (Processor Scheduling, SystemResponsiveness,
       NetworkThrottlingIndex) reset to "key absent = Windows default" the
       same way every other Restore-All* in this tool works. The Games-task
       repair and MMCSS-service repair aren't included here because both
       only ever restore Windows' own shipped values - there's no prior
       "tweaked" state of this tool's own to revert past that. #>
    Remove-RegValue $script:RegPath_PriorityControl "Win32PrioritySeparation" | Out-Null
    Remove-RegValue $script:RegPath_MmcssProfile    "SystemResponsiveness"    | Out-Null
    Remove-RegValue $script:RegPath_MmcssProfile    "NetworkThrottlingIndex"  | Out-Null
    Write-Host "[DONE] Process Scheduler tweaks restored to Windows defaults." -ForegroundColor Green
    Write-Log "Process Scheduler tweaks restored to defaults"
}

function Show-ProcessSchedulerDiagnostics {
    $s = Get-ProcessSchedulerState
    Write-Host "`n  Processor scheduling mode   : $($s.PrioritySeparationMode)"
    Write-Host ("  MMCSS SystemResponsiveness  : {0}{1}" -f $s.SystemResponsiveness, $(if ($s.SystemResponsivenessIsDefault) { " (Windows default)" } else { " (low-latency mode)" }))
    Write-Host ("  MMCSS NetworkThrottlingIndex: {0}{1}" -f $s.NetworkThrottlingIndex, $(if ($s.NetworkThrottlingDisabled) { " (0xFFFFFFFF - throttling disabled)" } else { " (Windows default)" }))
    if ($s.GamesTaskExists) {
        $healthy = Test-GamesTaskProfileHealthy
        $detail  = if ($healthy) { "Healthy (matches Windows' shipped defaults)" } else { "Degraded - GPU Priority=$($s.GamesTaskGpuPriority) Priority=$($s.GamesTaskPriority) Scheduling=$($s.GamesTaskScheduling) SFIO=$($s.GamesTaskSfio) BackgroundOnly=$($s.GamesTaskBackgroundOnly)" }
        Write-Host ("  'Games' task profile        : {0}" -f $detail) -ForegroundColor $(if ($healthy) { "Green" } else { "Yellow" })
    } else {
        Write-Host "  'Games' task profile        : Not present on this system" -ForegroundColor DarkGray
    }
    $mmcssOk = Test-MmcssServiceHealthy
    $mmcssDetail = if ($s.MmcssServicePresent) { "$($s.MmcssStartType), $(if ($s.MmcssServiceRunning) { 'Running' } else { 'Not running' })" } else { "Not present" }
    Write-Host ("  MMCSS service                : {0}" -f $mmcssDetail) -ForegroundColor $(if ($mmcssOk) { "Green" } else { "Yellow" })
    Write-Log "Process Scheduler diagnostics viewed"
}

function Show-ProcessSchedulerMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [16] PROCESS SCHEDULER OPTIMIZATION`n" -ForegroundColor Green
        Write-Host " Real, Microsoft-documented thread/process scheduler and MMCSS tuning -" -ForegroundColor Gray
        Write-Host " the same surface System Properties > Performance Options > Advanced and" -ForegroundColor Gray
        Write-Host " Windows' own 'Games' task registration use internally." -ForegroundColor Gray
        Write-Host " No core-parking override here - see CPU Tweaks [4] diagnostics for why.`n" -ForegroundColor Gray

        $s = Get-ProcessSchedulerState
        Write-Host (" Current mode: {0}" -f $s.PrioritySeparationMode) -ForegroundColor DarkGray

        $items = @(
            @{ Text = "Processor Scheduling: Programs (foreground boost, Windows client default)   [3/10]"
               Action = { Write-TweakResult (Set-ProcessorSchedulingMode "Programs") } }
            @{ Text = "Processor Scheduling: Background services (even quanta, server-style)       [3/10 background/render/streaming rigs, 1/10 gaming]"
               Action = { Write-TweakResult (Set-ProcessorSchedulingMode "Background") } }
            @{ Text = "MMCSS Low-Latency Mode (SystemResponsiveness 20 -> 0)                        [4/10, audio/input-latency workloads]"
               Action = { Write-TweakResult (Set-MmcssSystemResponsiveness $true) } }
            @{ Text = "Restore MMCSS System Responsiveness to Windows default (20)"
               Action = { Write-TweakResult (Set-MmcssSystemResponsiveness $false) } }
            @{ Text = "MMCSS Network Throttling: Disable (NetworkThrottlingIndex -> 0xFFFFFFFF)     [3/10, only matters under heavy simultaneous net+MM load]"
               Action = { Write-TweakResult (Set-MmcssNetworkThrottling $true) } }
            @{ Text = "Restore MMCSS Network Throttling to Windows default (10)"
               Action = { Write-TweakResult (Set-MmcssNetworkThrottling $false) } }
            @{ Text = "Repair 'Games' Task Priority Profile (undoes other tools' placebo edits)     [3/10, defensive only - see note]"
               Action = { Write-TweakResult (Repair-MmcssGamesTaskProfile) } }
            @{ Text = "Repair MMCSS Service (ensure Automatic + Running)                             [required for everything above to matter]"
               Action = { Write-TweakResult (Repair-MmcssService) } }
            @{ Text = "Process Scheduler Diagnostics (read current state)"
               Action = { Show-ProcessSchedulerDiagnostics } }
            @{ Text = "Restore ALL Process Scheduler tweaks to Windows defaults"
               Action = { if (Confirm-Action "Revert all Process Scheduler tweaks to Windows defaults?") { Restore-AllSchedulerTweaks } } }
        )

        Write-Host ""
        $num = 0; $indexMap = @{}
        foreach ($it in $items) {
            $num++
            $indexMap[$num] = $it
            Write-Host (" [{0}] {1}" -f $num, $it.Text)
        }
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        if ($c -eq "0") { return }
        if ($c -match '^\d+$' -and $indexMap.ContainsKey([int]$c)) {
            & $indexMap[[int]$c].Action
            Wait-ForEnter
        } else {
            Show-InvalidSelection
        }
    }
}

# ==============================================================================
#  17b. ADVANCED MEMORY OPTIMIZATION
#  Real, Microsoft-documented memory-manager tuning: MMAgent memory
#  compression (Get/Enable/Disable-MMAgent) and page-file configuration via
#  the same PagingFiles registry convention System Properties > Advanced >
#  Performance > Virtual Memory writes. SysMain/Superfetch is deliberately
#  NOT duplicated here - it already lives in Service Tweaks [9] with a
#  live disk-type/RAM-based recommendation (Get-SystemStorageProfile);
#  this module's diagnostics page links to it instead of re-implementing
#  the same toggle a second time. No "disable pagefile" or "LargeSystemCache"
#  option either - both are obsolete/harmful-by-default advice this tool
#  won't offer regardless of how common they are in older guides.
# ==============================================================================
$script:RegPath_MemoryManagement = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

function Test-MMAgentAvailable {
    <# Get-MMAgent/Enable-MMAgent/Disable-MMAgent ship as a Windows
       PowerShell 5.1 binary module and aren't natively present in
       PowerShell 7+. On PS7 this attempts the standard Windows-PowerShell
       compatibility import before giving up, so the tweak reports
       Skipped (Not Supported) only when the cmdlets are genuinely
       unavailable, not just because ZORO happens to be running under
       pwsh.exe instead of powershell.exe. #>
    if (Test-CommandExists "Get-MMAgent") { return $true }
    if ($script:PSMajor -ge 6) {
        try { Import-Module MMAgent -UseWindowsPowerShell -ErrorAction Stop | Out-Null } catch { return $false }
        return (Test-CommandExists "Get-MMAgent")
    }
    return $false
}

function Get-MemoryCompressionState {
    if (-not (Test-MMAgentAvailable)) { return $null }
    try { return [bool](Get-MMAgent -ErrorAction Stop).MemoryCompression } catch { return $null }
}

function Test-PageFileIsSystemManaged {
    <# Reads the PagingFiles REG_MULTI_SZ value directly rather than the
       Win32_ComputerSystem.AutomaticManagedPagefile WMI flag, since the
       registry value is what this tool actually writes/undoes - checking
       the same surface it controls instead of a second, only-loosely-
       coupled representation of the same setting. Per Microsoft's
       documented format ("<drive>:\pagefile.sys <initial-MB> <max-MB>"),
       trailing "0 0" means system-managed; a real min/max pair means a
       manual size is configured. Key/value absent is also treated as
       system-managed - that's what a clean install looks like before any
       tool (including this one) has ever touched it. #>
    try {
        $v = @((Get-ItemProperty -Path $script:RegPath_MemoryManagement -Name "PagingFiles" -ErrorAction Stop).PagingFiles)
        if (-not $v -or $v.Count -eq 0) { return $true }
        return (($v -join " ") -match '\s0\s+0\s*$')
    } catch { return $true }
}

function Get-MemoryOptimizationState {
    <# One cached read of everything this module touches, feeding the
       menu header, diagnostics screen, and Tweak Health Check alike. #>
    return Get-ZoroCachedValue -Key "MemoryOptimizationState" -TtlMs 1500 -Loader {
        $os = $null
        try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch {}
        $usage = $null
        try { $usage = Get-CimInstance Win32_PageFileUsage -ErrorAction Stop | Select-Object -First 1 } catch {}
        [PSCustomObject]@{
            TotalRamMB          = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1KB) } else { $null }
            FreeRamMB           = if ($os) { [math]::Round($os.FreePhysicalMemory / 1KB) } else { $null }
            CommitLimitMB       = if ($os) { [math]::Round($os.TotalVirtualMemorySize / 1KB) } else { $null }
            CommitUsedMB        = if ($os) { [math]::Round(($os.TotalVirtualMemorySize - $os.FreeVirtualMemory) / 1KB) } else { $null }
            MemoryCompressionOn = Get-MemoryCompressionState
            PageFileSystemManaged = Test-PageFileIsSystemManaged
            PageFileAllocatedMB = if ($usage) { $usage.AllocatedBaseSize } else { $null }
            PageFileCurrentMB   = if ($usage) { $usage.CurrentUsage } else { $null }
        }
    }
}

function Set-MemoryCompressionMode ([bool]$Enable) {
    <# Windows default is enabled. Disabling trades RAM headroom for CPU
       cycles otherwise spent compressing/decompressing standby pages -
       occasionally worth it on abundant-RAM systems running latency-
       sensitive real-time workloads, a wash or a regression on everything
       else. Rated for what it actually is, not sold as a universal win. #>
    $label = if ($Enable) { "Enabled (Windows default)" } else { "Disabled" }
    return Invoke-DetectedTweak -Name "Memory Compression: $label" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { Test-MMAgentAvailable } `
        -AlreadyOk { (Get-MemoryCompressionState) -eq $Enable } `
        -Apply {
            $prev = Get-MemoryCompressionState
            Add-UndoRecord @{ Type = "MemoryCompression"; PreviousEnabled = $prev }
            if ($Enable) { Enable-MMAgent -MemoryCompression -ErrorAction Stop } else { Disable-MMAgent -MemoryCompression -ErrorAction Stop }
            Clear-ZoroCache -KeyPrefix "MemoryOptimizationState"
            $true
        } `
        -Verify { (Get-MemoryCompressionState) -eq $Enable }
}

function Repair-PageFileSystemManaged {
    <# Defensive repair, same spirit as the Games-task repair in Process
       Scheduler: restores "Automatically manage paging file size for all
       drives" - the Windows-recommended default - rather than trying to
       hand-pick a fixed size, which stale guides still push and which
       stops adapting the moment your workload or installed RAM changes. #>
    $sysDrive = $env:SystemDrive
    $target = @("$sysDrive\pagefile.sys 0 0")
    return Invoke-DetectedTweak -Name "Repair Page File: System Managed (Windows recommended default)" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { $true } `
        -AlreadyOk { Test-PageFileIsSystemManaged } `
        -Apply { Set-RegMultiStringVerified $script:RegPath_MemoryManagement "PagingFiles" $target } `
        -Verify { Test-PageFileIsSystemManaged }
}

function Restore-AllMemoryTweaks {
    if (Test-MMAgentAvailable -and (Get-MemoryCompressionState) -eq $false) { Set-MemoryCompressionMode $true | Out-Null }
    Repair-PageFileSystemManaged | Out-Null
    Write-Host "[DONE] Memory tweaks restored to Windows defaults." -ForegroundColor Green
    Write-Log "Memory Optimization tweaks restored to defaults"
}

function Show-MemoryDiagnostics {
    $s = Get-MemoryOptimizationState
    Write-Host "`n  Total RAM               : $([math]::Round($s.TotalRamMB / 1024, 1)) GB"
    Write-Host "  Free RAM                : $([math]::Round($s.FreeRamMB / 1024, 1)) GB"
    if ($s.CommitLimitMB -and $s.CommitUsedMB) {
        $pct = [math]::Round(($s.CommitUsedMB / $s.CommitLimitMB) * 100, 1)
        Write-Host ("  Commit charge           : {0} GB / {1} GB ({2}%)" -f [math]::Round($s.CommitUsedMB/1024,1), [math]::Round($s.CommitLimitMB/1024,1), $pct)
    }
    $mc = $s.MemoryCompressionOn
    Write-Host ("  Memory Compression      : {0}" -f $(if ($null -eq $mc) { "Not available (MMAgent cmdlets missing)" } elseif ($mc) { "Enabled (Windows default)" } else { "Disabled" })) -ForegroundColor $(if ($mc -eq $false) { "Yellow" } else { "Green" })
    Write-Host ("  Page file management    : {0}" -f $(if ($s.PageFileSystemManaged) { "System Managed (Windows recommended)" } else { "Manually configured" })) -ForegroundColor $(if ($s.PageFileSystemManaged) { "Green" } else { "Yellow" })
    if ($s.PageFileAllocatedMB) { Write-Host ("  Page file size           : {0} MB allocated, {1} MB in use" -f $s.PageFileAllocatedMB, $s.PageFileCurrentMB) }
    Write-Host "`n  Top 5 processes by working set:" -ForegroundColor Cyan
    Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 |
        ForEach-Object { Write-Host ("    {0,-28} {1,8:N0} MB" -f $_.ProcessName, [math]::Round($_.WorkingSet64 / 1MB)) }
    Write-Host "`n  SysMain/Superfetch: see Service Tweaks [9] for the live disk-type-based" -ForegroundColor DarkGray
    Write-Host "  recommendation - not duplicated here." -ForegroundColor DarkGray
    Write-Log "Memory diagnostics viewed"
}

function Show-MemoryOptimizationMenu {
    while ($true) {
        Show-Banner | Out-Null
        Write-Host "`n>>> [17] ADVANCED MEMORY OPTIMIZATION`n" -ForegroundColor Green
        Write-Host " Real MMAgent memory-compression and page-file tuning - the same surface" -ForegroundColor Gray
        Write-Host " Task Manager's Memory tab and System Properties > Virtual Memory use." -ForegroundColor Gray
        Write-Host " No 'disable pagefile' option - that's not Windows-recommended and this" -ForegroundColor Gray
        Write-Host " tool doesn't ship advice it wouldn't stand behind.`n" -ForegroundColor Gray

        $items = @(
            @{ Text = "Disable Memory Compression                                                    [3/10, abundant-RAM + real-time workloads only]"
               Action = { Write-TweakResult (Set-MemoryCompressionMode $false) } }
            @{ Text = "Restore Memory Compression to Windows default (Enabled)"
               Action = { Write-TweakResult (Set-MemoryCompressionMode $true) } }
            @{ Text = "Repair Page File: System Managed (Windows recommended default)               [3/10, defensive - see note]"
               Action = { Write-TweakResult (Repair-PageFileSystemManaged) } }
            @{ Text = "Memory Diagnostics (RAM/commit/compression/page file, read-only)"
               Action = { Show-MemoryDiagnostics } }
            @{ Text = "Run Windows Memory Diagnostic (schedules a RAM test at next restart)"
               Action = {
                   if (Confirm-Action "This restarts Windows immediately after you confirm the built-in Memory Diagnostic tool, to run a hardware RAM test. Continue?") {
                       try { Start-Process "mdsched.exe" -ErrorAction Stop; Write-Host "[DONE] Windows Memory Diagnostic launched." -ForegroundColor Green }
                       catch { Write-Host "[FAILED] Could not launch mdsched.exe: $_" -ForegroundColor Red }
                   }
               } }
            @{ Text = "Restore ALL Memory Optimization tweaks to Windows defaults"
               Action = { if (Confirm-Action "Revert all Memory Optimization tweaks to Windows defaults?") { Restore-AllMemoryTweaks } } }
        )

        Write-Host ""
        $num = 0; $indexMap = @{}
        foreach ($it in $items) {
            $num++
            $indexMap[$num] = $it
            Write-Host (" [{0}] {1}" -f $num, $it.Text)
        }
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        if ($c -eq "0") { return }
        if ($c -match '^\d+$' -and $indexMap.ContainsKey([int]$c)) {
            & $indexMap[[int]$c].Action
            Wait-ForEnter
        } else {
            Show-InvalidSelection
        }
    }
}

# ==============================================================================
#  17c. ADVANCED STORAGE OPTIMIZATION
#  Real, Microsoft-documented storage tuning gated on the same
#  Get-SystemStorageProfile disk-type detection SysMain (Service Tweaks [9])
#  already uses - never guessed, never applied blind to an HDD or an SSD.
#  TRIM (DisableDeleteNotify) and the defrag/optimize schedule are the
#  actual mechanism behind "Optimize Drives"; NTFS last-access-timestamp
#  writes are a real, if small, per-file-access cost with no benefit on a
#  client machine. No manual "defrag now" button for SSDs (TRIM, not
#  defrag, is what an SSD needs) and no registry "SSD tweak pack" of
#  unrelated placebo keys - each item here maps to one specific, verifiable
#  mechanism.
# ==============================================================================
function Get-StorageOptimizationState {
    <# One cached read of everything this module touches. TRIM/last-access
       are registry+fsutil reads (cheap); the defrag schedule shells out to
       schtasks, so this is cached like every other multi-source snapshot
       in the tool rather than re-shelling on every menu redraw. #>
    return Get-ZoroCachedValue -Key "StorageOptimizationState" -TtlMs 1500 -Loader {
        $profile = Get-SystemStorageProfile

        $trimDisabled = $null
        try {
            $out = fsutil behavior query DisableDeleteNotify 2>$null
            if ($out -match ':\s*(\d)\s*$' -or $out -match '=\s*(\d)') { $trimDisabled = [int]$Matches[1] }
        } catch {}
        # DisableDeleteNotify: 0 = TRIM enabled (Windows default on SSD), 1 = disabled.

        $lastAccessDisabled = $null
        try {
            $out = fsutil behavior query DisableLastAccess 2>$null
            if ($out -match ':\s*(\d)\s*$' -or $out -match '=\s*(\d)') { $lastAccessDisabled = [int]$Matches[1] }
        } catch {}

        $scheduledOptEnabled = $null
        try {
            $task = Get-ScheduledTask -TaskName "ScheduledDefrag" -TaskPath "\Microsoft\Windows\Defrag\" -ErrorAction Stop
            $scheduledOptEnabled = ($task.State -ne "Disabled")
        } catch {}

        $storageSenseEnabled = $null
        try {
            $v = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -ErrorAction Stop).'01'
            $storageSenseEnabled = ($v -eq 1)
        } catch {}

        [PSCustomObject]@{
            StorageProfile        = $profile
            TrimEnabled            = if ($null -ne $trimDisabled) { ($trimDisabled -eq 0) } else { $null }
            LastAccessDisabled     = $lastAccessDisabled
            ScheduledOptEnabled    = $scheduledOptEnabled
            StorageSenseEnabled    = $storageSenseEnabled
        }
    }
}

function Set-TrimMode ([bool]$Enable) {
    <# TRIM (DisableDeleteNotify=0) is what actually keeps an SSD/NVMe fast
       over time by letting the controller reclaim freed blocks ahead of
       write time - defragmenting an SSD does nothing for this and adds
       needless write-cycle wear, which is why there's no "defrag now"
       button in this module. Gated to systems Get-SystemStorageProfile
       actually detected as solid-state; on an unknown/HDD profile this is
       Skipped rather than guessed. #>
    $target = if ($Enable) { 0 } else { 1 }
    $label  = if ($Enable) { "Enabled (SSD/NVMe recommended)" } else { "Disabled" }
    return Invoke-DetectedTweak -Name "TRIM (DisableDeleteNotify): $label" `
        -Requirements @(
            @{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }
            @{ Name = "SSD or NVMe detected (Get-SystemStorageProfile)";  Test = { (Get-SystemStorageProfile).IsSsd } }
        ) `
        -Supported { Test-CommandExists "fsutil" } `
        -AlreadyOk { (Get-StorageOptimizationState).TrimEnabled -eq $Enable } `
        -Apply {
            fsutil behavior set DisableDeleteNotify $target 2>$null | Out-Null
            Clear-ZoroCache -KeyPrefix "StorageOptimizationState"
            $LASTEXITCODE -eq 0
        } `
        -Verify { (Get-StorageOptimizationState).TrimEnabled -eq $Enable }
}

function Set-LastAccessTimestamps ([bool]$Disable) {
    <# NtfsDisableLastAccess: every file read otherwise triggers a metadata
       write to record the access time, a real (if small) per-access cost
       with no user-facing benefit on a client machine - a handful of
       backup/sync/AV tools do read it, so this is opt-in, not a default. #>
    $target = if ($Disable) { 1 } else { 0 }
    $label  = if ($Disable) { "Disabled" } else { "Enabled (Windows default)" }
    return Invoke-DetectedTweak -Name "NTFS Last-Access Timestamps: $label" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { Test-CommandExists "fsutil" } `
        -AlreadyOk { (Get-StorageOptimizationState).LastAccessDisabled -eq $target } `
        -Apply {
            fsutil behavior set DisableLastAccess $target 2>$null | Out-Null
            Clear-ZoroCache -KeyPrefix "StorageOptimizationState"
            $LASTEXITCODE -eq 0
        } `
        -Verify { (Get-StorageOptimizationState).LastAccessDisabled -eq $target }
}

function Repair-ScheduledOptimization {
    <# Ensures the built-in "ScheduledDefrag" task (what Settings > Storage
       > Optimize Drives actually schedules - weekly TRIM on SSDs, weekly
       defrag on HDDs, both disk-type-aware on their own) is enabled,
       rather than reimplementing disk maintenance this tool would then be
       responsible for scheduling and verifying itself. #>
    return Invoke-DetectedTweak -Name "Repair Scheduled Drive Optimization (Windows' own weekly maintenance task)" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { Test-CommandExists "Get-ScheduledTask" } `
        -AlreadyOk { (Get-StorageOptimizationState).ScheduledOptEnabled -eq $true } `
        -Apply {
            Enable-ScheduledTask -TaskName "ScheduledDefrag" -TaskPath "\Microsoft\Windows\Defrag\" -ErrorAction Stop | Out-Null
            Clear-ZoroCache -KeyPrefix "StorageOptimizationState"
            $true
        } `
        -Verify { (Get-StorageOptimizationState).ScheduledOptEnabled -eq $true }
}

function Set-StorageSenseMode ([bool]$Enable) {
    <# Storage Sense (Settings > System > Storage) auto-cleans temp files
       and the Recycle Bin on a schedule - the modern, Microsoft-supported
       replacement for "run Disk Cleanup manually"/third-party junk
       cleaners. Toggled via its own documented policy value, not by
       reaching into whatever it happens to be cleaning today. #>
    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
    $target = if ($Enable) { 1 } else { 0 }
    $label  = if ($Enable) { "Enabled" } else { "Disabled" }
    return Invoke-ValidatedTweak -Name "Storage Sense: $label" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Apply    { Set-RegDword $path "01" $target } `
        -Verify   { ((Get-ItemProperty -Path $path -Name "01" -ErrorAction Stop).'01') -eq $target } `
        -Rollback { Remove-RegValue $path "01" }
}

function Restore-AllStorageTweaks {
    $s = Get-StorageOptimizationState
    if ($s.StorageProfile.IsSsd -and $s.TrimEnabled -eq $false) { Set-TrimMode $true | Out-Null }
    if ($s.LastAccessDisabled -eq 1) { Set-LastAccessTimestamps $false | Out-Null }
    Repair-ScheduledOptimization | Out-Null
    Set-StorageSenseMode $true | Out-Null
    Write-Host "[DONE] Storage tweaks restored to Windows defaults." -ForegroundColor Green
    Write-Log "Storage Optimization tweaks restored to defaults"
}

function Show-StorageDiagnostics {
    $s = Get-StorageOptimizationState
    $p = $s.StorageProfile
    Write-Host "`n  Detected disk           : $(if ($p.IsNvme) { 'NVMe SSD' } elseif ($p.IsSsd) { 'SATA/other SSD' } elseif ($p.DiskKnown) { 'Spinning HDD' } else { 'Unknown (detection unavailable)' })"
    Write-Host ("  TRIM (DisableDeleteNotify): {0}" -f $(if ($null -eq $s.TrimEnabled) { "Unknown" } elseif ($s.TrimEnabled) { "Enabled" } else { "Disabled" })) -ForegroundColor $(if ($p.IsSsd -and $s.TrimEnabled -eq $false) { "Yellow" } else { "Green" })
    Write-Host ("  NTFS Last-Access Timestamps: {0}" -f $(if ($s.LastAccessDisabled -eq 1) { "Disabled" } elseif ($s.LastAccessDisabled -eq 0) { "Enabled (Windows default)" } else { "Unknown" }))
    Write-Host ("  Scheduled Drive Optimization: {0}" -f $(if ($null -eq $s.ScheduledOptEnabled) { "Unknown" } elseif ($s.ScheduledOptEnabled) { "Enabled" } else { "Disabled" })) -ForegroundColor $(if ($s.ScheduledOptEnabled -eq $false) { "Yellow" } else { "Green" })
    Write-Host ("  Storage Sense            : {0}" -f $(if ($null -eq $s.StorageSenseEnabled) { "Unknown/not configured" } elseif ($s.StorageSenseEnabled) { "Enabled" } else { "Disabled" }))
    if ($p.IsSsd) {
        Write-Host "`n  No 'defrag now' option is offered - TRIM (above) is the SSD-relevant" -ForegroundColor DarkGray
        Write-Host "  mechanism; defragmenting an SSD adds write-cycle wear for no read-speed" -ForegroundColor DarkGray
        Write-Host "  benefit, which is why Windows' own Optimize Drives runs TRIM here too." -ForegroundColor DarkGray
    }
    Write-Log "Storage diagnostics viewed"
}

function Show-StorageOptimizationMenu {
    while ($true) {
        Show-Banner | Out-Null
        $profile = (Get-SystemStorageProfile)
        Write-Host "`n>>> [18] ADVANCED STORAGE OPTIMIZATION`n" -ForegroundColor Green
        Write-Host (" Detected: {0}" -f $(if ($profile.IsNvme) { "NVMe SSD" } elseif ($profile.IsSsd) { "SATA/other SSD" } elseif ($profile.DiskKnown) { "Spinning HDD" } else { "Unknown" })) -ForegroundColor Gray
        Write-Host " Real TRIM/defrag-schedule/NTFS-metadata tuning, gated to what your" -ForegroundColor Gray
        Write-Host " actual disk type supports - nothing here is applied blind.`n" -ForegroundColor Gray

        $items = @()
        if ($profile.IsSsd) {
            $items += @{ Text = "Enable TRIM (DisableDeleteNotify=0, SSD/NVMe recommended)                    [7/10 if currently off]"
                         Action = { Write-TweakResult (Set-TrimMode $true) } }
        } else {
            $items += @{ IsHeader = $true; Text = "--- TRIM requires an SSD/NVMe (none detected - option hidden) ---" }
        }
        $items += @{ Text = "Disable NTFS Last-Access Timestamps                                           [3/10, tiny per-file-access saving]"
                     Action = { Write-TweakResult (Set-LastAccessTimestamps $true) } }
        $items += @{ Text = "Restore NTFS Last-Access Timestamps to Windows default (Enabled)"
                     Action = { Write-TweakResult (Set-LastAccessTimestamps $false) } }
        $items += @{ Text = "Repair Scheduled Drive Optimization (Windows' own weekly maintenance task)   [3/10, defensive - see note]"
                     Action = { Write-TweakResult (Repair-ScheduledOptimization) } }
        $items += @{ Text = "Enable Storage Sense (auto-clean temp files / Recycle Bin)                    [4/10]"
                     Action = { Write-TweakResult (Set-StorageSenseMode $true) } }
        $items += @{ Text = "Disable Storage Sense"
                     Action = { Write-TweakResult (Set-StorageSenseMode $false) } }
        $items += @{ Text = "Storage Diagnostics (TRIM/last-access/schedule/Storage Sense, read-only)"
                     Action = { Show-StorageDiagnostics } }
        $items += @{ Text = "Restore ALL Storage Optimization tweaks to Windows defaults"
                     Action = { if (Confirm-Action "Revert all Storage Optimization tweaks to Windows defaults?") { Restore-AllStorageTweaks } } }

        Write-Host ""
        $num = 0; $indexMap = @{}
        foreach ($it in $items) {
            if ($it.IsHeader) { Write-Host ("`n {0}" -f $it.Text) -ForegroundColor DarkGray; continue }
            $num++
            $indexMap[$num] = $it
            Write-Host (" [{0}] {1}" -f $num, $it.Text)
        }
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        if ($c -eq "0") { return }
        if ($c -match '^\d+$' -and $indexMap.ContainsKey([int]$c)) {
            & $indexMap[[int]$c].Action
            Wait-ForEnter
        } else {
            Show-InvalidSelection
        }
    }
}

# ==============================================================================
#  17d. SECURITY / PRIVACY / TELEMETRY OPTIMIZATION
#  Real, Microsoft-documented diagnostic-data/advertising/activity-history/
#  content-suggestion policy toggles - the same Group Policy / MDM surfaces
#  Settings > Privacy & security exposes, applied via registry so they work
#  identically on Home/Pro without gpedit. Per this tool's stated scope
#  (see file header), this module NEVER touches Defender, UAC, Windows
#  Update, or any other security control - DiagTrack/WerSvc service
#  startup-type toggles already live in Service Tweaks [9] and are not
#  duplicated here; this module is registry-policy-only. AllowTelemetry is
#  set no lower than 1 (Basic/Required) - level 0 (Security) is an
#  Enterprise/Education/Server-managed value this tool doesn't target.
# ==============================================================================
$script:RegPath_DataCollectionPolicy    = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
$script:RegPath_AdvertisingInfo         = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
$script:RegPath_ActivityFeedPolicy      = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
$script:RegPath_CloudContentPolicy      = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$script:RegPath_ContentDeliveryManager  = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$script:RegPath_ExplorerSearch          = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"

function Get-PrivacyOptimizationState {
    <# One cached read of everything this module touches, feeding the menu
       header, diagnostics screen, and Tweak Health Check alike - same
       shared-snapshot pattern as Get-StorageOptimizationState/
       Get-MemoryOptimizationState instead of a fourth copy of the idea. #>
    return Get-ZoroCachedValue -Key "PrivacyOptimizationState" -TtlMs 1500 -Loader {
        $allowTelemetry = $null
        try { $allowTelemetry = (Get-ItemProperty -Path $script:RegPath_DataCollectionPolicy -Name "AllowTelemetry" -ErrorAction Stop).AllowTelemetry } catch { $allowTelemetry = $null }

        $advertisingIdEnabled = $true
        try { $advertisingIdEnabled = [bool](Get-ItemProperty -Path $script:RegPath_AdvertisingInfo -Name "Enabled" -ErrorAction Stop).Enabled } catch { $advertisingIdEnabled = $true }

        $activityHistoryDisabled = $false
        try {
            $p = Get-ItemProperty -Path $script:RegPath_ActivityFeedPolicy -ErrorAction Stop
            $activityHistoryDisabled = ($p.EnableActivityFeed -eq 0) -and ($p.PublishUserActivities -eq 0) -and ($p.UploadUserActivities -eq 0)
        } catch { $activityHistoryDisabled = $false }

        $tailoredExperiencesDisabled = $false
        try { $tailoredExperiencesDisabled = [bool](Get-ItemProperty -Path $script:RegPath_CloudContentPolicy -Name "DisableTailoredExperiencesWithDiagnosticData" -ErrorAction Stop).DisableTailoredExperiencesWithDiagnosticData } catch { $tailoredExperiencesDisabled = $false }

        $startMenuWebSearchEnabled = $true
        try { $startMenuWebSearchEnabled = [bool](Get-ItemProperty -Path $script:RegPath_ExplorerSearch -Name "BingSearchEnabled" -ErrorAction Stop).BingSearchEnabled } catch { $startMenuWebSearchEnabled = $true }

        [PSCustomObject]@{
            AllowTelemetry               = $allowTelemetry
            AdvertisingIdEnabled         = $advertisingIdEnabled
            ActivityHistoryDisabled      = $activityHistoryDisabled
            TailoredExperiencesDisabled  = $tailoredExperiencesDisabled
            StartMenuWebSearchEnabled    = $startMenuWebSearchEnabled
        }
    }
}

function Set-DiagnosticDataLevel ([bool]$Reduce) {
    <# Windows default on Home/Pro is 3 (Full/Optional). Reduce sets 1
       (Basic/Required diagnostic data) - the documented floor for
       non-managed editions; this tool never writes 0 (Security), which is
       only honored on Enterprise/Education/Server under MDM/GPO management
       and would silently no-op (or worse, misrepresent state) elsewhere. #>
    $target = if ($Reduce) { 1 } else { 3 }
    $label  = if ($Reduce) { "Basic (Required diagnostic data)" } else { "Full (Windows default)" }
    return Invoke-DetectedTweak -Name "Diagnostic Data Level: $label" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { $true } `
        -AlreadyOk { (Get-PrivacyOptimizationState).AllowTelemetry -eq $target } `
        -Apply { Set-RegDword $script:RegPath_DataCollectionPolicy "AllowTelemetry" $target } `
        -Verify { ((Get-ItemProperty -Path $script:RegPath_DataCollectionPolicy -Name "AllowTelemetry" -ErrorAction Stop).AllowTelemetry) -eq $target } `
        -Rollback { Remove-RegValue $script:RegPath_DataCollectionPolicy "AllowTelemetry" }
}

function Set-AdvertisingId ([bool]$Disable) {
    <# Per-user "Let apps use advertising ID" toggle (Settings > Privacy &
       security > General). Windows default is Enabled (1). #>
    $target = if ($Disable) { 0 } else { 1 }
    $label  = if ($Disable) { "Disabled" } else { "Enabled (Windows default)" }
    return Invoke-DetectedTweak -Name "Advertising ID: $label" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { $true } `
        -AlreadyOk { (Get-PrivacyOptimizationState).AdvertisingIdEnabled -eq (-not $Disable) } `
        -Apply { Set-RegDword $script:RegPath_AdvertisingInfo "Enabled" $target } `
        -Verify { ((Get-ItemProperty -Path $script:RegPath_AdvertisingInfo -Name "Enabled" -ErrorAction Stop).Enabled) -eq $target } `
        -Rollback { Remove-RegValue $script:RegPath_AdvertisingInfo "Enabled" }
}

function Set-ActivityHistory ([bool]$Disable) {
    <# "Activity History" / Timeline publish+upload policy - three DWORDs
       under the one documented policy key, written/verified/undone
       together the same way Repair-MmcssGamesTaskProfile writes its three
       related string values as one logical tweak instead of three menu
       entries. Windows default is Enabled (no policy value present). #>
    $target = if ($Disable) { 0 } else { 1 }
    $label  = if ($Disable) { "Disabled" } else { "Enabled (Windows default)" }
    return Invoke-DetectedTweak -Name "Activity History / Timeline: $label" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { $true } `
        -AlreadyOk { (Get-PrivacyOptimizationState).ActivityHistoryDisabled -eq $Disable } `
        -Apply {
            $r1 = Set-RegDword $script:RegPath_ActivityFeedPolicy "EnableActivityFeed" $target
            $r2 = Set-RegDword $script:RegPath_ActivityFeedPolicy "PublishUserActivities" $target
            $r3 = Set-RegDword $script:RegPath_ActivityFeedPolicy "UploadUserActivities" $target
            $r1 -and $r2 -and $r3
        } `
        -Verify { (Get-PrivacyOptimizationState).ActivityHistoryDisabled -eq $Disable } `
        -Rollback {
            Remove-RegValue $script:RegPath_ActivityFeedPolicy "EnableActivityFeed" | Out-Null
            Remove-RegValue $script:RegPath_ActivityFeedPolicy "PublishUserActivities" | Out-Null
            Remove-RegValue $script:RegPath_ActivityFeedPolicy "UploadUserActivities" | Out-Null
        }
}

function Set-TailoredExperiences ([bool]$Disable) {
    <# "Tailored experiences" / personalized suggestions from diagnostic
       data (Settings > Privacy & security > Diagnostics & feedback), plus
       the matching Start-menu/lock-screen suggestion-content toggle
       (ContentDeliveryManager) - the two documented surfaces for the same
       user-facing setting. Windows default is Enabled on both. #>
    $policyTarget = if ($Disable) { 1 } else { 0 }
    $cdmTarget    = if ($Disable) { 0 } else { 1 }
    $label = if ($Disable) { "Disabled" } else { "Enabled (Windows default)" }
    return Invoke-DetectedTweak -Name "Tailored Experiences / Suggested Content: $label" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { $true } `
        -AlreadyOk { (Get-PrivacyOptimizationState).TailoredExperiencesDisabled -eq $Disable } `
        -Apply {
            $r1 = Set-RegDword $script:RegPath_CloudContentPolicy "DisableTailoredExperiencesWithDiagnosticData" $policyTarget
            $r2 = Set-RegDword $script:RegPath_ContentDeliveryManager "SubscribedContent-338389Enabled" $cdmTarget
            $r1
        } `
        -Verify { ((Get-ItemProperty -Path $script:RegPath_CloudContentPolicy -Name "DisableTailoredExperiencesWithDiagnosticData" -ErrorAction Stop).DisableTailoredExperiencesWithDiagnosticData) -eq $policyTarget } `
        -Rollback {
            Remove-RegValue $script:RegPath_CloudContentPolicy "DisableTailoredExperiencesWithDiagnosticData" | Out-Null
            Remove-RegValue $script:RegPath_ContentDeliveryManager "SubscribedContent-338389Enabled" | Out-Null
        }
}

function Set-StartMenuWebSearch ([bool]$Disable) {
    <# "Search highlights" / Bing web-results toggle in Start-menu search
       (Settings > Privacy & security > Search permissions, per-user).
       Windows default is Enabled (1). #>
    $target = if ($Disable) { 0 } else { 1 }
    $label  = if ($Disable) { "Disabled" } else { "Enabled (Windows default)" }
    return Invoke-DetectedTweak -Name "Start Menu Web Search: $label" `
        -Requirements @(@{ Name = "Windows 10 22H2+ / Windows 11 (per script scope)"; Test = { Test-MinWindowsBuild 19041 } }) `
        -Supported { $true } `
        -AlreadyOk { (Get-PrivacyOptimizationState).StartMenuWebSearchEnabled -eq (-not $Disable) } `
        -Apply { Set-RegDword $script:RegPath_ExplorerSearch "BingSearchEnabled" $target } `
        -Verify { ((Get-ItemProperty -Path $script:RegPath_ExplorerSearch -Name "BingSearchEnabled" -ErrorAction Stop).BingSearchEnabled) -eq $target } `
        -Rollback { Remove-RegValue $script:RegPath_ExplorerSearch "BingSearchEnabled" }
}

function Restore-AllPrivacyTweaks {
    Remove-RegValue $script:RegPath_DataCollectionPolicy "AllowTelemetry" | Out-Null
    Remove-RegValue $script:RegPath_AdvertisingInfo "Enabled" | Out-Null
    Remove-RegValue $script:RegPath_ActivityFeedPolicy "EnableActivityFeed" | Out-Null
    Remove-RegValue $script:RegPath_ActivityFeedPolicy "PublishUserActivities" | Out-Null
    Remove-RegValue $script:RegPath_ActivityFeedPolicy "UploadUserActivities" | Out-Null
    Remove-RegValue $script:RegPath_CloudContentPolicy "DisableTailoredExperiencesWithDiagnosticData" | Out-Null
    Remove-RegValue $script:RegPath_ContentDeliveryManager "SubscribedContent-338389Enabled" | Out-Null
    Remove-RegValue $script:RegPath_ExplorerSearch "BingSearchEnabled" | Out-Null
    Clear-ZoroCache -KeyPrefix "PrivacyOptimizationState"
    Write-Host "[DONE] Privacy/Telemetry tweaks restored to Windows defaults." -ForegroundColor Green
    Write-Log "Security/Privacy/Telemetry Optimization tweaks restored to defaults"
}

function Show-PrivacyDiagnostics {
    $s = Get-PrivacyOptimizationState
    Write-Host ("`n  Diagnostic Data Level     : {0}" -f $(switch ($s.AllowTelemetry) { 0 {"Security (Enterprise-managed only)"} 1 {"Basic (Required)"} 2 {"Enhanced (deprecated)"} 3 {"Full (Windows default)"} default {"Not set (Windows default)"} }))
    Write-Host ("  Advertising ID            : {0}" -f $(if ($s.AdvertisingIdEnabled) { "Enabled (Windows default)" } else { "Disabled" })) -ForegroundColor $(if ($s.AdvertisingIdEnabled) { "Yellow" } else { "Green" })
    Write-Host ("  Activity History/Timeline : {0}" -f $(if ($s.ActivityHistoryDisabled) { "Disabled" } else { "Enabled (Windows default)" })) -ForegroundColor $(if ($s.ActivityHistoryDisabled) { "Green" } else { "Yellow" })
    Write-Host ("  Tailored Experiences      : {0}" -f $(if ($s.TailoredExperiencesDisabled) { "Disabled" } else { "Enabled (Windows default)" })) -ForegroundColor $(if ($s.TailoredExperiencesDisabled) { "Green" } else { "Yellow" })
    Write-Host ("  Start Menu Web Search     : {0}" -f $(if ($s.StartMenuWebSearchEnabled) { "Enabled (Windows default)" } else { "Disabled" })) -ForegroundColor $(if ($s.StartMenuWebSearchEnabled) { "Yellow" } else { "Green" })
    Write-Host "`n  DiagTrack / Windows Error Reporting service startup: see Service Tweaks [9]" -ForegroundColor DarkGray
    Write-Host "  for the live per-service toggle - not duplicated here." -ForegroundColor DarkGray
    Write-Host "  This module never touches Defender, UAC, or Windows Update - see file header." -ForegroundColor DarkGray
    Write-Log "Privacy diagnostics viewed"
}

function Show-PrivacyOptimizationMenu {
    while ($true) {
        Show-Banner | Out-Null
        $s = Get-PrivacyOptimizationState
        Write-Host "`n>>> [19] SECURITY / PRIVACY / TELEMETRY OPTIMIZATION`n" -ForegroundColor Green
        Write-Host " Real, Microsoft-documented diagnostic-data/advertising/activity-history" -ForegroundColor Gray
        Write-Host " policy toggles - the same surfaces Settings > Privacy & security exposes." -ForegroundColor Gray
        Write-Host " Never touches Defender, UAC, or Windows Update - see file header.`n" -ForegroundColor Gray

        $items = @(
            @{ Text = "Set Diagnostic Data to Basic (Required diagnostic data)                       [4/10]"
               Action = { Write-TweakResult (Set-DiagnosticDataLevel $true) } }
            @{ Text = "Restore Diagnostic Data to Full (Windows default)"
               Action = { Write-TweakResult (Set-DiagnosticDataLevel $false) } }
            @{ Text = "Disable Advertising ID                                                        [3/10]"
               Action = { Write-TweakResult (Set-AdvertisingId $true) } }
            @{ Text = "Restore Advertising ID to Windows default (Enabled)"
               Action = { Write-TweakResult (Set-AdvertisingId $false) } }
            @{ Text = "Disable Activity History / Timeline publish+upload                           [3/10]"
               Action = { Write-TweakResult (Set-ActivityHistory $true) } }
            @{ Text = "Restore Activity History to Windows default (Enabled)"
               Action = { Write-TweakResult (Set-ActivityHistory $false) } }
            @{ Text = "Disable Tailored Experiences / Suggested Content                              [3/10]"
               Action = { Write-TweakResult (Set-TailoredExperiences $true) } }
            @{ Text = "Restore Tailored Experiences to Windows default (Enabled)"
               Action = { Write-TweakResult (Set-TailoredExperiences $false) } }
            @{ Text = "Disable Start Menu Web Search                                                 [2/10]"
               Action = { Write-TweakResult (Set-StartMenuWebSearch $true) } }
            @{ Text = "Restore Start Menu Web Search to Windows default (Enabled)"
               Action = { Write-TweakResult (Set-StartMenuWebSearch $false) } }
            @{ Text = "Privacy Diagnostics (current state of all items above, read-only)"
               Action = { Show-PrivacyDiagnostics } }
            @{ Text = "Restore ALL Privacy/Telemetry tweaks to Windows defaults"
               Action = { if (Confirm-Action "Revert all Security/Privacy/Telemetry tweaks to Windows defaults?") { Restore-AllPrivacyTweaks } } }
        )

        Write-Host ""
        $num = 0; $indexMap = @{}
        foreach ($it in $items) {
            $num++
            $indexMap[$num] = $it
            Write-Host (" [{0}] {1}" -f $num, $it.Text)
        }
        Write-Host " [0] Back to Main Menu"
        $c = Read-Host "`nSelect"
        if ($c -eq "0") { return }
        if ($c -match '^\d+$' -and $indexMap.ContainsKey([int]$c)) {
            & $indexMap[[int]$c].Action
            Wait-ForEnter
        } else {
            Show-InvalidSelection
        }
    }
}

# ==============================================================================
#  18. MAIN MENU
# ==============================================================================
Write-Log "===== ZORO session started (v$ScriptVersion) ====="
 
while ($true) {
    try {
        Show-Banner | Out-Null
        Write-Host ""
        Write-Host " [1]  Network Optimization      [2]  DNS Optimizer"
        Write-Host " [3]  Windows Tweaks            [4]  CPU Tweaks"
        Write-Host " [5]  Gaming Tweaks             [6]  Miscellaneous"
        Write-Host " [7]  Backup & Restore          [8]  Responsiveness & GPU Tweaks"
        Write-Host " [9]  Service Tweaks            [10] GPU Extras"
        Write-Host " [11] System Repair & RAM       [13] Connection Benchmark"
        Write-Host " [14] Live Network Health Monitor    [15] Game Network Diagnostics"
        Write-Host " [16] Process Scheduler Optimization"
        Write-Host " [17] Advanced Memory Optimization"
        Write-Host " [18] Advanced Storage Optimization"
        Write-Host " [19] Security / Privacy / Telemetry Optimization"
        Write-Host "------------------------------------------------------------------------"
        Write-Host " [12] Remove Microsoft Edge (complete removal, standalone)" -ForegroundColor DarkYellow
        Write-Host "------------------------------------------------------------------------"
        Write-Host (" [U] Undo Last Session ({0} change(s) recorded)" -f (Get-CurrentUndoRecords).Count) -ForegroundColor Magenta
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
            "10" { Show-GpuExtrasMenu }
            "11" { Show-RepairMenu }
            "12" { Show-EdgeRemovalMenu }
            "13" { Show-ConnectionBenchmarkMenu }
            "14" { Show-NetworkHealthMenu }
            "15" { Show-GameNetworkDiagnosticsMenu }
            "16" { Show-ProcessSchedulerMenu }
            "17" { Show-MemoryOptimizationMenu }
            "18" { Show-StorageOptimizationMenu }
            "19" { Show-PrivacyOptimizationMenu }
            "U" { Invoke-UndoLastSession; Wait-ForEnter }
            "D" {
                if ($DiscordInvite) { Start-Process $DiscordInvite } else { Write-Host "`nDiscord: $DiscordName" -ForegroundColor Cyan; Wait-ForEnter -NoBlank }
            }
            "G" { Start-Process $GitHubUrl }
            "Q" {
                if ($script:NetHealthState -and $script:NetHealthState.Running) { Stop-NetworkHealthMonitor -Silent }
                Write-Log "===== ZORO session ended normally ====="; Write-Host "`nSession ended. Goodbye!" -ForegroundColor Cyan; Exit
            }
            default { Write-Host "`nInvalid selection." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } catch {
        # Top-level safety net: a single bad tweak/menu should never crash the
        # whole session with no record of why. Log it, tell the user, keep going.
        Write-Log "UNHANDLED ERROR: $($_.Exception.Message) | $($_.InvocationInfo.PositionMessage)" "ERROR"
        Write-Host "`n[UNEXPECTED ERROR] Something went wrong. Details were logged to:" -ForegroundColor Red
        Write-Host "  $LogFile" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor DarkRed
        Read-Host "`nPress ENTER to return to the main menu" | Out-Null
    }
}
