#!/bin/bash

##############################################################################
# ArgoCD Installation & Setup Script
# This script installs ArgoCD on k3s and configures it for your app
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    ArgoCD Installation & Setup${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ Error: kubectl not found${NC}"
    echo -e "${YELLOW}Please install k3s first: ./scripts/setup-k3s.sh${NC}"
    exit 1
fi

# Check if cluster is reachable
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗ Error: Cannot connect to Kubernetes cluster${NC}"
    echo -e "${YELLOW}Please ensure k3s is running${NC}"
    exit 1
fi

# Create argocd namespace
echo -e "${BLUE}→ Creating argocd namespace...${NC}"
kubectl create namespace argocd 2>/dev/null || echo -e "${YELLOW}  (namespace already exists)${NC}"

# Install ArgoCD
echo -e "${BLUE}→ Installing ArgoCD from official manifest...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo -e "${BLUE}→ Waiting for ArgoCD pods to be ready (this may take 2-3 minutes)...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s 2>/dev/null || {
    echo -e "${YELLOW}  Checking pod status...${NC}"
    kubectl get pods -n argocd
}

# Check deployment status
echo -e "${BLUE}→ Verifying ArgoCD installation...${NC}"
kubectl get all -n argocd

# Get initial admin password
echo -e "${BLUE}→ Getting initial admin password...${NC}"
ADMIN_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

if [ -z "$ADMIN_PASS" ]; then
    echo -e "${YELLOW}⚠ Could not retrieve admin password${NC}"
    echo -e "${YELLOW}  Run manually: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d${NC}"
else
    echo -e "${GREEN}✓ Admin Password: ${ADMIN_PASS}${NC}"
fi

# Create ArgoCD application
echo -e "${BLUE}→ Creating ArgoCD Application...${NC}"

# Ask for GitHub repo URL
read -p "Enter your GitHub repository URL (e.g., https://github.com/yourusername/amazon-clone-k8s-eks-argocd): " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo -e "${RED}✗ Repository URL cannot be empty${NC}"
    exit 1
fi

# Create Application manifest
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: amazon-prime-app
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

echo -e "${GREEN}✓ ArgoCD Application created${NC}"

# Port-forward setup instructions
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    Access ArgoCD UI${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Option 1: Using kubectl port-forward (recommended)${NC}"
echo -e "  Run in a new terminal:"
echo -e "  ${GREEN}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo -e "\n  Then access: ${GREEN}https://localhost:8080${NC}"

echo -e "\n${YELLOW}Option 2: Change service type to NodePort${NC}"
echo -e "  Run:"
echo -e "  ${GREEN}kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"NodePort\"}}'${NC}"
echo -e "  ${GREEN}kubectl get svc argocd-server -n argocd${NC}"

echo -e "\n${BLUE}Login Credentials:${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}${ADMIN_PASS}${NC}"
echo -e "  Repository: ${GREEN}${REPO_URL}${NC}"

# Verify application
echo -e "\n${BLUE}→ Verifying application status...${NC}"
sleep 5
kubectl get application -n argocd amazon-prime-app

echo -e "\n${GREEN}✓ ArgoCD setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Set up port-forward as shown above"
echo -e "  2. Access ArgoCD UI at https://localhost:8080"
echo -e "  3. Login and monitor your application deployment"
echo -e "  4. Proceed to monitoring setup: ./scripts/setup-monitoring.sh"
