# Disclaimer

Please read this before running ZORO Tweaking Utility.

## No Warranty

ZORO Tweaking Utility is provided **"as is," without warranty of any kind**, express or implied, as stated in full in [`LICENSE`](LICENSE) (MIT). The author(s) make no guarantee that any tweak will improve performance on your specific hardware, and no guarantee that applying, undoing, or restoring a tweak will leave your system in a particular state.

## This Tool Modifies System-Level Settings

ZORO requires **Administrator privileges** and directly modifies:

- The Windows Registry (`HKLM` and `HKCU` hives)
- Network adapter configuration and driver-exposed advanced properties
- Windows service startup types
- Power plan configuration
- Boot configuration data (specifically, the Dynamic Tick tweak edits `bcdedit` settings)
- Installed first-party applications (Debloat checklist, Microsoft Edge removal)

Changes at this level carry inherent risk. While ZORO is built with verification, an undo ledger, and a backup/restore system specifically to reduce that risk (see `HOW_TO_USE.md`), **no amount of tooling eliminates the possibility of unexpected behavior on a specific combination of hardware, drivers, and Windows build.**

## Use at Your Own Risk

By running ZORO, you acknowledge and accept that:

- You are choosing to modify system settings using a third-party tool, not an official Microsoft or hardware-vendor utility.
- Some tweaks — most notably disabling **Memory Integrity (HVCI)** — trade away real security protections for a performance gain that ZORO itself states is hardware-dependent and not guaranteed. ZORO shows an explicit warning for this specific tweak, and you must actively confirm it before it applies.
- Some actions — Debloat/app removal, Microsoft Edge removal, and temp file cleanup — are **not reversible through ZORO's own Undo system**. Read the relevant section of `HOW_TO_USE.md` and `TWEAK_AUDIT.md` before running them.
- You are responsible for creating a System Restore Point and/or a ZORO backup before applying tweaks, as recommended throughout this documentation and inside the tool itself.
- Neither the author nor any contributor is liable for data loss, system instability, reduced device performance, reduced battery life, voided hardware/software warranties, or any other damages arising from the use or misuse of this tool.

## Not Affiliated With Microsoft, AMD, or NVIDIA

ZORO is an independent, community-built tool. It is **not** endorsed by, affiliated with, or supported by Microsoft Corporation, Advanced Micro Devices (AMD), or NVIDIA Corporation. References to Windows, Windows Update, Microsoft Edge, AMD, and NVIDIA are for descriptive purposes only — modifying settings related to these products through ZORO is done at your own risk and outside of any official support channel those companies provide.

## Removing Microsoft Edge

Microsoft Edge is treated by modern Windows builds as a system component in some contexts. ZORO's Edge removal feature (menu **[12]**) performs a complete, low-level removal that goes beyond what Microsoft officially supports removing. This may affect features that assume Edge's presence (certain WebView2-dependent functionality, some Store app rendering paths) on some Windows builds. This is explained again, in more detail, in `TWEAK_AUDIT.md` and `UNINSTALL.md`.

## Security Feature Trade-Offs

Certain tweaks intentionally weaken a real security or stability control in exchange for a performance or convenience benefit — most notably Memory Integrity (HVCI). ZORO always shows the specific trade-off before you confirm such a tweak. Applying it is your decision, made with that information in front of you, not a default or hidden behavior.

## No Guarantee of Fitness for a Particular Purpose

Ratings in `TWEAK_AUDIT.md` and inside the tool's own menus reflect the author's best honest assessment of real-world impact on modern hardware. They are not benchmarked against your specific system and should not be treated as a guarantee of any specific measurable result.

## Your Responsibility

Before using ZORO, you should:

1. Understand what a tweak does before applying it (read the menu text, the confirmation prompt, and the relevant entry in `TWEAK_AUDIT.md`).
2. Create a System Restore Point and a ZORO backup (see `HOW_TO_USE.md`).
3. Only run ZORO on a system where you are prepared to accept the risk described above.
4. Keep a copy of any files or data you cannot afford to lose backed up independently of ZORO's own backup system, which covers registry values only — not files, documents, or applications (with the specific exception of the Edge and Debloat removal actions, which do remove application files as their explicit, disclosed purpose).

If you are not comfortable with the risks described in this document, do not run ZORO.
