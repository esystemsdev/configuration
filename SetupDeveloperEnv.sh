#!/usr/bin/env bash
# macOS installer: reads SetupDeveloperEnv.yaml (same file as Windows) and installs
# applications via Homebrew (homebrewCask -> brew install --cask, homebrewFormula -> brew install).
# Usage: ./SetupDeveloperEnv.sh --groups "Basic,Development,Local Dev"
#    or: ./SetupDeveloperEnv.sh Basic Development "Local Dev"
# Groups: Basic (integration path), Development, Local Dev, Database, Development OutSystems.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YAML_PATH="${SCRIPT_DIR}/SetupDeveloperEnv.yaml"

if [ ! -f "$YAML_PATH" ]; then
  echo "SetupDeveloperEnv.yaml not found at $YAML_PATH" >&2
  exit 1
fi

# Parse --groups or positional args
SELECTED_GROUPS=()
if [ "$1" = "--groups" ] && [ -n "$2" ]; then
  IFS=',' read -ra SELECTED_GROUPS <<< "$2"
  shift 2
else
  while [ -n "$1" ]; do
    SELECTED_GROUPS+=("$1")
    shift
  done
fi

if [ ${#SELECTED_GROUPS[@]} -eq 0 ]; then
  echo "Usage: $0 --groups 'Basic,Development,Local Dev'"
  echo "   or: $0 Basic Development \"Local Dev\""
  echo "Groups: Basic (Cursor+Node+Git), Development, Local Dev, Database, Development OutSystems"
  exit 1
fi

# Check for Homebrew
if ! command -v brew &>/dev/null; then
  echo "Homebrew is required. Install from https://brew.sh"
  exit 1
fi

# Use Ruby (built-in on macOS) to parse YAML and output "cask:name" or "formula:name" per line
# Pass selected groups as comma-separated in env to avoid shell escaping issues
export SETUP_GROUPS_CSV
SETUP_GROUPS_CSV=$(IFS=,; echo "${SELECTED_GROUPS[*]}")
install_items() {
  ruby -r yaml -e "
    data = YAML.load_file(ENV['YAML_PATH'])
    selected = ENV['SETUP_GROUPS_CSV'].to_s.split(',').map(&:strip).reject(&:empty?)
    (data['applications'] || []).each do |app|
      g = app['group']
      app_groups = g.is_a?(Array) ? g : [g.to_s]
      next unless (app_groups & selected).any?
      puts \"cask:\#{app['homebrewCask']}\" if app['homebrewCask'].to_s != ''
      puts \"formula:\#{app['homebrewFormula']}\" if app['homebrewFormula'].to_s != ''
    end
  "
}
export YAML_PATH

# Ensure workspace directory for macOS (documented as \$HOME/workspace when not using /workspace)
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/workspace}"
if [ ! -d "$WORKSPACE_DIR" ]; then
  echo "Creating workspace directory: $WORKSPACE_DIR"
  mkdir -p "$WORKSPACE_DIR"
fi

echo "Installing applications for groups: $(IFS=,; echo "${SELECTED_GROUPS[*]}")"
echo "Workspace directory: $WORKSPACE_DIR"
echo ""

while IFS= read -r line; do
  [ -z "$line" ] && continue
  type="${line%%:*}"
  name="${line#*:}"
  [ -z "$name" ] && continue
  if [ "$type" = "cask" ]; then
    echo "Installing cask: $name"
    brew install --cask "$name" || true
  elif [ "$type" = "formula" ]; then
    echo "Installing formula: $name"
    brew install "$name" || true
  fi
done < <(install_items)

echo ""
echo "Setup complete. Open Cursor and use folder: $WORKSPACE_DIR"
echo "For full developer path, run SetupGitEnv.sh with GIT_FOLDER=$WORKSPACE_DIR"
