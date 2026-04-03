param (
    [string]$groups
)

# Check if the powershell-yaml module is installed
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "Powershell-yaml module not found. Installing..."
    try {
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser -ErrorAction Stop -Confirm:$false
        Write-Host "Powershell-yaml module installed successfully."
    } catch {
        Write-Error "Failed to install powershell-yaml module. Exiting."
        exit 1
    }
} else {
    Write-Host "Powershell-yaml module is already installed."
}

# Import the powershell-yaml module
Import-Module powershell-yaml

# Determine the script directory
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Manifest always lives next to this script (same folder).
$yamlFilePath = Join-Path -Path $scriptDir -ChildPath "SetupDeveloperEnv.yaml"

if (-not (Test-Path -Path $yamlFilePath)) {
    Write-Error "SetupDeveloperEnv.yaml was not found next to this script: $yamlFilePath"
    exit 1
}

$config = ConvertFrom-Yaml (Get-Content -Path $yamlFilePath -Raw)

Write-Host "Manifest (same folder as script): $yamlFilePath"

# Fail fast: known-invalid Compose URL (script does not fetch YAML from the network).
function Test-ManifestContainsBadComposeV2344 {
    param ($Cfg)
    foreach ($manifestApp in $Cfg.applications) {
        $xf = $manifestApp.windowsExtraFiles
        if ($null -eq $xf) { continue }
        foreach ($xfItem in @($xf)) {
            if ($null -eq $xfItem) { continue }
            $u = $xfItem.url
            if ([string]::IsNullOrWhiteSpace($u) -and $xfItem -is [hashtable]) { $u = $xfItem['url'] }
            if ($u -match 'docker/compose/releases/download/v2\.34\.4') {
                return $true
            }
        }
    }
    return $false
}

if (Test-ManifestContainsBadComposeV2344 -Cfg $config) {
    Write-Error @"
SetupDeveloperEnv.yaml next to this script lists Compose v2.34.4 (not available). Replace that file with the SetupDeveloperEnv.yaml from your configuration package (same folder as SetupDeveloperEnv.ps1).

$yamlFilePath
"@
    exit 1
}

# Helper: get all unique group names (group can be string or array in YAML)
function Get-AllGroupNames {
    $all = @()
    foreach ($app in $config.applications) {
        $g = $app.group
        if ($null -ne $g) {
            if ($g -is [Array]) { $all += $g } else { $all += $g }
        }
    }
    return $all | Sort-Object -Unique
}

# Helper: return true if app is in the selected groups (group can be string or array)
function Test-AppInSelectedGroups {
    param ($app, [array]$selectedGroups)
    $g = $app.group
    if ($null -eq $g) { return $false }
    if ($g -is [Array]) {
        foreach ($grp in $g) { if ($selectedGroups -contains $grp) { return $true } }
        return $false
    }
    return ($selectedGroups -contains $g)
}

# Function to prompt user for application group selection
# Groups: Basic (integration path), Development, Local Dev, Database, Development OutSystems
function Prompt-UserForGroupSelection {
    Write-Host "Please select the groups of applications you want to install."
    Write-Host "The following groups are available:"
    
    $groupNames = Get-AllGroupNames
    $groupSelections = @()
    
    foreach ($group in $groupNames) {
        $appsInGroup = $config.applications | Where-Object { Test-AppInSelectedGroups -app $_ -selectedGroups @($group) } | ForEach-Object { $_.name }
        Write-Host "`n[$group] includes:"
        $appsInGroup | ForEach-Object { Write-Host "- $_" }
        
        $choice = Read-Host "`nDo you want to install the $group group? (y/n)"
        if ($choice -eq 'y') {
            $groupSelections += $group
        }
    }

    # Auto-include Development only when user selected something but not "Basic" only (integration path = Basic only)
    if (-not ($groupSelections -contains "Development") -and -not ($groupSelections.Count -eq 1 -and $groupSelections -contains "Basic")) {
        Write-Host "`nThe 'Development' group will be installed automatically (developer path)."
        $groupSelections += "Development"
    }

    return $groupSelections
}

# Function to get the selected groups based on input or prompt
function Get-SelectedGroups {
    param (
        [string]$groups
    )

    if ($groups) {
        if ($groups -ieq "all") {
            return @(Get-AllGroupNames)
        } else {
            return $groups -split ',' | ForEach-Object { $_.Trim() }
        }
    } else {
        return Prompt-UserForGroupSelection
    }
}

# Helper function to download and install MSI or EXE files with error handling and exit code verification
function Install-Software {
    param (
        [string]$Name,
        [string]$Url,
        [string]$InstallerFileName,
        [string]$SilentArguments = "/quiet /norestart"
    )

    $tempPath = [System.IO.Path]::Combine($env:TEMP, $InstallerFileName)

    if (-not (Test-Path $tempPath)) {
        Write-Host "Downloading $InstallerFileName to $tempPath..."
        try {
            Start-BitsTransfer -Source $Url -Destination $tempPath -ErrorAction Stop
        } catch {
            Write-Error "Failed to download $InstallerFileName from $Url. Stopping the script."
            exit 1
        }
    } else {
        Write-Host "$InstallerFileName already exists at $tempPath. Skipping download."
    }

    Write-Host "Installing $Name - $InstallerFileName..."
    try {
        $process = Start-Process -FilePath $tempPath -ArgumentList $SilentArguments -Wait -PassThru

        if ($process.ExitCode -ne 0) {
            if ($process.ExitCode -eq 1603) {
                Write-Host "A later version of $Name may already be installed. Use 'Add or remove programs' to uninstall that version and try again."
            }
            throw "Installation of $InstallerFileName failed with exit code $($process.ExitCode)."
        }
    } catch {
        Write-Error $_.Exception.Message
        exit 1
    }

    try {
        Remove-Item $tempPath -Force
    } catch {
        Write-Host "Warning: Could not delete $tempPath. Access denied."
    }
}

# True if any windowsExtraFiles target path is missing (same rules as Install-WindowsArchiveApplication).
function Test-AnyWindowsExtraFileMissing {
    param (
        [hashtable]$App
    )
    $extras = $App.windowsExtraFiles
    if ($null -eq $extras) {
        return $false
    }
    foreach ($item in @($extras)) {
        if ($null -eq $item) { continue }
        $rel = $item.destRelativeToUserProfile
        if ([string]::IsNullOrWhiteSpace($rel) -and $item -is [hashtable]) {
            $rel = $item['destRelativeToUserProfile']
        }
        if ([string]::IsNullOrWhiteSpace($rel)) { continue }
        $relNorm = $rel -replace '/', '\'
        $destPath = Join-Path $env:USERPROFILE $relNorm
        if (-not (Test-Path -LiteralPath $destPath)) {
            return $true
        }
    }
    return $false
}

# HTTPS download with redirect support (GitHub release assets, etc.). Tries IWR then WebClient (some PS 5.1 / TLS setups close IWR mid-transfer).
function Save-UrlToFile {
    param (
        [string]$Url,
        [string]$DestinationPath
    )
    $proto12 = [Net.SecurityProtocolType]::Tls12
    try {
        $proto13 = [Net.SecurityProtocolType]::Tls13
        [Net.ServicePointManager]::SecurityProtocol = $proto13 -bor $proto12
    } catch {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $proto12
    }
    $userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'

    $iwrError = $null
    try {
        $params = @{
            Uri                = $Url
            OutFile            = $DestinationPath
            UseBasicParsing    = $true
            MaximumRedirection = 10
            UserAgent          = $userAgent
            ErrorAction        = 'Stop'
        }
        $iwrCmd = Get-Command Invoke-WebRequest -ErrorAction Stop
        if ($iwrCmd.Parameters.ContainsKey('TimeoutSec')) {
            $params['TimeoutSec'] = 600
        }
        Invoke-WebRequest @params
        return
    } catch {
        $iwrError = $_
    }

    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('User-Agent', $userAgent)
        $wc.DownloadFile($Url, $DestinationPath)
    } catch {
        $wcMsg = $_.Exception.Message
        $hint = ""
        if ($wcMsg -match '404|Not Found') {
            $hint = "`n`n(404) The URL in SetupDeveloperEnv.yaml may be wrong or the release was removed. Replace SetupDeveloperEnv.yaml next to this script with the copy from your configuration package."
        }
        throw "Download failed ($Url). Invoke-WebRequest: $($iwrError.Exception.Message); WebClient: $wcMsg$hint"
    }
}

# Generic Windows install from a zip URL: copies windowsArchiveMainBinary into %LOCALAPPDATA%\<relative path>.
# Optional windowsExtraFiles: list of { url, destRelativeToUserProfile }.
function Install-WindowsArchiveApplication {
    param (
        [hashtable]$App
    )

    if ([string]::IsNullOrWhiteSpace($App.windowsArchiveUrl)) {
        throw "windowsArchiveUrl is required for archive install ($($App.name))."
    }
    if ([string]::IsNullOrWhiteSpace($App.windowsArchiveMainBinary)) {
        throw "windowsArchiveMainBinary is required for archive install ($($App.name))."
    }
    if ([string]::IsNullOrWhiteSpace($App.windowsArchiveInstallRelativePath)) {
        throw "windowsArchiveInstallRelativePath is required for archive install ($($App.name))."
    }

    $destDir = Join-Path $env:LOCALAPPDATA $App.windowsArchiveInstallRelativePath
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $zipSource = $App.windowsArchiveUrl
    $zipName = if ($App.windowsArchiveSaveAs) {
        $App.windowsArchiveSaveAs
    } else {
        try {
            ([uri]$zipSource).Segments[-1] -replace '^/', ''
        } catch {
            "archive.zip"
        }
    }
    if ([string]::IsNullOrWhiteSpace($zipName)) {
        $zipName = "archive.zip"
    }
    $zipPath = Join-Path $env:TEMP $zipName
    $destFile = Join-Path $destDir $App.windowsArchiveMainBinary

    if (-not (Test-Path -LiteralPath $destFile)) {
        if (-not (Test-Path -LiteralPath $zipPath)) {
            Write-Host "Downloading archive for $($App.name) to $zipPath..."
            try {
                Save-UrlToFile -Url $zipSource -DestinationPath $zipPath
            } catch {
                Write-Error $_.Exception.Message
                exit 1
            }
        } else {
            Write-Host "Archive already at $zipPath. Skipping download."
        }

        $extractRoot = Join-Path $env:TEMP ("archive-extract-" + [Guid]::NewGuid().ToString())
        try {
            Expand-Archive -LiteralPath $zipPath -DestinationPath $extractRoot -Force
            $binName = $App.windowsArchiveMainBinary
            $src = Get-ChildItem -LiteralPath $extractRoot -Filter $binName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $src) {
                throw "$binName not found inside archive for $($App.name)."
            }
            Copy-Item -LiteralPath $src.FullName -Destination $destFile -Force
            Write-Host "$($App.name): installed $destFile"
        } catch {
            Write-Error $_.Exception.Message
            exit 1
        } finally {
            Remove-Item -LiteralPath $extractRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "$($App.name): $($App.windowsArchiveMainBinary) already present under $destDir; skipping archive extract."
    }

    $extras = $App.windowsExtraFiles
    if ($null -ne $extras) {
        foreach ($item in @($extras)) {
            if ($null -eq $item) { continue }
            $eu = $item.url
            if ([string]::IsNullOrWhiteSpace($eu) -and $item -is [hashtable]) {
                $eu = $item['url']
            }
            $rel = $item.destRelativeToUserProfile
            if ([string]::IsNullOrWhiteSpace($rel) -and $item -is [hashtable]) {
                $rel = $item['destRelativeToUserProfile']
            }
            if ([string]::IsNullOrWhiteSpace($eu) -or [string]::IsNullOrWhiteSpace($rel)) {
                continue
            }
            $relNorm = $rel -replace '/', '\'
            $destPath = Join-Path $env:USERPROFILE $relNorm
            if (Test-Path -LiteralPath $destPath) {
                Write-Host "Extra file already present: $destPath"
                continue
            }
            $parentDir = Split-Path -Path $destPath -Parent
            if (-not (Test-Path -LiteralPath $parentDir)) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }
            Write-Host "Downloading extra file for $($App.name) -> $destPath"
            try {
                Save-UrlToFile -Url $eu -DestinationPath $destPath
            } catch {
                Write-Error $_.Exception.Message
                exit 1
            }
        }
    }
}

# Helper function to check if a command exists
function Test-CommandExists {
    param (
        [string]$Command
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        return $true
    }
    return $false
}

# Helper function to check if any path exists from a comma-separated list or single value across all potential locations
function Test-AllProgramLocations {
    param (
        [string]$paths
    )
    if ([string]::IsNullOrEmpty($paths)) {
        return $false
    }
    
    $pathsArray = $paths -split ","
    $locations = @($env:ProgramFiles, "$env:ProgramFiles (x86)", $env:LOCALAPPDATA)
    
    foreach ($path in $pathsArray) {
        $path = $path.Trim()
        if (-not [string]::IsNullOrEmpty($path)) {
            # Check if the path is already a full path (contains drive letter or starts with \)
            if ($path -match '^[A-Za-z]:\\' -or $path.StartsWith('\\')) {
                # It's already a full path, check it directly
                if (Test-Path $path) {
                    return $true
                }
            } else {
                # It's a relative path, check in standard locations
                foreach ($location in $locations) {
                    if ($location) {
                        $fullPath = Join-Path -Path $location -ChildPath $path
                        
                        if (Test-Path $fullPath) {
                            return $true
                        }
                    }
                }
            }
        }
    }
    return $false
}

# Function to set environment path variable if not already set
function Set-EnvironmentVariable {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$app
    )

    # Define the locations to check for application paths
    $locations = @($env:ProgramFiles, "$env:ProgramFiles (x86)", $env:LOCALAPPDATA)

    # Find the actual installation path
    $actualPath = $null
    
    # Check if the programCheck is already a full path
    if ($app.programCheck -match '^[A-Za-z]:\\' -or $app.programCheck.StartsWith('\\')) {
        # It's already a full path, check it directly
        if (Test-Path $app.programCheck) {
            $actualPath = $app.programCheck
        }
    } else {
        # It's a relative path, check in standard locations
        foreach ($location in $locations) {
            $fullPath = Join-Path -Path $location -ChildPath $app.programCheck
            if (Test-Path $fullPath) {
                $actualPath = $fullPath
                break
            }
        }
    }

    if ($null -ne $actualPath) {
        # Get the directory path to add to the PATH environment variable and ensure it ends with a backslash
        $dirPath = (Split-Path -Path $actualPath -Parent) + '\'

        # Get the current PATH environment variable
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")

        # Check if the directory path is already in the PATH environment variable
        $pathArray = $currentPath -split ';'
        if (-not ($pathArray -contains $dirPath)) {
            $newPath = "$currentPath;$dirPath"
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host "Added $dirPath to the PATH environment variable."
        } else {
            Write-Host "$dirPath is already in the PATH environment variable."
        }
    } else {
        Write-Host "Could not find the installation path for $($app.name)."
    }
}

# Get user selection of groups to install
$selectedGroups = Get-SelectedGroups -groups $groups

# Check and install applications based on the configuration
$installVSCode = $false
$pendingWsl2 = $false

foreach ($app in $config.applications) {
    if (Test-AppInSelectedGroups -app $app -selectedGroups $selectedGroups) {
        # Default install to true if not explicitly set
        $install = $app.install
        if ($null -eq $install) {
            $install = $true
        }
    
        if ($install -eq $false) {
            Write-Host "Skipping installation of $($app.name) as per configuration."
            continue
        }

        $shouldInstall = $true

        if ($app.windowsArchiveUrl) {
            $mainMissing = (-not $app.programCheck) -or -not (Test-AllProgramLocations -paths $app.programCheck)
            $extrasMissing = Test-AnyWindowsExtraFileMissing -App $app
            $shouldInstall = $mainMissing -or $extrasMissing
        } else {
            if ($app.commandCheck -and (Test-CommandExists -Command $app.commandCheck)) {
                $shouldInstall = $false
            }
            if ($app.programCheck -and $shouldInstall) {
                if (Test-AllProgramLocations -paths $app.programCheck) {
                    $shouldInstall = $false
                }
            }
        }
        # vscode is a special case and we updated extensions if installed
        if ($app.name -eq "VSCode") {
            $installVSCode = $true
        }
        # Install if not installed
        if ($shouldInstall) {
            if ($app.windowsArchiveUrl) {
                Install-WindowsArchiveApplication -App $app
            } elseif ($app.url) {
                if ($app.enableWsl2 -eq $true) {
                    $pendingWsl2 = $true
                }
                $installerFileName = "$($app.name).exe"
                if ([string]::IsNullOrEmpty($app.installer) -eq $false) {
                    $installerFileName = $app.installer
                }
                if ([string]::IsNullOrEmpty($app.silentArguments) -eq $true) {
                    $app.silentArguments = "/quiet /norestart"
                }
                Install-Software -Name $app.name -Url $app.url -InstallerFileName $installerFileName -SilentArguments $app.silentArguments
            } else {
                Write-Warning "Skipping $($app.name): no windowsArchiveUrl or url for Windows."
            }
        } else {
            Write-Host "$($app.name) is already installed."
        }

        # Always check and set environment variables even if the application is already installed
        if ($app.environmentVariable -eq $true) {
            Set-EnvironmentVariable -app $app
        }
    } else {
        Write-Host "Skipping $($app.name) as it is not part of the selected groups."
    }
}

# Optional post-install: enable WSL 2 (YAML enableWsl2 on the application that was installed, e.g. Docker Desktop)
if ($pendingWsl2) {
    $wslVersion = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" -Name "DefaultVersion" -ErrorAction SilentlyContinue).DefaultVersion
    if ($wslVersion -ne 2) {
        Write-Host "Enabling WSL 2 (post-install flag enableWsl2)..."
        wsl --install
        wsl --set-default-version 2

        Write-Host "Please restart your system to apply WSL 2 changes. After restart, run this script again to continue the setup."
        shutdown /r /t 0
        exit
    } else {
        Write-Host "WSL 2 is already enabled."
    }
}

# If VSCode is installed or being installed, install the VSCode extensions
if ($installVSCode) {
    # Determine the correct path to code.cmd
    $codeCmdPath = (Get-Command code.cmd -ErrorAction SilentlyContinue).Source
    if (-not $codeCmdPath) {
        $codeCmdPath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"
        if (-not (Get-Item $codeCmdPath -ErrorAction SilentlyContinue)) {
            $codeCmdPath = "C:\Program Files\Microsoft VS Code\bin\code.cmd"
        }
    }

    # Install VSCode extensions
    Write-Host "Installing VSCode extensions..."
    foreach ($extension in $config.vscodeExtensions) {
        try {
            & $codeCmdPath --install-extension $extension --force
        } catch {
            Write-Error "Failed to install VSCode extension: $extension"
        }
    }
}

Write-Host "Computer setup complete. All selected applications and additional tools are installed. You can now proceed with the GitHub setup."
