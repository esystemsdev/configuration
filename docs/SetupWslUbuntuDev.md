# WSL Ubuntu dev image (Windows developers)

Install a pre-built aifabrix-dev image on your **Windows** PC so you can develop in Linux (WSL) and avoid Windows-specific tooling issues. The image is maintained separately; this guide is only for **using** it on your dev machine.

*Mac developers use macOS directly; this setup is not needed there.*

**The image already has `/workspace` configured.** After you import the image, you can open Cursor, connect to the WSL distro, and use the folder `/workspace` immediately. No extra steps are required to set up `/workspace`.

For the full Windows developer flow (tools + WSL + repos + onboarding), see [Setup-developer.md](../Setup-developer.md).

---

## 1. Get the setup script

Copy `SetupWslUbuntuDev.ps1` onto your machine into **`C:\Setup\`**. Use the same **pinned raw URL** as in [Setup-developer.md](../Setup-developer.md) (`$configurationVersion` + `raw.githubusercontent.com`), or clone the [configuration](https://github.com/esystemsdev/configuration) repository. See [README.md](../README.md#bootstrap-release-pinning).

## 2. Install the image on your dev PC

On your Windows dev PC (with WSL already installed), run the script from **`C:\Setup\`** as Administrator:

```powershell
cd C:\Setup\
powershell -ExecutionPolicy Bypass -File ".\SetupWslUbuntuDev.ps1" -TarPath "https://builder01.aifabrix.dev/wsl-image"
```

Or with a local .tar file:

```powershell
powershell -ExecutionPolicy Bypass -File ".\SetupWslUbuntuDev.ps1" -TarPath "C:\path\to\wsl-ubuntu-dev.tar"
```

- **-TarPath** – URL (http/https) or local path to the pre-built `.tar` image. The script downloads when given a URL.
- **-DistroName** – WSL distro name (default: `aifabrix-dev`).
- **-InstallLocation** – Where the distro is stored (default: `C:\wsl-data\aifabrix-dev`).

The script imports the image and sets it as the default WSL distro. **The image has `/workspace` ready**; no additional configuration is required.

## 3. Using the image

Start WSL (default distro **aifabrix-dev**, username `aifabrix`, password `admin123`):

```powershell
wsl
```

In Cursor: **File → Open Folder in WSL**, choose the distro, then open **`/workspace`**. You can clone repos into `/workspace` and run `aifabrix dev init` when you need remote development access (see [Setup-developer.md](../Setup-developer.md)).

## Summary

| Item | Purpose |
|------|--------|
| **SetupWslUbuntuDev.ps1** | Run from `C:\Setup\` as Administrator with **-TarPath** (URL or local .tar) to import the image and set the default distro. |
| **Image** | Has `/workspace` preconfigured; open it in Cursor after connecting to WSL. |

Image **creation** (building/exporting the .tar) is done elsewhere; this doc only covers installing and using the image on a Windows dev PC.
