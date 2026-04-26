#!/bin/bash

##############################################################################
# Cleanup Script - Removes all Kubernetes components (optional)
# Use this to reset your cluster or remove everything
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}    Cleanup Script - Destructive!${NC}"
echo -e "${RED}========================================${NC}"

echo -e "${YELLOW}This script will DELETE:${NC}"
echo -e "  • ArgoCD namespace (if exists)"
echo -e "  • Monitoring namespace (if exists)"
echo -e "  • All associated pods, services, and data"

read -p "Are you sure you want to proceed? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${GREEN}Cleanup cancelled${NC}"
    exit 0
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ Error: kubectl not found${NC}"
    exit 1
fi

# Remove ArgoCD
if kubectl get namespace argocd &> /dev/null; then
    echo -e "${BLUE}→ Removing ArgoCD...${NC}"
    kubectl delete namespace argocd --ignore-not-found=true
    echo -e "${GREEN}✓ ArgoCD removed${NC}"
fi

# Remove Monitoring
if kubectl get namespace monitoring &> /dev/null; then
    echo -e "${BLUE}→ Removing Monitoring (Prometheus, Grafana)...${NC}"
    kubectl delete namespace monitoring --ignore-not-found=true
    echo -e "${GREEN}✓ Monitoring removed${NC}"
fi

# Remove applications in default namespace
echo -e "${BLUE}→ Checking for app deployments...${NC}"
if kubectl get deployment amazon-prime-app &> /dev/null; then
    echo -e "${BLUE}→ Removing amazon-prime-app deployment...${NC}"
    kubectl delete deployment amazon-prime-app
    kubectl delete svc amazon-prime-app --ignore-not-found=true
    echo -e "${GREEN}✓ App deployment removed${NC}"
fi

echo -e "\n${GREEN}✓ Cleanup complete!${NC}"
echo -e "\n${YELLOW}Current namespaces:${NC}"
kubectl get namespaces

echo -e "\n${YELLOW}To reinstall everything, run:${NC}"
echo -e "  ${GREEN}./scripts/setup-all.sh${NC}"

echo -e "\n${YELLOW}To completely remove k3s:${NC}"
echo -e "  ${GREEN}sudo /usr/local/bin/k3s-uninstall.sh${NC}"
