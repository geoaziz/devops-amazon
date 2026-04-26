#!/bin/bash

# ====================================================================
# Quick Access Script - Get all credentials and connections at once
# ====================================================================

set -e

ARGOCD_NS="argocd"
MONITORING_NS="monitoring"

echo "╔════════════════════════════════════════╗"
echo "║  DevOps Environment Quick Access      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# ====================================================================
# ArgoCD Credentials
# ====================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📘 ArgoCD Dashboard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NS &>/dev/null; then
    ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NS -o jsonpath="{.data.password}" | base64 -d)
    echo "🔗 URL:      https://localhost:8080"
    echo "👤 Username: admin"
    echo "🔑 Password: $ARGOCD_PASSWORD"
else
    echo "⚠️  ArgoCD secret not found"
fi

echo ""

# ====================================================================
# Prometheus
# ====================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Prometheus Monitoring"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PROM_SVC=$(kubectl get svc -n $MONITORING_NS -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "Not found")

if [ "$PROM_SVC" != "Not found" ]; then
    echo "🔗 URL:     http://localhost:9090"
    echo "📝 Command: kubectl port-forward svc/$PROM_SVC -n $MONITORING_NS 9090:9090"
else
    echo "⚠️  Prometheus service not found (monitoring not installed?)"
fi

echo ""

# ====================================================================
# Grafana
# ====================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 Grafana Dashboards"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

GRAFANA_POD=$(kubectl get pods -n $MONITORING_NS -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "Not found")

if [ "$GRAFANA_POD" != "Not found" ]; then
    echo "🔗 URL:      http://localhost:3000"
    echo "👤 Username: admin"
    echo "🔑 Password: admin"
    echo "📝 Command: kubectl port-forward -n $MONITORING_NS pod/$GRAFANA_POD 3000:3000"
else
    echo "⚠️  Grafana pod not found (monitoring not installed?)"
fi

echo ""

# ====================================================================
# Your Application
# ====================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎬 Amazon Prime Clone App"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if kubectl get svc amazon-prime-app -n default &>/dev/null; then
    echo "🔗 URL:     http://localhost:3000"
    echo "📝 Command: kubectl port-forward svc/amazon-prime-app -n default 3000:3000"
else
    echo "⚠️  App not deployed yet. Run setup-argocd-app.sh to deploy it"
fi

echo ""

# ====================================================================
# Useful Commands
# ====================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Useful Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "Check everything is running:"
echo "  kubectl get pods -A"
echo ""
echo "Check ArgoCD application status:"
echo "  argocd app get amazon-prime-app"
echo "  kubectl get application amazon-prime-app -n argocd"
echo ""
echo "Watch pod logs:"
echo "  kubectl logs -f deployment/amazon-prime-app -n default"
echo ""
echo "Describe application for troubleshooting:"
echo "  kubectl describe pod <pod-name> -n default"
echo ""

# ====================================================================
# Automated Port-Forward
# ====================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ Quick Setup All Port-Forwards:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run this in another terminal to start all port-forwards:"
echo "  ./scripts/port-forward.sh"
echo ""
