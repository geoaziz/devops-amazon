#!/bin/bash

##############################################################################
# k3s Installation & Setup Script
# This script automates the installation of k3s on your local machine
##############################################################################

set -e  # Exit on any error

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    k3s Installation & Setup${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running on supported OS
if ! grep -qi "ubuntu\|debian" /etc/os-release; then
    echo -e "${RED}✗ Error: This script requires Ubuntu/Debian${NC}"
    echo -e "${YELLOW}Please install Ubuntu 20.04 or 22.04 (or WSL2 with Ubuntu)${NC}"
    exit 1
fi

# Check if already installed
if command -v k3s &> /dev/null; then
    echo -e "${YELLOW}⚠ k3s is already installed${NC}"
    k3s --version
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Skipping installation${NC}"
        exit 0
    fi
fi

# Install k3s
echo -e "${BLUE}→ Installing k3s...${NC}"
curl -sfL https://get.k3s.io | sh -

# Wait for k3s to be ready
echo -e "${BLUE}→ Waiting for k3s to be ready...${NC}"
sleep 10
sudo k3s kubectl wait --for=condition=ready node/localhost --timeout=60s 2>/dev/null || true
sleep 5

# Setup kubeconfig
echo -e "${BLUE}→ Setting up kubeconfig...${NC}"
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
chmod 600 ~/.kube/config

# Set KUBECONFIG environment variable
export KUBECONFIG=~/.kube/config

# Verify installation
echo -e "${BLUE}→ Verifying installation...${NC}"
if kubectl get nodes &> /dev/null; then
    echo -e "${GREEN}✓ k3s installed successfully${NC}"
    kubectl get nodes
else
    echo -e "${RED}✗ Failed to verify kubectl access${NC}"
    echo -e "${YELLOW}Try: sudo k3s kubectl get nodes${NC}"
    exit 1
fi

# Display k3s info
echo -e "\n${BLUE}k3s Information:${NC}"
echo -e "  Version: $(k3s --version)"
echo -e "  Kubeconfig: $HOME/.kube/config"
echo -e "  Service Type: Single-node cluster"
echo -e "  LoadBalancer: ServiceLB (local IP mapping)"

# Check for common services
echo -e "\n${BLUE}Checking cluster components...${NC}"
kubectl get pods -n kube-system

echo -e "\n${GREEN}✓ k3s is ready!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Run: source ~/.bashrc  # to update shell"
echo -e "  2. Run: kubectl get pods -A  # to verify cluster"
echo -e "  3. Proceed to ArgoCD installation: ./scripts/setup-argocd.sh"
