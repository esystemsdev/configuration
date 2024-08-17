# Install app-aoai-chatGPT

## Navigate to your desired folder

cd C:/git/esystemsdev

## Clone the repository

git clone https://github.com/microsoft/sample-app-aoai-chatGPT.git chatgpt

## Navigate to the project folder

cd C:/git/esystemsdev/chatgpt

## Initialize the project with Azure Developer CLI

azd init

## Install dependencies

pip install -r requirements.txt

## Deploy the project to Azure

azd up

## Create a new repo

### Step 1: Install GitHub CLI

Open Command Prompt or PowerShell as an administrator.
Run the following command to install GitHub CLI:

   ```bash
   winget install --id GitHub.cli
   ```

### Step 2: Authenticate with GitHub

Once `gh` is installed, you can authenticate with your GitHub account:

   ```bash
   gh auth login
   ```

### Step 3: Create and Push to a GitHub Repository

Now that the GitHub CLI is installed and you're authenticated, you can proceed with creating a repository and pushing your code as previously outlined.

1. **Navigate to Your Project Directory**:

   ```bash
   cd C:/git/esystemsdev/chatgpt
   ```

2. **Initialize the Git Repository (if not done)**:

   ```bash
   git init
   ```

3. **Create a New Private GitHub Repository**:

   ```bash
   gh repo create esystemsdev/chatgpt --private --source=. --remote=origin
   ```

4. **Update the Remote URL**:

   ```bash
   git remote set-url origin https://github.com/esystemsdev/chatgpt
   ```

5. **Push to GitHub**:

   ```bash
   git push -u origin main
   ```

## Delete the Repository

Run the following command to delete a repository. Be very careful with this command, as it cannot be undone.

   ```bash
   gh auth refresh -h github.com -s delete_repo
   gh repo delete esystemsdev/chatgpt
   ```
