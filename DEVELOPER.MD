# Developer Onboarding (Windows)

This guide helps new Windows developers get access, set up tools, and onboard to AI Fabrix or Workato.

## 1) Get access

- Request a developer account via Service Desk:  
  `https://esystem.atlassian.net/servicedesk/customer/portal/2/group/6/create/17`
  - Choose “Dev – Workato” or “Dev – AI Fabrix” as appropriate.

## 2) Install tools (Windows)

- Cursor editor: `https://cursor.com/download`
- For AI Fabrix developers (optional here, required for local infra):
  - Node.js 18+
  - Docker Desktop

## 3) Onboarding script (Windows PowerShell)

Path: `developers/onboard-developer.ps1`

What it does:
- Ensures you have an SSH key (`ed25519`).
- Calls the onboarding service on `http://<server>:9999/api/claim` to register your public key using a temporary PIN.
- Adds an SSH config entry for quick access.
- Tests SSH connectivity.

Usage (PowerShell 7, recommended interactive PIN):

```powershell
pwsh -File .\developers\onboard-developer.ps1 -Server dev.aifabrix -DeveloperId 01
```

Non-interactive example (not recommended; avoid putting PINs into shell history):

```powershell
pwsh -File .\developers\onboard-developer.ps1 -Server dev.aifabrix -DeveloperId 01 -Pin 123456
```

Troubleshooting:
- If the SSH test fails, run once to trust the host key:
  ```powershell
  ssh dev01@dev.aifabrix
  ```
- Ensure the onboarding service is reachable from your network on port `9999`.

## 4) Cursor basics

![Cursor SSH Connection](images/cursor-1.png)

To connect to your developer container:

1. **Connect via SSH**: Click "Connect via SSH" in Cursor's welcome screen.
2. **Select your SSH user**: Choose your configured SSH host (e.g., `dev01`) or enter `user@host` format.
3. **Automatic connection**: Cursor will automatically connect you to your developer container.
4. **Clone repo or open existing folder**: Once connected, you can:
   - Clone a repository from your remote host
   - Open an existing folder on the remote host

## 5) AI Fabrix developer basics

Install Builder CLI:

```powershell
npm install -g @aifabrix/builder
```

Quick start (minimal):

```powershell
aifabrix up
aifabrix create myapp
aifabrix build myapp
aifabrix run myapp
```

See the Builder docs and CLI reference:  
`https://github.com/esystemsdev/aifabrix-builder`

## 6) Workato developer basics

Follow the internal guide for org access, environments, and tooling:  
`https://esystem.atlassian.net/wiki/spaces/EWKT/pages/209879302147/Custom+Connector+SDK`

## 7) Security notes

- Do not paste or commit PINs or secrets. Prefer interactive prompts.
- PINs are single‑use and time‑limited. If a claim fails, request a new PIN.
- Never share private keys. Public keys only are used during onboarding.


