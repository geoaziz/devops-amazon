#!/bin/bash

##############################################################################
# Complete Setup Script - Orchestrates all installation phases
# Runs k3s, ArgoCD, and Monitoring setup in sequence
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Complete DevOps Pipeline Setup       ║${NC}"
echo -e "${BLUE}║   k3s + ArgoCD + Prometheus + Grafana  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to run setup scripts
run_setup() {
    local script_name=$1
    local script_path="${SCRIPT_DIR}/${script_name}"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}✗ Script not found: ${script_path}${NC}"
        return 1
    fi
    
    bash "$script_path"
    return $?
}

# Phase 1: k3s Installation
echo -e "\n${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}PHASE 1: Installing k3s${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
read -p "Install k3s? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_setup "setup-k3s.sh" || exit 1
    echo -e "${GREEN}✓ k3s installation complete${NC}"
    sleep 2
fi

# Phase 2: ArgoCD Installation
echo -e "\n${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}PHASE 2: Installing ArgoCD${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
read -p "Install ArgoCD? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_setup "setup-argocd.sh" || exit 1
    echo -e "${GREEN}✓ ArgoCD installation complete${NC}"
    sleep 2
fi

# Phase 3: Monitoring Installation
echo -e "\n${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}PHASE 3: Installing Prometheus & Grafana${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
read -p "Install Prometheus & Grafana? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_setup "setup-monitoring.sh" || exit 1
    echo -e "${GREEN}✓ Monitoring installation complete${NC}"
    sleep 2
fi

# Final summary
echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Setup Complete!                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Verify everything is running:"
echo -e "     ${GREEN}./scripts/test-pipeline.sh${NC}"
echo -e "\n  2. Set up port-forwards in separate terminals:"
echo -e "     ${GREEN}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo -e "     ${GREEN}kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090${NC}"
echo -e "     ${GREEN}kubectl port-forward -n monitoring pod/grafana-* 3000:3000${NC}"
echo -e "\n  3. Access your services:"
echo -e "     ArgoCD: ${GREEN}https://localhost:8080${NC}"
echo -e "     Prometheus: ${GREEN}http://localhost:9090${NC}"
echo -e "     Grafana: ${GREEN}http://localhost:3000${NC}"
echo -e "\n  4. Make a code change and push to test the full pipeline"
echo -e "\n${GREEN}Happy DevOps-ing! 🚀${NC}"
