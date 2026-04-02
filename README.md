# eSystems Nordic - Configuration Repository

Welcome to the eSystems Nordic configuration repository. This repository contains scripts and configuration for setting up development environments for projects managed by eSystems Nordic Ltd.

## Onboarding guides

Choose your path:

- **[Setup-developer.md](Setup-developer.md)** – **Full developer**: all repos, Cursor + full tool set, WSL (Windows) or native macOS. Use when you need the complete AI Fabrix dev environment and Builder Server sync.
- **[Setup-integration.md](Setup-integration.md)** – **Integration specialist**: Cursor, Node, Git, and aifabrix-builder CLI. Use when you create integrations and learn the platform without the full repo set.

## Quick reference

### Initial Developer Computer Setup - Windows

1. Download scripts to `C:\Setup` (see [Setup-developer.md](Setup-developer.md) for the download snippet).
2. Run **SetupDeveloperEnv.ps1** as Administrator with groups `Basic,Development,Local Dev` (or omit `-groups` to choose interactively). See [docs/SetupDeveloperEnv.md](docs/SetupDeveloperEnv.md).
3. Run **SetupWslUbuntuDev.ps1** as Administrator with `-TarPath` (URL or local .tar). The image has `/workspace` ready. See [docs/SetupWslUbuntuDev.md](docs/SetupWslUbuntuDev.md).
4. Open Cursor → WSL → `/workspace`; run `gh auth login`; clone repos; run `aifabrix dev init` when needed.

### Initial Developer Computer Setup - macOS

1. Clone this repo and run **SetupDeveloperEnv.sh** with `--groups "Basic,Development,Local Dev"` (uses same [SetupDeveloperEnv.yaml](SetupDeveloperEnv.yaml) via Homebrew). See [Setup-developer.md](Setup-developer.md).
2. Run **SetupGitEnv.sh** (defaults to `/workspace`, same idea as `C:\workspace` on Windows; use `GIT_FOLDER=$HOME/workspace` on a local Mac if needed). See [docs/SetupGitEnv.md](docs/SetupGitEnv.md).
3. Open Cursor in your workspace; run `gh auth login`; run `aifabrix dev init` when needed.

### Minimal installation – aifabrix WSL (Windows)

See [docs/SetupWslUbuntuDev.md](docs/SetupWslUbuntuDev.md). Run `SetupWslUbuntuDev.ps1` with `-TarPath`; the image has `/workspace` preconfigured.

## Repository contents

- **Setup-developer.md** – Full developer setup (Windows + macOS).
- **Setup-integration.md** – Integration specialist setup.
- **SetupDeveloperEnv.ps1** / **SetupDeveloperEnv.yaml** – Windows: install tools by group (Basic, Development, Local Dev, etc.). [docs/SetupDeveloperEnv.md](docs/SetupDeveloperEnv.md).
- **SetupDeveloperEnv.sh** – macOS: reads same YAML, installs via Homebrew.
- **SetupGitEnv.ps1** – Windows: create Git folder, clone repos, install global npm packages. [docs/SetupGitEnv.md](docs/SetupGitEnv.md).
- **SetupGitEnv.sh** – macOS/Unix: same as PS1; default `GIT_FOLDER` is `/workspace`.
- **SetupWslUbuntuDev.ps1** – Windows: import pre-built WSL dev image. [docs/SetupWslUbuntuDev.md](docs/SetupWslUbuntuDev.md).

### Developer onboarding (remote development)

One-time setup for remote development uses the **aifabrix** CLI: it issues a client certificate (mTLS), fetches server settings, and registers your SSH keys so Mutagen sync works without a password. Requires the [aifabrix-builder](https://github.com/esystemsdev/aifabrix-builder) CLI (`npm install -g @aifabrix/builder`) and a Builder Server URL plus a one-time PIN from your admin.

**Usage (aifabrix dev init):**

```bash
# One-time onboarding with Builder Server URL and PIN
aifabrix dev init --developer-id 01 --server https://builder01.aifabrix.dev --pin 123456

# Interactive (will prompt for developer-id, server, pin if omitted)
aifabrix dev init
```

**Options:**

- `--developer-id <id>` – Developer ID (e.g. `01`).
- `--server <url>` – Builder Server base URL (e.g. `https://builder01.aifabrix.dev`).
- `--pin <pin>` – One-time PIN for onboarding (from your admin).

**Process:**

1. Issue or use an existing client certificate (mTLS for dev APIs).
2. GET `/api/dev/settings` (cert-authenticated) to receive sync and Docker parameters.
3. POST SSH keys so Mutagen can sync without a password prompt.

**After onboarding:**

- Config is written to `~/.aifabrix/config.yaml` (e.g. `remote-server`, `docker-endpoint`, `sync-ssh-host`, `sync-ssh-user`).
- To refresh settings or renew the certificate: `aifabrix dev refresh` (use `aifabrix dev refresh --cert` to force certificate refresh).
- See [Developer Isolation Commands](https://github.com/esystemsdev/aifabrix-builder/blob/2.41.0/docs/commands/developer-isolation.md) for `dev refresh`, `dev config`, `dev down`, and related commands.

**macOS:** Use [Setup-developer.md](Setup-developer.md) or [Setup-integration.md](Setup-integration.md); then run `aifabrix dev init` as above. The same `~/.aifabrix/config.yaml` and CLI commands apply on Windows and macOS.

## About eSystems Nordic Ltd

eSystems Nordic Ltd is a leading provider of software solutions, specializing in creating innovative and scalable software products. This repository is part of our ongoing efforts to streamline development processes and ensure consistency across all our projects.

For more information or support, please contact the repository maintainers.
