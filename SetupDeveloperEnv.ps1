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

# Set the path to the YAML file
$yamlFilePath = Join-Path -Path $scriptDir -ChildPath "SetupDeveloperEnv.yaml"

# Check if the YAML file exists
if (-not (Test-Path -Path $yamlFilePath)) {
    Write-Error "The SetupDeveloperEnv.yaml file was not found in the script directory: $scriptDir"
    exit 1
}

# Parse the YAML file
$config = ConvertFrom-Yaml (Get-Content -Path $yamlFilePath -Raw)

# Function to prompt user for application group selection
function Prompt-UserForGroupSelection {
    Write-Host "Please select the groups of applications you want to install."
    Write-Host "The following groups are available:"
    
    $groupNames = $config.applications.group | Sort-Object -Unique
    $groupSelections = @()
    
    foreach ($group in $groupNames) {
        # Provide a brief description of the group contents
        $appsInGroup = $config.applications | Where-Object { $_.group -eq $group } | ForEach-Object { $_.name }
        Write-Host "`n[$group] includes:"
        $appsInGroup | ForEach-Object { Write-Host "- $_" }
        
        $choice = Read-Host "`nDo you want to install the $group group? (y/n)"
        if ($choice -eq 'y') {
            $groupSelections += $group
        }
    }

    # Automatically include the "Development" group
    if (-not ($groupSelections -contains "Development")) {
        Write-Host "`nThe 'Development' group is required and will be installed automatically."
        $groupSelections += "Development"
    }

    return $groupSelections
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
    return $false
}

# Get user selection of groups to install
$selectedGroups = Prompt-UserForGroupSelection

# Check and install applications based on the configuration
$installDocker = $false
$installVSCode = $false

foreach ($app in $config.applications) {
    if ($selectedGroups -contains $app.group) {
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

        # Check based on command
        if ($app.commandCheck -and (Test-CommandExists -Command $app.commandCheck)) {
            $shouldInstall = $false
        }

        # Check based on paths
        if ($app.programCheck -and $shouldInstall) {
            if (Test-AllProgramLocations -paths $app.programCheck) {
                $shouldInstall = $false
            }
        }
        if ($app.name -eq "VSCode") {
            $installVSCode = $true
        }
        # Install if not installed
        if ($shouldInstall) {
            if ($app.name -eq "Docker") {
                $installDocker = $true
            }

            # Determine installer type
            $installerFileName = "$($app.name).exe"
            if ([string]::IsNullOrEmpty($app.installer) -eq $false) {
                $installerFileName = $app.installer
            }
            if([string]::IsNullOrEmpty($app.silentArguments) -eq $true) {
                $app.silentArguments = "/quiet /norestart"
            }
            Install-Software -Name $app.name -Url $app.url -InstallerFileName $installerFileName -SilentArguments $app.silentArguments
        } else {
            Write-Host "$($app.name) is already installed."
        }
    } else {
        Write-Host "Skipping $($app.name) as it is not part of the selected groups."
    }
}

# If Docker is installed or being installed, check and enable WSL 2
if ($installDocker) {
    $wslVersion = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" -Name "DefaultVersion" -ErrorAction SilentlyContinue).DefaultVersion
    if ($wslVersion -ne 2) {
        Write-Host "Enabling WSL 2 for Docker..."
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
