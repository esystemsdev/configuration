# Clone/update Git repos from one SetupGitEnv YAML file (no merge / no extends).
# Default workspace root: C:\workspace. Override: $env:GIT_FOLDER
# Default config: SetupGitEnv.yaml next to this script. Override: $env:SETUPGITENV_CONFIG or -ConfigPath
# Group filter: $env:SETUPGITENV_GROUP or -Group (optional; uses `groups` in the YAML)

param(
    [string]$ConfigPath = "",
    [string]$Group = ""
)

if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "powershell-yaml not found. Installing (same as SetupDeveloperEnv.ps1)..."
    try {
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser -ErrorAction Stop -Confirm:$false
    } catch {
        Write-Error "Failed to install powershell-yaml. Exiting."
        exit 1
    }
}
Import-Module powershell-yaml

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ConfigPath) {
    $ConfigPath = if ($env:SETUPGITENV_CONFIG -and $env:SETUPGITENV_CONFIG.Trim()) {
        $env:SETUPGITENV_CONFIG.Trim()
    } else {
        Join-Path $ScriptDir "SetupGitEnv.yaml"
    }
}
if (-not $Group) {
    $Group = if ($env:SETUPGITENV_GROUP) { $env:SETUPGITENV_GROUP.Trim() } else { "" }
}

$gitFolder = if ($env:GIT_FOLDER -and $env:GIT_FOLDER.Trim()) {
    $env:GIT_FOLDER.Trim()
} else {
    "C:\workspace"
}

function ConvertTo-NormalizedHashtable {
    param ($Obj)
    if ($null -eq $Obj) { return $null }
    if ($Obj -is [hashtable]) {
        $h = @{}
        foreach ($k in $Obj.Keys) { $h[[string]$k] = ConvertTo-NormalizedHashtable $Obj[$k] }
        return $h
    }
    if ($Obj -is [System.Collections.IDictionary]) {
        $h = @{}
        foreach ($k in $Obj.Keys) { $h[[string]$k] = ConvertTo-NormalizedHashtable $Obj[$k] }
        return $h
    }
    if ($Obj -is [string]) { return $Obj }
    if ($Obj -is [System.Collections.IEnumerable]) {
        $arr = [System.Collections.ArrayList]@()
        foreach ($i in $Obj) { [void]$arr.Add((ConvertTo-NormalizedHashtable $i)) }
        return ,@($arr)
    }
    if ($Obj.GetType().Name -eq 'PSCustomObject') {
        $h = @{}
        foreach ($p in $Obj.PSObject.Properties) {
            $h[$p.Name] = ConvertTo-NormalizedHashtable $p.Value
        }
        return $h
    }
    return $Obj
}

function Read-WorkspaceYamlDoc {
    param ([string]$Path)
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding utf8
    $doc = ConvertFrom-Yaml $raw
    return (ConvertTo-NormalizedHashtable $doc)
}

function Apply-GroupFilter {
    param ($Doc, [string]$GroupName)
    $g = $Doc.groups[$GroupName]
    if ($null -eq $g) {
        $keys = @($Doc.groups.Keys) -join ", "
        Write-Error "SetupGitEnv: unknown group '$GroupName'. Defined: $keys"
        exit 1
    }
    $allowed = @{}
    foreach ($n in @($g)) { $allowed[[string]$n] = $true }
    $filtered = @($Doc.repos | Where-Object { $allowed[[string]$_.name] })
    if ($filtered.Count -eq 0) {
        Write-Error "SetupGitEnv: group '$GroupName' matched no repos."
        exit 1
    }
    $Doc = @{
        gitFolder    = $Doc.gitFolder
        organization = $Doc.organization
        packages     = $Doc.packages
        groups       = $Doc.groups
        repos        = $filtered
    }
    return $Doc
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    Write-Error "Workspace config not found: $ConfigPath"
    exit 1
}

$doc = Read-WorkspaceYamlDoc -Path $ConfigPath
$workspace = @{
    gitFolder    = $doc.gitFolder
    organization = $doc.organization
    packages     = @($doc.packages)
    repos        = @($doc.repos)
    groups       = if ($null -ne $doc.groups) { $doc.groups } else { @{} }
}

if ([string]::IsNullOrWhiteSpace([string]$workspace.organization)) {
    Write-Error "SetupGitEnv: YAML must set organization."
    exit 1
}
if (-not $workspace.repos -or $workspace.repos.Count -eq 0) {
    Write-Error "SetupGitEnv: no repositories to clone."
    exit 1
}

if ($Group) {
    $workspace = Apply-GroupFilter -Doc $workspace -GroupName $Group
}

foreach ($repo in $workspace.repos) {
    if ([string]::IsNullOrWhiteSpace([string]$repo.name) -or [string]::IsNullOrWhiteSpace([string]$repo.url)) {
        Write-Error "SetupGitEnv: each repo needs name and url."
        exit 1
    }
}

if ($workspace.gitFolder) {
    $gitFolder = [string]$workspace.gitFolder
}

$organization = [string]$workspace.organization
$packagesList = @($workspace.packages)
$repos = @($workspace.repos)

$orgFolder = Join-Path -Path $gitFolder -ChildPath $organization
$aifabrixWorkRoot = if ($env:AIFABRIX_WORK -and $env:AIFABRIX_WORK.Trim()) {
    $env:AIFABRIX_WORK.Trim()
} else {
    $orgFolder
}

function Set-DirectoryExists {
    param ([string]$Path)
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Creating directory: $Path"
        New-Item -Path $Path -ItemType Directory -Force
    } else {
        Write-Host "Directory already exists: $Path"
    }
}

function Set-FullAccessPermissions {
    param ([string]$Path)
    $acl = Get-Acl $Path
    $currentRules = $acl.Access | Where-Object {
        $_.IdentityReference -eq "Users" -and $_.FileSystemRights -eq "FullControl"
    }
    if ($currentRules.Count -eq 0) {
        Write-Host "Setting full access permissions to the Users group for: $Path"
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.AddAccessRule($accessRule)
        Set-Acl -Path $Path -AclObject $acl
    } else {
        Write-Host "Users group already has full access permissions on: $Path"
    }
}

function Set-AifabrixWorkConfig {
    param ([string]$WorkPath)
    $configDir = Join-Path -Path $HOME -ChildPath '.aifabrix'
    $cfgPath = Join-Path -Path $configDir -ChildPath 'config.yaml'
    if (-not (Test-Path -Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    $resolved = $WorkPath
    try {
        if (Test-Path -Path $WorkPath) {
            $resolved = (Resolve-Path -Path $WorkPath).Path
        }
    } catch { }
    $yamlValue = $resolved -replace "'", "''"
    $newLine = "aifabrix-work: '$yamlValue'"
    $lines = @()
    if (Test-Path -Path $cfgPath) {
        $lines = @(Get-Content -Path $cfgPath -Encoding utf8)
    }
    $filtered = $lines | Where-Object { $_ -notmatch '^\s*aifabrix-work\s*:' }
    $out = @($filtered + $newLine)
    Set-Content -Path $cfgPath -Value $out -Encoding utf8
    Write-Host "Updated aifabrix-work in: $cfgPath"
}

function Set-AifabrixUserEnv {
    param ([string]$ConfigDir, [string]$WorkPath)
    $homeResolved = $ConfigDir
    try {
        if (Test-Path -Path $ConfigDir) {
            $homeResolved = (Resolve-Path -Path $ConfigDir).Path
        }
    } catch { }
    $workResolved = $WorkPath
    try {
        if (Test-Path -Path $WorkPath) {
            $workResolved = (Resolve-Path -Path $WorkPath).Path
        }
    } catch { }
    [System.Environment]::SetEnvironmentVariable('AIFABRIX_HOME', $homeResolved, 'User')
    [System.Environment]::SetEnvironmentVariable('AIFABRIX_WORK', $workResolved, 'User')
    Write-Host "Set user environment AIFABRIX_HOME=$homeResolved"
    Write-Host "Set user environment AIFABRIX_WORK=$workResolved"
    Write-Host "Open a new terminal, then: echo `$env:AIFABRIX_HOME"
}

function Set-GitSafeDirectory {
    param ([string]$Path)
    $currentConfig = git config --global --get-all safe.directory
    if ($currentConfig -notcontains $Path) {
        Write-Host "Configuring Git safe directory for: $Path"
        git config --global --add safe.directory $Path
    } else {
        Write-Host "Git safe directory already configured for: $Path"
    }
}

function Set-Or-Update-RepositoryFromUrl {
    param (
        [string]$Name,
        [string]$Url,
        [string]$OrgFolder
    )
    $clonePath = Join-Path -Path $OrgFolder -ChildPath $Name
    Set-GitSafeDirectory -Path $clonePath
    if (-not (Test-Path -Path "$clonePath\.git")) {
        Write-Host "Cloning $Name from $Url to $clonePath..."
        & git clone $Url $clonePath
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git clone failed for $Name"
            exit 1
        }
    } else {
        Write-Host "Repository $Name already in $clonePath. Pulling..."
        & git -C $clonePath pull
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git pull failed for $Name"
            exit 1
        }
    }
}

Write-Host "Using workspace config: $ConfigPath"
if ($Group) {
    Write-Host "Group filter: $Group"
}

Write-Host "Ensuring directories exist..."
Set-DirectoryExists -Path $gitFolder
Set-DirectoryExists -Path $orgFolder

Set-AifabrixWorkConfig -WorkPath $aifabrixWorkRoot
$configDirForEnv = Join-Path -Path $HOME -ChildPath '.aifabrix'
Set-AifabrixUserEnv -ConfigDir $configDirForEnv -WorkPath $aifabrixWorkRoot

Set-FullAccessPermissions -Path $gitFolder
Set-FullAccessPermissions -Path $orgFolder
Set-GitSafeDirectory -Path $gitFolder

foreach ($repo in $repos) {
    Set-Or-Update-RepositoryFromUrl -Name $repo.name -Url $repo.url -OrgFolder $orgFolder
}

Write-Output "Installing necessary npm packages..."
foreach ($pkg in $packagesList) {
    $trimmedPackage = [string]$pkg
    if (-not [string]::IsNullOrWhiteSpace($trimmedPackage)) {
        Write-Output "Installing npm package: $trimmedPackage..."
        npm install -g $trimmedPackage
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Installation of npm package $trimmedPackage failed."
            exit 1
        }
    }
}

Write-Host "Setup complete."
