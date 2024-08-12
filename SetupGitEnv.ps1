# Define the directories
$gitFolder      = "C:\git"
$organization   = "esystemsdev"
$repositories   = "configuration,"  # Comma-separated list of repositories
$packages       = ""  # Comma-separated list of npm packages

$orgFolder = "$gitFolder\$organization"

# Function to create a directory if it doesn't exist
function Set-DirectoryExists {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Creating directory: $Path"
        New-Item -Path $Path -ItemType Directory -Force
    } else {
        Write-Host "Directory already exists: $Path"
    }
}

# Function to set full access permissions for the Users group
function Set-FullAccessPermissions {
    param (
        [string]$Path
    )

    $acl = Get-Acl $Path
    $currentRules = $acl.Access | Where-Object { $_.IdentityReference -eq "Users" -and $_.FileSystemRights -eq "FullControl" }

    if ($currentRules.Count -eq 0) {
        Write-Host "Setting full access permissions to the Users group for: $Path"
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($accessRule)
        Set-Acl -Path $Path -AclObject $acl
    } else {
        Write-Host "Users group already has full access permissions on: $Path"
    }
}

# Function to configure Git safe directory
function Set-GitSafeDirectory {
    param (
        [string]$Path
    )

    $currentConfig = git config --global --get-all safe.directory
    if ($currentConfig -notcontains $Path) {
        Write-Host "Configuring Git safe directory for: $Path"
        git config --global --add safe.directory $Path
    } else {
        Write-Host "Git safe directory already configured for: $Path"
    }
}

# Function to clone or update a repository
function Set-Or-Update-Repository {
    param (
        [string]$Repository,
        [string]$OrgFolder,
        [string]$Organization
    )
    
    $repositoryUrl = "https://github.com/$Organization/$Repository.git"
    $clonePath = Join-Path -Path $OrgFolder -ChildPath $Repository

    # Configure Git safe directory
    Set-GitSafeDirectory -Path $clonePath

    if (-not (Test-Path -Path "$clonePath\.git")) {
        Write-Host "Cloning the repository $Repository to $clonePath..."
        Start-Process -FilePath "git" -ArgumentList "clone", $repositoryUrl, $clonePath -NoNewWindow -Wait
    } else {
        Write-Host "Repository $Repository already cloned in $clonePath. Pulling the latest changes from $repositoryUrl..."
        Start-Process -FilePath "git" -ArgumentList "-C", $clonePath, "pull" -NoNewWindow -Wait
    }
}


# Ensure the directories exist
Write-Host "Ensuring directories exist..."
Set-DirectoryExists -Path $gitFolder
Set-DirectoryExists -Path $orgFolder

# Set full access permissions to the Users group
Set-FullAccessPermissions -Path $gitFolder
Set-FullAccessPermissions -Path $orgFolder

# Configure Git safe directory
Set-GitSafeDirectory -Path $gitFolder

# Clone or update each repository
$repositoriesList = $repositories -split ","
foreach ($repository in $repositoriesList) {
    Set-Or-Update-Repository -Repository $repository.Trim() -OrgFolder $orgFolder -Organization $organization
}

# Install necessary npm packages globally
Write-Output "Installing necessary npm packages..."

$packagesList = $packages -split ","
foreach ($package in $packagesList) {
    $trimmedPackage = $package.Trim()  # Trim whitespace from the package name

    if (-not [string]::IsNullOrEmpty($trimmedPackage)) {  # Check if the package name is not empty
        Write-Output "Installing npm package: $trimmedPackage..."
        npm install -g $trimmedPackage
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Installation of npm package $trimmedPackage failed."
            exit 1
        }
    } else {
        Write-Output "Skipping empty or whitespace-only package name."
    }
}

Write-Host "Setup complete."