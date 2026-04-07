#!/usr/bin/env bash
# macOS/Unix: one YAML file per run (no merge / no extends).
# Default root: /workspace. Override: GIT_FOLDER=/path ./SetupGitEnv.sh
# Config: SETUPGITENV_CONFIG, or first argument (path to YAML), else SetupGitEnv.yaml beside this script
# Group: SETUPGITENV_GROUP=public ./SetupGitEnv.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GROUP="${SETUPGITENV_GROUP:-}"

if [[ -n "${SETUPGITENV_CONFIG:-}" ]]; then
  CONFIG="${SETUPGITENV_CONFIG}"
elif [[ -n "${1:-}" ]]; then
  CONFIG="$1"
else
  CONFIG="${SCRIPT_DIR}/SetupGitEnv.yaml"
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "SetupGitEnv: config not found: $CONFIG" >&2
  exit 1
fi

if ! command -v ruby >/dev/null 2>&1; then
  echo "SetupGitEnv: Ruby is required to parse workspace YAML." >&2
  echo "Install Ruby (macOS: preinstalled or brew install ruby; Linux: apt install ruby)." >&2
  exit 1
fi

WORKSPACE_JSON="$(
  CONFIG_PATH="$CONFIG" GROUP_NAME="$GROUP" ruby <<'RUBY'
require 'yaml'
require 'json'

def stringify_keys(obj)
  case obj
  when Hash
    obj.each_with_object({}) { |(k, v), h| h[k.to_s] = stringify_keys(v) }
  when Array
    obj.map { |e| stringify_keys(e) }
  else
    obj
  end
end

path = ENV.fetch('CONFIG_PATH', '').strip
group_name = ENV.fetch('GROUP_NAME', '').strip
abort 'SetupGitEnv: CONFIG_PATH empty' if path.empty?
abort "SetupGitEnv: file not found: #{path}" unless File.file?(path)

doc = stringify_keys(YAML.load_file(path))
repos = doc['repos'] || []

unless group_name.empty?
  groups = doc['groups'] || {}
  allowed = groups[group_name]
  unless allowed
    keys = groups.keys.join(', ')
    warn "SetupGitEnv: unknown group '#{group_name}'. Defined: #{keys}"
    exit 1
  end
  allowed_set = allowed.map(&:to_s).each_with_object({}) { |n, h| h[n] = true }
  repos = repos.select { |r| allowed_set[r['name'].to_s] }
  if repos.empty?
    warn "SetupGitEnv: group '#{group_name}' matched no repos."
    exit 1
  end
end

out = {
  'organization' => doc['organization'],
  'gitFolder' => doc['gitFolder'],
  'packages' => doc['packages'] || [],
  'repos' => repos
}
puts JSON.generate(out)
RUBY
)"

GIT_FOLDER="${GIT_FOLDER:-/workspace}"
ORGANIZATION="$(ruby -rjson -e 'print JSON.parse(STDIN.read)["organization"].to_s' <<< "$WORKSPACE_JSON")"
if [[ -z "$ORGANIZATION" ]]; then
  echo "SetupGitEnv: could not read organization from config" >&2
  exit 1
fi

YAML_GIT_FOLDER="$(ruby -rjson -e 'v = JSON.parse(STDIN.read)["gitFolder"]; print v ? v.to_s : ""' <<< "$WORKSPACE_JSON")"
if [[ -n "$YAML_GIT_FOLDER" ]]; then
  GIT_FOLDER="$YAML_GIT_FOLDER"
fi

ORG_FOLDER="$GIT_FOLDER/$ORGANIZATION"
AIFABRIX_WORK_ROOT="${AIFABRIX_WORK:-$ORG_FOLDER}"

CONFIG_DIR="${HOME}/.aifabrix"
SHELL_ENV_FILE="${CONFIG_DIR}/aifabrix-shell-env.sh"
PROFILE_BLOCK_BEGIN="# BEGIN aifabrix-builder shell env"
PROFILE_BLOCK_END="# END aifabrix-builder shell env"

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

register_posix_aifabrix_env() {
  local home_abs
  home_abs="$(resolve_path "$CONFIG_DIR")"
  local work_abs="$WORK_RESOLVED"
  local q_home q_work
  q_home=$(printf '%q' "$home_abs")
  q_work=$(printf '%q' "$work_abs")

  mkdir -p "$CONFIG_DIR"
  {
    echo "# Managed by SetupGitEnv.sh — AI Fabrix. Do not edit."
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

  if AIFABRIX_PATCH_PROFILE="$profile" AIFABRIX_PATCH_SNIPPET="$snippet" ruby <<'PATCHRUBY'
require 'fileutils'
p = ENV['AIFABRIX_PATCH_PROFILE']
snippet = (ENV['AIFABRIX_PATCH_SNIPPET'] || '').rstrip + "\n"
text = File.exist?(p) ? File.read(p) : ''
text = text.gsub(/\n?# BEGIN aifabrix-builder shell env\n[\s\S]*?\n# END aifabrix-builder shell env\n?/, "\n")
text = text.rstrip + "\n\n" + snippet
FileUtils.mkdir_p(File.dirname(p))
File.write(p, text)
PATCHRUBY
then
    echo "Updated shell profile: $profile — open a new terminal, then: echo \"\$AIFABRIX_HOME\"" >&2
  else
    echo "Warning: could not patch shell profile; append this to $profile manually:" >&2
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

clone_or_update_repo_url() {
  local name="$1"
  local url="$2"
  local clone_path="$ORG_FOLDER/$name"

  add_safe_directory "$clone_path"

  if [ ! -d "$clone_path/.git" ]; then
    echo "Cloning $name from $url to $clone_path..."
    git clone "$url" "$clone_path"
  else
    echo "Repository $name already in $clone_path. Pulling..."
    git -C "$clone_path" pull
  fi
}

echo "Using workspace config: $CONFIG" >&2
if [[ -n "$GROUP" ]]; then
  echo "Group filter: $GROUP" >&2
fi

mkdir -p "$GIT_FOLDER"
mkdir -p "$ORG_FOLDER"

set_aifabrix_work_yaml "$AIFABRIX_WORK_ROOT"
register_posix_aifabrix_env

add_safe_directory "$GIT_FOLDER"

while IFS=$'\t' read -r repo_name repo_url; do
  [[ -z "$repo_name" ]] && continue
  clone_or_update_repo_url "$repo_name" "$repo_url"
done < <(ruby -rjson -e '(d = JSON.parse(STDIN.read); (d["repos"] || []).each { |r| n = r["name"].to_s; u = r["url"].to_s; puts n + "\t" + u if !n.empty? && !u.empty? })' <<< "$WORKSPACE_JSON")

echo "Installing necessary npm packages..." >&2
while read -r pkg; do
  [[ -z "$pkg" ]] && continue
  echo "Installing npm package: $pkg..." >&2
  npm install -g "$pkg" || { echo "Installation of npm package $pkg failed." >&2; exit 1; }
done < <(ruby -rjson -e '(d = JSON.parse(STDIN.read); (d["packages"] || []).each { |p| s = p.to_s.strip; puts s unless s.empty? })' <<< "$WORKSPACE_JSON")

echo "Setup complete."
