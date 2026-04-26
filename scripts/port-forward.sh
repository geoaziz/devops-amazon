#!/bin/bash

##############################################################################
# Port Forward Manager - Simplifies accessing all local services
##############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Port Forward Manager${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ Error: kubectl not found${NC}"
    exit 1
fi

# Function to start port-forwards
start_portforwards() {
    echo -e "${BLUE}→ Starting port-forwards...${NC}"
    
    # ArgoCD
    if kubectl get namespace argocd &> /dev/null; then
        echo -e "${YELLOW}Starting ArgoCD port-forward (8080:443)...${NC}"
        kubectl port-forward svc/argocd-server -n argocd 8080:443 &
        ARGOCD_PID=$!
        echo -e "${GREEN}✓ ArgoCD PID: ${ARGOCD_PID}${NC}"
    fi
    
    # Prometheus
    if kubectl get namespace monitoring &> /dev/null; then
        echo -e "${YELLOW}Starting Prometheus port-forward (9090:9090)...${NC}"
        PROM_SVC=$(kubectl get svc -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$PROM_SVC" ]; then
            kubectl port-forward svc/${PROM_SVC} -n monitoring 9090:9090 &
            PROM_PID=$!
            echo -e "${GREEN}✓ Prometheus PID: ${PROM_PID}${NC}"
        fi
        
        # Grafana
        echo -e "${YELLOW}Starting Grafana port-forward (3000:3000)...${NC}"
        GRAFANA_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$GRAFANA_POD" ]; then
            kubectl port-forward -n monitoring pod/${GRAFANA_POD} 3000:3000 &
            GRAFANA_PID=$!
            echo -e "${GREEN}✓ Grafana PID: ${GRAFANA_PID}${NC}"
        fi
    fi
    
    # App Service
    if kubectl get svc amazon-prime-app &> /dev/null; then
        echo -e "${YELLOW}Starting App port-forward (3000:3000)...${NC}"
        kubectl port-forward svc/amazon-prime-app 3001:3000 &
        APP_PID=$!
        echo -e "${GREEN}✓ App PID: ${APP_PID}${NC}"
    fi
    
    echo -e "\n${GREEN}✓ All port-forwards started!${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop all port-forwards${NC}"
    
    wait
}

# Function to show usage
show_usage() {
    echo -e "\n${BLUE}Available Services:${NC}"
    echo -e "  ArgoCD: ${GREEN}https://localhost:8080${NC}"
    echo -e "  Prometheus: ${GREEN}http://localhost:9090${NC}"
    echo -e "  Grafana: ${GREEN}http://localhost:3000${NC}"
    echo -e "  App: ${GREEN}http://localhost:3001${NC}"
    echo -e "\n${YELLOW}Credentials:${NC}"
    echo -e "  ArgoCD: admin / (check setup-argocd.sh output)"
    echo -e "  Grafana: admin / admin"
}

# Main
start_portforwards
show_usage
