# SetupGitEnv.ps1

This PowerShell script automates the setup of your Git workspace and development dependencies. It creates the required folder structure, configures Git safe directories, clones or updates repositories from GitHub, and installs global npm packages. Run it with your user account (no administrator rights required).

**Features:**

- Creates the Git root folder and organization folder (e.g. `C:\git\esystemsdev`) if they do not exist.
- Sets full access permissions for the Users group on the Git and organization folders so tools can access repositories reliably.
- Configures Git safe directory for the Git root and each cloned repository, so Git can work with them without trust prompts.
- Clones repositories from GitHub if they are not present, or pulls the latest changes if they are already cloned.
- Installs global npm packages (e.g. `@aifabrix/builder`) required for development.
- Uses a simple in-script configuration: edit variables at the top to choose organization, repository list, and npm packages.

**Usage:**

```powershell
# Run the script with your user account (no administrator rights required)
.\SetupGitEnv.ps1

# Or using full path
C:\git\esystemsdev\configuration\SetupGitEnv.ps1
```

**What the script does:**

1. Ensures the Git root directory (default `C:\git`) and the organization directory (e.g. `C:\git\esystemsdev`) exist.
2. Sets full access for the Users group on those directories so IDEs and other tools can access the repos.
3. Adds the Git root and (after cloning) each repo path to Git’s global `safe.directory` list.
4. For each repository in the configuration list, either clones it from `https://github.com/<organization>/<repo>.git` or runs `git pull` if it is already cloned.
5. Installs each configured global npm package with `npm install -g <package>`. The script exits with an error if any package installation fails.

**Configuration:**

The script is configured by editing variables at the top of `SetupGitEnv.ps1`:

| Variable        | Purpose                                                                 | Example                          |
|----------------|-------------------------------------------------------------------------|----------------------------------|
| `$gitFolder`   | Root folder for all Git repositories                                   | `C:\git`                         |
| `$organization`| GitHub organization or user name                                       | `esystemsdev`                    |
| `$repositories`| Comma-separated list of repository names to clone or update            | `configuration,aifabrix-training`|
| `$packages`    | Comma-separated list of global npm packages to install                 | `@aifabrix/builder`              |

**Sample configuration:**

```powershell
$gitFolder      = "C:\git"
$organization   = "esystemsdev"
$repositories   = "configuration,aifabrix-training"  # Comma-separated list of repositories
$packages       = "@aifabrix/builder"  # Comma-separated list of npm packages
```

- To add or remove repos, edit the `$repositories` string (e.g. add `,my-other-repo`).
- To add or remove global npm packages, edit the `$packages` string (e.g. add `,typescript`).
- Repositories are cloned to `$gitFolder\$organization\<repository-name>` (e.g. `C:\git\esystemsdev\configuration`).

**Prerequisites:**

- Git must be installed and available on the system `PATH` (e.g. via [SetupDeveloperEnv.ps1](SetupDeveloperEnv.md) or a manual Git install).
- Node.js and npm must be installed if you use the `$packages` list (script will fail on `npm install -g` if npm is missing).

## How this fits into the setup process

1. **Set up your development environment** – Run `SetupDeveloperEnv.ps1` (with administrator rights) to install tools such as Git and Node.js.
2. **Clone repositories and install global packages** – Run `SetupGitEnv.ps1` with your user account to create folders, clone/update repos, and install global npm packages.
3. **Onboard to development servers (optional)** – Use `aifabrix dev init` or `OnboardDeveloper.ps1` if you need remote development access.

For the full workflow, see [SetupDeveloperEnv.md](SetupDeveloperEnv.md).
