# **Documentation: Setting Up `ai-studio-in-a-box`**

## Navigate to your desired folder

cd C:/git/esystemsdev

## Clone the repository

```bash
git clone https://github.com/Azure-Samples/ai-studio-in-a-box chatbot

cd C:/git/esystemsdev/chatbot
azd auth login

az login
-- Account name must be between 3 and 15 characters in length and use numbers, line and lower-case letters only
azd env new esys-ai-demo
azd env set AZURE_LOCATION swedencentral
azd env set AZURE_SUBSCRIPTION_ID 67576622-504a-4532-9903-dbae7df491f5

azd up
Enter a value for the 'deployCosmosDb' infrastructure parameter: True
Enter a value for the 'deploySearch' infrastructure parameter: True
Enter a value for the 'publicNetworkAccess' infrastructure parameter: Disabled
Enter a value for the 'systemDatastoresAuthMode' infrastructure parameter: accessKey
```

Azure AI studio

- Deploy model gpt-4o

### Create a new repo

### Step 1: Authenticate with GitHub

Once `gh` is installed, you can authenticate with your GitHub account:

   ```bash
   gh auth login
   ```

### Step 2: Create and Push to a GitHub Repository

Now that the GitHub CLI is installed and you're authenticated, you can proceed with creating a repository and pushing your code as previously outlined.

1. **Navigate to Your Project Directory**:

   ```bash
   cd C:/git/esystemsdev/chatbot
   ```

2. **Initialize the Git Repository (if not done)**:

   ```bash
   git init
   ```

3. **Create a New Private GitHub Repository**:

   ```bash
   gh repo create esystemsdev/chatbot --private --source=.
   ```

4. **Update the Remote URL**:

   ```bash
   git remote set-url origin https://github.com/esystemsdev/chatbot
   ```

5. **Push to GitHub**:

   ```bash
   git push -u origin main
   ```

## Delete the Repository

Run the following command to delete a repository. Be very careful with this command, as it cannot be undone.

   ```bash
   gh auth refresh -h github.com -s delete_repo
   gh repo delete esystemsdev/chatbot
   ```
