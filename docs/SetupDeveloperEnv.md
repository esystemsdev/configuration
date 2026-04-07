# SetupDeveloperEnv.ps1 / SetupDeveloperEnv.sh

These scripts automate the installation of essential tools for development. They read **the same** `SetupDeveloperEnv.yaml` (in the same directory as the script). **SetupDeveloperEnv.ps1** is for Windows (PowerShell); **SetupDeveloperEnv.sh** is for macOS (Homebrew, using `homebrewCask` and `homebrewFormula` in the YAML).

**Windows without a prior clone:** scripts are normally downloaded with `Invoke-WebRequest` from `raw.githubusercontent.com` using a **pinned release ref** (see [README.md](../README.md#bootstrap-release-pinning)), not `main`. For unreleased script changes, clone the configuration repo and run the files locally.

**Groups:**

- **Basic** – Integration path: Cursor, Node.js, Git, and Docker **CLI + Compose v2 plugin only** (no Docker Desktop). Use `-groups "Basic"` for [Setup-integration.md](../Setup-integration.md).
- **Development** and **Local Dev** – Full developer path. **Local Dev** includes the **Docker Desktop** application entry in YAML (separate from **Docker CLI** under **Basic**). Selecting both groups installs both unless you change the YAML. Use `-groups "Basic,Development,Local Dev"` or `"Development,Local Dev"` for [Setup-developer.md](../Setup-developer.md).
- **Database**, **Development OutSystems** – Optional.

**Features (Windows PS1):**

- Installs tools by group; **Basic** = integration path, **Development** + **Local Dev** = developer path.
- Verifies if tools are already installed (via `commandCheck` or `programCheck`) and skips reinstallation when not needed.
- Lets you choose which groups to install (interactive prompts) or use the `-groups` parameter. If you select only **Basic**, the Development group is not auto-added.
- Sets environment variables for configured applications so their paths are on the user `PATH`.
- Installs or updates VS Code and VS Code extensions from the YAML when VS Code is in the selected groups.
- **Windows zip installs:** Any application can set `windowsArchiveUrl`, `windowsArchiveMainBinary`, `windowsArchiveInstallRelativePath` (under `%LOCALAPPDATA%`), and optional `windowsExtraFiles` (download `url` → path under `%USERPROFILE%`). No app-specific branching by name.
- **`enableWsl2`:** If `true` on an application installed via `url` (exe/msi), the script may enable WSL 2 after install (used by **Docker Desktop** in YAML).
- Installs the `powershell-yaml` module automatically if not already installed.

**Features (macOS SH):** Reads the same YAML and installs each selected application’s `homebrewCask` / `homebrewFormula` entries in file order (e.g. **Docker CLI** uses formulas; **Docker Desktop** uses the `docker` cask). Windows-only YAML keys are ignored. Creates a workspace directory (default `~/workspace`). See [Setup-developer.md](../Setup-developer.md) and [Setup-integration.md](../Setup-integration.md).

**Prerequisites:**

- Windows with PowerShell.
- Run PowerShell **as Administrator** (required for installing software and system changes).
- If the script cannot run, set execution policy (e.g. `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`).

**Usage:**

```powershell
# Run the script with administrator rights
.\SetupDeveloperEnv.ps1

# Basic only (integration path – Cursor, Node, Git, Docker)
.\SetupDeveloperEnv.ps1 -groups "Basic"

# Full developer path
.\SetupDeveloperEnv.ps1 -groups "Basic,Development,Local Dev"

# Install all applications from the YAML configuration
.\SetupDeveloperEnv.ps1 -groups "all"
```

**macOS:** From the repo directory, run `./SetupDeveloperEnv.sh --groups "Basic"` or `./SetupDeveloperEnv.sh --groups "Basic,Development,Local Dev"`.

**Installation process:**

1. The script prompts for group selection, or uses the `-groups` parameter if provided. Use `"all"` to install every application in the YAML.
2. For each application in the selected groups, it checks whether it is already installed (using `commandCheck` or `programCheck`). If already installed, it skips the installer but still updates environment variables if configured.
3. Missing applications are installed from `url` (exe/msi, silent args from YAML) or from `windowsArchiveUrl` (zip: extract `windowsArchiveMainBinary` into `%LOCALAPPDATA%\<windowsArchiveInstallRelativePath>`, then optional `windowsExtraFiles`).
4. If an installed exe/msi application has `enableWsl2: true`, WSL 2 may be enabled (reboot).
5. If VS Code is selected (or already installed), the script installs or updates all extensions listed in `vscodeExtensions` in the YAML.

## Configuration: `SetupDeveloperEnv.yaml`

This file must be in the same directory as `SetupDeveloperEnv.ps1`. It defines which applications to install, their download URLs, silent install arguments, and how the script detects an existing install. It also lists VS Code extensions that are installed or updated when VS Code is in the selected groups.

**Features:**

- **Customizable:** Edit the file to add or remove tools, change URLs, or adjust install arguments.
- **Installer types:** `.exe` / `.msi` via `url`, or **zip bundle** via `windowsArchiveUrl` + `windowsArchiveMainBinary` + `windowsArchiveInstallRelativePath`. Optional `windowsExtraFiles` (list of `url` + `destRelativeToUserProfile`). Optional `enableWsl2` after exe/msi install.
- **Groups:** Applications are grouped (Basic, Development, Local Dev, …). **Docker CLI** and **Docker Desktop** are separate YAML entries (different groups).
- **macOS:** The same YAML is used by `SetupDeveloperEnv.sh`; use `homebrewCask` (for `brew install --cask`) and `homebrewFormula` (string or list, for `brew install`) per application.
- **Detection:** `commandCheck` (e.g. `git`) and `programCheck` (path(s) under Program Files or LocalAppData) determine if an app is already installed; the script skips install but still updates `PATH` when `environmentVariable: true`.
- **Optional install:** Set `install: false` for an application to exclude it from installation even when its group is selected.
- **VS Code:** The `vscodeExtensions` list is used to install or update extensions whenever VS Code is in the selected groups.

**Sample configuration:**

```yaml
applications:
  - name: Docker CLI
    group: Basic
    windowsArchiveUrl: "https://download.docker.com/win/static/stable/x86_64/docker-29.3.1.zip"
    windowsArchiveMainBinary: docker.exe
    windowsArchiveInstallRelativePath: "Programs\\DockerCLI"
    windowsExtraFiles:
      - url: "https://github.com/docker/compose/releases/download/v5.1.1/docker-compose-windows-x86_64.exe"
        destRelativeToUserProfile: ".docker/cli-plugins/docker-compose.exe"
    programCheck: "Programs\\DockerCLI\\docker.exe"
    environmentVariable: true
    homebrewFormula:
      - docker
      - docker-compose

  - name: Docker Desktop
    group: "Local Dev"
    url: "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
    silentArguments: "install --quiet"
    programCheck: "Docker\\Docker\\DockerCli.exe"
    enableWsl2: true
    homebrewCask: docker

  - name: Git
    group: "Development"
    url: "https://github.com/git-for-windows/git/releases/download/v2.51.0.windows.1/Git-2.51.0-64-bit.exe"
    silentArguments: "/SILENT"
    programCheck: "Git\\cmd\\git.exe"
    commandCheck: git
    environmentVariable: true

  - name: JDK
    group: "Local Dev"
    url: "https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.msi"
    installer: "java.msi"
    programCheck: "Java\\jdk-21\\bin\\java.exe"
    environmentVariable: true

  - name: Microsoft SQL Server Management Studio
    group: "Database"
    url: "https://aka.ms/ssmsfullsetup"
    programCheck: "Microsoft SQL Server Management Studio 18\\Common7\\IDE\\Ssms.exe,Microsoft SQL Server Management Studio 20\\Common7\\IDE\\Ssms.exe"
    installer: "SSMS-Setup-ENU.exe"
  # Additional applications...

vscodeExtensions:
  - davidanson.vscode-markdownlint
  - dbaeumer.vscode-eslint
  - eamodio.gitlens
  - esbenp.prettier-vscode
  - github.copilot
  - ms-azuretools.vscode-docker
  - ms-python.python
  # Additional extensions...
```

## Next steps by persona

- **Full developer (all repos, WSL on Windows or native Mac):** See [Setup-developer.md](../Setup-developer.md).
- **Integration specialist (Cursor + Node + Git + Docker CLI, aifabrix-builder CLI):** See [Setup-integration.md](../Setup-integration.md).

After installing tools, use [SetupGitEnv.ps1](SetupGitEnv.md) (Windows) or [SetupGitEnv.sh](SetupGitEnv.md) (macOS) to clone repositories and install global npm packages. Run with your user account (no administrator rights required).

## How to use this repository

### Step 1: Get the repository and run the setup script

1. Clone or download this repository to your machine (e.g. to `C:\workspace\esystemsdev\configuration`).
2. Open PowerShell **as Administrator**, navigate to the repository directory, and run:
   ```powershell
   .\SetupDeveloperEnv.ps1
   ```
3. When prompted, select the application groups you want to install, or run with `-groups "..."` or `-groups "all"` to skip prompts (see **Usage** above).
4. **`SetupDeveloperEnv.yaml` must sit next to `SetupDeveloperEnv.ps1`.** The script does not download the manifest from Git or the network; it only reads that file beside itself. Install behavior is driven by YAML (`url` / `windowsArchiveUrl` / `enableWsl2`, etc.).

### Step 2: Clone repositories and install global packages

1. In a normal (non-admin) PowerShell window, run [SetupGitEnv.ps1](SetupGitEnv.md) from this repository.
2. It will create the Git folder structure, clone or update the configured repositories, and install global npm packages.

### Step 3: Onboard to development servers (optional)

1. For remote development access, run one-time setup with the aifabrix CLI:  
   `aifabrix dev init --developer-id <id> --server <Builder Server URL> --pin <PIN>` (get the PIN from your admin).
2. Or, if your environment uses it, run the `OnboardDeveloper.ps1` script and provide your Developer ID and PIN when prompted or as parameters.
3. Use `aifabrix dev refresh` later to update settings or renew your certificate.

### Step 4: Start developing

Your environment is ready. Use the scripts in this repository to manage tools and repositories as needed.

## Project-specific configuration

This repository provides general configuration for eSystems Nordic Ltd. Individual projects (e.g. aifabrix) may have their own similar configuration repositories tailored to that project.

## About eSystems Nordic Ltd

eSystems Nordic Ltd is a leading provider of software solutions, specializing in creating innovative and scalable software products. This repository is part of our ongoing efforts to streamline development processes and ensure consistency across all our projects.

For more information or support, please contact the repository maintainers.