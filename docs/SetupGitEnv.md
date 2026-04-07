# SetupGitEnv.ps1 / SetupGitEnv.sh

These scripts create your Git workspace, configure Git safe directories, clone or update repositories using **per-repo URLs** from YAML, and install global npm packages. Run with your user account. **SetupGitEnv.ps1** is for Windows; **SetupGitEnv.sh** is for macOS/Unix.

## Workspace files (public vs private)

| File | Location | Contents |
|------|------------|----------|
| **Public** | [SetupGitEnv.workspace.public.yaml](../SetupGitEnv.workspace.public.yaml) | **dev-config** (legacy *configuration*), **dataplane-integrations**, **training** (legacy *aifabrix-training*). Safe for the integration path and anyone without internal Git access. |
| **Default** | [SetupGitEnv.workspace.yaml](../SetupGitEnv.workspace.yaml) | Merges the public file, then optionally `../dev-config/workspace.private.yaml` (staff-only list from **dev-config-internal**). If the private file is missing, you get a warning and **only public repos** are cloned. |
| **Loader** | [SetupGitEnv_workspace_load.py](../SetupGitEnv_workspace_load.py) | Parses YAML; supports **`extends` as a string or a list** (merged in order). |

Override the config path with **`SETUPGITENV_CONFIG`** (or `-ConfigPath` on Windows). **Integration:** set it to `SetupGitEnv.workspace.public.yaml` so private paths are never required.

**Merge rules:** Each `extends` entry is loaded recursively. Later layers override `repos` by `name`, replace `groups` keys, merge `packages` uniquely, and prefer overlay `organization` / `gitFolder` when set. Partial YAML files used only as `extends` targets do not need `organization` until the final merged result (validated at the top-level load).

**Workspace path:** Defaults: `C:\workspace` (Windows) and `/workspace` (Unix). Override with `gitFolder` in YAML or `GIT_FOLDER` / `$env:GIT_FOLDER`. Repos clone to `<gitFolder>/<organization>/<name>`.

**Groups:** `SETUPGITENV_GROUP=<name>` (or `-Group`) clones only repos listed under `groups.<name>` in the **merged** config. Define groups that reference internal repos in `workspace.private.yaml` so public-only runs do not break.

**Prerequisites:** Python 3 + PyYAML (`pip install pyyaml`). Git on `PATH`; Node/npm if you use `packages` in YAML.

**Features:** Directory creation, Windows Users ACL, Git `safe.directory`, `aifabrix-work` in `~/.aifabrix/config.yaml`, user env / shell snippet (unchanged from earlier behavior).

**Usage:**

```powershell
.\SetupGitEnv.ps1
.\SetupGitEnv.ps1 -ConfigPath "D:\cfg\SetupGitEnv.workspace.public.yaml"
$env:SETUPGITENV_GROUP = "core"; .\SetupGitEnv.ps1
```

```bash
./SetupGitEnv.sh
SETUPGITENV_CONFIG="$PWD/SetupGitEnv.workspace.public.yaml" ./SetupGitEnv.sh
SETUPGITENV_GROUP=core ./SetupGitEnv.sh
```

**Migration:** Old GitHub org/repo names → new names are tracked in **aifabrix-setup** [migration/repo,map.json](https://github.com/esystemsdev/aifabrix-setup/blob/main/migration/repo,map.json) and updated as migration completes.

## How this fits into the setup process

1. **Install tools** – [SetupDeveloperEnv.ps1](SetupDeveloperEnv.md) or SetupDeveloperEnv.sh.
2. **Clone repos** – Run this script with the appropriate workspace YAML (public-only vs default).
3. **Remote onboarding (optional)** – `aifabrix dev init`.

- **Full developer:** [Setup-developer.md](../Setup-developer.md)
- **Integration:** [Setup-integration.md](../Setup-integration.md)
- **Tool installer:** [SetupDeveloperEnv.md](SetupDeveloperEnv.md)
