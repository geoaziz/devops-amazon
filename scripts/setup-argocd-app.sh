#!/bin/bash

# ====================================================================
# ArgoCD Application Setup Script
# Configures ArgoCD to deploy your Amazon Clone app from GitHub
# ====================================================================

set -e

REPO_URL="${1:-https://github.com/GeoAziz/DevOps-Amazon.git}"
REPO_BRANCH="${2:-main}"
NAMESPACE="default"
APP_NAME="amazon-prime-app"

echo "╔════════════════════════════════════════╗"
echo "║  ArgoCD Application Setup              ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  Repository URL: $REPO_URL"
echo "  Branch: $REPO_BRANCH"
echo "  App Namespace: $NAMESPACE"
echo "  App Name: $APP_NAME"
echo ""

# ====================================================================
# Step 1: Get ArgoCD Admin Password
# ====================================================================
echo "════════════════════════════════════════"
echo "STEP 1: Retrieving ArgoCD Admin Password"
echo "════════════════════════════════════════"

PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
ARGOCD_SERVER="localhost:8080"

echo "✓ Admin Password: $PASSWORD"
echo "✓ ArgoCD Server: https://$ARGOCD_SERVER"
echo ""

# ====================================================================
# Step 2: Create Application Manifest
# ====================================================================
echo "════════════════════════════════════════"
echo "STEP 2: Creating ArgoCD Application"
echo "════════════════════════════════════════"

cat > /tmp/argocd-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: amazon-prime-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: REPO_URL_PLACEHOLDER
    targetRevision: BRANCH_PLACEHOLDER
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
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

# Replace placeholders
sed -i "s|REPO_URL_PLACEHOLDER|$REPO_URL|g" /tmp/argocd-app.yaml
sed -i "s|BRANCH_PLACEHOLDER|$REPO_BRANCH|g" /tmp/argocd-app.yaml

echo "✓ Application manifest created"
echo ""

# ====================================================================
# Step 3: Apply the Application
# ====================================================================
echo "════════════════════════════════════════"
echo "STEP 3: Deploying Application to ArgoCD"
echo "════════════════════════════════════════"

kubectl apply -f /tmp/argocd-app.yaml

echo "✓ Application created successfully"
echo ""

# ====================================================================
# Step 4: Wait for sync
# ====================================================================
echo "════════════════════════════════════════"
echo "STEP 4: Waiting for Initial Sync"
echo "════════════════════════════════════════"

echo "⏳ Waiting for ArgoCD to sync the application..."
sleep 5

# Wait for the application to complete sync
for i in {1..30}; do
  STATUS=$(kubectl get application amazon-prime-app -n argocd -o jsonpath='{.status.operationState.phase}' 2>/dev/null || echo "Unknown")
  
  if [ "$STATUS" = "Succeeded" ] || [ "$STATUS" = "Unknown" ]; then
    break
  fi
  
  echo -n "."
  sleep 2
done

echo ""
echo "✓ Application deployed"
echo ""

# ====================================================================
# Step 5: Display Summary
# ====================================================================
echo "════════════════════════════════════════"
echo "✅ SETUP COMPLETE!"
echo "════════════════════════════════════════"
echo ""
echo "📊 ACCESS YOUR SERVICES:"
echo ""
echo "1️⃣  ArgoCD Dashboard:"
echo "   URL: https://localhost:8080"
echo "   Username: admin"
echo "   Password: $PASSWORD"
echo ""
echo "2️⃣  Your Application:"
echo "   Command: kubectl port-forward svc/amazon-prime-app 3000:3000"
echo "   URL: http://localhost:3000"
echo ""
echo "3️⃣  Check Application Status:"
echo "   kubectl get application amazon-prime-app -n argocd"
echo "   argocd app get amazon-prime-app"
echo ""

# ====================================================================
# Step 6: Display Application Details
# ====================================================================
echo "════════════════════════════════════════"
echo "Application Details:"
echo "════════════════════════════════════════"

kubectl get application amazon-prime-app -n argocd -o jsonpath='{
  "Name: ", .metadata.name, "\n",
  "Status: ", .status.operationState.phase, "\n",
  "Repo: ", .spec.source.repoURL, "\n",
  "Branch: ", .spec.source.targetRevision, "\n",
  "Namespace: ", .spec.destination.namespace, "\n"
}'

echo ""
echo "📝 Next Steps:"
echo "   1. Open https://localhost:8080 in your browser"
echo "   2. Login with admin / $PASSWORD"
echo "   3. View the 'amazon-prime-app' application"
echo "   4. Make changes to k8s/ files and push to GitHub"
echo "   5. ArgoCD will auto-sync within 3 minutes"
echo ""
