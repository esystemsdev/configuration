# WSL Ubuntu dev image (Windows developers)

Install a pre-built aifabrix-dev image on your **Windows** PC so you can develop in Linux (WSL) and avoid Windows-specific tooling issues. The image is maintained separately; this guide is only for **using** it on your dev machine.

*Mac developers use macOS directly; this setup is not needed there.*

**Where the image lives:** `C:\git\esystemsdev\configuration` (repo with `SetupWslUbuntuDev.ps1`, `wsl-ubuntu-dev.tar`, and this doc).

---

## 1. Get the setup script

Copy `SetupWslUbuntuDev.ps1` onto your machine via HTTP (or download) into **`C:\Setup\`**:

- Create `C:\Setup\` if needed and put `SetupWslUbuntuDev.ps1` there.

## 2. Install the image on your dev PC

On your Windows dev PC (with WSL already installed), run the script from **`C:\Setup\`** as Administrator (right-click PowerShell → Run as Administrator). Use **-ExecutionPolicy Bypass** so the script runs without changing system policy:

```powershell
cd C:\Setup\
powershell -ExecutionPolicy Bypass -File ".\SetupWslUbuntuDev.ps1" -WindowsReposPath "C:\git\esystemsdev" -TarPath "C:\git\esystemsdev\configuration\wsl-ubuntu-dev.tar"
```

- **-WindowsReposPath** – Your Windows repos path; WSL will expose it as `/workspace` (e.g. `C:\git\esystemsdev`).
- **-TarPath** – Path to the pre-built `.tar` image. When running from `C:\Setup\`, pass this explicitly (e.g. `C:\git\esystemsdev\configuration\wsl-ubuntu-dev.tar` if the repo is cloned; otherwise wherever you have the .tar).
- **-DistroName** – WSL distro name (default: `aifabrix-dev`).
- **-InstallLocation** – Where the distro is stored (default: `C:\wsl-data\aifabrix-dev`).

The script imports the image, sets it as the default WSL distro, and runs the on-start script so `/workspace` points at your repos. It uses `wsl-on-start.sh` from the repo path when available (so you can change it without rebuilding the image); otherwise the image already contains a copy (see below).

## 3. Using the image

Start WSL (default distro is **aifabrix-dev** and username aifabrix and password admin123):

```powershell
wsl
```

Inside WSL, run the on-start script to set `/workspace` (and optionally git config). The script lives in the image at `/usr/local/share/aifabrix-wsl/wsl-on-start.sh`, so no repo is needed:

```bash
sudo /usr/local/share/aifabrix-wsl/wsl-on-start.sh --workspace /mnt/c/git/esystemsdev
```

With git identity:

```bash
sudo /usr/local/share/aifabrix-wsl/wsl-on-start.sh --workspace /mnt/c/git/esystemsdev --git-name "Your Name" --git-email "you@example.com"
```

After setup, use **aifabrix-dev** via WSL (e.g. in Cursor: **File → Open Folder in WSL**, then choose the distro). Your Windows repos are available under `/workspace` inside WSL.


## Summary

| Item | Purpose |
|------|--------|
| **SetupWslUbuntuDev.ps1** | Copy to `C:\Setup\` via HTTP; run with `powershell -ExecutionPolicy Bypass -File ".\SetupWslUbuntuDev.ps1"` (as Admin) to install the image and set `/workspace`. |
| **wsl-ubuntu-dev.tar** | Pre-built image; path via **-TarPath** (e.g. from `C:\git\esystemsdev\configuration`). |
| **wsl-on-start.sh** | In image at `/usr/local/share/aifabrix-wsl/wsl-on-start.sh`. Optional copy in `C:\Setup\` lets the PS1 use your version when applying specs during install. |

Image **creation** (building/exporting the .tar) is done elsewhere; this doc only covers installing and using the image on a Windows dev PC.
