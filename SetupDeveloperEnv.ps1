
# Helper function to download and install MSI or EXE files with error handling and exit code verification
function Install-Software {
    param (
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

    Write-Host "Installing $InstallerFileName..."
    try {
        # Start the process and wait for it to finish
        $process = Start-Process -FilePath $tempPath -ArgumentList $SilentArguments -Wait -PassThru

        # Check the exit code
        if ($process.ExitCode -ne 0) {
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

# Helper function to check if any of the provided paths exist
function Test-AnyPath {
    param (
        [string[]]$Paths
    )

    foreach ($Path in $Paths) {
        if (Test-Path $Path) {
            return $true
        }
    }
    return $false
}

# Check if Docker is installed
if (Get-Item "C:\Program Files\Docker\Docker\DockerCli.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Docker is already installed."
} else {
    Install-Software -Url "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe" -InstallerFileName "DockerDesktopInstaller.exe" -SilentArguments "install --quiet"
}

# Check if WSL 2 is enabled
$wslVersion = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" -Name "DefaultVersion" -ErrorAction SilentlyContinue).DefaultVersion

if ($wslVersion -ne 2) {
    Write-Host "Enabling WSL 2..."
    wsl --install
    wsl --set-default-version 2

    Write-Host "Please restart your system to apply WSL 2 changes. After restart, run this script again to continue the setup."
    shutdown /r /t 0
    exit
} else {
    Write-Host "WSL 2 is already enabled."
}

# Install Git client
if (Get-Item "C:\Program Files\Git\cmd\git.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Git client is already installed."
} else {
    Install-Software -Url "https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/Git-2.46.0-64-bit.exe" -InstallerFileName "GitInstaller.exe" -SilentArguments "/SILENT"
}

# Check if VSCode is installed
if (Test-AnyPath -Paths @("C:\Program Files\Microsoft VS Code\Code.exe", "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe")) {
    Write-Host "VSCode is already installed."
} else {
    Install-Software -Url "https://update.code.visualstudio.com/latest/win32-x64/stable" -InstallerFileName "VSCodeInstaller.exe" -SilentArguments "/VERYSILENT /MERGETASKS=!runcode"
}

# Check if Node.js is installed
if (Get-Item "C:\Program Files\nodejs\node.exe" -ErrorAction SilentlyContinu) {
    Write-Host "Node.js is already installed."
} else {
    Install-Software -Url "https://nodejs.org/dist/v18.17.1/node-v18.17.1-x64.msi" -InstallerFileName "NodeInstaller.msi"
}

# Check if Python is installed
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Python is already installed."
} else {
    Install-Software -Url "https://www.python.org/ftp/python/3.11.5/python-3.11.5-amd64.exe" -InstallerFileName "PythonInstaller.exe" -SilentArguments "/quiet InstallAllUsers=1 PrependPath=1"
}

# Check if pgAdmin 4 is installed
if (Get-Item "C:\Program Files\pgAdmin 4\runtime\pgAdmin4.exe" -ErrorAction SilentlyContinue) {
    Write-Host "pgAdmin 4 is already installed."
} else {
    Install-Software -Url "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v8.10/windows/pgadmin4-8.10-x64.exe" -InstallerFileName "pgAdminInstaller.exe" -SilentArguments "/VERYSILENT /ALLUSERS"
}

# Check if Twingate is installed
if (Get-Item "C:\Program Files\Twingate\Twingate.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Twingate is already installed."
} else {
    Install-Software -Url "https://api.twingate.com/download/windows" -InstallerFileName "TwingateInstaller.exe" -SilentArguments "/quiet"
}

# Check if JDK is installed
if (Get-Item "C:\Program Files\Java\jdk-17\bin\java.exe" -ErrorAction SilentlyContinue) {
    Write-Host "JDK is already installed."
} else {
    Install-Software -Url "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.msi" -InstallerFileName "JDKInstaller.msi"
}

# Check if Visual Studio 2022 is installed
if (Get-Item "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Visual Studio 2022 is already installed."
} else {
    Install-Software -Url "https://aka.ms/vs/17/release/vs_community.exe" -InstallerFileName "VS2022Installer.exe" -SilentArguments "--add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.Net.Component.4.8.SDK --add Microsoft.Net.Component.4.8.TargetingPack --add Microsoft.Net.ComponentGroup.TargetingPacks.Common --add Microsoft.Net.ComponentGroup.DevelopmentPrerequisites --add Microsoft.VisualStudio.Component.Web --add Microsoft.VisualStudio.Component.FSharp --add Microsoft.VisualStudio.Component.VC.CoreIde --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.DiagnosticTools --add Microsoft.VisualStudio.Component.Windows10SDK.18362 --add Microsoft.Net.Component.4.8.SDK --add Microsoft.Net.Component.4.8.TargetingPack --add Microsoft.NetCore.Component.SDK --add Microsoft.NetCore.Component.DevelopmentTools --add Microsoft.NetCore.Component.Runtime.6.0 --add Microsoft.NetCore.Component.Runtime.8.0 --add Microsoft.VisualStudio.Workload.Python --add Microsoft.VisualStudio.Workload.Azure --add Microsoft.VisualStudio.Workload.Node"
}

# Check if SSMS is installed
$ssmsPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio"
if (Test-AnyPath -Paths @("$ssmsPath 18\Common7\IDE\Ssms.exe", "$ssmsPath 20\Common7\IDE\Ssms.exe")) {
    Write-Host "SSMS is already installed."
} else {
    Install-Software -Url "https://aka.ms/ssmsfullsetup" -InstallerFileName "SSMS-Setup-ENU.exe"
}

# Check if 7-Zip is installed
if (Get-Item "C:\Program Files\7-Zip\7z.exe" -ErrorAction SilentlyContinue) {
    Write-Host "7-Zip is already installed."
} else {
    Install-Software -Url "https://www.7-zip.org/a/7z2301-x64.exe" -InstallerFileName "7zInstaller.exe" -SilentArguments "/S"
}

# Install Slack using direct download
if (Test-AnyPath -Paths @("C:\Program Files\Slack\slack.exe", "$env:LOCALAPPDATA\slack\slack.exe")) {
    Write-Host "Slack is already installed."
} else {
    Write-Host "Installing Slack..."
    Install-Software -Url "https://downloads.slack-edge.com/releases/windows/4.32.122/prod/x64/SlackSetup.exe" -InstallerFileName "SlackSetup.exe"
}

# Check if Google Chrome is installed
if (Get-Item "C:\Program Files\Google\Chrome\Application\chrome.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Google Chrome is already installed."
} else {
    Install-Software -Url "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B743FF219-1E25-35A1-2BE5-CAAAAE003F78%7D%26lang%3Den%26browser%3D4%26usagestats3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dfalse%26ap%3Dx64-stable%26brand%3DGCEU/dl/chrome/install/googlechromestandaloneenterprise64.msi" -InstallerFileName "GoogleChrome.msi"
}

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
& $codeCmdPath --install-extension ms-azuretools.vscode-docker
& $codeCmdPath --install-extension ms-vscode-remote.remote-containers
& $codeCmdPath --install-extension ms-python.python
& $codeCmdPath --install-extension eamodio.gitlens
& $codeCmdPath --install-extension github.copilot
& $codeCmdPath --install-extension github.copilot-chat
& $codeCmdPath --install-extension ms-dotnettools.vscode-dotnet-runtime
& $codeCmdPath --install-extension ms-dotnettools.csharp
& $codeCmdPath --install-extension ms-dotnettools.csdevkit
& $codeCmdPath --install-extension davidanson.vscode-markdownlint
& $codeCmdPath --install-extension eg2.vscode-npm-script
& $codeCmdPath --install-extension ms-vscode.powershell
& $codeCmdPath --install-extension dbaeumer.vscode-eslint
& $codeCmdPath --install-extension esbenp.prettier-vscode
& $codeCmdPath --install-extension ms-vscode-remote.remote-wsl  # WSL extension

& $codeCmdPath --install-extension ms-vscode.vscode-html-language-features
& $codeCmdPath --install-extension ecmel.vscode-html-css
& $codeCmdPath --install-extension esbenp.prettier-vscode
& $codeCmdPath --install-extension ritwickdey.LiveServer
& $codeCmdPath --install-extension $ExtensionName --force

# Check if Postman is installed - THIS IS NOT SILENT
if (Test-AnyPath -Paths @("C:\Program Files\Postman\Postman.exe", "$env:LOCALAPPDATA\Postman\Postman.exe")) {
    Write-Host "Postman is already installed."
} else {
    Install-Software -Url "https://dl.pstmn.io/download/latest/win64" -InstallerFileName "Postman.exe" -SilentArguments "/S"
}

Write-Host "Computer setup complete. Docker, VSCode, Node.js, Python, and additional tools are installed. You can now proceed with the Frappe environment setup."
