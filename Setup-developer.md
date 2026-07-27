# Full developer setup (all repos)

**Persona: Developer** – Full stack, all repos, WSL (Windows) or native macOS, Builder Server sync, platform/infra.

This guide gets you from zero to a full AI Fabrix development environment with all repositories, Cursor, and remote development.

**Onboarding stages:** **Stage 1** is this public **configuration** repo (inspectable scripts and YAML). **Stage 2** is optional company-internal setup in **dev-config-internal** (private); it extends stage 1 and does not replace these steps. Missing private access does not block the public bootstrap.

**Important: You need eSystems Twingate activated before you can use any services.**

---

## 1) Get access

- Request a developer account via Service Desk.

---

## Windows (full developer path)

### 2) Install Windows tools (basic + developer groups)

**Step 1: Download setup scripts to `C:\Setup`**

Bootstrap files are fetched from a **pinned release ref** (not `main`) so runs are reproducible. Set `$configurationVersion` to the current release (see [README.md](README.md#bootstrap-release-pinning)). For the latest unpublished scripts, clone this repo instead of using raw URLs.

```powershell
New-Item -ItemType Directory -Force -Path "C:\Setup" | Out-Null
$configurationVersion = "1.1.0"
$baseUrl = "https://raw.githubusercontent.com/esystemsdev/configuration/$configurationVersion/"
$files = @(
    "SetupDeveloperEnv.ps1", "SetupDeveloperEnv.yaml", "SetupWslUbuntuDev.ps1",
    "SetupGitEnv.ps1", "SetupGitEnv.yaml"
)
foreach ($file in $files) {
    Invoke-WebRequest -Uri "$baseUrl$file" -OutFile "C:\Setup\$file"
}
```

**Step 2: Run the developer environment script (as Administrator)**

Open PowerShell **as Administrator**, then run with **Basic**, **Development**, and **Local Dev** groups (see [docs/SetupDeveloperEnv.md](docs/SetupDeveloperEnv.md)):

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupDeveloperEnv.ps1" -groups "Basic,Development,Local Dev"
```

Omit `-groups` to be prompted for which groups to install. Use `Basic` alone for the [integration path](Setup-integration.md) (includes **Docker CLI** in YAML). Full developer setup needs **`Local Dev`** as well (**Docker Desktop**, VS Code, GitHub CLI, Python, and related tools; `enableWsl2` on Windows) and optionally `Database`. **Docker CLI** and **Docker Desktop** are separate applications in `SetupDeveloperEnv.yaml`.

**Step 3: Install the WSL dev image (as Administrator)**

The WSL image **already has `/workspace` configured**; no extra steps needed. Run from **`C:\Setup`** as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupWslUbuntuDev.ps1" -TarPath "https://builder01.local/wsl-image"
```

Or with a local .tar file:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupWslUbuntuDev.ps1" -TarPath "C:\Setup\wsl-ubuntu-dev.tar"
```

Details: [WSL Ubuntu dev setup](docs/SetupWslUbuntuDev.md).

**Step 4: Open Cursor from WSL**

1. Start WSL (default distro **aifabrix-dev**; username `aifabrix`, password `admin123`): `wsl`
2. In Cursor, press **Ctrl+Shift+P** (Command Palette).
3. Run **WSL: Connect to WSL Using Distro...** and select **aifabrix-dev**.
4. When connected, open the folder **`/workspace/`** (File → Open Folder). The image has `/workspace` ready.

**Step 5: GitHub CLI login**

In the WSL terminal, run `gh auth login`. When prompted:

| Prompt | Choice |
|--------|--------|
| Where do you use GitHub? | GitHub.com |
| Preferred protocol for Git operations? | SSH |
| Generate a new SSH key to add to your GitHub account? | Yes |
| Passphrase for your new SSH key | (optional – press Enter to skip) |
| Title for your SSH key | GitHub CLI |
| How would you like to authenticate GitHub CLI? | Login with a web browser |

Set your Git identity:

```bash
git config --global user.name "Your Name"
git config --global user.email firstname.lastname@esystems.fi
```

**Step 6: Get repos into `/workspace`**

Stage 1 clones the **public** trio from [SetupGitEnv.yaml](SetupGitEnv.yaml): **dev-config**, **dataplane-integrations**, and **training**. Same list as the [integration path](Setup-integration.md).

Run [SetupGitEnv.ps1](SetupGitEnv.ps1) (Windows host) or [SetupGitEnv.sh](SetupGitEnv.sh) (WSL / macOS / Linux) with the default config next to the script (or from `C:\Setup` after the download step). Override with `SETUPGITENV_CONFIG` / `-ConfigPath` only if you keep a custom YAML. Set `$gitFolder` / `GIT_FOLDER` if needed (default `/workspace` / `C:\workspace`). Details: [docs/SetupGitEnv.md](docs/SetupGitEnv.md).

```powershell
# From Windows after download to C:\Setup (clones under C:\workspace by default):
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupGitEnv.ps1"
```

```bash
# From WSL (default root /workspace):
./SetupGitEnv.sh
# Or: SETUPGITENV_CONFIG=/mnt/c/Setup/SetupGitEnv.yaml ./SetupGitEnv.sh
```

**Stage 2 (optional):** Internal repos come from **dev-config-internal** after you have access—follow that repo’s README. This public tree does not ship a private overlay or merge loader.

**Step 7: Remote development onboarding**

When you need access to the Builder Server and Mutagen sync:

```bash
aifabrix dev init --developer-id <id> --server https://builder01.local --add-hosts --host-ip 192.168.1.30 --pin <pin>
```

Use the developer ID and one-time PIN from your admin. Omit arguments to be prompted. Config is written to `~/.aifabrix/config.yaml`. Use `aifabrix dev refresh` to refresh settings.

**Step 8: Set AI Fabrix developer environment up**

Install the Builder CLI if not already installed (e.g. by SetupGitEnv):

```bash
npm install -g @aifabrix/builder
```

Start local infrastructure and platform (after `aifabrix dev init` when needed):

```bash
aifabrix up-infra --pgAdmin --traefik
aifabrix up-platform
```

See [AI Fabrix developer basics](#ai-fabrix-developer-basics) below.

**Step 9: SSH (optional) – how to open Cursor**

For lightweight terminal-only work (e.g. Workato SDK):

1. In Cursor, click **Connect via SSH** on the welcome screen.
2. Choose your SSH host (e.g. `dev01.builder01.local`) or enter `user@host`.
3. Once connected, open folder `/workspace` or `/workspace/<repo>`.

---

## macOS (full developer path)

### 2) Install macOS tools (basic + developer groups)

**Step 1: Get the setup script and YAML**

Clone this repo (or download [SetupDeveloperEnv.sh](SetupDeveloperEnv.sh) and [SetupDeveloperEnv.yaml](SetupDeveloperEnv.yaml)):

```bash
mkdir -p ~/workspace
cd ~/workspace
git clone https://github.com/esystemsdev/configuration.git
cd configuration
# Optional: match the same release as Windows raw downloads (see README.md — Bootstrap release pinning)
git checkout 1.1.0
```

**Step 2: Run the developer environment script**

Install **Basic**, **Development**, and **Local Dev** groups (same tools as Windows, via Homebrew):

```bash
chmod +x SetupDeveloperEnv.sh
./SetupDeveloperEnv.sh --groups "Basic,Development,Local Dev"
```

This creates `~/workspace` (or use `WORKSPACE_DIR=/workspace` if you create that path). The script reads [SetupDeveloperEnv.yaml](SetupDeveloperEnv.yaml) and installs apps using Homebrew.

**Step 3: Open Cursor**

Open Cursor and open the folder **`~/workspace`** (or your workspace path). No WSL on macOS.

**Step 4: GitHub CLI and Git identity**

Run `gh auth login` in Terminal, then:

```bash
git config --global user.name "Your Name"
git config --global user.email firstname.lastname@esystems.fi
```

**Step 5: Get all repos**

Use [SetupGitEnv.sh](SetupGitEnv.sh) with the default [SetupGitEnv.yaml](SetupGitEnv.yaml) (public trio; see [Step 6](#step-6-get-repos-into-workspace)). Default clone root is `/workspace`. **On a local Mac** where you use `~/workspace` from SetupDeveloperEnv, prefix with `GIT_FOLDER=$HOME/workspace`:

```bash
chmod +x SetupGitEnv.sh
GIT_FOLDER=$HOME/workspace ./SetupGitEnv.sh
```

**Step 6: Remote development onboarding**

```bash
aifabrix dev init --developer-id <id> --server https://builder01.local --pin <pin>
```

**Step 7: Set AI Fabrix developer environment up**

Same as Windows: `npm install -g @aifabrix/builder`, then `aifabrix up-infra` and `aifabrix up-platform` when needed.

**Step 8: SSH (optional)**

Same as Windows: Connect via SSH in Cursor and open `/workspace` or `/workspace/<repo>`.

---

## Architecture: what and where

- **Workspace root:** `/workspace` (WSL image or your Mac workspace folder).
- **Per-developer config:** `~/.aifabrix/config.yaml` (after `aifabrix dev init`).
- **Builder Server:** e.g. `https://builder01.local` – provides dev settings, certificates, sync parameters.
- **CLI:** `aifabrix` (from `@aifabrix/builder`) for infra, platform, and dev isolation.

For diagrams and flows, see the **builder-cli** repo: [flows-and-visuals.md](https://github.com/aifabrix/builder-cli/blob/main/.cursor/rules/flows-and-visuals.md).

---

## AI Fabrix developer basics

### Builder CLI

```bash
npm install -g @aifabrix/builder
```

(Already installed if you ran SetupDeveloperEnv or SetupGitEnv.)

### Start and test the platform

After `aifabrix dev init` when you need the platform:

1. **Start local infrastructure:** `aifabrix up-infra`
2. **Start the platform:** `aifabrix up-platform` (or `aifabrix up-miso` then `aifabrix up-dataplane`)

### Developer workspace

Workspace root: `/workspace`. Key config (in container): `aifabrix-home: '/workspace/.aifabrix'`, and Builder secrets under your **miso-controller** clone, e.g. `.../builder/secrets.local.yaml`. Use `aifabrix` CLI for local infra and app workflows.

---

## Security notes

- Do not paste or commit PINs or secrets. Prefer interactive prompts.
- PINs are single-use and time-limited. Request a new PIN if claim fails.
- Never share private keys; public keys only are used during onboarding.

---

## Reference: Remote development onboarding

**What `aifabrix dev init` does:** Issues or reuses a client certificate (mTLS), fetches sync and Docker parameters from the Builder Server, and registers your SSH keys for Mutagen.

**Options:** `--developer-id <id>`, `--server <url>`, `--pin <pin>`. Omit to be prompted. Refresh: `aifabrix dev refresh` or `aifabrix dev refresh --cert`.

**Troubleshooting:** Ensure Twingate is connected; verify ID and PIN with admin; run `aifabrix dev refresh --cert` for certificate or sync issues. For SSH, wait for the container to start after first-time setup.
