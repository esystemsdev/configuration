# Azure AI Repository Setup

This document provides step-by-step instructions to create a private GitHub repository named `azure-ai`, clone it locally, set up the required directory structure, and push the initial commit.

## **Prerequisites**

- **GitHub CLI**: Ensure that the GitHub CLI (`gh`) is installed on your machine. You can download it from [GitHub CLI](https://cli.github.com/).
- **Git**: Ensure that `git` is installed and configured on your machine.
- **GitHub Account**: You must have a GitHub account to create the repository.

## **1. Create a Private Repository on GitHub**

Use the following command to create a new private repository named `azure-ai`:

```bash
gh repo create esystemsdev/azure-ai --private --confirm
```

This command will:

- Create a new private repository named `azure-ai` in your GitHub account.

## **2. Clone the Repository Locally**

After creating the repository, clone it to your local machine:

```bash
cd C:/git/esystemsdev
git clone https://github.com/esystemsdev/azure-ai.git
cd azure-ai
```

## **3. Set Up the Directory Structure**

Once you are inside the `azure-ai` directory, create the following directory structure:

```bash
mkdir -p .github/workflows
mkdir config
mkdir docs
mkdir function-app
mkdir scripts

```

### **Create Necessary Files**

You also need to create the following placeholder files:

```bash
touch .github/workflows/deploy.yml
touch function-app/requirements.txt
touch config/template.md
touch config/variables-dev.yaml
touch config/variables-tst.yaml
touch config/variables-pro.yaml
```

### **Directory Structure Overview**

After running the above commands, your directory structure should look like this:

```bash
azure-ai/
├── .github/
│   └── workflows/
│       ├── deploy.yml
├── function-app/
│   └── requirements.txt
└── config/
    └── template.md
    └── variables-dev.yaml
    └── variables-tst.yaml
    └── variables-pro.yaml
```

## **4. Initialize the Repository**

Now, initialize the repository, add all the files, and push the initial commit to GitHub:

```bash
git init
git add .
git commit -m "Initial setup of Azure AI repo with CI/CD structure"
git push -u origin main
```

## **Next Steps**

- **Populate the Workflows**: Edit the `deploy-dev.yml`, `deploy-tst.yml`, and `deploy-prod.yml` files in the `.github/workflows/` directory to configure your CI/CD pipelines.
- **Add Your Functions**: Add your Azure Function code to the `function-app/` directory.
- **Configure Variables**: Define your environment variables and secrets in the `config/variables.yaml` file. Remember, this file should only specify the secret names and descriptions, not their actual values.

### **Conclusion**

You have successfully created a private repository, set up the necessary directory structure, and made the initial commit. You can now proceed with developing your Azure Functions and configuring the CI/CD pipelines to automate your deployments.

### **Explanation**

- **Repository Creation**: The instructions start with creating a private GitHub repository using the GitHub CLI.
- **Cloning and Setup**: The steps guide you through cloning the repository and setting up the directory structure with placeholder files.
- **Initialization and Commit**: Finally, the repository is initialized, the files are added, and the initial commit is pushed to GitHub.
- **Next Steps**: Briefly outlines what to do next, including populating the workflow files, adding function code, and setting up environment variables.

This `README.md` provides clear, step-by-step guidance for setting up the repository, making it easy for any developer to follow.
