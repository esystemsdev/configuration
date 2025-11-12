Param(
    [string]$Server = "dev.aifabrix",
    [string]$DeveloperId,
    [string]$Pin
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
            return [Runtime.InteropServices.Marshal]::PtrToStringUni([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
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
    return Get-Content -Raw -Path $pub
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
    $Pin = Read-ValueIfEmpty -Value $Pin -Prompt "Enter PIN (6–8 digits)"
    if ($Pin -notmatch '^[0-9]{4,8}$') {
        throw "Invalid PIN."
    }
    $pubKey = Get-SSHPublicKey
    $body = @{
        developerId = $DeveloperId
        pin         = $Pin
        publicKey   = $pubKey
    } | ConvertTo-Json

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
            try {
                $stream = $exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = New-Object System.IO.StreamReader($stream)
                    $errorDetails = $reader.ReadToEnd()
                    $reader.Close()
                    $stream.Close()
                }
            } catch {
                $errorDetails = "Could not read error response"
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
    Add-SSHConfigEntry -Alias $username -Server $Server -User $username

    Write-Host "Testing SSH connectivity..." -ForegroundColor Cyan
    $null = & ssh "$username@$Server" -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "echo ok" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "SSH test failed. You may need to run: ssh $username@$Server"
    } else {
        Write-Host "Onboarding complete. Connect with: ssh $username" -ForegroundColor Green
    }
} catch {
    $errorMessage = $_.Exception.Message
    if ($_.Exception.InnerException) {
        $errorMessage = "$errorMessage`nInner exception: $($_.Exception.InnerException.Message)"
    }
    Write-Host "`nError: $errorMessage" -ForegroundColor Red
    exit 1
}

