# eSystems Nordic - Configuration Repository

Welcome to the eSystems Nordic configuration repository. This repository contains essential scripts and configuration files necessary for setting up development environments across various projects managed by eSystems Nordic Ltd. It provides a standardized setup process, ensuring that all developers have a consistent environment for building and deploying software.

## Prerequisites

### Initial Developer Computer Setup - Windows

1. **Download the Setup Script to C:\Setup folder**:
   - **Download all files at once** (recommended):

     ```powershell
     New-Item -ItemType Directory -Force -Path "C:\Setup" | Out-Null
     $baseUrl = "https://raw.githubusercontent.com/esystemsdev/configuration/main/"
     $files = @("SetupDeveloperEnv.ps1", "SetupDeveloperEnv.yaml","SetupWslUbuntuDev.ps1")
     foreach ($file in $files) {
         Invoke-WebRequest -Uri "$baseUrl$file" -OutFile "C:\Setup\$file"
     }
     ```

2. **Run the Script**:
   - Run the script with administrator rights. Open PowerShell as an administrator and navigate to the location of the script.
   - Execute the script:

     ```powershell
     powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupDeveloperEnv.ps1"
     ```

   - You will need to answer a few questions during the installation. Note that the installation is not fully silent.
3. **Installed Applications**:
   - The `SetupDeveloperEnv.ps1` script installs applications organized by groups:

   **Development Group:**
   - **Cursor**: AI-powered code editor
   - **Node.js**: JavaScript runtime and package manager
   - **Twingate**: Secure remote access tool
   - **7-Zip**: File archiver
   - **Slack**: Communication platform
   - **Google Chrome**: Web browser
   - **Postman**: API testing tool
   - **PowerShell**: Cross-platform automation and configuration tool

   **Local Dev Group:**
   - **Git**: Version control system
   - **GitHub CLI**: Command-line interface for GitHub
   - **Docker**: Containerization platform
   - **Visual Studio Code (VS Code)**: Code editor with essential extensions (ESLint, GitLens, Prettier, GitHub Copilot, Docker, Python, PowerShell, and more)
   - **Python**: Programming language
   - **Ruby**: Programming language with development kit
   - **JDK (Java Development Kit)**: Development environment for building applications using Java

   **Database Group:**
   - **pgAdmin 4**: PostgreSQL management tool
   - **Microsoft SQL Server Management Studio (SSMS)**: Tool for managing SQL Server

   **Development OutSystems Group:**
   - **Microsoft Visual Studio 2022**: IDE for .NET, C#, and other languages
4. **Run the Script** (optional):
   - Run the script with your own account. Open PowerShell navigate to the location of the script.
   - Execute the script:

     ```powershell
     powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupGitEnv.ps1"
     ```

5. **Authenticate with GitHub CLI** (optional): In PowerShell, run `gh auth login` to sign in to GitHub for CLI operations (e.g. cloning, PRs).

### Minimal installation – aifabrix WSL (Windows)

For a minimal aifabrix development environment on Windows using WSL (no full app installer), see [WSL Ubuntu dev setup](docs/SetupWslUbuntuDev.md). In short:

1. Ensure **WSL** is installed on Windows.
2. Run PowerShell as **Administrator** from `C:\Setup\`:

   ```powershell
   powershell -ExecutionPolicy Bypass -File ".\SetupWslUbuntuDev.ps1" -TarPath "http://builder01.aifabrix.dev/wsl-image"
   ```

3. Using the image
   Start WSL (default distro is **aifabrix-dev** and username aifabrix and password admin123):

   ```powershell
   wsl
   ```

### Initial Developer Computer Setup - macOS

The full app installer (`SetupDeveloperEnv.ps1`) is Windows-only. On macOS, install tools manually (e.g. via [Homebrew](https://brew.sh)), then use the shell script for Git workspace and npm packages.

**Equivalent apps on macOS** (install via [Homebrew](https://brew.sh) where applicable):

| Windows (Development group) | macOS install |
| ---------------------------- | ------------- |
| Cursor | `brew install --cask cursor` |
| Git | Xcode Command Line Tools or `brew install git` |
| GitHub CLI | `brew install gh` |
| Node.js | `brew install node` |
| Twingate | `brew install --cask twingate` or [twingate.com](https://www.twingate.com/download/) |
| 7-Zip | Built-in Archive Utility, or `brew install --cask the-unarchiver` / `brew install p7zip` |
| Slack | `brew install --cask slack` |
| Google Chrome | `brew install --cask google-chrome` |
| Postman | `brew install --cask postman` |
| PowerShell | `brew install --cask powershell` |

| Windows (Local Dev group) | macOS install |
| --------------------------- | ------------- |
| Docker | `brew install --cask docker` |
| VS Code | `brew install --cask visual-studio-code` (extensions: install from VS Code or see `SetupDeveloperEnv.yaml` vscodeExtensions) |
| Python | `brew install python@3.11` |
| Ruby | Built-in or `brew install ruby` |
| JDK | `brew install openjdk@21` or `brew install --cask oracle-jdk` |

1. **Install Git and Node.js** (if not already installed):
   - **Option A:** [Xcode Command Line Tools](https://developer.apple.com/xcode/) for Git, then [Node.js](https://nodejs.org/) or `brew install node`
   - **Option B:** `brew install git node`

2. **Get the setup script** (clone this repo or download the file):

   ```bash
   mkdir -p ~/git/esystemsdev
   cd ~/git/esystemsdev
   git clone https://github.com/esystemsdev/configuration.git
   cd configuration
   ```

3. **Run the Git/env setup script** (creates `~/git/esystemsdev`, clones repos, installs global npm packages such as `@aifabrix/builder`):

   ```bash
   chmod +x SetupGitEnv.sh
   ./SetupGitEnv.sh
   ```

   Optional: override defaults with env vars, e.g. `GIT_FOLDER=$HOME/git ORGANIZATION=esystemsdev REPOSITORIES=configuration,aifabrix-training PACKAGES=@aifabrix/builder ./SetupGitEnv.sh`

4. **Authenticate with GitHub CLI** (optional): In Terminal, run `gh auth login` to sign in to GitHub for CLI operations (e.g. cloning, PRs).

5. **Remote development onboarding** uses the same commands as Windows (see below); `aifabrix dev init` works on macOS.

## Repository Contents

- **SetupGitEnv.ps1** – Windows: creates `C:\git\esystemsdev`, clones repos, installs global npm packages.
- **SetupGitEnv.sh** – macOS/Unix: creates `~/git/esystemsdev`, clones same repos, installs same npm packages; use for Mac onboarding.
- **SetupWslUbuntuDev.ps1** – Windows: minimal aifabrix WSL setup; installs pre-built Ubuntu dev image. See [WSL Ubuntu dev setup](docs/SetupWslUbuntuDev.md).

### 1. Developer onboarding (remote development)

One-time setup for remote development uses the **aifabrix** CLI: it issues a client certificate (mTLS), fetches server settings, and registers your SSH keys so Mutagen sync works without a password. Requires the [aifabrix-builder](https://github.com/esystemsdev/aifabrix-builder) CLI (`npm install -g @aifabrix/builder`) and a Builder Server URL plus a one-time PIN from your admin.

**Usage (aifabrix dev init):**

```bash
# One-time onboarding with Builder Server URL and PIN
aifabrix dev init --developer-id 01 --server https://builder01.aifabrix.dev --pin 123456

# Interactive (will prompt for developer-id, server, pin if omitted)
aifabrix dev init
```

**Options:**

- `--developer-id <id>` – Developer ID (e.g. `01`).
- `--server <url>` – Builder Server base URL (e.g. `https://builder01.aifabrix.dev`).
- `--pin <pin>` – One-time PIN for onboarding (from your admin).

**Process:**

1. Issue or use an existing client certificate (mTLS for dev APIs).
2. GET `/api/dev/settings` (cert-authenticated) to receive sync and Docker parameters.
3. POST SSH keys so Mutagen can sync without a password prompt.

**After onboarding:**

- Config is written to `~/.aifabrix/config.yaml` (e.g. `remote-server`, `docker-endpoint`, `sync-ssh-host`, `sync-ssh-user`).
- To refresh settings or renew the certificate: `aifabrix dev refresh` (use `aifabrix dev refresh --cert` to force certificate refresh).
- See [Developer Isolation Commands](https://github.com/esystemsdev/aifabrix-builder/blob/2.41.0/docs/commands/developer-isolation.md) for `dev refresh`, `dev config`, `dev down`, and related commands.

**macOS validation:** The onboarding flow is validated for macOS: use [Initial Developer Computer Setup - macOS](#initial-developer-computer-setup---macos) (Git, Node, `SetupGitEnv.sh`), then run `aifabrix dev init` as above. The same `~/.aifabrix/config.yaml` and CLI commands apply on Windows and macOS.

## About eSystems Nordic Ltd

eSystems Nordic Ltd is a leading provider of software solutions, specializing in creating innovative and scalable software products. This repository is part of our ongoing efforts to streamline development processes and ensure consistency across all our projects.

For more information or support, please contact the repository maintainers.
