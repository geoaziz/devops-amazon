#!/usr/bin/env bash

##############################################################################
# Credential Validation Script
# Validates SonarCloud, GitHub, and Docker Hub credentials for this project.
##############################################################################

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

print_result() {
    local name="$1"
    local status="$2"
    local detail="${3:-}"

    case "$status" in
        PASS)
            echo -e "${GREEN}[PASS]${NC} ${name}${detail:+ - ${detail}}"
            ((PASS++))
            ;;
        FAIL)
            echo -e "${RED}[FAIL]${NC} ${name}${detail:+ - ${detail}}"
            ((FAIL++))
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${name}${detail:+ - ${detail}}"
            ((WARN++))
            ;;
    esac
}

require_cmd() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi
    print_result "Required command '$cmd'" "FAIL" "Install $cmd and rerun"
    return 1
}

load_env_file() {
    local env_file="${PROJECT_ROOT}/.env"
    if [[ -f "$env_file" ]]; then
        # shellcheck disable=SC1090
        set -a
        source "$env_file"
        set +a
        print_result "Loaded .env" "PASS" "$env_file"
    else
        print_result "Loaded .env" "WARN" "No .env file found; using current shell env"
    fi
}

check_env_var() {
    local var_name="$1"
    if [[ -n "${!var_name:-}" ]]; then
        print_result "Env var ${var_name}" "PASS"
        return 0
    fi
    print_result "Env var ${var_name}" "FAIL" "Not set"
    return 1
}

validate_sonar() {
    local ok=true

    check_env_var "SONAR_TOKEN" || ok=false
    check_env_var "SONAR_ORG" || ok=false
    check_env_var "SONAR_PROJECT" || ok=false

    if [[ "$ok" != true ]]; then
        print_result "SonarCloud validation" "FAIL" "Missing SONAR_* variables"
        return
    fi

    local auth_resp
    auth_resp="$(curl -sS -u "${SONAR_TOKEN}:" "https://sonarcloud.io/api/authentication/validate" || true)"
    if [[ "$auth_resp" == *'"valid":true'* ]]; then
        print_result "SonarCloud token" "PASS" "Authentication valid"
    else
        print_result "SonarCloud token" "FAIL" "Authentication failed"
    fi

    local org_status
    org_status="$(curl -sS -o /tmp/sonar_org_check.json -w "%{http_code}" -u "${SONAR_TOKEN}:" "https://sonarcloud.io/api/organizations/search?organizations=${SONAR_ORG}" || true)"
    if [[ "$org_status" == "200" ]]; then
        if grep -q '"organizations"' /tmp/sonar_org_check.json 2>/dev/null; then
            print_result "SonarCloud organization access" "PASS" "${SONAR_ORG}"
        else
            print_result "SonarCloud organization access" "WARN" "Request succeeded but org not confirmed"
        fi
    else
        print_result "SonarCloud organization access" "FAIL" "HTTP ${org_status}"
    fi

    local project_status
    project_status="$(curl -sS -o /tmp/sonar_project_check.json -w "%{http_code}" -u "${SONAR_TOKEN}:" "https://sonarcloud.io/api/components/show?component=${SONAR_PROJECT}" || true)"
    if [[ "$project_status" == "200" ]]; then
        if grep -q '"component"' /tmp/sonar_project_check.json 2>/dev/null; then
            print_result "SonarCloud project access" "PASS" "${SONAR_PROJECT}"
        else
            print_result "SonarCloud project access" "WARN" "Request succeeded but project not confirmed"
        fi
    else
        print_result "SonarCloud project access" "FAIL" "HTTP ${project_status}"
    fi

    rm -f /tmp/sonar_org_check.json /tmp/sonar_project_check.json
}

validate_github() {
    check_env_var "GIT_TOKEN" || {
        print_result "GitHub token validation" "FAIL" "Missing GIT_TOKEN"
        return
    }

    local status
    status="$(curl -sS -o /tmp/github_user_check.json -w "%{http_code}" \
        -H "Authorization: token ${GIT_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/user" || true)"

    if [[ "$status" == "200" ]]; then
        local login
        login="$(grep -o '"login":"[^"]*"' /tmp/github_user_check.json | head -1 | cut -d '"' -f4)"
        print_result "GitHub token" "PASS" "Authenticated as ${login:-unknown}"
    else
        print_result "GitHub token" "FAIL" "HTTP ${status}"
    fi

    rm -f /tmp/github_user_check.json
}

validate_dockerhub() {
    local ok=true

    check_env_var "DOCKER_USERNAME" || ok=false
    check_env_var "DOCKER_PAT" || ok=false

    if [[ "$ok" != true ]]; then
        print_result "Docker Hub validation" "FAIL" "Missing DOCKER_* variables"
        return
    fi

    local status
    status="$(curl -sS -o /tmp/docker_login_check.json -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -X POST "https://hub.docker.com/v2/users/login/" \
        -d "{\"username\":\"${DOCKER_USERNAME}\",\"password\":\"${DOCKER_PAT}\"}" || true)"

    if [[ "$status" == "200" ]] && grep -q '"token"' /tmp/docker_login_check.json 2>/dev/null; then
        print_result "Docker Hub PAT" "PASS" "Authenticated as ${DOCKER_USERNAME}"
    else
        print_result "Docker Hub PAT" "FAIL" "HTTP ${status}"
    fi

    rm -f /tmp/docker_login_check.json
}

main() {
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}Credential Validation (SonarCloud / GitHub / Docker Hub)${NC}"
    echo -e "${CYAN}============================================================${NC}"

    require_cmd "curl" || exit 1

    load_env_file
    echo
    validate_sonar
    echo
    validate_github
    echo
    validate_dockerhub

    echo
    echo -e "${CYAN}Summary:${NC} PASS=${PASS} WARN=${WARN} FAIL=${FAIL}"
    if [[ "$FAIL" -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
