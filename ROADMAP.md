# Roadmap

This document describes the general direction ZORO Tweaking Utility is headed. It is **not a commitment or a release schedule** — priorities shift based on what actually turns out to matter once real hardware/driver combinations are tested, consistent with the project's honesty-first philosophy (see `TWEAK_AUDIT.md`'s "removed tweaks" history for examples of past items cut for lacking real-world value).

## Guiding Principles for Future Work

Everything on this roadmap is filtered through the same standard the project already applies to every existing tweak:

1. **No feature ships with an inflated benefit claim.** If a proposed tweak turns out to be placebo on modern hardware during testing, it doesn't ship — or it ships labeled `Legacy`/removed, the same way several detection-only reporting functions were cut in v3.3.0.
2. **Reversibility is a design requirement, not an afterthought.** Any new setting that writes to the registry or changes service state should go through the existing `Invoke-ValidatedTweak` / Undo ledger framework from day one, not bolted on later.
3. **Detection before offering.** New tweaks should be gated behind real prerequisite checks (the way HAGS is gated behind Windows build + WDDM version) rather than shown to everyone and failing silently or loudly for unsupported systems.

## Near-Term Direction

- **Broader NIC vendor coverage.** Continued refinement of Advanced NIC Optimizer detection across a wider range of driver vendors, following the same "detect real per-driver support before touching anything" approach introduced in v3.6.0.
- **Expanded diagnostics reporting.** Building on the Advanced Diagnostics Report (menu [15]) to make gathered data easier to share when asking for help or filing an issue, without adding any automatic transmission of that data (see `PRIVACY.md` — this stays local-only).
- **Continued GPU-generation audits.** The v3.5.0-style audit process (verifying tweaks and ratings against current-generation NVIDIA/AMD hardware) is expected to repeat as new GPU generations become mainstream, the same way RTX 3000–5000 and RX 6000–9000 were audited together.
- **Refinement of context-aware recommendations.** The SysMain/Superfetch live-guidance model introduced for Service Tweaks (recommendation computed from actual detected disk type + RAM rather than a static claim) is a pattern the project intends to extend to other storage- or hardware-dependent tweaks where a single static rating doesn't tell the full story.

## Medium-Term Ideas Under Consideration

These are being evaluated, not committed to:

- Additional gaming-service connectivity targets in the Gaming Connectivity Test, based on community requests.
- A read-only "export current Tweak Health Check to file" option, complementing the existing Advanced Diagnostics Report.
- Further consolidation of duplicated detection logic across menus, in the same spirit as the AMD/NVIDIA registry-lookup deduplication done in v3.1.0 and the error-handling centralization done in v3.9.0.

## Explicitly Not Planned

Consistent with the project's stated scope (see `README.md` and `SUPPORTED.md`):

- **No Windows Defender, UAC, Windows Update, or BitLocker tweaks.** These remain out of scope; the only security-relevant setting ZORO touches (Memory Integrity/HVCI) stays a single, clearly-warned, opt-in exception rather than a precedent for expanding into security tooling.
- **No "apply everything" / one-click optimization mode.** Every tweak will continue to require an individual, explicit selection — this is a permanent design decision, not a temporary limitation.
- **No telemetry or automatic update-checking.** See `PRIVACY.md`.
- **No support for Windows 7/8/Server.** These remain permanently out of scope.

## How to Influence the Roadmap

- Feature requests and feedback: via Discord (`cwizxir`) or GitHub Issues on [github.com/zoronolonger](https://github.com/zoronolonger).
- If you're proposing a new tweak, the most useful thing you can include is **real, measured before/after data on your own hardware** — the project's entire premise is refusing to add tweaks on the strength of a reputation alone. See `TWEAK_AUDIT.md` for the bar every existing tweak had to clear.

For what has already shipped, see [`CHANGELOG.md`](CHANGELOG.md).
