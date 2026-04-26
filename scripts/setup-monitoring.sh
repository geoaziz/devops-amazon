#!/bin/bash

##############################################################################
# Prometheus & Grafana Installation Script
# Sets up complete monitoring stack on k3s
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Prometheus & Grafana Setup${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ Error: kubectl not found${NC}"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo -e "${RED}✗ Error: helm not found${NC}"
    echo -e "${YELLOW}Installing Helm...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗ Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

# Add Helm repositories
echo -e "${BLUE}→ Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

# Create monitoring namespace
echo -e "${BLUE}→ Creating monitoring namespace...${NC}"
kubectl create namespace monitoring 2>/dev/null || echo -e "${YELLOW}  (namespace already exists)${NC}"

# Install Prometheus
echo -e "${BLUE}→ Installing Prometheus (this may take 1-2 minutes)...${NC}"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=24h \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=5Gi \
  --set grafana.enabled=false \
  --wait \
  --timeout 5m

echo -e "${GREEN}✓ Prometheus installed${NC}"

# Wait for Prometheus to be ready
echo -e "${BLUE}→ Waiting for Prometheus to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus \
  -n monitoring --timeout=300s 2>/dev/null || echo -e "${YELLOW}  Prometheus pods may still be starting${NC}"

# Install Grafana
echo -e "${BLUE}→ Installing Grafana...${NC}"
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --set adminPassword=admin \
  --set service.type=ClusterIP \
  --set persistence.enabled=true \
  --set persistence.size=5Gi \
  --wait \
  --timeout 5m

echo -e "${GREEN}✓ Grafana installed${NC}"

# Verify installations
echo -e "${BLUE}→ Verifying installations...${NC}"
echo -e "${BLUE}Prometheus components:${NC}"
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus

echo -e "\n${BLUE}Grafana components:${NC}"
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Get Prometheus service endpoint
PROMETHEUS_SERVICE=$(kubectl get svc -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

# Get Grafana pod for port-forward
GRAFANA_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    Access Prometheus & Grafana${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Prometheus Port-Forward:${NC}"
echo -e "  Run in a new terminal:"
echo -e "  ${GREEN}kubectl port-forward -n monitoring svc/${PROMETHEUS_SERVICE} 9090:9090${NC}"
echo -e "  Then access: ${GREEN}http://localhost:9090${NC}"

echo -e "\n${YELLOW}Grafana Port-Forward:${NC}"
echo -e "  Run in a new terminal:"
echo -e "  ${GREEN}kubectl port-forward -n monitoring pod/${GRAFANA_POD} 3000:3000${NC}"
echo -e "  Then access: ${GREEN}http://localhost:3000${NC}"

echo -e "\n${BLUE}Login Credentials (Grafana):${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}admin${NC}"
echo -e "  ${YELLOW}(Change on first login)${NC}"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}    Configure Grafana${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}After logging into Grafana (http://localhost:3000):${NC}"

echo -e "\n${GREEN}Step 1: Add Prometheus Data Source${NC}"
echo -e "  1. Click Configuration (gear icon) → Data Sources"
echo -e "  2. Click 'Add data source'"
echo -e "  3. Select 'Prometheus'"
echo -e "  4. URL: ${GREEN}http://${PROMETHEUS_SERVICE}.monitoring.svc:9090${NC}"
echo -e "  5. Click 'Save & Test'"

echo -e "\n${GREEN}Step 2: Import Kubernetes Dashboard${NC}"
echo -e "  1. Click '+' (Create) → Import"
echo -e "  2. Enter Dashboard ID: ${GREEN}3119${NC}"
echo -e "  3. Click 'Load'"
echo -e "  4. Select Prometheus as data source"
echo -e "  5. Click 'Import'"

echo -e "\n${GREEN}Step 3: View Cluster Metrics${NC}"
echo -e "  The dashboard shows:"
echo -e "    - Cluster CPU and memory usage"
echo -e "    - Pod status and resource consumption"
echo -e "    - Node performance metrics"
echo -e "    - Pod restart events"

# Create a configuration summary file
cat > /tmp/monitoring-config.txt <<EOF
Prometheus Service: ${PROMETHEUS_SERVICE}.monitoring.svc:9090
Grafana Pod: ${GRAFANA_POD}

Port-Forward Commands:
  Prometheus: kubectl port-forward -n monitoring svc/${PROMETHEUS_SERVICE} 9090:9090
  Grafana: kubectl port-forward -n monitoring pod/${GRAFANA_POD} 3000:3000

Grafana Configuration:
  Prometheus URL: http://${PROMETHEUS_SERVICE}.monitoring.svc:9090
  Dashboard ID: 3119
  Grafana Admin Password: admin
EOF

echo -e "\n${GREEN}✓ Monitoring stack setup complete!${NC}"
echo -e "${YELLOW}Configuration saved to: /tmp/monitoring-config.txt${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Open two new terminal windows for port-forwards"
echo -e "  2. Configure Grafana as shown above"
echo -e "  3. Make a code change and push to test the full pipeline"
echo -e "  4. Run: ./scripts/test-pipeline.sh"
