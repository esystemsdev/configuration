# SetupDeveloperEnv.ps1

This PowerShell script automates the installation of essential tools and dependencies required for development. It reads configuration data from `SetupDeveloperEnv.yaml` (in the same directory as the script) and installs the necessary software, ensuring that your development environment is fully equipped.

**Features:**

- Installs tools organized by groups: **Development**, **Local Dev**, **Database**, and **Development OutSystems**.
- Verifies if tools are already installed (via `commandCheck` or `programCheck`) and skips reinstallation when not needed.
- Lets you choose which groups to install (interactive prompts) or use the `-groups` parameter for unattended setup.
- Always includes the **Development** group when using interactive selection if you do not choose it.
- Sets environment variables for configured applications (and updates existing installs) so their paths are on the user `PATH`.
- Installs or updates VS Code and installs/updates the list of VS Code extensions defined in the YAML.
- If Docker is installed, ensures WSL 2 is enabled (may prompt for a reboot).
- Installs the `powershell-yaml` module automatically if it is not already installed.

**Prerequisites:**

- Windows with PowerShell.
- Run PowerShell **as Administrator** (required for installing software and system changes).
- If the script cannot run, set execution policy (e.g. `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`).

**Usage:**

```powershell
# Run the script with administrator rights
.\SetupDeveloperEnv.ps1

# Specify groups to install without prompts (comma-separated)
.\SetupDeveloperEnv.ps1 -groups "Development, Local Dev, Database"

# Install all applications from the YAML configuration
.\SetupDeveloperEnv.ps1 -groups "all"
```

**Installation process:**

1. The script prompts for group selection, or uses the `-groups` parameter if provided. Use `"all"` to install every application in the YAML.
2. For each application in the selected groups, it checks whether it is already installed (using `commandCheck` or `programCheck`). If already installed, it skips the installer but still updates environment variables if configured.
3. Missing applications are downloaded (via BITS) and installed with the silent arguments defined in the YAML.
4. If Docker is selected and WSL 2 is not the default, the script enables WSL 2 and may restart the machine; you can run the script again after reboot to continue.
5. If VS Code is selected (or already installed), the script installs or updates all extensions listed in `vscodeExtensions` in the YAML.

## Configuration: `SetupDeveloperEnv.yaml`

This file must be in the same directory as `SetupDeveloperEnv.ps1`. It defines which applications to install, their download URLs, silent install arguments, and how the script detects an existing install. It also lists VS Code extensions that are installed or updated when VS Code is in the selected groups.

**Features:**

- **Customizable:** Edit the file to add or remove tools, change URLs, or adjust install arguments.
- **Installer types:** Supports both `.exe` and `.msi` installers (use the `installer` field to set the downloaded filename when it differs from the default).
- **Groups:** Applications are grouped (e.g. Development, Local Dev, Database, Development OutSystems); the script installs only applications in the selected groups.
- **Detection:** `commandCheck` (e.g. `git`) and `programCheck` (path(s) under Program Files or LocalAppData) determine if an app is already installed; the script skips install but still updates `PATH` when `environmentVariable: true`.
- **Optional install:** Set `install: false` for an application to exclude it from installation even when its group is selected.
- **VS Code:** The `vscodeExtensions` list is used to install or update extensions whenever VS Code is in the selected groups.

**Sample configuration:**

```yaml
applications:
  - name: Docker
    group: "Local Dev"
    url: "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
    silentArguments: "install --quiet"
    programCheck: "Docker\\Docker\\DockerCli.exe"
    commandCheck: docker

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

## Next step: Git and repositories

After installing tools with this script, use [SetupGitEnv.ps1](SetupGitEnv.md) to clone the configured repositories and install global npm packages. Run that script with your user account (no administrator rights required).

## How to use this repository

### Step 1: Get the repository and run the setup script

1. Clone or download this repository to your machine (e.g. to `C:\git\esystemsdev\configuration`).
2. Open PowerShell **as Administrator**, navigate to the repository directory, and run:
   ```powershell
   .\SetupDeveloperEnv.ps1
   ```
3. When prompted, select the application groups you want to install, or run with `-groups "..."` or `-groups "all"` to skip prompts (see **Usage** above).
4. If the script enables WSL 2 for Docker, restart when prompted and run the script again after reboot to finish.

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