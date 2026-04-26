# ArgoCD Complete Setup & Configuration Guide

## 🎯 What ArgoCD Does

ArgoCD is a **GitOps** tool that automatically deploys your app whenever you:
1. Push code to your GitHub repo
2. Update Kubernetes manifests in `k8s/` folder
3. Update container image tags

**Without ArgoCD**: You manually run `kubectl apply -f k8s/`  
**With ArgoCD**: It watches GitHub and auto-deploys

---

## 📊 Your Setup Status

### Current State ✅
```
✅ k3s running
✅ ArgoCD installed & all pods running
✅ Port-forwarding to localhost:8080
✅ Admin password retrieved
```

### What's Left ⏳
```
⏳ Create an ArgoCD "Application" resource
   (This tells ArgoCD where your code is & where to deploy it)
⏳ Verify deployment
⏳ Access the dashboard
```

---

## 🚀 Quick Setup (2 minutes)

### Run the Automated Script

```bash
cd /home/devmahnx/Dev/Portfolio/DevOps/amazon-clone-k8s-eks-argoCD
chmod +x scripts/setup-argocd-app.sh
./scripts/setup-argocd-app.sh https://github.com/GeoAziz/DevOps-Amazon.git main
```

**That's it!** This script will:
- ✅ Retrieve your admin password
- ✅ Create the Application resource
- ✅ Sync your deployment from GitHub
- ✅ Display access credentials

**Skip to "Access Your Services" section below after running**

---

## 🔧 Manual Setup (if you prefer step-by-step)

### Step 1: Get Admin Credentials
```bash
# Get the password
kubectl get secret argocd-initial-admin-secret \
  -n argocd -o jsonpath="{.data.password}" | base64 -d
echo ""  # newline for clarity
```

**Save this password!** You'll need it to login.

### Step 2: Create the Application Resource

Create this file as `argocd-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: amazon-prime-app
  namespace: argocd
spec:
  project: default
  
  # Where to find your manifests (your GitHub repo)
  source:
    repoURL: https://github.com/GeoAziz/DevOps-Amazon.git
    targetRevision: main
    path: k8s  # This folder contains deployment.yaml & service.yaml
  
  # Where to deploy them (your k3s cluster)
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  
  # Auto-sync settings
  syncPolicy:
    # Automatically sync when repo changes
    automated:
      prune: true      # Delete resources that were removed from repo
      selfHeal: true   # Fix drift (if someone manually changes resources)
    
    syncOptions:
      - CreateNamespace=true
    
    # Retry logic if sync fails
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### Step 3: Apply It
```bash
kubectl apply -f argocd-app.yaml
```

### Step 4: Verify It's Working
```bash
# Check application status
kubectl get application -n argocd
argocd app get amazon-prime-app
```

Look for:
- `STATUS: Synced` ✅
- `HEALTH: Healthy` ✅

---

## 🌐 Access Your Services

Once setup is complete:

### 1️⃣ ArgoCD Dashboard
```
🔗 URL: https://localhost:8080
👤 Username: admin
🔑 Password: (from Step 1 above)
```

**What you'll see:**
- Your "amazon-prime-app" application
- Real-time sync status
- Deployment logs
- Resource health

### 2️⃣ Your Application
```bash
# In a new terminal, run:
kubectl port-forward svc/amazon-prime-app 3000:3000
```
Then visit: `http://localhost:3000`

### 3️⃣ Monitor Logs
```bash
# Watch real-time deployment
kubectl logs -f -n argocd deployment/argocd-application-controller

# Check if pods are running
kubectl get pods -n default
kubectl describe pod <pod-name> -n default
```

---

## 📝 Field Explanation

### Application Spec

| Field | What It Means | Your Value |
|-------|---------------|-----------|
| `name` | Name of this app in ArgoCD | `amazon-prime-app` |
| `namespace` | Where to store the app config | `argocd` (don't change) |
| `repoURL` | Your GitHub repo URL | `https://github.com/GeoAziz/DevOps-Amazon.git` |
| `targetRevision` | Which branch to watch | `main` |
| `path` | Folder with K8s manifests | `k8s/` |
| `destination.server` | Kubernetes cluster to deploy to | `https://kubernetes.default.svc` (local cluster) |
| `destination.namespace` | Where to deploy your app | `default` |
| `automated.prune` | Delete old resources | `true` |
| `automated.selfHeal` | Auto-fix drift | `true` |

---

## 🔄 GitOps Workflow (How It Works)

### Scenario: You Update Your App

```
1. Edit src/components/App.jsx
2. Build new Docker image → geoaziz/amazon-prime-app:v2
3. Update k8s/deployment.yaml with new image tag
4. Push to GitHub (main branch)
   ⬇️
5. ArgoCD detects change (polls every 3 minutes)
   ⬇️
6. ArgoCD reads your k8s/ manifests from GitHub
   ⬇️
7. ArgoCD applies them to the cluster
   ⬇️
8. New pods spawn with v2 image
   ⬇️
9. Old pods are terminated
   ⬇️
10. Your app updates with ZERO downtime ✨
```

---

## ❌ Troubleshooting

### "Application shows as OutOfSync"
```bash
# Force sync
argocd app sync amazon-prime-app

# Or use the dashboard: click the app → SYNC button
```

### "Pods not deploying"
```bash
# Check application events
kubectl get application amazon-prime-app -n argocd -o yaml | grep -A 10 status

# Check pod logs
kubectl logs -f deployment/amazon-prime-app -n default
kubectl describe pod <pod-name> -n default
```

### "Image pull errors"
Make sure your image exists in Docker Hub: `docker pull geoaziz/amazon-prime-app:latest`

### "Can't access ArgoCD dashboard"
```bash
# Make sure port-forward is running
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Should output: "Forwarding from 127.0.0.1:8080 -> 8080"
```

---

## 📚 What Changes Should Trigger ArgoCD Deploy

ArgoCD auto-syncs when you change **any of these files** and push to GitHub:

```
k8s/
├── deployment.yaml    ← Change image, replicas, resources
├── service.yaml       ← Change ports, type
```

✅ **Changes that trigger auto-deploy:**
- Image tag: `geoaziz/amazon-prime-app:latest` → `v2.0`
- Replicas: 2 → 3
- Port changes
- Resource limits
- Environment variables

❌ **Changes that DON'T trigger deploy (still applied manually):**
- Pipeline scripts in `pipeline_script/`
- Terraform in `terraform/`
- Source code in `src/` (unless you rebuild the Docker image)

---

## 🎓 Learn More

```bash
# View application in ArgoCD CLI
argocd app get amazon-prime-app

# Watch sync progress
argocd app wait amazon-prime-app

# View sync history
argocd app history amazon-prime-app

# Get application details
kubectl get application amazon-prime-app -n argocd -o yaml
```

---

## ✅ Verification Checklist

- [ ] Port-forward running: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- [ ] Can access https://localhost:8080
- [ ] Can login with admin password
- [ ] See "amazon-prime-app" in dashboard
- [ ] Application shows "Synced" status
- [ ] Pods are "Running": `kubectl get pods -n default`
- [ ] Can access app at `http://localhost:3000`
