#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

MAX_RETRIES="${MAX_RETRIES:-4}"
RETRY_DELAY_SECONDS="${RETRY_DELAY_SECONDS:-2}"

usage() {
  cat <<'EOF'
Usage:
  bootstrap-github-secrets.sh [--repo owner/name]

GitHub secrets written (canonical names):
  DOCKERHUB_USERNAME
  DOCKERHUB_TOKEN
  SONAR_TOKEN
  SONAR_ORGANIZATION
  SONAR_PROJECT_KEY
  GIT_TOKEN

Accepted local aliases (for .env or shell input):
  DOCKER_USERNAME -> DOCKERHUB_USERNAME
  DOCKER_PAT -> DOCKERHUB_TOKEN
  SONAR_ORG -> SONAR_ORGANIZATION
  SONAR_PROJECT -> SONAR_PROJECT_KEY
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

normalize_repo() {
  local input="$1"
  local normalized="$input"

  if [[ -z "$normalized" ]]; then
    printf '%s' "$normalized"
    return 0
  fi

  if [[ "$normalized" =~ github.com[:/]([^[:space:]]+)$ ]]; then
    normalized="${BASH_REMATCH[1]}"
  fi

  normalized="${normalized%.git}"
  normalized="${normalized#/}"

  printf '%s' "$normalized"
}

load_env_file() {
  local script_dir repo_root env_file
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "${script_dir}/.." && pwd)"
  env_file="${repo_root}/.env"

  if [[ ! -f "$env_file" ]]; then
    echo "No .env file found at ${env_file}; script will prompt for missing values."
    return 0
  fi

  # Parse simple KEY=VALUE lines so .env works even with CRLF and comments.
  while IFS= read -r line || [[ -n "$line" ]]; do
    local key value

    line="${line%$'\r'}"
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" != *=* ]] && continue

    key="${line%%=*}"
    value="${line#*=}"

    key="${key#${key%%[![:space:]]*}}"
    key="${key%${key##*[![:space:]]}}"

    if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      echo "Skipping invalid variable name in .env: ${key}" >&2
      continue
    fi

    if [[ "$value" =~ ^\".*\"$ ]]; then
      value="${value:1:${#value}-2}"
    elif [[ "$value" =~ ^\'.*\'$ ]]; then
      value="${value:1:${#value}-2}"
    fi

    export "$key=$value"
  done < "$env_file"

  echo "Loaded environment from ${env_file}"
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
  local attempt=1
  local last_error=""

  while (( attempt <= MAX_RETRIES )); do
    if printf '%s' "$secret_value" | gh secret set "$secret_name" --repo "$repo" --body - >/dev/null 2>/tmp/bootstrap-secret-error.log; then
      echo "Set ${secret_name}"
      rm -f /tmp/bootstrap-secret-error.log
      return 0
    fi

    last_error="$(cat /tmp/bootstrap-secret-error.log 2>/dev/null || true)"
    rm -f /tmp/bootstrap-secret-error.log

    if (( attempt == MAX_RETRIES )); then
      echo "Failed to set ${secret_name} after ${MAX_RETRIES} attempts." >&2
      if [[ -n "$last_error" ]]; then
        echo "$last_error" >&2
      fi
      return 1
    fi

    echo "Attempt ${attempt}/${MAX_RETRIES} failed while setting ${secret_name}. Retrying..." >&2
    if [[ -n "$last_error" ]]; then
      echo "$last_error" >&2
    fi
    sleep "$(( RETRY_DELAY_SECONDS * attempt ))"
    attempt=$(( attempt + 1 ))
  done
}

repo="${GITHUB_REPOSITORY:-}"
repo="$(normalize_repo "$repo")"

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

# Fix: load repo-root .env so values are available even if not exported in shell
load_env_file

if [[ -z "$repo" ]]; then
  if command -v git >/dev/null 2>&1; then
    remote_url="$(git remote get-url origin 2>/dev/null || true)"
    if [[ "$remote_url" =~ github.com[:/]([^[:space:]]+)$ ]]; then
      repo="${BASH_REMATCH[1]}"
    fi
  fi
fi

repo="$(normalize_repo "$repo")"

if [[ -n "$repo" && ! "$repo" =~ ^[^/]+/[^/]+$ ]]; then
  echo "Repository format is invalid: ${repo}. Expected owner/name." >&2
  exit 1
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

echo "Writing canonical secrets to ${repo}"
echo "Accepted aliases: DOCKER_USERNAME, DOCKER_PAT, SONAR_ORG, SONAR_PROJECT"

for entry in "${secrets[@]}"; do
  secret_name="${entry%%:*}"
  fallback_name="${entry#*:}"
  secret_value="$(resolve_value "$secret_name" "$fallback_name")"
  set_secret "$repo" "$secret_name" "$secret_value"
done

echo "All required secrets were written successfully."