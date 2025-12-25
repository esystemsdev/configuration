# Developer Onboarding

This guide helps new developers get access, set up tools, and onboard to AI Fabrix or Workato.

**⚠️ Important: You need eSystems Twingate activated before you can use any services!**

**Platform-specific guides:**

- [Windows](#windows-developer-onboarding) - Full support for RDP and SSH
- [macOS](#macos-developer-onboarding) - RDP only (recommended for Mac users)

## 1) Get access

- Request a developer account via Service Desk:  
  `https://esystem.atlassian.net/servicedesk/customer/portal/2/group/6/create/17`
  - Choose "Dev – Workato" or "Dev – AI Fabrix" as appropriate.

---

## Windows Developer Onboarding

**Note**: When using RDP, you do not need to install Cursor on your local Windows machine. Cursor is pre-installed in the RDP session and available after connecting.

### 2) Onboarding script (Windows PowerShell)

**Starting point**: Begin here to set up your developer account.

### Step 1: Download the script

```powershell
New-Item -ItemType Directory -Force -Path "C:\Setup" | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/esystemsdev/configuration/main/OnboardDeveloper.ps1" -OutFile "C:\Setup\OnboardDeveloper.ps1"
```

### Step 2: Run the onboarding script

Use the developer ID that was delivered to you:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\OnboardDeveloper.ps1" -Server dev.aifabrix -DeveloperId <DeveloperId>
```

Replace `<DeveloperId>` with your actual developer ID (e.g., `01`, `02`, etc.).

### Step 3: Register GitHub token

1. Create a GitHub Personal Access Token (if you don't have one)
2. When prompted by the script, paste your GitHub token
3. The script will automatically set up GitHub SSH key for server-side commits

### Step 4: Connect after onboarding (Windows)

Once onboarding is complete, wait a few minutes for the Docker container to start up. You have two connection options:

#### Option 1: RDP (Recommended - Full Development Power)

See [RDP Connection Guide](#4-rdp-connection-guide) for detailed instructions.

**Quick start:**

- Open Remote Desktop Connection
- Enter server address: `dev.aifabrix:<port>` where port = `3389 + (DeveloperId * 100)`
  - Example: `dev01` uses port `3489` (3389 + 100)
  - Example: `dev02` uses port `3589` (3389 + 200)
  - Example: `dev03` uses port `3689` (3389 + 300)
- Log in with username `dev<DeveloperId>` (e.g., `dev01`) - **no password needed** (passwordless authentication enabled)

#### Option 2: SSH (Lightweight - Terminal Only)

SSH provides terminal-only access, suitable for lightweight development tasks such as Workato SDK development or quick terminal operations.

**Install tools for SSH (Windows):**

- Cursor editor: `https://cursor.com/download` (required for SSH via Cursor)
- For AI Fabrix developers (optional here, required for local infra):
  - Node.js 18+
  - Docker Desktop

**Connect via SSH:**

```powershell
ssh dev<DeveloperId>.aifabrix
```

For example, if your Developer ID is `01`:

```powershell
ssh dev01.aifabrix
```

**Note**: SSH connects directly to your Docker container. The container needs time to start up after onboarding. If the connection fails, wait a few minutes and try again.

---

## macOS Developer Onboarding

**Important**: macOS developers can only use RDP connection. SSH via Cursor is not supported on Mac.

**Note**: When using RDP, you do not need to install Cursor on your local Mac. Cursor is pre-installed in the RDP session and available after connecting.

### 2) Install tools (macOS)

- Microsoft Remote Desktop: Install from [Mac App Store](https://apps.apple.com/app/microsoft-remote-desktop/id1295203466)

### 3) Onboarding (macOS)

You need to run the onboarding script once to create your developer account and Docker container. You have two options:

#### Option A: Use PowerShell Core (Recommended)

1. **Install PowerShell Core**:

   ```bash
   brew install --cask powershell
   ```

2. **Download and run the onboarding script**:

   ```bash
   mkdir -p ~/Setup
   curl -o ~/Setup/OnboardDeveloper.ps1 https://raw.githubusercontent.com/esystemsdev/configuration/main/OnboardDeveloper.ps1
   pwsh ~/Setup/OnboardDeveloper.ps1 -Server dev.aifabrix -DeveloperId <DeveloperId>
   ```

   Replace `<DeveloperId>` with your actual developer ID (e.g., `01`, `02`, etc.).

3. **Register GitHub token** (optional):
   - When prompted, paste your GitHub Personal Access Token
   - The script will automatically set up GitHub SSH key for server-side commits

#### Option B: Manual onboarding with curl

If you prefer not to use PowerShell, you can manually call the API:

1. **Generate SSH key** (if you don't have one):

   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```

2. **Get your public key**:

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

3. **Call the onboarding API**:

   ```bash
   curl -X POST http://dev.aifabrix:9999/api/claim \
     -H "Content-Type: application/json" \
     -d '{
       "developerId": "<DeveloperId>",
       "pin": "<YourPIN>",
       "publicKey": "your-public-key-here"
     }'
   ```

   Replace `<DeveloperId>` and `<YourPIN>` with your actual values, and `your-public-key-here` with the output from step 2.

### Step 4: Connect via RDP (macOS)

**Note**: RDP is the only supported connection method for macOS developers.

See [RDP Connection Guide](#4-rdp-connection-guide) for detailed instructions.

**Quick start:**

1. **Open Microsoft Remote Desktop** (installed in Step 2)
2. **Add a new PC**:
   - Click "Add PC" or the "+" button
   - Enter PC name: `dev.aifabrix:3389`
   - Click "Add"
3. **Connect**:
   - Double-click the new connection
   - Log in with username `dev<DeveloperId>` (e.g., `dev01`) - **no password needed** (passwordless authentication enabled)
   - You'll see the Xfce desktop environment

**Note**: The onboarding script creates your account and enables passwordless RDP authentication. After onboarding, you only need Microsoft Remote Desktop to connect - no other software is required on your Mac.

---

## 4) RDP Connection Guide

**Applies to**: Windows and macOS developers using RDP.

### Connecting to RDP

Each developer has a unique RDP port calculated as: **3389 + (DeveloperId × 100)**

**Port Examples:**

- `dev01` → Port `3489` (3389 + 100)
- `dev02` → Port `3589` (3389 + 200)
- `dev03` → Port `3689` (3389 + 300)
- `dev10` → Port `4389` (3389 + 1000)

**Windows:**

- Open Remote Desktop Connection
- Enter server address: `dev.aifabrix:<your-port>` (use your calculated port from above)
- Log in with username `dev<DeveloperId>` (e.g., `dev01`) - **no password needed** (passwordless authentication enabled)

**macOS:**

- Open Microsoft Remote Desktop
- Add new PC: `dev.aifabrix:<your-port>` (use your calculated port from above)
- Log in with username `dev<DeveloperId>` - **no password needed** (passwordless authentication enabled)

### Using Development Tools

Once connected via RDP, you'll see the Xfce desktop environment:

1. **Bottom menu bar (dock)**: Access development tools directly from the bottom menu bar:

   - **Cursor** - Code editor (pre-installed)
   - **Postman** - API testing tool (pre-installed)
   - **Web browser** - For testing web applications

2. **Understanding your environment:**
   - **RDP session**: Runs on the host OS (Linux server)
   - **Terminal**: When you open a terminal, you're automatically dropped into your Docker container
   - **Files**: `/home/dev01` on host = `/workspace` in container (same files, automatically synced)

3. **Launch Cursor**:
   - Click **Cursor** icon in the bottom menu bar
   - Open workspace: `/home/dev<DeveloperId>` (e.g., `/home/dev01`)
   - All development tools are available via terminal in Cursor

4. **Using development tools:**
   - When you open a terminal in Cursor, you're already in your container
   - All tools are pre-installed: `node`, `pnpm`, `aifabrix`, `git`, etc.
   - No need to run `docker exec` - you're already there!

### Keyring Password Setup

**Note**: This setup is only required when using RDP.

On first use, you'll be prompted to set a keyring password. This is a one-time setup:

1. **First Launch**: When Chrome, Cursor, or other apps try to save passwords, you'll see "Unlock Keyring" dialog
2. **Set Password**: Enter a password (can be same as your login password for convenience)
3. **Confirm**: Click "Unlock"
4. **Future Sessions**: You'll only need to unlock once per session

**Security Note**: The keyring encrypts stored passwords. Setting a password is recommended for security.

### First-time setup

When installing for the first time as a developer:

- Open `/workspace/` root folder (or `/home/dev<DeveloperId>` on the host)
- Clone repositories: See [Git configuration](#6-git-configuration) section below for repository cloning instructions

---

## 5) SSH Connection Guide (Windows Only)

**Applies to**: Windows developers only. macOS developers should use RDP.

### SSH + Cursor (Lightweight - Terminal Only)

**Best for**: Lightweight development tasks such as Workato SDK development or quick terminal operations.

**Install tools for SSH (Windows):**

- Cursor editor: `https://cursor.com/download` (required for SSH via Cursor)
- For AI Fabrix developers (optional here, required for local infra):
  - Node.js 18+
  - Docker Desktop

![Cursor SSH Connection](images/cursor-1.png)

1. **Connect via SSH**: Click "Connect via SSH" in Cursor's welcome screen.
2. **Select your SSH user**: Choose your configured SSH host (e.g., `dev01.aifabrix`) or enter `user@host` format.
3. **Automatic connection**: Cursor will automatically connect you to your developer container.
   - **Note**: SSH connects directly to your Docker container. The container needs time to start up after onboarding. If the connection fails, wait a few minutes and try again.
4. **Clone repo or open existing folder**: Once connected, you can:
   - Clone a repository from your remote host
   - Open an existing folder on the remote host: select your working folder `/workspace/<your repo>`

### SSH: First-time setup

When installing for the first time as a developer:

- Open `/workspace/` root folder
- Clone repositories: See [Git configuration](#6-git-configuration) section below for repository cloning instructions

---

## 6) Git configuration

Configure your Git identity:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@esystems.fi"
```

### Clone repositories

When installing for the first time as a developer, clone the following repositories:

```bash
git clone git@github.com:esystemsdev/aifabrix-miso.git
git clone git@github.com:esystemsdev/aifabrix-miso-azure.git
git clone git@github.com:esystemsdev/aifabrix-miso-backend.git
git clone git@github.com:esystemsdev/aifabrix-miso-client.git
git clone git@github.com:esystemsdev/aifabrix-miso-client-python.git
git clone git@github.com:esystemsdev/aifabrix-dataplane.git
git clone git@github.com:esystemsdev/aifabrix-d360.git
git clone git@github.com:esystemsdev/aifabrix-core.git
git clone git@github.com:esystemsdev/aifabrix-form-engine.git
git clone git@github.com:esystemsdev/aifabrix-builder.git
git clone git@github.com:esystemsdev/aifabrix-docs.git
git clone git@github.com:esystemsdev/openwebui-template.git
git clone git@github.com:esystemsdev/flowise-template.git
```

## 7) AI Fabrix developer basics

### Step 1: Install Builder CLI

```bash
npm install -g @aifabrix/builder
```

### Step 2: Quick start (minimal)

1. **Put infra up:**

```bash
aifabrix up
```

1. **Open miso-controller project:**

Navigate to the miso-controller project directory.

1. **Build Keycloak Docker image:**

```bash
aifabrix build keycloak
```

1. **Run Keycloak locally:**

```bash
aifabrix run keycloak
```

1. **Build Docker image:**

```bash
aifabrix build miso-controller
```

1. **Run in local Docker:**

```bash
aifabrix run miso-controller
```

1. **Validate via web-browser:**

Open your web browser and verify the services are running.

**Happy coding!**

See the Builder docs and CLI reference:  
`https://github.com/esystemsdev/aifabrix-builder`

## 8) AI Fabrix Developer Workspace

This is your workspace root inside the container: `/workspace`.

Key locations and settings:

- Per-developer config: `/home/dev{id}/.aifabrix/config.yaml`
- Default config values:

```yaml
environment: 'dev'
developer-id: '{id}'
secrets-encryption: '<key from Key Vault>'
aifabrix-home: '/workspace/.aifabrix'
aifabrix-secrets: '/workspace/aifabrix-miso/builder/secrets.local.yaml'
```

Notes:

- Use `aifabrix` CLI for local infrastructure and app workflows.
- Docker access is via `aifabrix-docker` inside this container.
- Editors available: `vim`, `nano`.

## 9) Workato developer basics

Follow the internal guide for org access, environments, and tooling:  
`https://esystem.atlassian.net/wiki/spaces/EWKT/pages/209879302147/Custom+Connector+SDK`

## 10) Security notes

- Do not paste or commit PINs or secrets. Prefer interactive prompts.
- PINs are single‑use and time‑limited. If a claim fails, request a new PIN.
- Never share private keys. Public keys only are used during onboarding.

## 11) Reference information

### Onboarding script details

**What the script does:**

- Automatically generates SSH keys (ed25519) if they don't exist
- Calls the onboarding service on `http://<server>:9999/api/claim` to register your public key using a temporary PIN
- Optionally sets up GitHub SSH key for server-side commits (requires a Personal Access Token)
- Adds an SSH config entry for quick access using `ssh dev<DeveloperId>.<domain>`
- Note: SSH connects directly to your Docker container, which needs time to start up. If the container is not running, SSH will not work.

**Script parameters:**

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `-Server` | string | No | `"dev.aifabrix"` | The development server hostname |
| `-DeveloperId` | string | Yes* | - | Your developer ID (1-6 digits). Will be prompted if not provided |
| `-Pin` | string | Yes* | - | Your PIN (4-8 digits). Will be prompted if not provided |
| `-GitHubToken` | string | No | - | GitHub Personal Access Token for server-side SSH key setup. Will be prompted if not provided |

*Required but can be provided interactively if not specified as parameters.

**Onboarding process:**

1. The script prompts for your Developer ID and PIN if not provided as parameters
2. Checks for existing SSH keys in `~/.ssh/` and generates new ed25519 keys if needed
3. Sends your public SSH key to the onboarding API endpoint to claim access
4. Creates an SSH config entry for easy access using `ssh dev<DeveloperId>.<domain>`
5. Optionally, if a GitHub token is provided, the server will generate an SSH key and add it to your GitHub account

**Troubleshooting:**

- **Twingate connectivity**: Validate that your Twingate is up and running and can ping `dev.aifabrix`. If Twingate is not connected or cannot reach the server, SSH connections will fail.
- **Container startup**: SSH connects directly to your Docker container. The container needs time to start up. If the container is not running, SSH connections will fail. Wait a few minutes after onboarding and try again.
- **Connection fails immediately after onboarding**: Wait a few minutes for the Docker container to start up. The container needs time to initialize after onboarding.
- **Invalid Developer ID or PIN error**: Verify your Developer ID and PIN are correct. Ensure the PIN hasn't expired (request a new one if needed). Check that you're using the correct server address.
- **SSH connection refused**: Ensure the onboarding service is reachable from your network on port `9999`. Verify the server address is correct. Check that the container has finished starting up.
- **If the SSH test fails**, run once to trust the host key.
