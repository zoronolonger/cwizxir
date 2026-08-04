ZORO Tweaking Utility Guide
This document explains step-by-step how to run the script on your device.
Requirements
Windows 10 or 11
Administrator privileges
PowerShell (included by default in all Windows versions)

Method 1 (Fastest): Direct Run from GitHub Without Downloading
Open the Start menu and type PowerShell.

Right-click on Windows PowerShell and choose Run as Administrator. This step is mandatory; the script will not work without it.

Paste the following command and press Enter:

PowerShell
irm "https://raw.githubusercontent.com/zoronolonger/cwizxir/refs/heads/main/ZORO%20Tweaking%20Utility.ps1" | iex
The script will open the main menu directly. Choose the number of the section you want and press Enter.

Security Note: This command downloads and runs the script directly from GitHub without saving it to your device. Do not run commands of this type unless from a trusted source.

Method 2: Download the Script and Run Locally
A) Downloading the File
If you have Git:

PowerShell
git clone https://github.com/zoronolonger/cwizxir.git
cd cwizxir
Or without Git, download the file directly via PowerShell:

PowerShell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zoronolonger/cwizxir/refs/heads/main/ZORO%20Tweaking%20Utility.ps1" -OutFile "ZORO Tweaking Utility.ps1"
Or open the file page on GitHub and click the Download raw file button.

B) Running as Administrator
Open PowerShell as Administrator (same step as above).

Navigate to the file's folder, for example:

PowerShell
cd "C:\Users\YourName\Downloads"
Allow script execution for this session only (safe, does not permanently change your device settings):

PowerShell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Run the script:

PowerShell
.\ZORO Tweaking Utility.ps1
Common Issues
"running scripts is disabled on this system"
This means the Execution Policy is blocking script execution. Apply the command in step (B-3) above before running the file.

SmartScreen message ("Windows protected your PC")
This happens because the script is unsigned. Click More info then Run anyway if you trust the source.

"[ERROR] Please run ZORO as Administrator!"
You must open PowerShell as an Administrator from the beginning (right-click -> Run as Administrator), not just open it normally.

Before Making Any Tweaks
It is recommended before using any tweaks—especially from section [8] Responsiveness & GPU Tweaks or [9] Service Tweaks:

From the main menu, choose [7] Backup & Restore → [1] to create a backup of your settings.

Choose [6] Miscellaneous → [1] to create a System Restore Point.

This way, if anything unexpected happens, you can easily restore settings from the same menu (the Restore option in each section, or full restoration from the backup).

Exiting the Tool
Type Q from the main menu and press Enter (in English).
