#!/bin/bash

# ====================================================================
# Fix Image Pull Error - Use Local Docker Image with k3s
# ====================================================================

set -e

echo "╔════════════════════════════════════════╗"
echo "║  Fix ImagePullBackOff Error            ║"
echo "║  Using Local Docker Image with k3s     ║"
echo "╚════════════════════════════════════════╝"
echo ""

# ====================================================================
# Step 1: Build Docker Image
# ====================================================================
echo "════════════════════════════════════════"
echo "STEP 1: Building Docker Image"
echo "════════════════════════════════════════"

if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile not found. Please run from project root."
    exit 1
fi

echo "📦 Building: amazon-clone-k8s-eks-argocd:latest"
docker build -t amazon-clone-k8s-eks-argocd:latest .

if [ $? -eq 0 ]; then
    echo "✅ Image built successfully"
else
    echo "❌ Docker build failed"
    exit 1
fi

echo ""

# ====================================================================
# Step 2: Load Image into k3s
# ====================================================================
echo "════════════════════════════════════════"
echo "STEP 2: Loading Image into k3s"
echo "════════════════════════════════════════"

echo "📥 Importing image to k3s..."
docker save amazon-clone-k8s-eks-argocd:latest | k3s ctr images import -

if [ $? -eq 0 ]; then
    echo "✅ Image imported to k3s"
else
    echo "❌ Image import failed"
    exit 1
fi

echo ""

# ====================================================================
# Step 3: Update Deployment to Use Local Image
# ====================================================================
echo "════════════════════════════════════════"
echo "STEP 3: Updating Deployment"
echo "════════════════════════════════════════"

echo "🔄 Patching deployment to use local image..."

kubectl patch deployment amazon-prime-app -n default \
  -p '{
    "spec": {
      "template": {
        "spec": {
          "containers": [
            {
              "name": "amazon-prime-container",
              "image": "amazon-clone-k8s-eks-argocd:latest",
              "imagePullPolicy": "Never"
            }
          ]
        }
      }
    }
  }'

if [ $? -eq 0 ]; then
    echo "✅ Deployment updated"
else
    echo "❌ Patch failed"
    exit 1
fi

echo ""

# ====================================================================
# Step 4: Wait for Pods to Start
# ====================================================================
echo "════════════════════════════════════════"
echo "STEP 4: Waiting for Pods"
echo "════════════════════════════════════════"

echo "⏳ Pods should start in 10-20 seconds..."
echo ""

# Watch the pods
kubectl get pods -n default -w &
WATCH_PID=$!

# Wait for pods to be ready
sleep 5

# Check if any pod is ready
for i in {1..30}; do
    READY=$(kubectl get deployment amazon-prime-app -n default -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" = "2" ]; then
        kill $WATCH_PID 2>/dev/null || true
        break
    fi
    sleep 2
done

echo ""
echo "════════════════════════════════════════"
echo "✅ Setup Complete!"
echo "════════════════════════════════════════"
echo ""

# Check final status
echo "Final Pod Status:"
kubectl get pods -n default
echo ""

echo "Deployment Status:"
kubectl get deployment amazon-prime-app -n default
echo ""

echo "Next Steps:"
echo "  1. Port-forward to your app:"
echo "     kubectl port-forward svc/amazon-prime-app 3000:3000"
echo ""
echo "  2. Open browser:"
echo "     http://localhost:3000"
echo ""
echo "  3. Check logs:"
echo "     kubectl logs -f deployment/amazon-prime-app -n default"
echo ""
