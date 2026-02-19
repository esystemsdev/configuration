#!/usr/bin/env bash
# macOS/Unix equivalent of SetupGitEnv.ps1
# Creates git workspace, clones/updates repos, installs global npm packages.
# Run with your user account (no sudo required for typical use).

set -e

# Configuration (mirror SetupGitEnv.ps1)
GIT_FOLDER="${GIT_FOLDER:-$HOME/git}"
ORGANIZATION="${ORGANIZATION:-esystemsdev}"
REPOSITORIES="${REPOSITORIES:-configuration,aifabrix-training}"
PACKAGES="${PACKAGES:-@aifabrix/builder}"

ORG_FOLDER="$GIT_FOLDER/$ORGANIZATION"

# Ensure directories exist
mkdir -p "$GIT_FOLDER"
mkdir -p "$ORG_FOLDER"

# Configure Git safe directory for root and org folder
add_safe_directory() {
  local path="$1"
  if ! git config --global --get-all safe.directory | grep -Fxq "$path"; then
    echo "Configuring Git safe directory for: $path"
    git config --global --add safe.directory "$path"
  else
    echo "Git safe directory already configured for: $path"
  fi
}

add_safe_directory "$GIT_FOLDER"

# Clone or update a repository
clone_or_update_repo() {
  local repo="$1"
  local repo_url="https://github.com/$ORGANIZATION/$repo.git"
  local clone_path="$ORG_FOLDER/$repo"

  add_safe_directory "$clone_path"

  if [ ! -d "$clone_path/.git" ]; then
    echo "Cloning the repository $repo to $clone_path..."
    git clone "$repo_url" "$clone_path"
  else
    echo "Repository $repo already cloned in $clone_path. Pulling the latest changes..."
    git -C "$clone_path" pull
  fi
}

# Clone or update each repository
IFS=',' read -ra REPO_LIST <<< "$REPOSITORIES"
for repo in "${REPO_LIST[@]}"; do
  clone_or_update_repo "$(echo "$repo" | xargs)"
done

# Install global npm packages
echo "Installing necessary npm packages..."
IFS=',' read -ra PKG_LIST <<< "$PACKAGES"
for pkg in "${PKG_LIST[@]}"; do
  pkg=$(echo "$pkg" | xargs)
  if [ -n "$pkg" ]; then
    echo "Installing npm package: $pkg..."
    npm install -g "$pkg" || { echo "Installation of npm package $pkg failed." >&2; exit 1; }
  fi
done

echo "Setup complete."
