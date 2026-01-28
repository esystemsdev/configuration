# Developer Onboarding

This guide helps new developers get access, set up tools, and onboard to AI Fabrix or Workato.

**⚠️ Important: You need eSystems Twingate activated before you can use any services!**

**Platform-specific guides:**

- [Windows](#windows-developer-onboarding) - SSH onboarding
- [macOS](#macos-developer-onboarding) - SSH onboarding

## 1) Get access

- Request a developer account via Service Desk:  
  `https://esystem.atlassian.net/servicedesk/customer/portal/2/group/6/create/17`
  - Choose "Dev – Workato" or "Dev – AI Fabrix" as appropriate.

---

## Windows Developer Onboarding

### 2) Onboarding (Windows)

**What you need:**

- Developer ID and PIN (provided by admin)
- Cursor editor: `https://cursor.com/download` (required for SSH via Cursor)
- For AI Fabrix developers (optional here, required for local infra):
  - Node.js 18+
  - Docker Desktop

**Step 1: Download the script**

```powershell
New-Item -ItemType Directory -Force -Path "C:\Setup" | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/esystemsdev/configuration/main/OnboardDeveloper.ps1" -OutFile "C:\Setup\OnboardDeveloper.ps1"
```

**Step 2: Run the onboarding script**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\OnboardDeveloper.ps1" -Server dev.aifabrix -DeveloperId <DeveloperId>
```

Replace `<DeveloperId>` with your actual developer ID (e.g., `01`, `02`, etc.).

**Step 3: Register GitHub token (optional)**

1. Create a GitHub Personal Access Token (if you don't have one)
2. When prompted by the script, paste your GitHub token
3. The script will automatically set up GitHub SSH key for server-side commits

**What happens:**

- Script generates SSH keys (ed25519) if they don't exist
- Prompts you to set a password for your server account (with confirmation)
- Registers your SSH public key
- Optionally sets up GitHub SSH key (if you provide a GitHub token)
- Creates SSH config entry for easy access

**Step 4: Connect via SSH**

Once onboarding is complete, wait a few minutes for the Docker container to start up, then:

1. **Connect via SSH**: Click "Connect via SSH" in Cursor's welcome screen
2. **Select your SSH user**: Choose your configured SSH host (e.g., `dev01.aifabrix`) or enter `user@host` format
3. **Automatic connection**: Cursor will automatically connect you to your developer container
   - **Note**: SSH connects directly to your Docker container. The container needs time to start up after onboarding. If the connection fails, wait a few minutes and try again.

See [SSH Connection Guide](#4-ssh-connection-guide) for detailed instructions.

---

## macOS Developer Onboarding

### 2) Onboarding (macOS)

**What you need:**

- Developer ID and PIN (provided by admin)
- Cursor editor: `https://cursor.com/download` (required for SSH via Cursor)
- PowerShell Core (to run the onboarding script)

**Step 1: Install PowerShell Core**

```bash
brew install --cask powershell
```

**Step 2: Download and run the onboarding script**

```bash
mkdir -p ~/Setup
curl -o ~/Setup/OnboardDeveloper.ps1 https://raw.githubusercontent.com/esystemsdev/configuration/main/OnboardDeveloper.ps1
pwsh ~/Setup/OnboardDeveloper.ps1 -Server dev.aifabrix -DeveloperId <DeveloperId>
```

Replace `<DeveloperId>` with your actual developer ID (e.g., `01`, `02`, etc.).

**What happens:**

- Script generates SSH keys (ed25519) if they don't exist
- Prompts you to set a password for your server account (with confirmation)
- Registers your SSH public key
- Optionally sets up GitHub SSH key (if you provide a GitHub token)
- Creates SSH config entry for easy access

**Step 3: Connect via SSH**

Once onboarding is complete, wait a few minutes for the Docker container to start up, then use Cursor to connect via SSH (e.g., `dev01.aifabrix`) or run:

```bash
ssh dev<DeveloperId>.aifabrix
```

See [SSH Connection Guide](#4-ssh-connection-guide) for detailed instructions.

---

## 4) SSH Connection Guide

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
- Clone repositories: See [Git configuration](#5-git-configuration) section below for repository cloning instructions

---

## 5) Git configuration

Configure your Git identity:

```bash
git config --global user.name
git config --global user.email
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

## 6) AI Fabrix developer basics

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

## 7) AI Fabrix Developer Workspace

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

## 9) Security notes

- Do not paste or commit PINs or secrets. Prefer interactive prompts.
- PINs are single‑use and time‑limited. If a claim fails, request a new PIN.
- Never share private keys. Public keys only are used during onboarding.

## 10) Reference information

### Onboarding script details

**What the script does:**

- Automatically generates SSH keys (ed25519) if they don't exist
- Prompts you to set a password for your server account (with confirmation)
- Calls the onboarding service on `http://<server>:9999/api/claim` to register your public key and set your password using a temporary PIN
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
2. Prompts you to set a password for your server account (with confirmation)
3. Checks for existing SSH keys in `~/.ssh/` and generates new ed25519 keys if needed
4. Sends your public SSH key and password to the onboarding API endpoint (`/api/claim`) to claim access
5. Creates an SSH config entry for easy access using `ssh dev<DeveloperId>.<domain>`
6. Optionally, if a GitHub token is provided, the server will generate an SSH key and add it to your GitHub account

**Troubleshooting:**

- **Twingate connectivity**: Validate that your Twingate is up and running and can ping `dev.aifabrix`. If Twingate is not connected or cannot reach the server, SSH connections will fail.
- **Container startup**: SSH connects directly to your Docker container. The container needs time to start up. If the container is not running, SSH connections will fail. Wait a few minutes after onboarding and try again.
- **Connection fails immediately after onboarding**: Wait a few minutes for the Docker container to start up. The container needs time to initialize after onboarding.
- **Invalid Developer ID or PIN error**: Verify your Developer ID and PIN are correct. Ensure the PIN hasn't expired (request a new one if needed). Check that you're using the correct server address.
- **SSH connection refused**: Ensure the onboarding service is reachable from your network on port `9999`. Verify the server address is correct. Check that the container has finished starting up.
- **If the SSH test fails**, run once to trust the host key.
