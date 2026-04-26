# Quick Start Guide

## ⚡ TL;DR - Get Running in 10 Minutes

### Prerequisites
- Ubuntu 20.04+ or WSL2 with Ubuntu
- 4GB RAM minimum
- 2GB free disk space
- Git configured with GitHub credentials

### One-Command Setup

```bash
cd /path/to/amazon-clone-k8s-eks-argocd
chmod +x scripts/*.sh
./scripts/setup-all.sh
```

Then follow the interactive prompts.

---

## 📋 Manual Step-by-Step

### Step 1: Configure GitHub Secrets (5 mins)
1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Create these 6 secrets:

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `SONAR_TOKEN` | SonarCloud token |
| `SONAR_ORGANIZATION` | SonarCloud org name |
| `SONAR_PROJECT_KEY` | SonarCloud project key |
| `GIT_TOKEN` | GitHub Personal Access Token (with repo scope) |

Compatibility note: the project also accepts legacy aliases during secret resolution (`DOCKER_USERNAME`, `DOCKER_PAT`, `SONAR_ORG`, `SONAR_PROJECT`), but the canonical names above are recommended.

### Step 2: Install k3s (2 mins)
```bash
./scripts/setup-k3s.sh
```

Verify:
```bash
kubectl get nodes
```

### Step 3: Install ArgoCD (3 mins)
```bash
./scripts/setup-argocd.sh
```

When prompted, enter your GitHub repo URL.

### Step 4: Install Monitoring (2 mins)
```bash
./scripts/setup-monitoring.sh
```

### Step 5: Verify Everything (1 min)
```bash
./scripts/test-pipeline.sh
```

### Step 6: Start Port Forwards

Open 3 terminal windows and run:

**Terminal 1 - ArgoCD:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Terminal 2 - Monitoring:**
```bash
PROM_SVC=$(kubectl get svc -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward svc/${PROM_SVC} -n monitoring 9090:9090
```

**Terminal 3 - Grafana:**
```bash
GRAFANA_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n monitoring pod/${GRAFANA_POD} 3000:3000
```

Or use the helper:
```bash
./scripts/port-forward.sh
```

---

## 🌐 Access Your Services

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| **ArgoCD** | https://localhost:8080 | admin | (from setup output) |
| **Prometheus** | http://localhost:9090 | - | - |
| **Grafana** | http://localhost:3000 | admin | admin |
| **Your App** | http://localhost:3000 | - | - |

---

## 🧪 Test the Full Pipeline

1. **Make a code change:**
   ```bash
   # Edit src/components/HeaderComp.jsx or similar
   # Change a color, text, or component
   ```

2. **Commit and push:**
   ```bash
   git add .
   git commit -m "test: verify pipeline"
   git push origin main
   ```

3. **Watch GitHub Actions:**
   - Go to your repo on GitHub
   - Click **Actions** tab
   - Watch the workflow run (3-6 minutes)

4. **Watch ArgoCD:**
   - Open ArgoCD UI
   - App should show `OutOfSync`
   - After 3 minutes, syncs to `Healthy`

5. **Check Grafana:**
   - New pod restart event appears
   - Resource usage updates

6. **Access your app:**
   ```bash
   kubectl port-forward svc/amazon-prime-app 3000:3000
   ```
   - Visit http://localhost:3000
   - You'll see your changes live!

---

## 🔍 Verify Each Component

### k3s Cluster
```bash
kubectl get nodes
kubectl get pods -A
```

### ArgoCD
```bash
kubectl get namespace argocd
kubectl get pods -n argocd
kubectl get applications -n argocd
```

### Prometheus
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
```

### Grafana
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
```

### Your App
```bash
kubectl get deployment amazon-prime-app
kubectl get svc amazon-prime-app
kubectl logs deployment/amazon-prime-app
```

---

## 🚨 Common Issues

### kubectl: command not found
```bash
export KUBECONFIG=~/.kube/config
# Or use: sudo kubectl (temporary)
```

### ArgoCD won't connect to app
```bash
# Check if app deployment exists
kubectl get deployment amazon-prime-app

# Check deployment status
kubectl describe deployment amazon-prime-app

# Check logs
kubectl logs deployment/amazon-prime-app
```

### Port-forward connection refused
```bash
# Restart the service
kubectl rollout restart deployment/amazon-prime-app

# Try a different port
kubectl port-forward svc/amazon-prime-app 3001:3000
```

### Pipeline fails on SonarCloud
- SonarCloud might need initial project setup
- Check GitHub Actions logs for exact error
- Configure continues-on-error in workflow (already set)

### No changes visible after deployment
```bash
# Force refresh app pod
kubectl delete pod -l app=amazon-prime-app

# Check new pod logs
kubectl logs deployment/amazon-prime-app
```

---

## 🧹 Cleanup

### Remove everything except k3s
```bash
./scripts/cleanup.sh
```

### Completely remove k3s
```bash
sudo /usr/local/bin/k3s-uninstall.sh
rm ~/.kube/config
```

---

## 📚 File Structure

```
.
├── .github/workflows/
│   └── build.yml                    # GitHub Actions pipeline
├── scripts/
│   ├── setup-k3s.sh                # Install k3s
│   ├── setup-argocd.sh             # Install ArgoCD
│   ├── setup-monitoring.sh         # Install Prometheus & Grafana
│   ├── setup-all.sh                # Run all setups
│   ├── test-pipeline.sh            # Verify installation
│   ├── cleanup.sh                  # Remove components
│   └── port-forward.sh             # Start port-forwards
├── k8s/
│   ├── deployment.yaml             # App deployment manifest
│   └── service.yaml                # App service manifest
├── src/                             # React app source
├── sonar-project.properties        # SonarCloud configuration
└── Dockerfile                       # Container image definition
```

---

## ✅ Success Checklist

- [ ] GitHub secrets configured (6 secrets)
- [ ] k3s installed and running
- [ ] kubectl works without sudo
- [ ] ArgoCD installed and accessible at https://localhost:8080
- [ ] Prometheus collecting metrics
- [ ] Grafana dashboard showing cluster metrics
- [ ] Made a code change and pushed to main
- [ ] GitHub Actions workflow completed successfully
- [ ] ArgoCD shows app as "Healthy"
- [ ] App accessible at http://localhost:3000
- [ ] Changes visible in running app

---

## 🎓 What You've Built

| Component | Purpose |
|-----------|---------|
| **GitHub Actions** | CI pipeline - builds, tests, scans, deploys |
| **SonarCloud** | Code quality and security analysis |
| **Trivy** | Vulnerability scanning (code + images) |
| **Docker Hub** | Container image registry |
| **k3s** | Lightweight Kubernetes cluster |
| **ArgoCD** | GitOps deployment automation |
| **Prometheus** | Metrics collection and monitoring |
| **Grafana** | Visualization and dashboards |

This is a **production-ready** DevOps setup used by real teams!

---

## 📞 Need Help?

1. Check logs: `kubectl logs deployment/amazon-prime-app`
2. Run diagnostics: `./scripts/test-pipeline.sh`
3. Review GitHub Actions output
4. Check ArgoCD UI for sync status
5. See DEVOPS_PIPELINE_SETUP.md for detailed troubleshooting

Happy DevOps-ing! 🚀
