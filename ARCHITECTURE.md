# DevOps Pipeline Architecture & Implementation

## 📐 Complete Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Your Local Machine                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐                                                       │
│  │  Your Code   │  ← Edit src/, commit to main                          │
│  └──────┬───────┘                                                       │
│         │                                                               │
│         └──→ Git Push to GitHub                                         │
│              │                                                          │
└──────────────┼──────────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    GitHub (Cloud)                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Repository Push                                                        │
│  └─→ Triggers GitHub Actions Workflow (.github/workflows/build.yml)    │
│      │                                                                 │
│      ├─ Checkout Code                                                  │
│      ├─ Install Dependencies (npm install)                             │
│      ├─ SonarCloud Analysis (static code quality)                      │
│      ├─ Trivy Filesystem Scan (source code vulnerabilities)            │
│      ├─ Build Docker Image (with versioning)                           │
│      ├─ Trivy Image Scan (container vulnerabilities)                   │
│      ├─ Push to Docker Hub (geoaziz/amazon-prime-app:N)               │
│      └─ Update k8s/deployment.yaml + Commit                           │
│                                                                         │
│  Push manifest change back to repo                                      │
│  └─→ Triggers ArgoCD via webhook                                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     Docker Hub (Registry)                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Stores: geoaziz/amazon-prime-app:latest                               │
│          geoaziz/amazon-prime-app:123                                  │
│          (versioned container images)                                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              k3s Kubernetes Cluster (Your Machine)                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │ ArgoCD Namespace (argocd)                                       │  │
│  │ ┌─────────────┐    ┌──────────────┐    ┌──────────────┐       │  │
│  │ │ ArgoCD      │    │ ArgoCD       │    │ ArgoCD       │       │  │
│  │ │ Server      │←──→│ Controller   │←──→│ Dex (Auth)   │       │  │
│  │ └─────────────┘    └──────────────┘    └──────────────┘       │  │
│  │                                                                 │  │
│  │  Watches: https://github.com/user/repo/k8s                    │  │
│  │  On change: Deploy/Update applications                        │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                               │                                        │
│                               ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │ Default Namespace (Applications)                                │  │
│  │ ┌────────────────────────────────────────────────────────────┐ │  │
│  │ │ Deployment: amazon-prime-app                              │ │  │
│  │ │ ├─ Pod 1: amazon-prime-app-xyz1 (Running)                │ │  │
│  │ │ └─ Pod 2: amazon-prime-app-xyz2 (Running)                │ │  │
│  │ │                                                            │ │  │
│  │ │ Service: amazon-prime-app:3000                           │ │  │
│  │ │ Type: LoadBalancer (maps to localhost via ServiceLB)     │ │  │
│  │ └────────────────────────────────────────────────────────────┘ │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                               │                                        │
│                               ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │ Monitoring Namespace (monitoring)                               │  │
│  │ ┌──────────────────────┐  ┌──────────────────────────────────┐ │  │
│  │ │ Prometheus           │  │ Grafana                          │ │  │
│  │ │ ├─ Pod               │  │ ├─ Pod                           │ │  │
│  │ │ ├─ Service:9090      │  │ ├─ Service:3000                  │ │  │
│  │ │ └─ Data: metrics     │  │ ├─ Dashboard: K8s Metrics (3119) │ │  │
│  │ │                      │  │ └─ Alerts: Configured            │ │  │
│  │ └──────────────────────┘  └──────────────────────────────────┘ │  │
│  │      ▲                                  ▲                        │  │
│  │      └──────────────────────────────────┘                       │  │
│  │           Scrapes metrics from Kubernetes API                   │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Complete Pipeline Flow

### 1. Code Change
```
You (Local) → Edit file in src/
           → git commit -m "feature: update UI"
           → git push origin main
```

### 2. GitHub Actions Triggers
```
GitHub → Detects push to main
      → Starts workflow from .github/workflows/build.yml
      → Allocates Ubuntu runner
      → Executes 8+ pipeline steps (3-6 minutes)
```

### 3. Build & Scan Phase
```
GitHub Actions
├─ Checkout code
├─ npm install
├─ SonarCloud scan (code quality)
├─ Trivy filesystem scan (vulnerabilities)
├─ Build Docker image (both latest + numbered tag)
├─ Trivy image scan (container vulnerabilities)
├─ Publish to Docker Hub
└─ Update k8s/deployment.yaml with new image tag
```

### 4. GitOps Deployment Phase
```
GitHub Actions → Commits manifest change with new image tag
             → Pushes back to main branch
             ↓
ArgoCD (watching k8s/ folder) → Detects change
                              → Compares actual ≠ desired state
                              → Status: OutOfSync
                              ↓
ArgoCD auto-sync → Pulls new image from Docker Hub
                 → Kills old pods
                 → Deploys new pods with new image
                 → Waits for readiness
                 → Status: Healthy
```

### 5. Observability Phase
```
Prometheus → Collects metrics from Kubernetes
          → Stores time-series data
          ↓
Grafana → Queries Prometheus
        → Displays dashboard (ID: 3119)
        → Shows pod restart event
        → Shows resource usage change
```

### 6. Access Your App
```
You (Local) → kubectl port-forward svc/amazon-prime-app 3000:3000
           → Open http://localhost:3000
           → See your changes live!
```

---

## 📊 Component Responsibilities

| Component | Role | Trigger | Output |
|-----------|------|---------|--------|
| **GitHub Actions** | CI Pipeline | Push to main | Docker image + manifest update |
| **SonarCloud** | Code Quality | GitHub Actions | Quality gate report |
| **Trivy** | Security Scan | GitHub Actions | Vulnerability report |
| **Docker Hub** | Image Registry | GitHub Actions | Stored container image |
| **ArgoCD** | GitOps Controller | Manifest change | Running pods in k3s |
| **k3s** | Container Orchestration | ArgoCD | Running application |
| **Prometheus** | Metrics Collection | Kubernetes API | Time-series data |
| **Grafana** | Visualization | Prometheus queries | Dashboards |

---

## 🔐 Authentication & Secrets Flow

```
┌─────────────────────────────────────────────────────┐
│         GitHub Secrets (Encrypted)                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  DOCKERHUB_USERNAME   ──┐                           │
│  DOCKERHUB_TOKEN      ──┼─→ Docker Push            │
│                         │                           │
│  SONAR_TOKEN          ──┼─→ SonarCloud Analysis    │
│  SONAR_ORGANIZATION   ──┤                           │
│  SONAR_PROJECT_KEY    ──┘                           │
│                                                     │
│  GIT_TOKEN            ──→ Git Push (manifest)      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 Success Criteria

A successful pipeline run looks like:

```
✓ GitHub Actions Workflow
  ✓ Checkout code
  ✓ Install dependencies
  ✓ SonarCloud scan (warning or pass)
  ✓ Trivy filesystem scan (continuing)
  ✓ Docker build successful
  ✓ Trivy image scan (continuing)
  ✓ Docker push to hub.docker.com successful
  ✓ Manifest update pushed to main
  
✓ ArgoCD
  ✓ Application detected manifest change
  ✓ Sync initiated
  ✓ New image pulled from Docker Hub
  ✓ Pods terminated
  ✓ New pods started
  ✓ Application status: Healthy
  
✓ Grafana
  ✓ Pod restart event visible
  ✓ Resource metrics updated
  
✓ Your App
  ✓ Changes visible at http://localhost:3000
```

---

## 🛠️ Component Installation Order

1. **k3s** - Must be first (provides Kubernetes)
2. **ArgoCD** - Watches repository, deploys apps
3. **Prometheus & Grafana** - Monitors the system
4. **Your App** - Deployed by ArgoCD

---

## 📈 Data Flow

```
Application → Prometheus (scrapes metrics)
           → Time-series database
           → Grafana (displays)
           → Dashboard (visualizes)

Also tracked:
- Pod events (restarts, creation)
- Resource usage (CPU, memory)
- Network traffic
- Container logs
```

---

## 🚀 Scaling & Customization

### Increase Replicas
```yaml
# k8s/deployment.yaml
spec:
  replicas: 5  # Was 2, now 5
```
→ ArgoCD syncs → 5 pods run

### Change Image
```yaml
# k8s/deployment.yaml
image: geoaziz/amazon-prime-app:v2.0.0
```
→ Push → GitHub Actions builds v2.0.0 → ArgoCD deploys

### Add Another Service
```yaml
# k8s/my-service.yaml (new file)
apiVersion: v1
kind: Service
name: my-service
...
```
→ Commit → ArgoCD deploys automatically

---

## 🔄 GitOps Principles in Action

1. **Source of Truth:** GitHub repository (k8s/ folder)
2. **Declarative:** "This is what should run" (manifests)
3. **Automatic:** ArgoCD continuously enforces desired state
4. **Versioned:** Every change tracked in Git
5. **Auditable:** Git history shows all deployments

---

## 📊 Monitoring Metrics Captured

| Metric | Source | Frequency | Purpose |
|--------|--------|-----------|---------|
| CPU Usage | Kubernetes API | 15s | Detect overload |
| Memory Usage | Kubernetes API | 15s | Detect memory issues |
| Pod Count | Kubernetes API | 30s | Track replicas |
| Pod Restarts | Kubernetes API | 30s | Detect crashes |
| Network Traffic | kubelet | 30s | Monitor bandwidth |
| Requests/Sec | App metrics | 1m | Traffic volume |

---

## 🎓 What Each Phase Teaches

| Phase | DevOps Concept | What You Learn |
|-------|---|---|
| GitHub Actions | CI Automation | Pipelines, versioning, testing |
| SonarCloud | Quality Gates | Code standards, security rules |
| Trivy | Security Scanning | Vulnerability management |
| Docker | Containerization | Image building, tagging, registry |
| ArgoCD | GitOps | Declarative infrastructure, automation |
| k3s | Kubernetes | Container orchestration, manifests |
| Prometheus | Monitoring | Metrics collection, time-series DB |
| Grafana | Observability | Dashboard design, visualization |

---

## 🔗 How Secrets Protect You

```
❌ BAD: Store credentials in code
  docker login -u "myusername" -p "mytoken"

✅ GOOD: Use GitHub Secrets
  docker login -u ${{ secrets.DOCKERHUB_USERNAME }} -p ${{ secrets.DOCKERHUB_TOKEN }}
  
Benefits:
- Credentials never appear in logs
- Encrypted at rest in GitHub
- Can be rotated without changing code
- Different projects can have different tokens
- Can audit token usage in each service
```

---

## 📞 Troubleshooting Quick Map

| Symptom | Likely Cause | Command to Check |
|---------|--------------|------------------|
| Workflow fails at Docker push | Bad credentials | Check DOCKERHUB_TOKEN in secrets |
| App stuck in ImagePullBackOff | Image not in Docker Hub | `kubectl logs -l app=amazon-prime-app` |
| ArgoCD stuck OutOfSync | Git token expired | `kubectl describe app amazon-prime-app -n argocd` |
| Pod not starting | Resource limits exceeded | `kubectl describe pod <pod-name>` |
| Metrics not in Grafana | Prometheus not scraping | `kubectl logs -n monitoring prometheus-0` |
| Port-forward fails | Port in use | `lsof -i :8080` |

---

## 🎯 Next Steps After Setup

1. **Understand the flow:** Make a small change and watch the entire pipeline
2. **Customize:** Update k8s/deployment.yaml (replicas, resources, etc.)
3. **Add monitoring:** Configure custom alerts in Grafana
4. **Extend:** Add more services/deployments
5. **Scale:** Increase replicas or add node capacity
6. **Secure:** Review and rotate tokens regularly

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## ✨ You've Built

A **production-grade DevOps pipeline** that:
- ✅ Automatically builds and tests on every commit
- ✅ Scans for code quality and security vulnerabilities
- ✅ Packages as Docker images with versioning
- ✅ Deploys to Kubernetes automatically (GitOps)
- ✅ Monitors with Prometheus and Grafana
- ✅ Requires zero manual deployment steps
- ✅ Keeps audit trail in Git
- ✅ Scales horizontally with pod replicas

This exact architecture is used by real DevOps teams! 🚀
