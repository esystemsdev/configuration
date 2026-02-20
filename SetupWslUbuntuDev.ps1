#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Start WSL and load a pre-built dev image from a .tar; optionally apply user specs (e.g. /workspace).
.DESCRIPTION
  Ensures WSL is available, imports the .tar as a distro, sets it default, and runs wsl-on-start.sh
  to link /workspace to your Windows repos path. Run in an elevated PowerShell.
  The image is built separately (see install-wsl-ubuntu-dev.sh and wsl --export).
.PARAMETER WindowsReposPath
  Windows path to your repos (e.g. C:\git\esystemsdev). If set, /workspace in WSL is symlinked here.
.PARAMETER TarPath
  Path to the .tar image. Default: repo root\wsl-ubuntu-dev.tar.
.PARAMETER DistroName
  Name of the imported distro (default: aifabrix-dev).
.PARAMETER InstallLocation
  Directory where the distro is stored (default: C:\wsl-data\aifabrix-dev).
.EXAMPLE
  .\Setup-WslUbuntuDev.ps1 -WindowsReposPath "C:\git\esystemsdev"
.EXAMPLE
  .\Setup-WslUbuntuDev.ps1 -TarPath "C:\path\to\wsl-ubuntu-dev.tar" -WindowsReposPath "C:\git\esystemsdev"
#>
[CmdletBinding()]
param(
    [string]$WindowsReposPath = "",
    [string]$TarPath = "",
    [string]$DistroName = "aifabrix-dev",
    [string]$InstallLocation = "C:\wsl-data\aifabrix-dev"
)

$ErrorActionPreference = "Stop"

# ---------- WSL available ----------
Write-Host "Checking WSL..." -ForegroundColor Cyan
$wslOk = $false
try { $null = wsl --status 2>$null; $wslOk = $true } catch {}
if (-not $wslOk) {
    Write-Host "WSL is not installed. Install it first: wsl --install --no-distribution" -ForegroundColor Red
    exit 1
}

# ---------- Resolve tar path ----------
if ([string]::IsNullOrWhiteSpace($TarPath)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
    $TarPath = Join-Path $repoRoot "wsl-ubuntu-dev.tar"
}
$TarPath = (Resolve-Path $TarPath -ErrorAction Stop).Path
if (-not (Test-Path -LiteralPath $TarPath)) {
    Write-Host "Tar file not found: $TarPath" -ForegroundColor Red
    exit 1
}

# ---------- Import image ----------
$InstallLocation = $InstallLocation.TrimEnd('\')
$installDir = Split-Path -Parent $InstallLocation
if (-not (Test-Path -LiteralPath $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}
$existing = (wsl -l -q) 2>$null
if ($existing -match [regex]::Escape($DistroName)) {
    Write-Host "Unregistering existing distro '$DistroName'..." -ForegroundColor Yellow
    wsl --unregister $DistroName
}
Write-Host "Importing $TarPath as '$DistroName' to $InstallLocation..." -ForegroundColor Cyan
wsl --import $DistroName $InstallLocation $TarPath
Write-Host "Setting default WSL distro to $DistroName..." -ForegroundColor Cyan
wsl -s $DistroName

# ---------- User specs (workspace, etc.) ----------
$onStartScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "wsl-on-start.sh"
if (Test-Path -LiteralPath $onStartScript) {
    $onStartWslPath = (wsl -d $DistroName -u root -e wslpath -a $onStartScript).Trim()
    if ($WindowsReposPath) {
        $wslReposPath = (wsl -d $DistroName -u root -e wslpath -a $WindowsReposPath.Trim()).Trim()
        Write-Host "Applying user specs (workspace -> $WindowsReposPath)..." -ForegroundColor Cyan
        wsl -d $DistroName -u root -e bash -c "bash '$onStartWslPath' --workspace '$wslReposPath'"
    } else {
        Write-Host "To link /workspace later: wsl -d $DistroName -u root -e bash '$onStartWslPath' --workspace /mnt/c/path/to/repos" -ForegroundColor Gray
    }
}

Write-Host "Done. Open Cursor and use WSL: $DistroName (e.g. File > Open Folder in WSL)." -ForegroundColor Green
