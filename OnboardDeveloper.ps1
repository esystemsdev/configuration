Param(
    [string]$Server = "dev.aifabrix",
    [string]$DeveloperId,
    [string]$Pin,
    [string]$GitHubToken
)

function Read-ValueIfEmpty {
    param(
        [string]$Value,
        [string]$Prompt,
        [ValidateSet("text","secure")] [string]$Type = "text"
    )
    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($Type -eq "secure") {
            $sec = Read-Host -AsSecureString -Prompt $Prompt
            if ($null -eq $sec -or $sec.Length -eq 0) {
                return ""
            }
            $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
            try {
                $plainText = [Runtime.InteropServices.Marshal]::PtrToStringUni($bstr)
                return $plainText
            } finally {
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            }
        } else {
            return Read-Host -Prompt $Prompt
        }
    }
    return $Value
}

function Get-SSHPublicKey {
    $userHome = [Environment]::GetFolderPath("UserProfile")
    $sshDir = Join-Path $userHome ".ssh"
    $priv = Join-Path $sshDir "id_ed25519"
    $pub = Join-Path $sshDir "id_ed25519.pub"
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
    if (-not (Test-Path $priv -PathType Leaf -ErrorAction SilentlyContinue) -or -not (Test-Path $pub -PathType Leaf -ErrorAction SilentlyContinue)) {
        Write-Host "Generating SSH key (ed25519)..." -ForegroundColor Cyan
        & ssh-keygen -t ed25519 -f $priv -N "" -C "$env:USERNAME@aifabrix" | Out-Null
    }
    $pubKeyContent = Get-Content -Raw -Path $pub
    # Remove any trailing newlines/whitespace but keep the key on a single line
    return $pubKeyContent.Trim()
}

function Add-SSHConfigEntry {
    param(
        [string]$Alias,
        [string]$Server,
        [string]$User
    )
    $userHome = [Environment]::GetFolderPath("UserProfile")
    $sshDir = Join-Path $userHome ".ssh"
    $configPath = Join-Path $sshDir "config"
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
    $entry = @"
Host $Alias
    HostName $Server
    User $User
    IdentitiesOnly yes
"@
    if (Test-Path $configPath) {
        $existing = Get-Content -Raw -Path $configPath
        if ($existing -match "(?ms)^Host\s+$Alias(\r?\n\s+.+)*$") {
            return
        }
    }
    Add-Content -Path $configPath -Value "`n$entry"
}


try {
    $DeveloperId = Read-ValueIfEmpty -Value $DeveloperId -Prompt "Enter developer ID (e.g., 01)"
    if ($DeveloperId -notmatch '^[0-9]{1,6}$') {
        throw "Invalid DeveloperId. Use digits only."
    }
    $Pin = Read-ValueIfEmpty -Value $Pin -Prompt "Enter PIN (6-8 digits)"
    if ($Pin -notmatch '^[0-9]{4,8}$') {
        throw "Invalid PIN."
    }
    $pubKey = Get-SSHPublicKey
    
    # Optionally collect GitHub token for server-side SSH key setup
    if ([string]::IsNullOrWhiteSpace($GitHubToken)) {
        Write-Host "`nGitHub Setup (Optional):" -ForegroundColor Cyan
        Write-Host "To enable the server to commit to GitHub repositories, the server will generate an SSH key and add it to your GitHub account." -ForegroundColor Yellow
        Write-Host "`nCreate a Personal Access Token:" -ForegroundColor Cyan
        $tokenUrl = "https://github.com/settings/tokens/new?scopes=admin:public_key`&description=SSH%20Key%20for%20Dev%20Server%20-%20dev$DeveloperId"
        Write-Host "  Link: $tokenUrl" -ForegroundColor White
        Write-Host "  Note: The scope 'admin:public_key' is pre-selected for you" -ForegroundColor Yellow
        Write-Host "  Just give it a name and click 'Generate token', then copy it immediately!" -ForegroundColor Yellow
        $openBrowser = Read-Host "`nOpen this link in your browser now? (Y/N)"
        if ($openBrowser -match '^[Yy]') {
            try {
                Start-Process $tokenUrl
                Write-Host "Browser opened. After creating your token, come back here to enter it." -ForegroundColor Green
            } catch {
                Write-Host "Could not open browser automatically. Please visit: $tokenUrl" -ForegroundColor Yellow
            }
        }
        $GitHubToken = Read-ValueIfEmpty -Value $GitHubToken -Prompt "Enter GitHub Personal Access Token (optional, press Enter to skip)" -Type "secure"
    }
    
    $body = @{
        developerId = $DeveloperId
        pin         = $Pin
        publicKey   = $pubKey
    }
    if (-not [string]::IsNullOrWhiteSpace($GitHubToken)) {
        $body.githubToken = $GitHubToken
    }
    $body = $body | ConvertTo-Json

    $url = "http://$Server`:9999/api/claim"
    Write-Host "Claiming access at $url ..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $url -Body $body -ContentType "application/json" -ErrorAction Stop
    } catch {
        $statusCode = $null
        $errorDetails = $null
        $exception = $_.Exception
        
        # Try to extract HTTP status code from various exception types
        if ($exception.Response) {
            $statusCode = [int]$exception.Response.StatusCode
            $statusDescription = $exception.Response.StatusDescription
            $stream = $null
            $reader = $null
            try {
                $stream = $exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = New-Object System.IO.StreamReader($stream)
                    $errorDetails = $reader.ReadToEnd()
                }
            } catch {
                $errorDetails = "Could not read error response"
            } finally {
                if ($reader) {
                    try {
                        $reader.Dispose()
                    } catch {
                        # Ignore disposal errors
                    }
                }
                if ($stream) {
                    try {
                        $stream.Dispose()
                    } catch {
                        # Ignore disposal errors
                    }
                }
            }
        } elseif ($exception -is [System.Net.Http.HttpRequestException]) {
            # For HttpRequestException, try to get status code from inner exception
            if ($exception.InnerException -and $exception.InnerException.Response) {
                $statusCode = [int]$exception.InnerException.Response.StatusCode
                $statusDescription = $exception.InnerException.Response.ReasonPhrase
            }
        }
        
        # Fallback: try to parse status code from exception message
        if (-not $statusCode -and $exception.Message -match 'status code does not indicate success:\s*(\d+)\s*\(([^)]+)\)') {
            $statusCode = [int]$matches[1]
            $statusDescription = $matches[2]
        }
        
        # Provide user-friendly error messages based on status code
        if ($statusCode) {
            $statusMessages = @{
                400 = "Bad Request - Invalid developer ID or PIN format"
                401 = "Unauthorized - Invalid developer ID or PIN. Please verify your credentials."
                403 = "Forbidden - Access denied"
                404 = "Not Found - The claim endpoint was not found"
                500 = "Internal Server Error - Server encountered an error"
                503 = "Service Unavailable - Server is temporarily unavailable"
            }
            
            $userMessage = if ($statusMessages.ContainsKey($statusCode)) {
                $statusMessages[$statusCode]
            } else {
                "HTTP error $statusCode"
            }
            
            $errorMsg = "HTTP request failed: $userMessage (Status: $statusCode"
            if ($statusDescription) {
                $errorMsg += " - $statusDescription"
            }
            $errorMsg += ")"
            
            if ($errorDetails -and $errorDetails.Trim()) {
                $errorMsg += "`nServer response: $errorDetails"
            }
            
            throw $errorMsg
        } elseif ($exception.InnerException) {
            throw "Network error: $($exception.InnerException.Message). Server: $Server. Check if the server is reachable and the URL is correct."
        } else {
            throw "Network error: $($exception.Message). Server: $Server. Check if the server is reachable and the URL is correct."
        }
    }

    if (-not $response.ok) {
        throw "Claim failed: $($response | ConvertTo-Json -Compress)"
    }

    $username = "dev$DeveloperId"
    # Extract domain from server (everything after the first dot)
    $domain = if ($Server -match '^[^.]+\.(.+)$') { $matches[1] } else { "" }
    $hostAlias = if ($domain) { "$username.$domain" } else { $username }
    Add-SSHConfigEntry -Alias $hostAlias -Server $Server -User $username

    Write-Host "`nOnboarding complete!" -ForegroundColor Green
    Write-Host "SSH config entry added: $hostAlias" -ForegroundColor Cyan
    if ($response.githubKeyAdded) {
        Write-Host "SSH key generated in container and added to GitHub - server can now commit to repositories" -ForegroundColor Green
    } elseif (-not [string]::IsNullOrWhiteSpace($GitHubToken)) {
        Write-Host "GitHub token provided - server will attempt to set up SSH key for GitHub access" -ForegroundColor Yellow
    }
    Write-Host "`nNote: SSH connects directly to your Docker container, which needs time to start up." -ForegroundColor Yellow
    Write-Host "Please wait a few minutes before connecting via SSH or Cursor." -ForegroundColor Yellow
    Write-Host "`nTo connect later, use: ssh $hostAlias" -ForegroundColor Cyan
    Write-Host "Or connect via Cursor: Select '$hostAlias' when connecting via SSH" -ForegroundColor Cyan
} catch {
    $errorMessage = $_.Exception.Message
    if ($_.Exception.InnerException) {
        $errorMessage = "$errorMessage`nInner exception: $($_.Exception.InnerException.Message)"
    }
    Write-Host "`nError: $errorMessage" -ForegroundColor Red
    exit 1
}
