# Developer Onboarding

This guide helps new developers get access, set up tools, and onboard to AI Fabrix.

**⚠️ Important: You need eSystems Twingate activated before you can use any services!**

**Platform-specific guides:**

- [Windows](#windows-developer-onboarding) – Full setup or minimal WSL; then remote dev via `aifabrix dev init`
- [macOS](#macos-developer-onboarding) – Git/env setup; then remote dev via `aifabrix dev init`

## 1) Get access

- Request a developer account via Service Desk:  
  `https://esystem.atlassian.net/servicedesk/customer/portal/2/group/6/create/17`
  - Choose "Dev – Workato" or "Dev – AI Fabrix" as appropriate.

---

## Windows Developer Onboarding

### 2) Onboarding (Windows)

Choose one of two paths: **full developer setup** (all tools on Windows) or **minimal WSL setup** (Linux dev environment via WSL). After your machine is set up, use **remote development onboarding** (`aifabrix dev init`) when you need access to Builder Server and sync.

**What you need (before starting):**

- Twingate activated (required for any eSystems services)
- Developer account requested via Service Desk (see [Get access](#1-get-access))

---

#### Option A: Full developer computer setup (Windows)

Best if you want all tools installed on Windows (Cursor, Git, Node, Docker, VS Code, etc.).

**Step 1: Download setup scripts to `C:\Setup`**

```powershell
New-Item -ItemType Directory -Force -Path "C:\Setup" | Out-Null
$baseUrl = "https://raw.githubusercontent.com/esystemsdev/configuration/main/"
$files = @("SetupDeveloperEnv.ps1", "SetupDeveloperEnv.yaml", "SetupGitEnv.ps1", "SetupWslUbuntuDev.ps1")
foreach ($file in $files) {
    Invoke-WebRequest -Uri "$baseUrl$file" -OutFile "C:\Setup\$file"
}
```

**Step 2: Run the full environment script (as Administrator)**

Open PowerShell **as Administrator**, then:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupDeveloperEnv.ps1"
```

Answer the prompts during installation. This installs Cursor, Git, GitHub CLI, Node.js, Twingate, Docker, VS Code, Python, and other tools (see [README – Installed Applications](https://github.com/esystemsdev/configuration#installed-applications)).

**Step 3: Run the Git/workspace script (as your user)**

Open PowerShell as your **normal user** (not Administrator):

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupGitEnv.ps1"
```

This creates `C:\git\esystemsdev`, clones configured repos, and installs global npm packages (e.g. `@aifabrix/builder`).

**Step 4: GitHub CLI (optional)**

In PowerShell: `gh auth login` to sign in for cloning, PRs, etc.

**Step 5: Remote development onboarding (when needed)**

When you need access to the Builder Server and Mutagen sync, run the one-time onboarding:

```powershell
aifabrix dev init --developer-id <id> --server https://builder01.aifabrix.dev --pin <pin>
```

Use the developer ID and one-time PIN from your admin. Omit arguments to be prompted interactively. See [README – Developer onboarding (remote development)](https://github.com/esystemsdev/configuration#1-developer-onboarding-remote-development).

---

#### Option B: WSL Ubuntu dev (Windows)

Same repos and tooling as Option A – only the runtime is Linux (WSL) instead of native Windows. You use the same `C:\git\esystemsdev` workspace; WSL mounts it as `/workspace` inside the distro.

**Prerequisites:** WSL installed (`wsl --install --no-distribution` if needed).

**Step 1: Same scripts and Git/workspace as Option A**

Download the same setup files to `C:\Setup\` (same block as Option A):

```powershell
New-Item -ItemType Directory -Force -Path "C:\Setup" | Out-Null
$baseUrl = "https://raw.githubusercontent.com/esystemsdev/configuration/main/"
$files = @("SetupDeveloperEnv.ps1", "SetupDeveloperEnv.yaml", "SetupGitEnv.ps1", "SetupWslUbuntuDev.ps1")
foreach ($file in $files) {
    Invoke-WebRequest -Uri "$baseUrl$file" -OutFile "C:\Setup\$file"
}
```

Run the **Git/workspace script** as your normal user (so you have the same repos and npm packages as full Windows):

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupGitEnv.ps1"
```

This creates `C:\git\esystemsdev`, clones the same repos, and installs global npm packages (e.g. `@aifabrix/builder`).

**Step 2: Install the WSL dev image (as Administrator)**

From `C:\Setup\`, run PowerShell **as Administrator**:

```powershell
cd C:\Setup
powershell -ExecutionPolicy Bypass -File ".\SetupWslUbuntuDev.ps1" -WindowsReposPath "C:\git\esystemsdev" -TarPath "C:\git\esystemsdev\configuration\wsl-ubuntu-dev.tar"
```

- **-WindowsReposPath** – Same path as Option A (`C:\git\esystemsdev`); WSL exposes it as `/workspace`.
- **-TarPath** – Path to the pre-built image (e.g. from cloned repo as above).

Full details: [WSL Ubuntu dev setup](docs/SetupWslUbuntuDev.md).

**Step 3: Use the WSL image**

Start WSL (default distro **aifabrix-dev**; username `aifabrix`, password `admin123`):

```powershell
wsl
```

Inside WSL, run the on-start script to set `/workspace` (and optionally Git identity):

```bash
sudo /usr/local/share/aifabrix-wsl/wsl-on-start.sh --workspace /mnt/c/git/esystemsdev
```

With Git identity:

```bash
sudo /usr/local/share/aifabrix-wsl/wsl-on-start.sh --workspace /mnt/c/git/esystemsdev --git-name "Your Name" --git-email "you@example.com"
```

Use **aifabrix-dev** in Cursor via **File → Open Folder in WSL**. Your repos are under `/workspace` – the same content as `C:\git\esystemsdev`.

**Step 4: Remote development onboarding (when needed)**

Same as Option A: run `aifabrix dev init` (from WSL or Windows) with your developer ID, Builder Server URL, and PIN.

---

#### After onboarding (both options)

- **Full setup (Option A):** Use Cursor, VS Code, or terminal from Windows; repos under `C:\git\esystemsdev`.
- **WSL (Option B):** Same repos and tooling; use Cursor **File → Open Folder in WSL** and work in the Linux environment; repos under `/workspace` (same as `C:\git\esystemsdev`).
- **Remote dev:** After `aifabrix dev init`, config is in `~/.aifabrix/config.yaml`. Use `aifabrix dev refresh` to refresh settings or renew the certificate. Then use [Goal 1: Start and test the AI Fabrix platform](#goal-1-start-and-test-the-ai-fabrix-platform) to run the platform locally.

See [SSH Connection Guide](#4-ssh-connection-guide) for SSH-based remote workflows and [5) Git configuration](#5-git-configuration) for clone and identity setup.

---

## macOS Developer Onboarding

### 2) Onboarding (macOS)

**What you need:** Cursor, Git, Node.js (e.g. via Homebrew). See [README – Initial Developer Computer Setup - macOS](https://github.com/esystemsdev/configuration#initial-developer-computer-setup---macos) for the full app list and install commands.

**Step 1: Clone this repo and run Git/env setup**

```bash
mkdir -p ~/git/esystemsdev
cd ~/git/esystemsdev
git clone https://github.com/esystemsdev/configuration.git
cd configuration
chmod +x SetupGitEnv.sh
./SetupGitEnv.sh
```

This creates `~/git/esystemsdev`, clones configured repos, and installs global npm packages (e.g. `@aifabrix/builder`).

**Step 2: Remote development onboarding (when needed)**

One-time onboarding with Builder Server URL and PIN (from your admin):

```bash
aifabrix dev init --developer-id <id> --server https://builder01.aifabrix.dev --pin <pin>
# Or interactive: aifabrix dev init
```

Config is written to `~/.aifabrix/config.yaml`. Use `aifabrix dev refresh` to refresh settings or renew the certificate.

**Step 3: Optional – GitHub CLI**

Run `gh auth login` in Terminal for CLI operations (clone, PRs).

See [SSH Connection Guide](#4-ssh-connection-guide) for SSH-based remote workflows and [5) Git configuration](#5-git-configuration) for clone and identity setup.

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

### Install Builder CLI

```bash
npm install -g @aifabrix/builder
```

(Already installed if you ran `SetupGitEnv.ps1` or `SetupGitEnv.sh`.)

### Goal 1: Start and test the AI Fabrix platform

Get the platform running locally so you can try it. Do this after `aifabrix dev init` when you need the platform.

1. **Start local infrastructure** (Postgres, Redis, optional Traefik):

   ```bash
   aifabrix up-infra
   ```

2. **Start the platform** (Keycloak, Miso Controller, Dataplane) from community images:

   ```bash
   aifabrix up-platform
   ```

   Or run platform apps separately: `aifabrix up-miso` then `aifabrix up-dataplane`. Infra must be up first.

### Building and running specific services (optional)

- **Open miso-controller project:** Navigate to the miso-controller project directory.
- **Build Keycloak Docker image:** `aifabrix build keycloak`
- **Run Keycloak locally:** `aifabrix run keycloak`
- **Build Docker image:** `aifabrix build miso-controller`
- **Run in local Docker:** `aifabrix run miso-controller`
- **Validate:** Open your web browser and verify the services are running.

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

### Remote development onboarding (`aifabrix dev init`)

**What it does:**

- Issues or reuses a client certificate (mTLS for dev APIs)
- GET `/api/dev/settings` (cert-authenticated) to receive sync and Docker parameters
- Registers your SSH keys so Mutagen can sync without a password prompt

**Options:**

| Option | Description |
| --- | --- |
| `--developer-id <id>` | Developer ID (e.g. `01`) |
| `--server <url>` | Builder Server base URL (e.g. `https://builder01.aifabrix.dev`) |
| `--pin <pin>` | One-time PIN from your admin |

Omit arguments to be prompted interactively. After onboarding, config is in `~/.aifabrix/config.yaml`. Use `aifabrix dev refresh` (or `aifabrix dev refresh --cert` to force certificate refresh). See [aifabrix-builder – Developer Isolation Commands](https://github.com/esystemsdev/aifabrix-builder/blob/main/docs/commands/developer-isolation.md).

**Troubleshooting:**

- **Twingate**: Ensure Twingate is connected and can reach the Builder Server. Required for eSystems services.
- **Invalid Developer ID or PIN**: Verify ID and PIN with your admin; request a new PIN if it has expired.
- **Certificate or sync issues**: Run `aifabrix dev refresh --cert` to refresh the client certificate and settings.
- **SSH / container access**: If you use SSH to a dev container, ensure the container has started; wait a few minutes after first-time setup. Run once to trust the host key if prompted.
