# SetupGitEnv.ps1 / SetupGitEnv.sh

These scripts create your Git workspace, configure Git safe directories, clone or update repositories using **per-repo URLs** from YAML, and install global npm packages. Run with your user account. **SetupGitEnv.ps1** is for Windows; **SetupGitEnv.sh** is for macOS/Unix.

## Workspace config

| File | Location | Contents |
|------|------------|----------|
| **Default** | [SetupGitEnv.yaml](../SetupGitEnv.yaml) | Public workspace: **dev-config**, **dataplane-integrations**, **training**, plus `@aifabrix/builder` in `packages`. Includes a `groups.public` list for optional filtering. |

Override the config path with **`SETUPGITENV_CONFIG`** (or `-ConfigPath` on Windows) if you keep a custom YAML elsewhere. For stage 1 (this public repo), the default file next to the script is enough—no separate public/private merge files or Python/Ruby loader scripts are shipped.

**Stage 2 (optional):** Staff with **dev-config-internal** access clone additional internal repos per that repo’s README (not via a private overlay in this public tree).

**Workspace path:** Defaults: `C:\workspace` (Windows) and `/workspace` (Unix). Override with `gitFolder` in YAML or `GIT_FOLDER` / `$env:GIT_FOLDER`. Repos clone to `<gitFolder>/<organization>/<name>` (for example `C:\workspace\aifabrix\training`).

**Groups:** `SETUPGITENV_GROUP=<name>` (or `-Group`) clones only repos listed under `groups.<name>` in the YAML. Example: `SETUPGITENV_GROUP=public` uses the `public` group in [SetupGitEnv.yaml](../SetupGitEnv.yaml).

**Prerequisites:**

- **Windows:** PowerShell module **powershell-yaml** (the script installs it for the current user if missing).
- **macOS/Linux:** **Ruby** (stdlib `yaml`; same pattern as [SetupDeveloperEnv.sh](../SetupDeveloperEnv.sh)).
- Git on `PATH`; Node/npm if you use `packages` in YAML.

**Features:** Directory creation, Windows Users ACL, Git `safe.directory`, `aifabrix-work` in `~/.aifabrix/config.yaml`, user env / shell snippet.

**Usage:**

```powershell
.\SetupGitEnv.ps1
.\SetupGitEnv.ps1 -ConfigPath "D:\cfg\SetupGitEnv.yaml"
$env:SETUPGITENV_GROUP = "public"; .\SetupGitEnv.ps1
```

```bash
./SetupGitEnv.sh
SETUPGITENV_CONFIG="$PWD/SetupGitEnv.yaml" ./SetupGitEnv.sh
SETUPGITENV_GROUP=public ./SetupGitEnv.sh
# Local Mac without /workspace:
GIT_FOLDER=$HOME/workspace ./SetupGitEnv.sh
```

## How this fits into the setup process

1. **Install tools** – [SetupDeveloperEnv.ps1](SetupDeveloperEnv.md) or SetupDeveloperEnv.sh.
2. **Clone repos** – Run this script (default [SetupGitEnv.yaml](../SetupGitEnv.yaml)).
3. **Remote onboarding (optional)** – `aifabrix dev init`.

- **Full developer:** [Setup-developer.md](../Setup-developer.md)
- **Integration:** [Setup-integration.md](../Setup-integration.md)
- **Tool installer:** [SetupDeveloperEnv.md](SetupDeveloperEnv.md)
