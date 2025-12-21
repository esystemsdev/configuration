# Developer Onboarding (Windows)

This guide helps new Windows developers get access, set up tools, and onboard to AI Fabrix or Workato.

## 1) Get access

- Request a developer account via Service Desk:  
  `https://esystem.atlassian.net/servicedesk/customer/portal/2/group/6/create/17`
  - Choose “Dev – Workato” or “Dev – AI Fabrix” as appropriate.

## 2) Install tools (Windows)

- Cursor editor: `https://cursor.com/download`
- For AI Fabrix developers (optional here, required for local infra):
  - Node.js 18+
  - Docker Desktop

## 3) Onboarding script (Windows PowerShell)

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

### Step 4: Connect after onboarding

Once onboarding is complete, wait a few minutes for the Docker container to start up, then connect:

```powershell
ssh dev<DeveloperId>.aifabrix
```

For example, if your Developer ID is `01`:

```powershell
ssh dev01.aifabrix
```

## 4) Cursor basics

![Cursor SSH Connection](images/cursor-1.png)

To connect to your developer container:

1. **Connect via SSH**: Click "Connect via SSH" in Cursor's welcome screen.
2. **Select your SSH user**: Choose your configured SSH host (e.g., `dev01.aifabrix`) or enter `user@host` format.
3. **Automatic connection**: Cursor will automatically connect you to your developer container.
   - **Note**: SSH connects directly to your Docker container. The container needs time to start up after onboarding. If the connection fails, wait a few minutes and try again.
4. **Clone repo or open existing folder**: Once connected, you can:
   - Clone a repository from your remote host
   - Open an existing folder on the remote host: select your working folder `/workspace/<your repo>`

**First-time setup**: When installing for the first time as a developer:

- Open `/workspace/` root folder
- Clone the following repositories:

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

## 5) Git configuration

Configure your Git identity:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@esystems.fi"
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

## 8) Workato developer basics

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
- Calls the onboarding service on `http://<server>:9999/api/claim` to register your public key using a temporary PIN
- Optionally sets up GitHub SSH key for server-side commits (requires a Personal Access Token)
- Adds an SSH config entry for quick access using `ssh dev<DeveloperId>.<domain>`
- Note: SSH connects directly to your Docker container, which needs time to start up. If the container is not running, SSH will not work.

**Script parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
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
