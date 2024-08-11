# Define the directories
$gitFolder = "C:\git"
$organization = "esystemsdev"
$repository = "configuration"
$orgFolder = "$gitFolder\$organization"

# Function to create a directory if it doesn't exist
function Set-Directory {
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

    Write-Host "Setting full access permissions to the Users group for: $Path"
    $acl = Get-Acl $Path
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRuleProtection($false, $false)
    $acl.AddAccessRule($accessRule)
    Set-Acl -Path $Path -AclObject $acl
}

# Create the directories
Write-Host "Ensuring directories exist..."
Set-Directory -Path $gitFolder
Set-Directory -Path $orgFolder

# Set full access permissions to the Users group
Set-FullAccessPermissions -Path $gitFolder
Set-FullAccessPermissions -Path $orgFolder

# Configure Git
Write-Host "Configuring Git..."
git config --global --add safe.directory C:\git

# Clone the repository
$repositoryUrl = "https://github.com/$organization/$repository.git"
$clonePath = "$orgFolder\$repository"

if (-not (Test-Path -Path "$clonePath\.git")) {
    Write-Host "Cloning the repository to $clonePath..."
    git clone $repositoryUrl $clonePath
} else {
    Write-Host "Repository already cloned in $clonePath. Pulling the latest changes..."
    git -C $clonePath pull
}

Write-Host "Setup complete."
