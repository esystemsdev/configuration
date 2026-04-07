# Integration specialist setup

**Persona: Integration specialist** – Use your own AI Fabrix environment and the **aifabrix-builder CLI** to create integrations and learn the platform. Windows and macOS. No full repo set or WSL required.

This guide gets you Cursor, Node, Git, **Docker** (via the same installer), and the Git workspace so you can work with the Builder CLI and integrations.

**Onboarding stages:** **Stage 1** is this public **configuration** repo. **Stage 2** (optional) is **dev-config-internal** for staff-only settings; see its README if you have access.

**Important: You need eSystems Twingate activated before you can use Builder Server sync, shared dev hosts, or other internal services.** Request access via Service Desk if needed (see [DEVELOPER.MD](DEVELOPER.MD)).

---

## 1) Install Cursor and Node (Basic group)

Use the same installer as developers, but install only the **Basic** group (Cursor, Node, Git).

**Windows:** Create `C:\Setup`, download the scripts from this repo, then run as Administrator:

```powershell
New-Item -ItemType Directory -Force -Path "C:\Setup" | Out-Null
$configurationVersion = "1.1.0"
$baseUrl = "https://raw.githubusercontent.com/esystemsdev/configuration/$configurationVersion/"
foreach ($file in @(
    "SetupDeveloperEnv.ps1", "SetupDeveloperEnv.yaml",
    "SetupGitEnv.ps1", "SetupGitEnv.workspace.public.yaml", "SetupGitEnv_workspace_load.py"
)) {
    Invoke-WebRequest -Uri "$baseUrl$file" -OutFile "C:\Setup\$file"
}
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupDeveloperEnv.ps1" -groups "Basic"
```

These files are loaded from release **`1.1.0`**; for the latest development work, clone [configuration](https://github.com/esystemsdev/configuration) instead of raw download.

(If you already use the full developer download from [Setup-developer.md](Setup-developer.md), you can reuse those files; you do not need the WSL script for this path.)

**macOS:** Install [Homebrew](https://brew.sh) if you do not have it. Clone this repo or download [SetupDeveloperEnv.sh](SetupDeveloperEnv.sh) and [SetupDeveloperEnv.yaml](SetupDeveloperEnv.yaml) into the same folder, then:

```bash
chmod +x SetupDeveloperEnv.sh
./SetupDeveloperEnv.sh --groups "Basic"
```

This installs Cursor, Node.js, Git, and **Docker CLI** via Homebrew.

---

## 2) Set up Git workspace (local / `C:\workspace` or `/workspace`)

Use [SetupGitEnv.ps1](SetupGitEnv.ps1) (Windows) or [SetupGitEnv.sh](SetupGitEnv.sh) (macOS/Linux) with the **public-only** workspace file so you never depend on a private overlay. **Prerequisite:** Python 3 with PyYAML (`pip install pyyaml` or `python3 -m pip install pyyaml`).

**Windows:** Point the script at [SetupGitEnv.workspace.public.yaml](SetupGitEnv.workspace.public.yaml) (three public repos: **dev-config**, **dataplane-integrations**, **training**—see [Setup-developer.md](Setup-developer.md) for legacy names and [aifabrix-setup migration/repo,map.json](https://github.com/esystemsdev/aifabrix-setup/blob/main/migration/repo,map.json)). Default root is `C:\workspace` unless you set `$env:GIT_FOLDER`.

```powershell
$env:SETUPGITENV_CONFIG = "C:\Setup\SetupGitEnv.workspace.public.yaml"
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupGitEnv.ps1"
```

**macOS/Linux:** Default root is `/workspace`. [SetupDeveloperEnv.sh](SetupDeveloperEnv.sh) still creates `~/workspace` for Cursor on Mac; if you do not use a `/workspace` mount, use `GIT_FOLDER=$HOME/workspace`.

```bash
SETUPGITENV_CONFIG="$PWD/SetupGitEnv.workspace.public.yaml" ./SetupGitEnv.sh
# Local Mac: GIT_FOLDER=$HOME/workspace SETUPGITENV_CONFIG=... ./SetupGitEnv.sh
```

**Where repos land:** `<gitFolder>/aifabrix/<name>` (for example `C:\workspace\aifabrix\training`). Details: [docs/SetupGitEnv.md](docs/SetupGitEnv.md).

---

## 3) Open Cursor in your folder

**Working on your local machine**

Open Cursor and use **File → Open Folder** to open your workspace root (e.g. `C:\workspace` or `/workspace`, or `~/workspace` if you used `GIT_FOLDER=$HOME/workspace`) or the org folder `.../aifabrix` for a single tree of repos. No WSL is required for this path.

For CLI usage, local infra, and platform commands, continue with **section 5** below. For workspace layout, optional global CLI install, and diagrams, see [AI Fabrix developer basics](Setup-developer.md#ai-fabrix-developer-basics) in [Setup-developer.md](Setup-developer.md).

**Working via SSH**

1. In Cursor, choose **Connect via SSH** on the welcome screen (or connect from the command palette).
2. Choose your SSH host (e.g. `dev01.builder01.local`) or enter `user@host`.
3. After connecting, open folder `/workspace` or `/workspace/<repo>`.

In the SSH terminal, run `gh auth login`. When prompted:

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

If you clone by hand instead of SetupGitEnv, use the **public** trio (post-migration **aifabrix** org names; legacy names in [repo,map.json](https://github.com/esystemsdev/aifabrix-setup/blob/main/migration/repo,map.json)):

```bash
git clone git@github.com:aifabrix/dev-config.git
git clone git@github.com:aifabrix/dataplane-integrations.git
git clone git@github.com:aifabrix/training.git
```

The Builder CLI still comes from npm (`@aifabrix/builder`); the old **aifabrix-builder** repo is **builder-cli** after rename. Add internal repos only if you have access and need them.

---

## 4) Remote development onboarding (when needed, on your local computer)

When you need access to the Builder Server and sync:

```bash
aifabrix dev init --developer-id <id> --server https://builder01.local --add-hosts --host-ip 192.168.1.30 --pin <pin>
```

Get developer ID and one-time PIN from your admin. Omit arguments to be prompted. Config is written to `~/.aifabrix/config.yaml`. Use `aifabrix dev refresh` to refresh.

---

## 5) Set AI Fabrix developer environment up (local or SSH)

After SetupGitEnv you have `@aifabrix/builder` installed. Use the CLI to create integrations and work with the platform:

```bash
aifabrix --help
```

Start local infrastructure and platform (after `aifabrix dev init` when your workflow needs Builder Server sync):

```bash
aifabrix up-infra --pgAdmin --traefik
aifabrix up-platform
```

Builder CLI source repo (renaming to **builder-cli**): [aifabrix-builder](https://github.com/esystemsdev/aifabrix-builder) — see [repo,map.json](https://github.com/esystemsdev/aifabrix-setup/blob/main/migration/repo,map.json) for current naming.

---

## Summary

| Step | Windows | macOS / Linux |
|------|---------|----------------|
| 1. Install Cursor + Node + Git + Docker CLI | `SetupDeveloperEnv.ps1` with `-groups "Basic"` | `SetupDeveloperEnv.sh --groups "Basic"` |
| 2. Git workspace | `SETUPGITENV_CONFIG` → `SetupGitEnv.workspace.public.yaml`; run `SetupGitEnv.ps1` | Same with `SETUPGITENV_CONFIG`; optional `GIT_FOLDER=$HOME/workspace` on local Mac |
| 3. Open Cursor | Open `C:\workspace` or `C:\workspace\aifabrix` | Open `/workspace` or `/workspace/aifabrix` (or `~/workspace` if you cloned there) |
| 4. Remote onboarding | `aifabrix dev init` when needed | Same |
| 5. AI Fabrix env | `aifabrix` CLI (`up-infra`, `up-platform`, …) | Same |
| Optional: SSH remote | Connect via SSH in Cursor; clone repos under `/workspace` | Same |

For the full developer path (all repos, WSL on Windows), see [Setup-developer.md](Setup-developer.md).
