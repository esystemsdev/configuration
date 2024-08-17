# **Documentation: Setting Up `contoso-chat`**

## **1. Prerequisites**

- **Install Docker Desktop**: Ensure Docker Desktop is installed and running on your machine.
  - [Download Docker Desktop](https://www.docker.com/products/docker-desktop/) if it's not already installed.

## **2. Clone and Open the Project in Visual Studio Code**

1. **Open the Project in Dev Containers**:
   - Use the following link to open the project in Visual Studio Code using Dev Containers:
   - [Open in Dev Containers](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/azure-samples/contoso-chat)
   
   This will clone the repository into a Docker container for development.

2. **Wait for Project Initialization**:
   - In the VS Code window that opens, wait for the project files to load. This may take several minutes as the development container is set up.

3. **Open a Terminal in VS Code**:
   - Once the project is fully loaded, open a terminal within VS Code.

## **3. Authenticate with Azure and Set Up Environment**

1. **Authenticate with Azure**:
   - Run the following command to log in to your Azure account:

     ```bash
     azd auth login
     ```

## **4. Deploy the Solution**

1. **Run the Deployment Command**:

   - Start the provisioning of Azure resources and deployment of the accelerator:

     ```bash
     azd up
     ```

   - During deployment, you will be prompted to set the following parameters:
     - **Subscription**: `eSystems`
     - **Location**: `Sweden Central`
     - **Environment Name**: `eSYS-Demo-chatbot`

   - The deployment process will take some time as resources are provisioned in Azure.
