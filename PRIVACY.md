# Privacy Policy

ZORO Tweaking Utility is a **local, offline-first PowerShell script**. This document explains exactly what data it reads, what it stores, and what — if anything — leaves your machine.

## Summary

- ZORO **does not contain any telemetry, analytics, or automatic data-collection code.**
- ZORO **does not send your registry values, settings, hardware information, or logs to the author, to Anthropic, or to any third party.**
- Every network request ZORO makes is either (a) a change you explicitly asked for (e.g., setting your DNS to a specific provider) or (b) a diagnostic you explicitly triggered (e.g., a benchmark or connectivity test) — never a background upload of your data.

## What ZORO Reads From Your System

To detect what tweaks are relevant and safe to offer, ZORO reads (but does not transmit):

- Windows version/build number
- CPU topology (core/thread counts, hybrid P-core/E-core layout)
- GPU vendor, model tier, and driver version/signature status (via WMI/CIM)
- Storage type (HDD/SSD/NVMe) and installed RAM
- Network adapter names, types, and current configuration (DNS, MTU, RSS/RSC, power settings)
- Currently applied values for the specific registry keys and services ZORO is capable of modifying
- Battery/chassis signals, used only to determine if the device is a laptop (for battery-impact warnings)

All of this stays local and is used only to decide what to show you in the menu and what a tweak's current state is.

## What ZORO Writes to Your System

ZORO creates a working folder at `C:\ZORO_Suite\` containing:

| File/Folder | Contents | Purpose |
|---|---|---|
| `Logs\yyyy-MM-dd.log` | Timestamped record of every tweak applied, skipped, or failed, plus error details | Troubleshooting (see below) |
| `Backups\<timestamp>\*.reg` | Exported registry keys ZORO is capable of changing | Manual restore via menu [7] |
| `Backups\<timestamp>\DnsServers.json` | Per-adapter DNS server assignments at backup time | DNS restore |
| `Backups\<timestamp>\ActivePowerScheme.txt` | Active power plan at backup time | Reference only |
| `ServiceState.json` | Original startup type of any service you've disabled through ZORO | Precise service restore |
| `UndoSession.json` | A rolling ledger of pending, reversible changes (registry values and service startup types) with their prior values | Undo Last Session |

**None of these files are transmitted anywhere.** They exist solely on your local disk for ZORO's own use, and you can inspect, back up, or delete them at any time — see `UNINSTALL.md` for how to remove them.

## Logging: What Gets Recorded

The log files under `C:\ZORO_Suite\Logs\` record:

- Which tweaks were applied, skipped (already correct), or failed, with timestamps
- Error messages and their classified category (e.g., `AccessDenied`, `MissingAdapter`) for troubleshooting
- Session start/end markers
- Backup and restore actions and their outcomes

Logs **do not** contain your personal files, browsing history, credentials, or any data outside of ZORO's own tweak-related operations. If you file a bug report or support request and choose to share a log excerpt, review it first — while it's not designed to contain sensitive information, it may reveal your network adapter names, installed GPU model, or which specific tweaks/services you've changed, which you may or may not want to share publicly.

## Network Requests ZORO Makes

All of the following are **triggered only when you explicitly select the corresponding menu option** — none run automatically or in the background without your action:

| Feature | What it contacts | Why |
|---|---|---|
| Quick-set DNS providers / Smart DNS Benchmark | Cloudflare, Google, Quad9, OpenDNS, or AdGuard DNS servers | To measure or apply DNS resolution |
| Connection Benchmark / Bufferbloat Test | Public ping targets and a throughput test endpoint | To measure your connection's latency/throughput — this is a real, timed data transfer you initiate |
| Route Quality Analyzer | A hostname/IP **you provide** | Traceroute analysis |
| Gaming Connectivity Test | Steam/Battle.net/Epic/Riot/Roblox/Xbox/PlayStation servers, or a custom host you provide | Connectivity testing to services you choose |
| Advanced Diagnostics Report | Includes a lookup of your **public IP address** via a Cloudflare diagnostic endpoint | Included in the local diagnostics report file only — not transmitted elsewhere by ZORO |
| `[D]` Discord button | Opens a Discord invite link in your default browser (if configured) | Community support link — this is you clicking a link, not ZORO transmitting anything |
| `[G]` GitHub button | Opens the project's GitHub page in your default browser | Same as above |

None of these features send your registry values, logs, hardware profile, or backups anywhere — they either fetch public network-testing data on your behalf, or open a link in your own browser.

## No Update Checker

ZORO does not phone home to check for a newer version. You'll need to check the GitHub repository yourself for updates — see `VERSIONING.md` and `CHANGELOG.md`.

## Your Control Over Your Data

- All data ZORO creates lives under `C:\ZORO_Suite\` and is fully under your control.
- You can delete logs, backups, or the entire folder at any time (see `UNINSTALL.md`) — this does not "phone home" to notify anyone, because there is nothing to notify.
- Nothing ZORO stores is encrypted or access-controlled beyond normal NTFS permissions on your user profile — treat log/backup contents with the same care you'd give any local file containing details about your system configuration.

## Changes to This Policy

If ZORO's data-handling behavior changes in a future version (for example, an opt-in crash-reporting feature), this document will be updated alongside that release and the change will be called out in `CHANGELOG.md`.
