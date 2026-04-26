#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bootstrap-github-secrets.sh [--repo owner/name]

Environment variables accepted:
  DOCKERHUB_USERNAME or DOCKER_USERNAME
  DOCKERHUB_TOKEN or DOCKER_PAT
  SONAR_TOKEN
  SONAR_ORGANIZATION or SONAR_ORG
  SONAR_PROJECT_KEY or SONAR_PROJECT
  GIT_TOKEN
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

prompt_value() {
  local label="$1"
  local value=""

  read -r -s -p "Enter value for ${label}: " value
  echo

  if [[ -z "$value" ]]; then
    echo "Value for ${label} cannot be empty." >&2
    exit 1
  fi

  printf '%s' "$value"
}

resolve_value() {
  local primary_name="$1"
  local fallback_name="$2"
  local value="${!primary_name:-}"

  if [[ -z "$value" && -n "$fallback_name" ]]; then
    value="${!fallback_name:-}"
  fi

  if [[ -z "$value" ]]; then
    value="$(prompt_value "$primary_name")"
  fi

  printf '%s' "$value"
}

set_secret() {
  local repo="$1"
  local secret_name="$2"
  local secret_value="$3"

  printf '%s' "$secret_value" | gh secret set "$secret_name" --repo "$repo" --body - >/dev/null
  echo "Set ${secret_name}"
}

repo="${GITHUB_REPOSITORY:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$repo" ]]; then
  if command -v git >/dev/null 2>&1; then
    remote_url="$(git remote get-url origin 2>/dev/null || true)"
    if [[ "$remote_url" =~ github.com[:/](.+/.+)(\.git)?$ ]]; then
      repo="${BASH_REMATCH[1]}"
    fi
  fi
fi

if [[ -z "$repo" ]]; then
  echo "Repository could not be determined. Pass --repo owner/name or set GITHUB_REPOSITORY." >&2
  exit 1
fi

require_command gh

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

secrets=(
  "DOCKERHUB_USERNAME:DOCKER_USERNAME"
  "DOCKERHUB_TOKEN:DOCKER_PAT"
  "SONAR_TOKEN:"
  "SONAR_ORGANIZATION:SONAR_ORG"
  "SONAR_PROJECT_KEY:SONAR_PROJECT"
  "GIT_TOKEN:"
)

echo "Writing secrets to ${repo}"

for entry in "${secrets[@]}"; do
  secret_name="${entry%%:*}"
  fallback_name="${entry#*:}"
  secret_value="$(resolve_value "$secret_name" "$fallback_name")"
  set_secret "$repo" "$secret_name" "$secret_value"
done

echo "All required secrets were written successfully."
