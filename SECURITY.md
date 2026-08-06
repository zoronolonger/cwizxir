# Security Policy

ZORO Tweaking Utility runs with **Administrator privileges** and directly edits the Windows Registry, network adapter configuration, service startup types, and installed applications. Because of that elevated footprint, security issues in ZORO are taken seriously and prioritized above ordinary bug reports.

## Supported Versions

Security fixes are provided for the **latest released version only**. ZORO is a single-file script distributed from this repository; there is no long-term support branch for older versions.

| Version | Supported |
|---|---|
| 3.9.x (latest) | ✅ Yes |
| 3.x (older than latest) | ⚠️ Best-effort only — please update first |
| ≤ 2.x | ❌ No |

If you're running a version older than the latest tagged release, update before reporting a suspected security issue — it may already be fixed.

## What Counts as a Security Issue Here

Because ZORO is a local administrative tool rather than a networked service, its threat model is narrower than a typical application's. Examples of what belongs in a security report:

- A tweak that silently weakens a security control **without the warning ZORO is supposed to show** (e.g., the Memory Integrity/HVCI toggle applying without its confirmation and warning text).
- Any code path that could let a malicious or malformed input (registry state, file, network response) cause ZORO to write to a registry path or file location it shouldn't.
- Insecure handling of the script itself — for example, a distribution channel that could allow tampering between the source and what a user downloads/runs.
- Privilege-escalation behavior beyond ZORO's own intended self-elevation via UAC.
- Any scenario where ZORO's logs, backups, or undo ledger under `C:\ZORO_Suite\` could expose sensitive data or be manipulated to cause unintended system changes on restore.

Examples of what is **not** a security report and should go through normal GitHub Issues instead:
- A tweak not producing the performance improvement you expected.
- Disagreement with a tweak's honesty rating in `TWEAK_AUDIT.md`.
- General compatibility requests for unsupported Windows versions.

## Reporting a Vulnerability

**Please do not open a public GitHub Issue for a suspected security vulnerability.**

To report a security issue privately, use one of the following:

1. **GitHub Security Advisories** (preferred): open a private advisory on the repository via the "Security" tab → "Report a vulnerability."
2. **Discord DM:** `cwizxir`

When reporting, please include:
- The ZORO version (shown in the banner, or via menu **[6] Miscellaneous → [3] About / Credits**).
- Windows version/build and PowerShell version.
- Exact menu path and steps to reproduce.
- What you expected to happen vs. what actually happened.
- Relevant excerpts from the log file at `C:\ZORO_Suite\Logs\yyyy-MM-dd.log` (redact anything you consider private — see `PRIVACY.md` for what the logs typically contain).

## Responsible Disclosure Policy

- Reports are acknowledged as soon as reasonably possible.
- The issue is investigated and, where confirmed, a fix is prepared and released as a new version.
- Reporters are credited in the `CHANGELOG.md` release notes unless they request anonymity.
- Please allow a reasonable window for a fix to be released before any public disclosure. If you believe a vulnerability is being actively exploited or poses immediate risk to users, say so in your initial report — that changes the urgency, not the private-first channel.
- There is no bug bounty program; this is a community-maintained personal project.

## Security Recommendations When Using ZORO

Because ZORO requires Administrator rights and directly edits sensitive system state, follow these practices:

- **Only run the script from a source you trust.** Download it from the official repository (`github.com/zoronolonger`) rather than a mirrored or reposted copy, and verify the file hasn't been altered if you obtained it any other way.
- **Read a tweak's confirmation prompt before answering "yes."** Higher-impact tweaks (Memory Integrity/HVCI, Dynamic Tick/boot config edits, Winsock Reset, service disabling) show an explicit warning — it exists because that specific change carries real risk or trade-offs.
- **Create a System Restore Point and a ZORO backup before your first tweaking session.** See `HOW_TO_USE.md` for exactly how and when.
- **Don't disable Memory Integrity (HVCI) unless you understand the trade-off.** It is a real exploit-mitigation feature; ZORO's menu explains the CPU-specific FPS trade-off in detail before you confirm it.
- **Review `TWEAK_AUDIT.md`** before applying anything in the "Situational" or "Experimental" categories — these are the tweaks most likely to have hardware-specific or workload-specific downsides.
- **Keep an eye on the log file** (`C:\ZORO_Suite\Logs\`) if something behaves unexpectedly; it records every action, error category, and recovery attempt ZORO takes.
- **Never run ZORO, or any script that requests Administrator rights, from an untrusted or unverified source** — this applies as much to forks and "modified" copies of ZORO as it does to any other elevated script.
