# **Documentation: Setting Up `ai-studio-in-a-box`**

## Navigate to your desired folder

cd C:/git/esystemsdev

## Clone the repository

```bash
git clone https://github.com/Azure-Samples/ai-studio-in-a-box chatbot

cd C:/git/esystemsdev/chatbot
azd auth login

# Create a new environment
azd env new esys-demo-ai

# Existing environment variables
azd env set AZURE_LOCATION swedencentral
azd env set AZURE_SUBSCRIPTION_ID 67576622-504a-4532-9903-dbae7df491f5

# Infrastructure-specific parameters
azd env set AZURE_DEPLOY_COSMOS_DB True
azd env set AZURE_DEPLOY_SEARCH True
azd env set AZURE_PUBLIC_NETWORK_ACCESS Disabled
azd env set AZURE_SYSTEM_DATASTORES_AUTH_MODE accessKey
# Add your allowed IPs here, e.g., 192.168.1.1, or use $(curl -s https://api.ipify.org) to dynamically set it
azd env set AZURE_ALLOWED_IPS 185.11.208.90
# GlobalDocumentDB or MongoDB, Cassandra, etc.
azd env set AZURE_COSMOS_DB_KIND GlobalDocumentDB

azd up

```

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

## Deleting Resources with `azd down`

The `azd down` command is a powerful tool that deletes all resources associated with your Azure deployment as defined in your Azure Developer CLI (azd) environment. This operation is irreversible, so it's essential to ensure that you no longer need the resources or have backups if required.

### Steps to Delete Resources

1. **Navigate to Your Project Directory:**
   Ensure you are in the root directory of your Azure Developer project where your `azd` environment files and infrastructure code are located.

   ```bash
   cd C:/git/esystemsdev/chatbot
   ```

2. **Check the Current Environment:**
   It's always a good idea to confirm the environment you are targeting. You can do this by checking the environment configuration file.

   ```bash
   azd env list
   ```

   Ensure that the environment you intend to delete is active.

3. **Run the `azd down` Command:**
   To delete all resources associated with your current environment, run the following command:

   ```bash
   azd down
   ```

   This command will start the process of deleting all resources in Azure that are tracked by the `azd` environment.

4. **Confirm Deletion:**
   During the process, you may be prompted to confirm the deletion of resources. Ensure that you read the prompts carefully and confirm only if you are certain you want to proceed.

   ```plaintext
   Are you sure you want to delete all resources? (y/n): y
   ```

### Important Notes

- **Irreversibility**: Once the `azd down` command completes, the deletion of resources cannot be undone. All data and configurations associated with those resources will be permanently lost.
  
- **Check for Critical Resources**: Before running the command, ensure that there are no critical resources that should be preserved, such as databases, storage accounts, or production environments.

- **Backup Important Data**: If you have critical data stored in Azure resources, make sure to back it up before running the `azd down` command.

- **Verify Environment**: Double-check that you are operating in the correct environment. Deleting resources in the wrong environment could have unintended consequences.

By following these steps and precautions, you can safely delete your Azure resources using the `azd down` command.
