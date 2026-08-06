# Changelog

All notable changes to ZORO Tweaking Utility are documented in this file. Versioning follows the scheme described in [`VERSIONING.md`](VERSIONING.md).

This changelog reflects the version history recorded directly in the script's own header comments, expanded here with additional context.

---

## [3.9.0] — Release-hardening pass

*No menu or user-facing behavior changes — internal reliability work.*

- **Centralized error handling.** New `Get-ZoroErrorCategory` / `Invoke-ZoroSafeOperation` functions classify every network/registry failure into one of: `RegistryLocked`, `AccessDenied`, `AdapterRestart`, `NetworkReset`, `MissingAdapter`, `UnsupportedHardware`, or `TemporaryNetworkFailure`, each paired with a specific recovery message shown to the user. This replaced roughly 15 duplicated `try/catch` blocks across the Recovery Actions menu, NIC power/RSS/Interrupt-Moderation toggles, MTU/DNS/NIC-property writers, and `Invoke-ValidatedTweak`'s apply path.
- **Network Config Consistency check.** New `Test-/Repair-NetworkConfigConsistency` cross-checks MTU/DNS/RSS-RSC on the primary adapter after MTU Discovery and DNS changes. It auto-reverts only the two unambiguous, undo-ledger-backed cases (MTU dropped below the safe floor; static DNS resolving nothing) and surfaces anything else as read-only information in the Tweak Health Check rather than silently "fixing" ambiguous states.
- **Short-TTL result cache.** `Get-ZoroCachedValue`, automatically invalidated by `Add-UndoRecord` on every tracked write, cuts down repeated `Get-NetAdapter`/CIM/WMI reads on every menu redraw — this speeds up the system snapshot in the banner, GPU vendor detection, CPU topology, storage profile, and primary/active adapter lookups.

## [3.8.0] — Game Network Diagnostics (new menu [15])

- **Automatic Best Game Adapter Detection** — classifies Ethernet/Wi-Fi/VPN/Hyper-V/VMware/VirtualBox/WSL and other virtual adapters currently carrying the active default route.
- **NIC Driver Health Check** — built on `Win32_PnPSignedDriver` + `Get-PnpDevice`, following the same "warn only on a genuine signal" precedent as the existing GPU driver check.
- **IRQ / MSI Capability Detection** with an opt-in MSI-mode enable, routed through the existing documented per-device Interrupt Management registry key and the existing `Set-RegDword` undo/verify path (no new undo record type required).
- **Bufferbloat Test** — real idle-vs-loaded latency measurement via `ping.exe` and `HttpClient`, graded A–F strictly from the measured latency increase; skipped outright if the idle ping itself fails.
- **Route Quality Analyzer** — `tracert.exe` per-hop latency/loss parsing with a multi-pass consistency check.
- **Gaming Connectivity Test** — DNS/TCP-connect/ICMP checks against Steam, Battle.net, Epic, Riot, Roblox, Xbox, PlayStation, or a custom host.
- **Advanced Diagnostics Report** — writes all of the above, plus DNS/Gateway/IPv4/IPv6/public IP, to a timestamped TXT file.

## [3.7.0] — Smart DNS Benchmark & Connection Benchmark

- **Smart DNS Benchmark** — multi-pass `Resolve-DnsName` timing across 5 providers (Cloudflare, Google, Quad9, OpenDNS, AdGuard), with auto or manual apply, tracked through the Undo ledger via a new `DnsServers` record type. DNS configuration is now also included in Backup/Restore.
- **Standalone Connection Benchmark** — Avg/Min/Max ping, jitter, and loss parsed from a single `ping.exe` run (`Get-PingStatistics`); DNS latency reuses `Test-DnsResolutionLatency`; real timed HTTP throughput; a weighted Network Quality Score that reports "Partial" if any input measurement is missing rather than silently ignoring the gap.

## [3.6.0] — Network Core: MTU Discovery, TCP Analyzer, Advanced NIC Optimizer

- **Automatic MTU Discovery** — DF-flagged ICMP binary search via `ping.exe`, applied and read back through `Set-NetIPInterface`, undoable via a new `InterfaceMtu` record type.
- **Modern TCP Analyzer** (read-only) — reports Auto-Tuning, ECN, Congestion Provider, RSS, RSC, NetworkDirect, plus `netsh` DCA/Chimney state; only actively fixes Auto-Tuning/ECN, and only when they're not already correct.
- **Advanced NIC Optimizer** — detects genuine per-driver support before touching anything; RSS/RSC detection is shared with the TCP Analyzer via `Invoke-RssRscTweaks`; buffers are raised to the driver's own advertised maximum; ARP/NS Offload and EEE are reported but never silently auto-applied — EEE remains its own explicit opt-in toggle.
- Undo engine extended with `InterfaceMtu`, `NicFeatureToggle`, and `NicAdvancedProperty` record types.

## [3.5.0] — GPU-section audit (RTX 3000–5000, RX 6000–9000)

- Fixed a SysMain/Superfetch classification bug where a SATA SSD was incorrectly treated as an HDD; `Get-SystemStorageProfile` now reads `MediaType` directly.
- Added `Test-IsLaptop` (battery + chassis signal detection), which now gates Ultimate Performance behind an explicit battery-impact confirmation on laptops.
- Removed a duplicate, non-undo-tracked HAGS writer from Gaming Tweaks in favor of the single validated `Set-HagsMode` path; rebuilt that menu as data-driven.
- HAGS entries are now hidden outright (not shown-then-refused) when prerequisites — Windows 10 build 19041+ and WDDM 2.7+ — aren't met.
- AMD/NVIDIA tweaks are grouped under explicit headers everywhere they appear together.
- Added `Get-GpuDriverInfo` (WMI driver-age/WHQL signature check), surfaced on System Requirements Check and GPU Extras whenever the driver is stale or unsigned.

## [3.4.0] — Ultimate Performance power plan & Undo Last Session

- Added the **Ultimate Performance** power plan alongside High Performance in menu [4] — an addition, not a replacement.
- Added the two-stage **Undo Last Session** system: every `Set-RegDword`/`Remove-RegValue`/service-startup write now records its prior value both in memory and to disk *before* writing, so **[U]** can roll back live during the session or after a restart/crash. This does not cover application/Edge removal, temp-file cleanup, or DISM/SFC repairs — those remain explicitly non-reversible by design.

## [3.3.0] — Detection cleanup

- Removed detection-only functions that printed a value but never gated a tweak's Supported/AlreadyOk/Verify state: PCIe link speed, Resizable BAR/SAM, standalone driver-age reporting, DirectStorage prerequisites, VRR, DX12 Ultimate level, MPO/Flip-Model, DXGI summary, overlay scan, VBS status, and GPU power telemetry — along with the menu that existed only to display them.
- Detection that still gates real behavior (WDDM version, Game Mode, HAGS, HVCI, GPU MSI Mode, ASPM) was kept. ASPM now verifies its actually-applied state instead of trusting the `powercfg` exit code.

## [3.2.0] — Pre-check layer for detected tweaks

- Added `Invoke-DetectedTweak`, a silent pre-check layer so HAGS, HVCI, GPU MSI Mode, and VBS/Game Mode report **Skipped** instead of blindly re-applying an already-correct value.

## [3.1.0] — Validated tweak framework

- Added the `Test-*` / `Invoke-ValidatedTweak` framework: declare preconditions, apply the change, then verify the actual resulting state rather than trusting the command's exit code.
- `Set-RegDword` / `Remove-RegValue` now read back every value they write to confirm it landed correctly.
- Deduplicated AMD/NVIDIA registry-lookup and vendor-service-toggle logic.
- Fixed a bug where the System Repair & RAM menu was unreachable from the main menu.

---

## Versions prior to 3.1.0

Earlier development history predates the structured changelog format above and is not individually itemized here. If you are running a version older than 3.1.0, please update — see [`SECURITY.md`](SECURITY.md) for why running an outdated version is discouraged, and [`INSTALL.md`](INSTALL.md) for how to get the current release.
