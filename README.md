# eSystems Nordic - Configuration Repository

Welcome to the eSystems Nordic configuration repository. This repository contains essential scripts and configuration files necessary for setting up development environments across various projects managed by eSystems Nordic Ltd. It provides a standardized setup process, ensuring that all developers have a consistent environment for building and deploying software.

## Repository Contents

### 1. `SetupDeveloperEnv.ps1`

This PowerShell script automates the installation of essential tools and dependencies required for development. It reads configuration data from `SetupDeveloperEnv.yaml` and installs the necessary software, ensuring that your development environment is fully equipped.

**Features:**
- Installs tools such as Docker, Git, Node.js, Python, Visual Studio Code, and more.
- Verifies if tools are already installed and skips reinstallation if unnecessary.
- Allows the user to choose which groups of applications to install, with a default installation of the "Development" group.
- Configures your environment according to company standards.

**Usage:**
```powershell
# Run the script with administrator rights
.\SetupDeveloperEnv.ps1
```

**Installation Process:**
- The script will prompt you to select which groups of applications you wish to install. Available groups will be displayed, and the script will provide a brief description of each.
- The "Development" group, containing essential development tools, will always be installed by default.
- After selecting the desired groups, the script will proceed to install the necessary software, skipping any that are already installed.

### 2. `SetupDeveloperEnv.yaml`

This YAML file contains the configuration data used by `SetupDeveloperEnv.ps1`. It lists all the software that needs to be installed, along with their respective download URLs, installation arguments, and checks to ensure they are installed correctly.

**Features:**
- Customizable: You can modify this file to adjust which tools are installed or to change installation parameters.
- Supports both `.exe` and `.msi` installers.
- Organized by application groups, allowing for targeted installation based on development needs.

**Sample Configuration:**
```yaml
applications:
  - name: Docker
    install: true
    group: "Virtualization"
    url: "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
    silentArguments: "install --quiet"
    programCheck: "Docker\Docker\DockerCli.exe"
    commandCheck: docker

  - name: JDK
    install: false
    group: "Development"
    url: "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.msi"
    installer: "java.msi"
    programCheck: "Java\\jdk-17\\bin\\java.exe"

  - name: SSMS
    group: "Database"
    url: "https://aka.ms/ssmsfullsetup"
    programCheck: "Microsoft SQL Server Management Studio 18\\Common7\\IDE\\Ssms.exe,Microsoft SQL Server Management Studio 20\\Common7\\IDE\\Ssms.exe"
    installer: "SSMS-Setup-ENU.exe"
  # Additional applications...
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
.\SetupGitEnv.ps1
```

## How to Use This Repository

### Step 1: Set Up Your Development Environment

1. Clone this repository to your local machine.
2. Open a PowerShell terminal with administrator rights.
3. Navigate to the directory where you cloned the repository.
4. Run the `SetupDeveloperEnv.ps1` script to install all necessary tools.

### Step 2: Select Application Groups

1. When running the `SetupDeveloperEnv.ps1` script, you will be prompted to select which groups of applications to install. Review the descriptions provided for each group and make your selections.
2. The "Development" group will be installed by default, ensuring that essential development tools are always available.

### Step 3: Clone Necessary Repositories

1. After setting up your environment, run the `SetupGitEnv.ps1` script.
2. This will clone all necessary repositories and install global npm packages for your projects.

### Step 4: Begin Development

With your environment set up, you can now begin working on your projects. Clone additional repositories as needed, and use the provided scripts to manage your development environment efficiently.

## Project-Specific Configuration

While this repository is designed to provide general configuration for all projects at eSystems Nordic Ltd, individual projects (like `agilenowdev`) may have their own specific configurations. These configurations will be similar but tailored to the specific needs of the project.

## About eSystems Nordic Ltd

eSystems Nordic Ltd is a leading provider of software solutions, specializing in creating innovative and scalable software products. This repository is part of our ongoing efforts to streamline development processes and ensure consistency across all our projects.

For more information or support, please contact the repository maintainers.
