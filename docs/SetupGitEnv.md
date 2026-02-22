# SetupGitEnv.ps1 / SetupGitEnv.sh

These scripts automate the setup of your Git workspace and development dependencies. They create the folder structure, configure Git safe directories, clone or update repositories from GitHub, and install global npm packages. Run with your user account (no administrator rights required). **SetupGitEnv.ps1** is for Windows; **SetupGitEnv.sh** is for macOS/Unix.

**Workspace path:**

- **Integration path:** Use `C:\workspace` (Windows) or `GIT_FOLDER=$HOME/workspace` / `GIT_FOLDER=/workspace` (macOS). Edit `$gitFolder` at the top of the PS1 script, or set the `GIT_FOLDER` env var when running the shell script. See [Setup-integration.md](../Setup-integration.md).
- **Full developer path:** For the complete repository list, see [Setup-developer.md](../Setup-developer.md); set `$repositories` / `REPOSITORIES` accordingly.

**Features:**

- Creates the Git root folder and organization folder (e.g. `C:\git\esystemsdev` or `C:\workspace\esystemsdev`) if they do not exist.
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
| `$gitFolder`   | Root folder for all Git repositories (use `C:\workspace` for integration path) | `C:\git` or `C:\workspace`       |
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

1. **Set up your development environment** – Run [SetupDeveloperEnv.ps1](SetupDeveloperEnv.md) (Windows) or SetupDeveloperEnv.sh (macOS) to install tools such as Git and Node.js.
2. **Clone repositories and install global packages** – Run this script with your user account to create folders, clone/update repos, and install global npm packages.
3. **Onboard to development servers (optional)** – Use `aifabrix dev init` if you need remote development access.

- **Full developer path:** [Setup-developer.md](../Setup-developer.md)
- **Integration specialist path:** [Setup-integration.md](../Setup-integration.md)
- **Tool installer details:** [SetupDeveloperEnv.md](SetupDeveloperEnv.md)
