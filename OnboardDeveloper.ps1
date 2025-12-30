Param(
    [string]$Server = "dev.aifabrix",
    [string]$DeveloperId,
    [string]$Pin,
    [string]$GitHubToken,
    [switch]$RDPOnly
)

function Test-CommandAvailable {
    param(
        [string]$CommandName,
        [string]$InstallationHint
    )
    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $cmd) {
        $message = "$CommandName is not available. $InstallationHint"
        if ($InstallationHint) {
            throw $message
        } else {
            throw "$CommandName is not available. Please ensure it is installed and available in your PATH."
        }
    }
    return $true
}

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
    
    if (-not (Test-Path $sshDir)) {
        try {
            New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
        } catch {
            throw "Failed to create SSH directory at $sshDir`: $($_.Exception.Message)"
        }
    }
    
    if (-not (Test-Path $priv -PathType Leaf -ErrorAction SilentlyContinue) -or -not (Test-Path $pub -PathType Leaf -ErrorAction SilentlyContinue)) {
        # ssh-keygen should already be verified at script start, but check again defensively
        if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
            throw "ssh-keygen command not found. Please ensure OpenSSH is installed and available in your PATH."
        }
        
        Write-Host "Generating SSH key (ed25519)..." -ForegroundColor Cyan
        
        $comment = "$env:USERNAME@aifabrix"
        
        try {
            # Capture both stdout and stderr to check for errors
            # Use Start-Process for better argument control on Windows, or fallback to direct call
            $keygenSucceeded = $false
            $lastError = $null
            $output = $null
            
            # Method 1: Try direct call with -N "" (most common case)
            try {
                $output = & ssh-keygen -t ed25519 -f $priv -N '""' -C $comment 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 0) {
                    $keygenSucceeded = $true
                } else {
                    $outputStr = $output | Out-String
                    $lastError = "Exit code: $exitCode"
                    if ($outputStr) {
                        $lastError += ", Output: $outputStr"
                    }
                }
            } catch {
                $lastError = "Exception: $($_.Exception.Message)"
            }
            
            # Method 2: If "too many arguments" or other failure, try using Start-Process without -N
            if (-not $keygenSucceeded -and ($lastError -match 'too many arguments' -or $lastError -match 'Too many arguments')) {
                Write-Host "Retrying without passphrase parameter..." -ForegroundColor Yellow
                try {
                    # Try without -N parameter (some Windows versions don't accept empty -N)
                    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                    $processInfo.FileName = "ssh-keygen"
                    $processInfo.Arguments = "-q -t ed25519 -f `"$priv`" -C `"$comment`""
                    $processInfo.UseShellExecute = $false
                    $processInfo.RedirectStandardOutput = $true
                    $processInfo.RedirectStandardError = $true
                    $processInfo.RedirectStandardInput = $true
                    $processInfo.CreateNoWindow = $true
                    
                    $process = New-Object System.Diagnostics.Process
                    $process.StartInfo = $processInfo
                    $null = $process.Start()
                    
                    # Send two newlines (empty passphrase and confirmation)
                    $process.StandardInput.WriteLine()
                    $process.StandardInput.WriteLine()
                    $process.StandardInput.Close()
                    
                    $stdout = $process.StandardOutput.ReadToEnd()
                    $stderr = $process.StandardError.ReadToEnd()
                    $process.WaitForExit()
                    $exitCode = $process.ExitCode
                    
                    if ($exitCode -eq 0) {
                        $keygenSucceeded = $true
                    } else {
                        $lastError = "Start-Process exit code: $exitCode"
                        if ($stderr) { $lastError += ", Error: $stderr" }
                        if ($stdout) { $lastError += ", Output: $stdout" }
                    }
                } catch {
                    $lastError = "$lastError ; Start-Process exception: $($_.Exception.Message)"
                }
            }
            
            if (-not $keygenSucceeded) {
                throw "ssh-keygen failed after multiple attempts. $lastError`n`nTroubleshooting: Ensure OpenSSH is properly installed. You may need to generate the key manually using: ssh-keygen -t ed25519 -f `"$priv`" -C `"$comment`""
            }
            
            # Verify the key files were created
            if (-not (Test-Path $pub -PathType Leaf -ErrorAction SilentlyContinue)) {
                throw "SSH key generation appeared to succeed, but public key file was not created at $pub"
            }
            if (-not (Test-Path $priv -PathType Leaf -ErrorAction SilentlyContinue)) {
                throw "SSH key generation appeared to succeed, but private key file was not created at $priv"
            }
        } catch {
            $errorMsg = $_.Exception.Message
            if ($errorMsg -match 'Too many arguments') {
                throw "SSH key generation failed: Invalid arguments passed to ssh-keygen. This may indicate an issue with your OpenSSH installation. Error: $errorMsg"
            }
            throw "SSH key generation failed: $errorMsg"
        }
    }
    
    # Verify the public key file exists before reading
    if (-not (Test-Path $pub -PathType Leaf -ErrorAction SilentlyContinue)) {
        throw "SSH public key file not found at $pub. Please ensure the key was generated successfully."
    }
    
    try {
        $pubKeyContent = Get-Content -Raw -Path $pub
        if ([string]::IsNullOrWhiteSpace($pubKeyContent)) {
            throw "SSH public key file is empty at $pub"
        }
        # Remove any trailing newlines/whitespace but keep the key on a single line
        return $pubKeyContent.Trim()
    } catch {
        throw "Failed to read SSH public key from $pub`: $($_.Exception.Message)"
    }
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

function New-RDPFile {
    param(
        [string]$Server,
        [int]$Port,
        [string]$Username,
        [string]$DesktopPath
    )
    
    $rdpContent = @"
screen mode id:i:2
use multimon:i:0
desktopwidth:i:2560
desktopheight:i:1440
session bpp:i:32
winposstr:s:0,1,125,21,2174,1104
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
full address:s:${Server}:${Port}
use redirection server name:i:1
alternate full address:s:${Username}-${Server}:${Port}
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:2
prompt for credentials:i:0
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:4
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:0
promptcredentialonce:i:0
gatewaybrokeringtype:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
redirectwebauthn:i:1
enablerdsaadauth:i:0
remoteappmousemoveinject:i:1
redirectlocation:i:0
username:s:${Username}
drivestoredirect:s:
"@
    
    try {
        $rdpFileName = "${Server} - ${Username}.rdp"
        $rdpFilePath = Join-Path $DesktopPath $rdpFileName
        $rdpContent | Out-File -FilePath $rdpFilePath -Encoding ASCII -NoNewline
        Write-Host "RDP file created: $rdpFilePath" -ForegroundColor Green
        return $rdpFilePath
    } catch {
        Write-Host "Warning: Failed to create RDP file: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}


try {
    $DeveloperId = Read-ValueIfEmpty -Value $DeveloperId -Prompt "Enter developer ID (e.g., 01)"
    if ($DeveloperId -notmatch '^[0-9]{1,6}$') {
        throw "Invalid DeveloperId. Use digits only."
    }
    
    # RDP-only mode: skip SSH key generation and GitHub token
    if ($RDPOnly) {
        Write-Host "Password-only mode: Setting password via PIN code." -ForegroundColor Cyan
        $Pin = Read-ValueIfEmpty -Value $Pin -Prompt "Enter PIN (4-8 digits)"
        if ($Pin -notmatch '^[0-9]{4,8}$') {
            throw "Invalid PIN."
        }
    } else {
        # Full onboarding mode: check for required applications
        Write-Host "Checking for required applications..." -ForegroundColor Cyan
        $opensshHint = "OpenSSH is required for SSH key generation and connections. On Windows 10/11, you can install it via: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
        Test-CommandAvailable -CommandName "ssh-keygen" -InstallationHint $opensshHint | Out-Null
        Test-CommandAvailable -CommandName "ssh" -InstallationHint $opensshHint | Out-Null
        Write-Host "Required applications found." -ForegroundColor Green
        
        # Validate and generate SSH key BEFORE collecting PIN
        # This prevents wasting a single-use PIN if key generation fails
        Write-Host "`nValidating SSH key..." -ForegroundColor Cyan
        $pubKey = Get-SSHPublicKey
        Write-Host "SSH key ready." -ForegroundColor Green
        
        # Only collect PIN after we know we have a valid SSH key
        $Pin = Read-ValueIfEmpty -Value $Pin -Prompt "Enter PIN (4-8 digits)"
        if ($Pin -notmatch '^[0-9]{4,8}$') {
            throw "Invalid PIN."
        }
    }
    
    # Collect password for RDP authentication (with confirmation)
    Write-Host "`nPassword Setup (Required for RDP):" -ForegroundColor Cyan
    Write-Host "You will need this password to connect via RDP (Remote Desktop)." -ForegroundColor Yellow
    Write-Host "Password requirements:" -ForegroundColor Yellow
    Write-Host "  - Minimum 8 characters" -ForegroundColor White
    Write-Host "  - At least one uppercase letter" -ForegroundColor White
    Write-Host "  - At least one lowercase letter" -ForegroundColor White
    Write-Host "  - At least one number" -ForegroundColor White
    
    $password = ""
    $passwordConfirm = ""
    $maxAttempts = 3
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        $password = Read-ValueIfEmpty -Value "" -Prompt "Enter password" -Type "secure"
        if ([string]::IsNullOrWhiteSpace($password)) {
            Write-Host "Password cannot be empty." -ForegroundColor Red
            $attempt++
            continue
        }
        
        # Validate password strength
        if ($password.Length -lt 8) {
            Write-Host "Password must be at least 8 characters long." -ForegroundColor Red
            $attempt++
            continue
        }
        if ($password -notmatch '[A-Z]') {
            Write-Host "Password must contain at least one uppercase letter." -ForegroundColor Red
            $attempt++
            continue
        }
        if ($password -notmatch '[a-z]') {
            Write-Host "Password must contain at least one lowercase letter." -ForegroundColor Red
            $attempt++
            continue
        }
        if ($password -notmatch '[0-9]') {
            Write-Host "Password must contain at least one number." -ForegroundColor Red
            $attempt++
            continue
        }
        
        # Confirm password
        $passwordConfirm = Read-ValueIfEmpty -Value "" -Prompt "Confirm password" -Type "secure"
        if ($password -ne $passwordConfirm) {
            Write-Host "Passwords do not match. Please try again." -ForegroundColor Red
            $attempt++
            continue
        }
        
        break
    }
    
    if ($attempt -ge $maxAttempts) {
        throw "Failed to set password after $maxAttempts attempts. Please run the script again."
    }
    
    # RDP-only mode: call /api/set-password endpoint
    if ($RDPOnly) {
        $body = @{
            developerId = $DeveloperId
            pin         = $Pin
            password    = $password
        }
        $body = $body | ConvertTo-Json

        $url = "http://${Server}:9999/api/set-password"
        Write-Host "Setting password at $url ..." -ForegroundColor Cyan
    } else {
        # Full onboarding mode: optionally collect GitHub token for server-side SSH key setup
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
            password    = $password
        }
        if (-not [string]::IsNullOrWhiteSpace($GitHubToken)) {
            $body.githubToken = $GitHubToken
        }
        $body = $body | ConvertTo-Json

        $url = "http://${Server}:9999/api/claim"
        Write-Host "Claiming access at $url ..." -ForegroundColor Cyan
    }
    
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
        } elseif ($exception.GetType().FullName -eq 'System.Net.Http.HttpRequestException') {
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
        if ($RDPOnly) {
            throw "Password change failed: $($response | ConvertTo-Json -Compress)"
        } else {
            throw "Claim failed: $($response | ConvertTo-Json -Compress)"
        }
    }

    $username = "dev$DeveloperId"
    # Calculate RDP port: 3389 + (DeveloperId * 100)
    $rdpPort = 3389 + ([int]$DeveloperId * 100)
    $rdpAddress = "${Server}:${rdpPort}"
    
    # Create RDP file on desktop
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        if (-not (Test-Path $desktopPath)) {
            $desktopPath = Join-Path ([Environment]::GetFolderPath("UserProfile")) "Desktop"
        }
        if (Test-Path $desktopPath) {
            $rdpFile = New-RDPFile -Server $Server -Port ([int]$rdpPort) -Username $username -DesktopPath $desktopPath
        }
    } catch {
        Write-Host "Warning: Could not create RDP file on desktop: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # RDP-only mode: show simplified success message
    if ($RDPOnly) {
        Write-Host "`nPassword set successfully!" -ForegroundColor Green
        Write-Host "`nRDP Connection Information:" -ForegroundColor Cyan
        Write-Host "  Server: $rdpAddress" -ForegroundColor White
        Write-Host "  Username: $username" -ForegroundColor White
        Write-Host "  Password: [The password you just set]" -ForegroundColor White
        Write-Host "  Use Windows Remote Desktop Connection or mstsc.exe" -ForegroundColor White
        if ($rdpFile) {
            Write-Host "  RDP file created on desktop: ${Server} - ${username}.rdp" -ForegroundColor Green
        }
        Write-Host "`nNote: The Docker container needs time to start up." -ForegroundColor Yellow
        Write-Host "Please wait a few minutes before connecting via RDP." -ForegroundColor Yellow
    } else {
        # Full onboarding mode: show complete success message
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
        Write-Host "Please wait a few minutes before connecting via SSH, RDP, or Cursor." -ForegroundColor Yellow
        Write-Host "`nConnection Methods:" -ForegroundColor Cyan
        Write-Host "  SSH:" -ForegroundColor White
        Write-Host "    Command: ssh $hostAlias" -ForegroundColor Gray
        Write-Host "    Or via Cursor: Select '$hostAlias' when connecting via SSH" -ForegroundColor Gray
        Write-Host "  RDP (Remote Desktop):" -ForegroundColor White
        Write-Host "    Server: $rdpAddress" -ForegroundColor Gray
        Write-Host "    Username: $username" -ForegroundColor Gray
        Write-Host "    Password: [The password you just set]" -ForegroundColor Gray
        Write-Host "    Use Windows Remote Desktop Connection or mstsc.exe" -ForegroundColor Gray
        if ($rdpFile) {
            Write-Host "    RDP file created on desktop: ${Server} - ${username}.rdp" -ForegroundColor Green
        }
    }
} catch {
    $errorMessage = $_.Exception.Message
    if ($_.Exception.InnerException) {
        $errorMessage = "$errorMessage`nInner exception: $($_.Exception.InnerException.Message)"
    }
    Write-Host "`nError: $errorMessage" -ForegroundColor Red
    exit 1
}
