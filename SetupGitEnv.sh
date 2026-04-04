#!/usr/bin/env bash
# macOS/Unix equivalent of SetupGitEnv.ps1
# Creates git workspace, clones/updates repos, installs global npm packages.
# Run with your user account. Default root is /workspace (same role as C:\workspace on Windows in SetupGitEnv.ps1).
# On a local Mac, or if you cannot create /workspace, use: GIT_FOLDER=$HOME/workspace ./SetupGitEnv.sh
#
# For full developer path: see Setup-developer.md for the complete repository list and set REPOSITORIES accordingly.

set -e

# Configuration (mirror SetupGitEnv.ps1: $gitFolder = "C:\workspace")
GIT_FOLDER="${GIT_FOLDER:-/workspace}"
ORGANIZATION="${ORGANIZATION:-esystemsdev}"
REPOSITORIES="${REPOSITORIES:-configuration,aifabrix-training}"  # Full list in Setup-developer.md
PACKAGES="${PACKAGES:-@aifabrix/builder}"

ORG_FOLDER="$GIT_FOLDER/$ORGANIZATION"
# aifabrix-work in ~/.aifabrix/config.yaml (AI Fabrix CLI). Default: org clone root.
# Override: AIFABRIX_WORK=/your/path ./SetupGitEnv.sh
AIFABRIX_WORK_ROOT="${AIFABRIX_WORK:-$ORG_FOLDER}"

CONFIG_DIR="${HOME}/.aifabrix"
SHELL_ENV_FILE="${CONFIG_DIR}/aifabrix-shell-env.sh"
# Match lib/utils/register-aifabrix-shell-env.js so blocks merge cleanly with `aifabrix dev set-work`.
PROFILE_BLOCK_BEGIN="# BEGIN aifabrix-builder shell env"
PROFILE_BLOCK_END="# END aifabrix-builder shell env"

# Exported after set_aifabrix_work_yaml runs
WORK_RESOLVED=""

resolve_path() {
  local p="$1"
  if [ -d "$p" ]; then
    (cd "$p" && pwd)
  elif [ -e "$p" ]; then
    local _d _b
    _d="$(dirname "$p")"
    _b="$(basename "$p")"
    printf '%s\n' "$(cd "$_d" && pwd)/$_b"
  else
    printf '%s' "$p"
  fi
}

# Ensure ~/.aifabrix/config.yaml contains aifabrix-work (merge; other keys preserved)
set_aifabrix_work_yaml() {
  local work_path="$1"
  local config_path="${CONFIG_DIR}/config.yaml"
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR" 2>/dev/null || true

  local resolved
  resolved="$(resolve_path "$work_path")"
  WORK_RESOLVED="$resolved"

  local yq_escaped="${resolved//\'/\'\'}"

  if [ -f "$config_path" ]; then
    grep -v '^[[:space:]]*aifabrix-work[[:space:]]*:' "$config_path" > "${config_path}.tmp" || true
    mv "${config_path}.tmp" "$config_path"
  fi
  printf "aifabrix-work: '%s'\n" "$yq_escaped" >>"$config_path"
  chmod 600 "$config_path" 2>/dev/null || true
  echo "Updated aifabrix-work in: $config_path" >&2
}

# Write aifabrix-shell-env.sh and ensure ~/.zshrc or ~/.bashrc sources it (same markers as aifabrix CLI)
register_posix_aifabrix_env() {
  local home_abs
  home_abs="$(resolve_path "$CONFIG_DIR")"
  local work_abs="$WORK_RESOLVED"
  local q_home q_work
  q_home=$(printf '%q' "$home_abs")
  q_work=$(printf '%q' "$work_abs")

  mkdir -p "$CONFIG_DIR"
  {
    echo "# Managed by SetupGitEnv.sh (AI Fabrix). Do not edit."
    echo "export AIFABRIX_HOME=${q_home}"
    echo "export AIFABRIX_WORK=${q_work}"
  } >"$SHELL_ENV_FILE"
  chmod 600 "$SHELL_ENV_FILE" 2>/dev/null || true
  echo "Wrote: $SHELL_ENV_FILE" >&2

  local profile
  case "${SHELL:-}" in
    */zsh) profile="${HOME}/.zshrc" ;;
    *) profile="${HOME}/.bashrc" ;;
  esac

  local q_env
  q_env=$(printf '%q' "$SHELL_ENV_FILE")
  local snippet="${PROFILE_BLOCK_BEGIN}
[ -f ${q_env} ] && . ${q_env}
${PROFILE_BLOCK_END}
"

  if command -v python3 >/dev/null 2>&1; then
    AIFABRIX_PATCH_PROFILE="$profile" AIFABRIX_PATCH_SNIPPET="$snippet" python3 - <<'PY'
import os, re, pathlib
p = pathlib.Path(os.environ["AIFABRIX_PATCH_PROFILE"])
snippet = os.environ["AIFABRIX_PATCH_SNIPPET"].rstrip() + "\n"
text = p.read_text() if p.exists() else ""
text = re.sub(
    r"\n?# BEGIN aifabrix-builder shell env\n[\s\S]*?\n# END aifabrix-builder shell env\n?",
    "\n",
    text,
)
text = text.rstrip() + "\n\n" + snippet
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(text)
PY
    echo "Updated shell profile: $profile (open a new terminal, then: echo \"\$AIFABRIX_HOME\")" >&2
  else
    echo "Warning: python3 not found; append this to $profile manually:" >&2
    printf '%s\n' "$snippet" >&2
  fi
}

add_safe_directory() {
  local path="$1"
  if ! git config --global --get-all safe.directory | grep -Fxq "$path"; then
    echo "Configuring Git safe directory for: $path"
    git config --global --add safe.directory "$path"
  else
    echo "Git safe directory already configured for: $path"
  fi
}

# Ensure directories exist
mkdir -p "$GIT_FOLDER"
mkdir -p "$ORG_FOLDER"

set_aifabrix_work_yaml "$AIFABRIX_WORK_ROOT"
register_posix_aifabrix_env

# Configure Git safe directory for root and org folder
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
