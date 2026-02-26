# Integration specialist setup

**Persona: Integration specialist** – Use your own AI Fabrix environment and the **aifabrix-builder CLI** to create integrations and learn the platform. Windows and macOS. No full repo set or WSL required.

This guide gets you Cursor, Node, Git, and the Git workspace so you can work with the Builder CLI and integrations.

---

## 1) Install Cursor and Node (Basic group)

Use the same installer as developers, but install only the **Basic** group (Cursor, Node, Git).

**Windows:** Download and run [SetupDeveloperEnv.ps1](SetupDeveloperEnv.ps1) (as Administrator):

```powershell
# Download to C:\Setup (see Setup-developer.md for full download snippet), then:
powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupDeveloperEnv.ps1" -groups "Basic"
```

**macOS:** Clone this repo or download [SetupDeveloperEnv.sh](SetupDeveloperEnv.sh) and [SetupDeveloperEnv.yaml](SetupDeveloperEnv.yaml), then:

```bash
chmod +x SetupDeveloperEnv.sh
./SetupDeveloperEnv.sh --groups "Basic"
```

This installs Cursor, Node.js, and Git via Homebrew on Mac (or the Windows installers on Windows).

---

## 2) Set up Git workspace (local /workspace or C:\workspace)

Use [SetupGitEnv.ps1](SetupGitEnv.ps1) (Windows) or [SetupGitEnv.sh](SetupGitEnv.sh) (macOS) to create your workspace, clone repos, and install `@aifabrix/builder`.

**Windows:** Use `C:\workspace` as the root. Either edit the script (`$gitFolder = "C:\workspace"`) or run from a copy. From the folder containing the script:

```powershell
# If you cloned configuration to C:\workspace\esystemsdev\configuration, set git root to C:\workspace:
$env:GitFolder = "C:\workspace"   # optional; script uses in-script $gitFolder by default
.\SetupGitEnv.ps1
```

To use `C:\workspace`, edit the top of `SetupGitEnv.ps1`: set `$gitFolder = "C:\workspace"`. Then run it (no Administrator required).

**macOS:** Use `$HOME/workspace` or `/workspace`:

```bash
GIT_FOLDER=$HOME/workspace ./SetupGitEnv.sh
# or, if you use /workspace: GIT_FOLDER=/workspace ./SetupGitEnv.sh
```

Default repos are `configuration,aifabrix-training`; the script also installs `@aifabrix/builder`. See [docs/SetupGitEnv.md](docs/SetupGitEnv.md).

---

## 3) Open Cursor in your folder

Open Cursor and use **File → Open Folder** to open your workspace (e.g. `C:\workspace` or `~/workspace`). No WSL required for the integration path.

---

## 4) Remote development onboarding (when needed)

When you need access to the Builder Server and sync:

```bash
aifabrix dev init --developer-id <id> --server https://builder01.local --pin <pin>
```

Get developer ID and one-time PIN from your admin. Omit arguments to be prompted. Config is written to `~/.aifabrix/config.yaml`. Use `aifabrix dev refresh` to refresh.

---

## 5) Set AI Fabrix developer environment up

After SetupGitEnv you have `@aifabrix/builder` installed. Use the CLI to create integrations and work with the platform:

```bash
aifabrix --help
```

See the Builder docs: [aifabrix-builder](https://github.com/esystemsdev/aifabrix-builder).

---

## 6) SSH (optional) – how to open Cursor

If you use SSH to a dev container:

1. In Cursor, click **Connect via SSH** on the welcome screen.
2. Enter your SSH host (e.g. `user@dev01.local`).
3. Once connected, open folder `/workspace` or `/workspace/<repo>`.

---

## Summary

| Step | Windows | macOS |
|------|---------|--------|
| 1. Install Cursor + Node | `SetupDeveloperEnv.ps1` with `-groups "Basic"` | `SetupDeveloperEnv.sh --groups "Basic"` |
| 2. Git workspace | `SetupGitEnv.ps1` with `$gitFolder = "C:\workspace"` | `GIT_FOLDER=$HOME/workspace ./SetupGitEnv.sh` |
| 3. Open Cursor | Open folder `C:\workspace` | Open folder `~/workspace` |
| 4. Remote onboarding | `aifabrix dev init` when needed | Same |
| 5. AI Fabrix env | Use `aifabrix` CLI | Same |
| 6. SSH | Connect via SSH in Cursor, open `/workspace` | Same |

For the full developer path (all repos, WSL on Windows), see [Setup-developer.md](Setup-developer.md).
