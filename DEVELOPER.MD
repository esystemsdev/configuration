# Developer Onboarding

This guide helps new developers get access, set up tools, and onboard to AI Fabrix.

**⚠️ Important: You need eSystems Twingate activated before you can use any services!**

**Platform-specific guides:**

- [Windows](#windows-developer-onboarding) – One setup: dev tools + WSL image; then remote dev via `aifabrix dev init`
- [macOS](#macos-developer-onboarding) – One setup: Git/env; then remote dev via `aifabrix dev init`

## 1) Get access

- Request a developer account via Service Desk:  
  `https://esystem.atlassian.net/servicedesk/customer/portal/2/group/6/create/17`
  - Choose "Dev – Workato" or "Dev – AI Fabrix" as appropriate.

---

## Windows Developer Onboarding

### 2) Onboarding (Windows)

One installation path: install developer tools on Windows, then the WSL dev image. When you need access to Builder Server and sync, run **remote development onboarding** (`aifabrix dev init`).

**What you need (before starting):**

- Twingate activated (required for any eSystems services)
- Developer account requested via Service Desk (see [Get access](#1-get-access))

---

#### Developer computer setup (Windows)

Install basic tools on your Windows (Cursor, Node, etc.).

**Step 1: Download setup scripts to `C:\Setup`**

```powershell
New-Item -ItemType Directory -Force -Path "C:\Setup" | Out-Null
$baseUrl = "https://raw.githubusercontent.com/esystemsdev/configuration/main/"
$files = @("SetupDeveloperEnv.ps1", "SetupDeveloperEnv.yaml", "SetupWslUbuntuDev.ps1")
foreach ($file in $files) {
    Invoke-WebRequest -Uri "$baseUrl$file" -OutFile "C:\Setup\$file"
}
```

**Step 2: Run the developer environment script (as Administrator)**

Open PowerShell **as Administrator**, then:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupDeveloperEnv.ps1" -groups "Development"
```

Omit `-groups "Development,Local Dev"` to be prompted for which groups to install. Development group is always included.

**Step 3: Install the WSL dev image (as Administrator)**

Run the setup script with **-TarPath** set to either an **HTTP(S) URL** (script downloads the image) or a **local .tar path**. PowerShell **as Administrator**:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupWslUbuntuDev.ps1" -TarPath "https://builder01.aifabrix.dev/wsl-image"
```

Or with a local file:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupWslUbuntuDev.ps1" -TarPath "C:\Setup\wsl-ubuntu-dev.tar"
```

- **-TarPath** – URL (http/https) or local path to the .tar image; the script downloads when given a URL.

Full details: [WSL Ubuntu dev setup](docs/SetupWslUbuntuDev.md).

**Step 4: Use the WSL image**

Start WSL (default distro **aifabrix-dev**; username `aifabrix`, password `admin123`):

```powershell
wsl
```

**Open Cursor in WSL**

1. In Cursor, press **Ctrl+Shift+P** (Command Palette).
2. Run **WSL: Connect to WSL Using Distro...** and select **aifabrix-dev**.
3. When connected, open the folder **`/workspace/`** (File → Open Folder).
4. In the WSL terminal, run GitHub CLI authentication (see below) so you can clone via SSH.
5. Clone your repos – see [4) Git configuration](#4-git-configuration).

**Step 5: Remote development onboarding (when needed)**

When you need access to the Builder Server and Mutagen sync, run the one-time onboarding:

```powershell
aifabrix dev init --developer-id <id> --server https://builder01.aifabrix.dev --pin <pin>
```

Use the developer ID and one-time PIN from your admin. Omit arguments to be prompted interactively. See [README – Developer onboarding (remote development)](https://github.com/esystemsdev/configuration#1-developer-onboarding-remote-development).

---

## macOS Developer Onboarding

### 2) Onboarding (macOS)

Single installation path: install Cursor, Git, and Node.js (e.g. via Homebrew), then clone this repo and run the Git/env setup script. When you need Builder Server and sync, run `aifabrix dev init`.

**What you need:** Cursor, Git, Node.js. See [README – Initial Developer Computer Setup - macOS](https://github.com/esystemsdev/configuration#initial-developer-computer-setup---macos) for the full app list and install commands.

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

See [SSH Connection Guide](#3-ssh-connection-guide) for SSH-based remote workflows and [4) Git configuration](#4-git-configuration) for clone and identity setup.

---

## 3) SSH Connection Guide

### SSH + Cursor (Lightweight - Terminal Only)

**Best for**: Lightweight development tasks such as Workato SDK development or quick terminal operations.

**Install tools for SSH (Windows):**

- Cursor editor: `https://cursor.com/download` (required for SSH via Cursor)
- For AI Fabrix developers (optional here, required for local infra):
  - Node.js 18+
  - Docker Desktop

1. **Connect via SSH**: Click "Connect via SSH" in Cursor's welcome screen.
2. **Select your SSH user**: Choose your configured SSH host (e.g., `dev01.aifabrix.dev`) or enter `user@host` format.
3. **Automatic connection**: Cursor will automatically connect you to your developer container.
   - **Note**: SSH connects directly to your Docker container. The container needs time to start up after onboarding. If the connection fails, wait a few minutes and try again.
4. **Clone repo or open existing folder**: Once connected, you can:
   - Clone a repository from your remote host
   - Open an existing folder on the remote host: select your working folder `/workspace/<your repo>`

### SSH: First-time setup

When installing for the first time as a developer:

- Open `/workspace/` root folder
- Clone repositories: See [Git configuration](#4-git-configuration) section below for repository cloning instructions

---

## 4) Git configuration

**GitHub CLI authentication**

Run `gh auth login` in the WSL terminal for clone/PR operations. When prompted, use:

| Prompt | Choice |
|--------|--------|
| Where do you use GitHub? | GitHub.com |
| Preferred protocol for Git operations? | SSH |
| Generate a new SSH key to add to your GitHub account? | Yes |
| Passphrase for your new SSH key | (optional – press Enter to skip) |
| Title for your SSH key | GitHub CLI |
| How would you like to authenticate GitHub CLI? | Login with a web browser |

Configure your Git identity:

```bash
git config --global user.name "Your Name"
git config --global user.email firstname.lastname@esystems.fi
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

## 5) AI Fabrix developer basics

### Install Builder CLI

```bash
npm install -g @aifabrix/builder
```

(Already installed if you ran the setup script: `SetupDeveloperEnv.ps1` on Windows or `SetupGitEnv.sh` on macOS.)

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

## 6) AI Fabrix Developer Workspace

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

## 7) Workato developer basics

Follow the internal guide for org access, environments, and tooling:  
`https://esystem.atlassian.net/wiki/spaces/EWKT/pages/209879302147/Custom+Connector+SDK`

## 8) Security notes

- Do not paste or commit PINs or secrets. Prefer interactive prompts.
- PINs are single‑use and time‑limited. If a claim fails, request a new PIN.
- Never share private keys. Public keys only are used during onboarding.

## 9) Reference information

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
