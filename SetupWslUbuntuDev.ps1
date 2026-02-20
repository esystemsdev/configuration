#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Start WSL and load a pre-built dev image from a .tar; optionally apply user specs (e.g. /workspace).
.DESCRIPTION
  Ensures WSL is available, imports the .tar as a distro, sets it default, and runs wsl-on-start.sh
  to link /workspace to your Windows repos path. Run in an elevated PowerShell.
  The image is built separately (see install-wsl-ubuntu-dev.sh and wsl --export).
.PARAMETER TarPath
  Path to the .tar image (local file or http/https URL). Default: repo root\wsl-ubuntu-dev.tar.
.PARAMETER DistroName
  Name of the imported distro (default: aifabrix-dev).
.PARAMETER InstallLocation
  Directory where the distro is stored (default: C:\wsl-data\aifabrix-dev).
.EXAMPLE
  .\Setup-WslUbuntuDev.ps1 -TarPath "C:\path\to\wsl-ubuntu-dev.tar"
#>
[CmdletBinding()]
param(
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

# ---------- Resolve tar path (file or http download) ----------
if ([string]::IsNullOrWhiteSpace($TarPath)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
    $TarPath = Join-Path $repoRoot "wsl-ubuntu-dev.tar"
}

$tarIsUrl = $TarPath -match '^https?://'
if ($tarIsUrl) {
    $tempTar = Join-Path $env:TEMP "wsl-ubuntu-dev-$(Get-Date -Format 'yyyyMMddHHmmss').tar"
    Write-Host "Downloading image from $TarPath..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $TarPath -OutFile $tempTar -UseBasicParsing
    } catch {
        Write-Host "Download failed: $_" -ForegroundColor Red
        exit 1
    }
    $TarPath = $tempTar
} else {
    $TarPath = (Resolve-Path $TarPath -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath $TarPath)) {
        Write-Host "Tar file not found: $TarPath" -ForegroundColor Red
        exit 1
    }
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
if ($tarIsUrl -and (Test-Path -LiteralPath $TarPath)) {
    Remove-Item -LiteralPath $TarPath -Force
}
Write-Host "Setting default WSL distro to $DistroName..." -ForegroundColor Cyan
wsl -s $DistroName

Write-Host "Done. Open Cursor and use WSL: $DistroName (e.g. File > Open Folder in WSL)." -ForegroundColor Green
