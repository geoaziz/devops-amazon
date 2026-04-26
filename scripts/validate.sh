#!/bin/bash

##############################################################################
# Comprehensive Validation Script - Checks entire pipeline setup
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters for results
PASS=0
FAIL=0
WARN=0

# Function to print test result
test_result() {
    local name=$1
    local status=$2
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} ${name}"
        ((PASS++))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗${NC} ${name}"
        ((FAIL++))
    else  # WARN
        echo -e "${YELLOW}⚠${NC} ${name}"
        ((WARN++))
    fi
}

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Pipeline Setup Validation                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"

# 1. System Prerequisites
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. System Prerequisites${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -f /etc/os-release ] && grep -qi "ubuntu\|debian" /etc/os-release; then
    test_result "Linux OS (Ubuntu/Debian)" "PASS"
else
    test_result "Linux OS (Ubuntu/Debian)" "FAIL"
fi

if command -v git &> /dev/null; then
    test_result "Git installed" "PASS"
else
    test_result "Git installed" "FAIL"
fi

if command -v docker &> /dev/null; then
    test_result "Docker installed" "PASS"
else
    test_result "Docker installed (optional)" "WARN"
fi

# 2. k3s & Kubernetes
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. Kubernetes (k3s)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v kubectl &> /dev/null; then
    test_result "kubectl available" "PASS"
else
    test_result "kubectl available" "FAIL"
fi

if command -v k3s &> /dev/null; then
    test_result "k3s installed" "PASS"
    K3S_VERSION=$(k3s --version 2>/dev/null | awk '{print $3}')
    echo -e "   Version: ${CYAN}${K3S_VERSION}${NC}"
else
    test_result "k3s installed" "FAIL"
fi

if kubectl cluster-info &> /dev/null 2>&1; then
    test_result "Kubernetes cluster accessible" "PASS"
    NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    echo -e "   Nodes: ${CYAN}${NODE_COUNT}${NC}"
else
    test_result "Kubernetes cluster accessible" "FAIL"
fi

if [ -f ~/.kube/config ]; then
    test_result "kubeconfig file exists" "PASS"
else
    test_result "kubeconfig file exists" "FAIL"
fi

# 3. Project Files
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. Project Configuration Files${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -f .github/workflows/build.yml ]; then
    test_result "GitHub Actions workflow exists" "PASS"
else
    test_result "GitHub Actions workflow exists" "FAIL"
fi

if [ -f k8s/deployment.yaml ]; then
    test_result "Kubernetes deployment manifest" "PASS"
    IMAGE=$(grep -o 'image:.*' k8s/deployment.yaml | head -1)
    echo -e "   ${IMAGE}"
else
    test_result "Kubernetes deployment manifest" "FAIL"
fi

if [ -f k8s/service.yaml ]; then
    test_result "Kubernetes service manifest" "PASS"
else
    test_result "Kubernetes service manifest" "FAIL"
fi

if [ -f Dockerfile ]; then
    test_result "Dockerfile exists" "PASS"
else
    test_result "Dockerfile exists" "FAIL"
fi

if [ -f sonar-project.properties ]; then
    test_result "SonarCloud configuration" "PASS"
else
    test_result "SonarCloud configuration" "FAIL"
fi

if [ -f .gitignore ]; then
    test_result ".gitignore configured" "PASS"
else
    test_result ".gitignore configured" "FAIL"
fi

# 4. Scripts
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. Automation Scripts${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

for script in setup-k3s.sh setup-argocd.sh setup-monitoring.sh setup-all.sh test-pipeline.sh cleanup.sh port-forward.sh; do
    if [ -x "scripts/$script" ]; then
        test_result "scripts/$script" "PASS"
    elif [ -f "scripts/$script" ]; then
        test_result "scripts/$script (not executable)" "WARN"
    else
        test_result "scripts/$script" "FAIL"
    fi
done

# 5. Runtime Components
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. Runtime Components${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ArgoCD
if kubectl get namespace argocd &> /dev/null 2>&1; then
    ARGOCD_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l)
    if [ "$ARGOCD_PODS" -gt 0 ]; then
        test_result "ArgoCD namespace and pods" "PASS"
        echo -e "   Pods running: ${CYAN}${ARGOCD_PODS}${NC}"
    else
        test_result "ArgoCD namespace (pods not running)" "WARN"
    fi
else
    test_result "ArgoCD installed" "WARN"
fi

# Monitoring
if kubectl get namespace monitoring &> /dev/null 2>&1; then
    MON_PODS=$(kubectl get pods -n monitoring --no-headers 2>/dev/null | wc -l)
    if [ "$MON_PODS" -gt 0 ]; then
        test_result "Monitoring namespace and pods" "PASS"
        echo -e "   Pods running: ${CYAN}${MON_PODS}${NC}"
    else
        test_result "Monitoring namespace (pods not running)" "WARN"
    fi
else
    test_result "Monitoring (Prometheus/Grafana) installed" "WARN"
fi

# App Deployment
if kubectl get deployment amazon-prime-app &> /dev/null 2>&1; then
    READY=$(kubectl get deployment amazon-prime-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    DESIRED=$(kubectl get deployment amazon-prime-app -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    if [ "$READY" = "$DESIRED" ] && [ "$DESIRED" -gt 0 ]; then
        test_result "App deployment (ready)" "PASS"
        echo -e "   Replicas: ${CYAN}${READY}/${DESIRED}${NC}"
    else
        test_result "App deployment (pods pending)" "WARN"
        echo -e "   Replicas: ${CYAN}${READY}/${DESIRED}${NC}"
    fi
else
    test_result "App deployment" "WARN"
fi

# App Service
if kubectl get svc amazon-prime-app &> /dev/null 2>&1; then
    test_result "App service" "PASS"
else
    test_result "App service" "WARN"
fi

# 6. GitHub Configuration
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}6. Git & GitHub${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if git rev-parse --git-dir > /dev/null 2>&1; then
    test_result "Git repository initialized" "PASS"
else
    test_result "Git repository initialized" "FAIL"
fi

ORIGIN=$(git config --get remote.origin.url 2>/dev/null || echo "")
if [ -n "$ORIGIN" ]; then
    test_result "Git remote (origin) configured" "PASS"
    echo -e "   Origin: ${CYAN}${ORIGIN}${NC}"
else
    test_result "Git remote (origin) configured" "FAIL"
fi

BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -n "$BRANCH" ]; then
    test_result "Git branch" "PASS"
    echo -e "   Current: ${CYAN}${BRANCH}${NC}"
else
    test_result "Git branch" "FAIL"
fi

# 7. Port Availability
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}7. Port Availability${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

for port in 3000 3001 8080 9090; do
    if ! nc -z localhost $port &> /dev/null 2>&1; then
        test_result "Port $port available" "PASS"
    else
        test_result "Port $port available" "WARN"
    fi
done

# Summary
echo -e "\n${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              Summary                              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Passed:${NC}  ${PASS}"
echo -e "${YELLOW}Warnings:${NC} ${WARN}"
echo -e "${RED}Failed:${NC}  ${FAIL}"

# Determine overall status
if [ "$FAIL" -eq 0 ]; then
    if [ "$WARN" -eq 0 ]; then
        echo -e "\n${GREEN}✓ All checks passed! Pipeline is ready.${NC}"
        exit 0
    else
        echo -e "\n${YELLOW}⚠ All critical checks passed, but some components may need setup.${NC}"
        exit 0
    fi
else
    echo -e "\n${RED}✗ Some critical checks failed. Please review the output above.${NC}"
    exit 1
fi
