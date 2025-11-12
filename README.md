# eSystems Nordic - Configuration Repository

Welcome to the eSystems Nordic configuration repository. This repository contains essential scripts and configuration files necessary for setting up development environments across various projects managed by eSystems Nordic Ltd. It provides a standardized setup process, ensuring that all developers have a consistent environment for building and deploying software.

## Prerequisites

### Initial Developer Computer Setup

1. **Download the Setup Script to C:\Setup folder**:
   - Download the [SetupDeveloperEnv.ps1](https://github.com/esystemsdev/configuration/blob/main/SetupDeveloperEnv.ps1) script from GitHub.
   - Download the [SetupDeveloperEnv.yaml](https://github.com/esystemsdev/configuration/blob/main/SetupDeveloperEnv.yaml) script from GitHub.
   - Download the [SetupGitEnv.ps1](https://github.com/esystemsdev/configuration/blob/main/SetupGitEnv.ps1) script from GitHub.
   - Download the [OnboardDeveloper.ps1](https://github.com/esystemsdev/configuration/blob/main/OnboardDeveloper.ps1) script from GitHub.
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
   - **Git**: Version control system
   - **GitHub CLI**: Command-line interface for GitHub
   - **Visual Studio Code (VS Code)**: Code editor with essential extensions (ESLint, GitLens, Prettier, GitHub Copilot, Docker, Python, PowerShell, and more)
   - **Node.js**: JavaScript runtime and package manager
   - **Python**: Programming language
   - **Twingate**: Secure remote access tool
   - **JDK (Java Development Kit)**: Development environment for building applications using Java
   - **7-Zip**: File archiver
   - **Slack**: Communication platform
   - **Google Chrome**: Web browser
   - **Postman**: API testing tool
   - **PowerShell**: Cross-platform automation and configuration tool

   **Development AI Group:**
   - **Docker**: Containerization platform
   - **Cursor**: AI-powered code editor

   **Database Group:**
   - **pgAdmin 4**: PostgreSQL management tool
   - **Microsoft SQL Server Management Studio (SSMS)**: Tool for managing SQL Server

   **Development OutSystems Group:**
   - **Microsoft Visual Studio 2022**: IDE for .NET, C#, and other languages

   **Development Workato Group:**
   - **Ruby**: Programming language with development kit
4. **Run the Script**:
   - Run the script with your own account. Open PowerShell navigate to the location of the script.
   - Execute the script:

     ```powershell
     powershell -ExecutionPolicy Bypass -File "C:\Setup\SetupGitEnv.ps1"
     ```

## Repository Contents

### 1. `SetupDeveloperEnv.ps1`

This PowerShell script automates the installation of essential tools and dependencies required for development. It reads configuration data from `SetupDeveloperEnv.yaml` and installs the necessary software, ensuring that your development environment is fully equipped.

**Features:**

- Installs tools organized by groups: Development, Development AI, Database, Development OutSystems, and Development Workato.
- Verifies if tools are already installed and skips reinstallation if unnecessary.
- Allows the user to choose which groups of applications to install, with a default installation of the "Development" group.
- Supports an optional `-groups` parameter to automate the selection process, allowing for a faster setup without user prompts.
- Automatically sets environment variables for installed applications if needed.
- Installs VS Code with essential extensions for development.
- Configures your environment according to company standards.

**Usage:**

```powershell
# Run the script with administrator rights
.\SetupDeveloperEnv.ps1

# Optionally, specify the groups to install without prompts
.\SetupDeveloperEnv.ps1 -groups "Development, Development AI, Database"

.\SetupDeveloperEnv.ps1 -groups "Development Workato"
```

**Installation Process:**

- The script will either prompt you to select which groups of applications you wish to install or automatically install based on the `-groups` parameter.
- The "Development" group, containing essential development tools, will always be installed by default if no groups are specified.
- If the `-groups` parameter is set to `"all"`, all applications in the YAML configuration will be installed.
- The script installs the necessary software and ensures that the appropriate environment variables are set, updating the system `PATH` if needed.

### 2. `SetupDeveloperEnv.yaml`

This YAML file contains the configuration data used by `SetupDeveloperEnv.ps1`. It lists all the software that needs to be installed, along with their respective download URLs, installation arguments, and checks to ensure they are installed correctly. It also defines VS Code extensions that will be automatically installed with VS Code.

**Features:**

- Customizable: You can modify this file to adjust which tools are installed or to change installation parameters.
- Supports both `.exe` and `.msi` installers.
- Organized by application groups: Development, Development AI, Database, Development OutSystems, and Development Workato.
- Includes options to set environment variables automatically after installation.
- Defines VS Code extensions to be installed automatically with VS Code.
- Allows for targeted installation based on development needs.

**Sample Configuration:**

```yaml
applications:
  - name: Docker
    group: "Development AI"
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
    group: "Development"
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

### 3. `SetupGitEnv.ps1`

This script is designed to help developers quickly clone all necessary repositories and install global npm packages. It supports multiple repositories, making it easy to set up the development environment for different projects.

**Features:**

- Clones repositories from GitHub based on configuration.
- Installs global npm packages required for development.
- Ensures that all repositories are up-to-date with the latest changes.

**Usage:**

```powershell
# Run the script with your user account
C:\git\esystemsdev\configuration\SetupGitEnv.ps1
```

### 4. `OnboardDeveloper.ps1`

This script automates the onboarding process for developers by setting up SSH access to development servers. It generates SSH keys, claims access through an API endpoint, and configures SSH settings for seamless connectivity.

**Features:**

- Automatically generates SSH keys (ed25519) if they don't exist.
- Claims developer access via API endpoint with developer ID and PIN.
- Configures SSH config entries for easy server access.
- Tests SSH connectivity to verify successful onboarding.

**Usage:**

```powershell
# Run the script with your user account
.\OnboardDeveloper.ps1

# Or specify parameters directly
.\OnboardDeveloper.ps1 -DeveloperId "01" -Pin "123456"

# Optionally specify a different server
.\OnboardDeveloper.ps1 -Server "dev.aifabrix" -DeveloperId "01" -Pin "123456"
```

**Parameters:**

- `-Server` (optional): The development server hostname. Defaults to `"dev.aifabrix"`.
- `-DeveloperId` (optional): Your developer ID (1-6 digits). Will be prompted if not provided.
- `-Pin` (optional): Your PIN (4-8 digits). Will be prompted if not provided.

**Process:**

1. The script will prompt for your Developer ID and PIN if not provided as parameters.
2. It checks for existing SSH keys in `~/.ssh/` and generates new ed25519 keys if needed.
3. Your public SSH key is sent to the onboarding API endpoint to claim access.
4. An SSH config entry is created for easy access using `ssh dev<DeveloperId>`.
5. The script tests SSH connectivity to verify the setup was successful.

**After Onboarding:**

Once onboarding is complete, you can connect to the development server using:
```powershell
ssh dev<DeveloperId>
```

For example, if your Developer ID is `01`, you would use:
```powershell
ssh dev01
```

## How to Use This Repository

### Step 1: Set Up Your Development Environment

1. Clone this repository to your local machine.
2. Open a PowerShell terminal with administrator rights.
3. Navigate to the directory where you cloned the repository.
4. Run the `SetupDeveloperEnv.ps1` script to install all necessary tools.

### Step 2: Select Application Groups

1. If you do not use the `-groups` parameter, you will be prompted to select which groups of applications to install. Review the descriptions provided for each group and make your selections.
2. Alternatively, specify the `-groups` parameter to install applications from selected groups automatically, or use `"all"` to install all available applications.

### Step 3: Clone Necessary Repositories

1. After setting up your environment, run the `SetupGitEnv.ps1` script.
2. This will clone all necessary repositories and install global npm packages for your projects.

### Step 4: Onboard to Development Servers (Optional)

1. If you need access to development servers, run the `OnboardDeveloper.ps1` script.
2. Provide your Developer ID and PIN when prompted, or pass them as parameters.
3. The script will set up SSH access and verify connectivity.

### Step 5: Begin Development

With your environment set up, you can now begin working on your projects. Clone additional repositories as needed, and use the provided scripts to manage your development environment efficiently.

## Project-Specific Configuration

While this repository is designed to provide general configuration for all projects at eSystems Nordic Ltd, individual projects (like `agilenowdev`) may have their own specific configurations. These configurations will be similar but tailored to the specific needs of the project.

## About eSystems Nordic Ltd

eSystems Nordic Ltd is a leading provider of software solutions, specializing in creating innovative and scalable software products. This repository is part of our ongoing efforts to streamline development processes and ensure consistency across all our projects.

For more information or support, please contact the repository maintainers.
