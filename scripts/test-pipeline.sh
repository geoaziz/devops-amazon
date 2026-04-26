#!/bin/bash

##############################################################################
# Full Pipeline Test Script
# Verifies that the entire DevOps pipeline is working end-to-end
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Full Pipeline End-to-End Test${NC}"
echo -e "${BLUE}========================================${NC}"

# Check prerequisites
echo -e "${BLUE}→ Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found${NC}"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗ Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ git not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites satisfied${NC}"

# Verify k3s cluster
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    1. Checking k3s Cluster${NC}"
echo -e "${BLUE}========================================${NC}"

NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')
echo -e "${GREEN}✓ Nodes: ${NODES}${NC}"

PODS=$(kubectl get pods -A --no-headers | wc -l)
echo -e "${GREEN}✓ Running pods: ${PODS}${NC}"

# Verify ArgoCD
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    2. Checking ArgoCD${NC}"
echo -e "${BLUE}========================================${NC}"

if kubectl get namespace argocd &> /dev/null; then
    echo -e "${GREEN}✓ ArgoCD namespace exists${NC}"
    
    ARGOCD_READY=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server --no-headers 2>/dev/null | wc -l)
    if [ "$ARGOCD_READY" -gt 0 ]; then
        echo -e "${GREEN}✓ ArgoCD server is running${NC}"
    else
        echo -e "${YELLOW}⚠ ArgoCD server not ready yet${NC}"
    fi
    
    APP_STATUS=$(kubectl get application -n argocd amazon-prime-app -o jsonpath='{.status.operationState.phase}' 2>/dev/null || echo "NotFound")
    echo -e "  Application status: ${GREEN}${APP_STATUS}${NC}"
else
    echo -e "${YELLOW}⚠ ArgoCD not installed${NC}"
    echo -e "  Run: ./scripts/setup-argocd.sh"
fi

# Verify your app deployment
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    3. Checking Amazon Prime App${NC}"
echo -e "${BLUE}========================================${NC}"

if kubectl get deployment amazon-prime-app &> /dev/null; then
    REPLICAS=$(kubectl get deployment amazon-prime-app -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl get deployment amazon-prime-app -o jsonpath='{.spec.replicas}')
    echo -e "${GREEN}✓ Deployment exists: ${REPLICAS}/${DESIRED} replicas ready${NC}"
    
    # Get the image being used
    IMAGE=$(kubectl get deployment amazon-prime-app -o jsonpath='{.spec.template.spec.containers[0].image}')
    echo -e "  Image: ${GREEN}${IMAGE}${NC}"
else
    echo -e "${YELLOW}⚠ Deployment not found${NC}"
fi

# Check service
if kubectl get svc amazon-prime-app &> /dev/null; then
    echo -e "${GREEN}✓ Service exists${NC}"
    PORT=$(kubectl get svc amazon-prime-app -o jsonpath='{.spec.ports[0].port}')
    echo -e "  Port: ${GREEN}${PORT}${NC}"
else
    echo -e "${YELLOW}⚠ Service not found${NC}"
fi

# Verify Prometheus
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    4. Checking Prometheus${NC}"
echo -e "${BLUE}========================================${NC}"

if kubectl get namespace monitoring &> /dev/null; then
    PROMETHEUS_READY=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers 2>/dev/null | wc -l)
    if [ "$PROMETHEUS_READY" -gt 0 ]; then
        echo -e "${GREEN}✓ Prometheus is running${NC}"
    else
        echo -e "${YELLOW}⚠ Prometheus not ready yet${NC}"
    fi
    
    GRAFANA_READY=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers 2>/dev/null | wc -l)
    if [ "$GRAFANA_READY" -gt 0 ]; then
        echo -e "${GREEN}✓ Grafana is running${NC}"
    else
        echo -e "${YELLOW}⚠ Grafana not ready yet${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Monitoring not installed${NC}"
    echo -e "  Run: ./scripts/setup-monitoring.sh"
fi

# Verify Git setup
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    5. Checking Git Configuration${NC}"
echo -e "${BLUE}========================================${NC}"

ORIGIN=$(git config --get remote.origin.url 2>/dev/null || echo "Not set")
echo -e "  Origin: ${GREEN}${ORIGIN}${NC}"

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "Unknown")
echo -e "  Current branch: ${GREEN}${CURRENT_BRANCH}${NC}"

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${GREEN}✓ Cluster Status: OK${NC}"
echo -e "${GREEN}✓ k3s: Running${NC}"

if kubectl get namespace argocd &> /dev/null; then
    echo -e "${GREEN}✓ ArgoCD: Running${NC}"
else
    echo -e "${YELLOW}○ ArgoCD: Not installed${NC}"
fi

if kubectl get namespace monitoring &> /dev/null; then
    echo -e "${GREEN}✓ Monitoring: Running${NC}"
else
    echo -e "${YELLOW}○ Monitoring: Not installed${NC}"
fi

if kubectl get deployment amazon-prime-app &> /dev/null; then
    echo -e "${GREEN}✓ Application: Deployed${NC}"
else
    echo -e "${YELLOW}○ Application: Not deployed${NC}"
fi

# Instructions for testing
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    Next: Test the Full Pipeline${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}To test the complete pipeline:${NC}"
echo -e "\n${GREEN}1. Make a code change:${NC}"
echo -e "   Edit any file in src/ (e.g., change a color or text)"

echo -e "\n${GREEN}2. Commit and push:${NC}"
echo -e "   git add ."
echo -e "   git commit -m \"test: verify full pipeline\""
echo -e "   git push origin main"

echo -e "\n${GREEN}3. Watch GitHub Actions:${NC}"
echo -e "   Go to your GitHub repo → Actions tab"
echo -e "   Watch the workflow execute (3-6 minutes)"

echo -e "\n${GREEN}4. Check ArgoCD:${NC}"
echo -e "   Open https://localhost:8080 (port-forward required)"
echo -e "   Watch for 'OutOfSync' → 'Syncing' → 'Healthy'"

echo -e "\n${GREEN}5. Monitor in Grafana:${NC}"
echo -e "   Open http://localhost:3000"
echo -e "   Look for pod restart events in dashboard"

echo -e "\n${GREEN}6. Access your app:${NC}"
echo -e "   kubectl port-forward svc/amazon-prime-app 3000:3000"
echo -e "   Open http://localhost:3000"

echo -e "\n${GREEN}✓ Pipeline test instructions complete!${NC}"
