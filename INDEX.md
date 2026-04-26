# 📖 Complete Documentation Index

Welcome to your production-grade DevOps pipeline implementation! This document maps all resources to help you navigate quickly.

---

## 🚀 Getting Started (Start Here!)

### For First-Time Setup
1. **[QUICK_START.md](QUICK_START.md)** ← **START HERE**
   - ⚡ TL;DR: Get running in 10 minutes
   - Step-by-step manual instructions
   - Expected output for each phase

2. **[GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)**
   - How to create 6 GitHub secrets
   - Step-by-step screenshots
   - Security best practices

3. **[scripts/README.md](scripts/README.md)**
   - Reference for all automation scripts
   - When to use each script
   - Troubleshooting scripts

---

## 📚 Deep Dives & Reference

### Understanding the Architecture
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Visual diagrams and component explanations
  - Complete pipeline flow
  - Component responsibilities
  - Data flow diagrams
  - GitOps principles

### Complete Setup Guide
- **[DEVOPS_PIPELINE_SETUP.md](DEVOPS_PIPELINE_SETUP.md)** - Phases 3-9 detailed
  - GitHub secrets configuration
  - k3s installation guide
  - ArgoCD setup walkthrough
  - Prometheus & Grafana installation
  - Full pipeline testing procedure

### Troubleshooting
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Problem solutions
  - 10 common issues with solutions
  - Debugging commands
  - Recovery procedures
  - Performance tuning

### Quick Command Reference
- **[COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)** - Copy-paste kubectl commands
  - Cluster management
  - Pod operations
  - Monitoring queries
  - Emergency procedures

---

## 🛠️ Automation Scripts

Located in `scripts/` directory:

| Script | Purpose | When to Use |
|--------|---------|------------|
| **setup-all.sh** | Interactive orchestrator | First installation |
| **setup-k3s.sh** | Install k3s | Part of setup-all.sh |
| **setup-argocd.sh** | Install ArgoCD | Part of setup-all.sh |
| **setup-monitoring.sh** | Install Prometheus & Grafana | Part of setup-all.sh |
| **test-pipeline.sh** | Verify installation | After setup |
| **validate.sh** | Check system config | Troubleshooting |
| **port-forward.sh** | Start port-forwards | Every session |
| **cleanup.sh** | Remove components | Reset cluster |

**[Read: scripts/README.md](scripts/README.md)** for detailed script reference.

---

## 📝 Configuration Files

### Workflow Files
- **`.github/workflows/build.yml`** - GitHub Actions CI/CD pipeline
  - Triggers on push to main
  - Runs 8 pipeline stages
  - Updates k8s manifest automatically

### Kubernetes Manifests
- **`k8s/deployment.yaml`** - Your app deployment
  - 2 replicas by default
  - Resource requests/limits
  - Health probes
  - Updated automatically by pipeline

- **`k8s/service.yaml`** - Your app service
  - LoadBalancer type (ServiceLB on k3s)
  - Port 3000 exposure

### Project Configuration
- **`sonar-project.properties`** - SonarCloud configuration
  - Project key and organization
  - Source directories
  - Coverage settings

- **`.gitignore`** - Git ignore patterns
  - Node modules, build artifacts
  - Secrets and credentials
  - Pipeline artifacts

- **`.dockerignore`** - Docker build context
  - Excludes unnecessary files
  - Speeds up Docker builds

---

## 🔐 Secrets Configuration

6 secrets required in GitHub repository:

```
DOCKERHUB_USERNAME       → Your Docker Hub username
DOCKERHUB_TOKEN         → Docker Hub access token
SONAR_TOKEN             → SonarCloud authentication
SONAR_ORGANIZATION      → SonarCloud organization
SONAR_PROJECT_KEY       → SonarCloud project key
GIT_TOKEN               → GitHub Personal Access Token
```

**Setup Guide:** [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)

---

## 📋 Complete Workflow (Phases)

### Phase 3: GitHub Secrets ✅
**Action Required:** Manual in GitHub UI
- **Guide:** [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)
- **Time:** 15 minutes
- **Deliverable:** 6 secrets configured

### Phase 4: Kubernetes Manifest ✅
**Action Required:** Already completed
- **File:** `k8s/deployment.yaml`
- **Change:** ECR URL → Docker Hub URL (`geoaziz/amazon-prime-app:latest`)
- **Status:** ✅ Done

### Phase 5: GitHub Actions Workflow ✅
**Action Required:** Already completed
- **File:** `.github/workflows/build.yml`
- **Contains:** 8-stage CI/CD pipeline
- **Status:** ✅ Done

### Phase 6: Install k3s
**Action Required:** Run script
- **Script:** `./scripts/setup-k3s.sh`
- **Alternative:** `./scripts/setup-all.sh`
- **Time:** ~3 minutes
- **Prerequisites:** Ubuntu 20.04+

### Phase 7: Install ArgoCD
**Action Required:** Run script
- **Script:** `./scripts/setup-argocd.sh`
- **Alternative:** `./scripts/setup-all.sh`
- **Time:** ~5 minutes
- **Requires:** k3s running

### Phase 8: Install Prometheus & Grafana
**Action Required:** Run script
- **Script:** `./scripts/setup-monitoring.sh`
- **Alternative:** `./scripts/setup-all.sh`
- **Time:** ~5 minutes
- **Requires:** Helm

### Phase 9: Test Full Pipeline
**Action Required:** Run test and make code change
- **Test Script:** `./scripts/test-pipeline.sh`
- **Test Action:** Push code change to main
- **Expected:** Full deployment cycle
- **Duration:** 3-6 minutes end-to-end

---

## 🎯 Success Criteria Checklist

### Setup Complete When
- [ ] GitHub secrets created (6 total)
- [ ] k3s cluster running (`kubectl get nodes` works)
- [ ] ArgoCD deployed and accessible
- [ ] Prometheus collecting metrics
- [ ] Grafana dashboard accessible
- [ ] Test validation passes (`./scripts/validate.sh`)

### Pipeline Working When
- [ ] Code change pushed to main
- [ ] GitHub Actions workflow runs automatically
- [ ] Workflow completes all 8 stages
- [ ] k8s/deployment.yaml updated with new image tag
- [ ] ArgoCD shows app as "Healthy"
- [ ] App accessible with new changes
- [ ] Grafana shows pod restart event

---

## 📖 Document Quick Links

| Need | Document | Section |
|------|----------|---------|
| **Quick start** | [QUICK_START.md](QUICK_START.md) | TL;DR |
| **Set up secrets** | [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) | All phases |
| **Understand architecture** | [ARCHITECTURE.md](ARCHITECTURE.md) | Overview |
| **Run setup scripts** | [scripts/README.md](scripts/README.md) | Script details |
| **Detailed setup guide** | [DEVOPS_PIPELINE_SETUP.md](DEVOPS_PIPELINE_SETUP.md) | Phases 3-9 |
| **Fix problems** | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Issues & solutions |
| **kubectl commands** | [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md) | Command reference |
| **See what's installed** | [This file](INDEX.md) | Full overview |

---

## 🚀 Recommended Reading Order

1. **First Time?**
   - Read: [QUICK_START.md](QUICK_START.md)
   - Understand: [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)
   - Run: `./scripts/setup-all.sh`

2. **Want to Understand More?**
   - Read: [ARCHITECTURE.md](ARCHITECTURE.md)
   - Read: [DEVOPS_PIPELINE_SETUP.md](DEVOPS_PIPELINE_SETUP.md)
   - Review: `.github/workflows/build.yml`

3. **Something Not Working?**
   - Run: `./scripts/validate.sh`
   - Check: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
   - Refer: [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)

4. **Need Specific Help?**
   - Scripts: [scripts/README.md](scripts/README.md)
   - Commands: [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)
   - Setup: [DEVOPS_PIPELINE_SETUP.md](DEVOPS_PIPELINE_SETUP.md)

---

## 📊 Tools & Technologies

```
Language:           JavaScript (React)
Containerization:   Docker
Container Registry: Docker Hub
CI/CD:              GitHub Actions
Code Quality:       SonarCloud
Security Scanning:  Trivy
Container Platform: k3s (Kubernetes)
GitOps Controller:  ArgoCD
Monitoring:         Prometheus
Visualization:      Grafana
```

---

## 🎓 Learning Paths

### DevOps Engineer
1. Understand [ARCHITECTURE.md](ARCHITECTURE.md)
2. Run `./scripts/setup-all.sh`
3. Study [DEVOPS_PIPELINE_SETUP.md](DEVOPS_PIPELINE_SETUP.md)
4. Practice commands from [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)
5. Troubleshoot issues using [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### SRE (Site Reliability Engineering)
1. Review monitoring setup in [DEVOPS_PIPELINE_SETUP.md](DEVOPS_PIPELINE_SETUP.md) Phase 8
2. Explore Prometheus queries
3. Configure Grafana dashboards
4. Set up alerts based on metrics

### Security Engineer
1. Review scanning configuration in [DEVOPS_PIPELINE_SETUP.md](DEVOPS_PIPELINE_SETUP.md) Phase 5
2. Check SonarCloud code quality rules
3. Review Trivy scanning in `.github/workflows/build.yml`
4. Understand secrets management in [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)

### Full Stack Developer
1. Start with [QUICK_START.md](QUICK_START.md)
2. Run through all phases
3. Make code changes and watch pipeline
4. Review logs in GitHub Actions
5. Monitor app in Grafana

---

## 🔧 Common Tasks

### Make a Code Change & Deploy
```bash
# 1. Edit file in src/
# 2. Commit and push
git add .
git commit -m "feature: update"
git push origin main

# 3. Watch GitHub Actions
# (in GitHub UI, Actions tab)

# 4. Check ArgoCD
https://localhost:8080

# 5. Access app
http://localhost:3000
```

### Scale Application
```bash
# 1. Edit k8s/deployment.yaml
spec:
  replicas: 5  # Was 2

# 2. Commit and push
# (ArgoCD auto-deploys)
```

### View Application Logs
```bash
kubectl logs deployment/amazon-prime-app
kubectl logs -f deployment/amazon-prime-app  # Follow
```

### Access Monitoring Dashboards
```bash
# Terminal 1
./scripts/port-forward.sh

# Terminal 2 (access while running)
open https://localhost:8080      # ArgoCD
open http://localhost:3000       # Grafana
open http://localhost:9090       # Prometheus
```

---

## 🆘 Need Help?

1. **Setup not working?**
   - Run: `./scripts/validate.sh`
   - Check: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

2. **Don't know a command?**
   - Reference: [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md)
   - Grep search: `grep "kubectl get" COMMANDS_REFERENCE.md`

3. **Understanding a component?**
   - Read: [ARCHITECTURE.md](ARCHITECTURE.md)
   - Study: Relevant section in [DEVOPS_PIPELINE_SETUP.md](DEVOPS_PIPELINE_SETUP.md)

4. **Scripts help**
   - Guide: [scripts/README.md](scripts/README.md)
   - Check: `./scripts/<script-name>.sh --help` or `head -50 scripts/<script-name>.sh`

---

## 📞 Quick Reference

| What | Where | Command |
|------|-------|---------|
| **Cluster status** | Terminal | `kubectl get nodes` |
| **App logs** | Terminal | `kubectl logs deployment/amazon-prime-app` |
| **Port forwards** | Terminal | `./scripts/port-forward.sh` |
| **Full validation** | Terminal | `./scripts/validate.sh` |
| **Setup everything** | Terminal | `./scripts/setup-all.sh` |
| **ArgoCD UI** | Browser | `https://localhost:8080` |
| **Grafana UI** | Browser | `http://localhost:3000` |
| **Prometheus UI** | Browser | `http://localhost:9090` |
| **Your app** | Browser | `http://localhost:3000` (or 3001) |

---

## 🎯 30-Second Summary

**What you've built:**
- Automated CI/CD pipeline (GitHub Actions)
- Container image management (Docker Hub)
- GitOps deployment (ArgoCD)
- Kubernetes cluster (k3s)
- Monitoring & alerts (Prometheus + Grafana)

**How it works:**
1. You push code to GitHub
2. GitHub Actions automatically builds, tests, scans, and deploys
3. ArgoCD watches Git and keeps cluster in sync
4. Prometheus monitors everything
5. Grafana visualizes metrics
6. **Result:** Fully automated DevOps pipeline

**To get started:**
```bash
./scripts/setup-all.sh
# Follow prompts
./scripts/port-forward.sh
# Then make a code change and push!
```

---

## 📚 External Resources

- **Kubernetes:** https://kubernetes.io/docs/
- **ArgoCD:** https://argo-cd.readthedocs.io/
- **k3s:** https://k3s.io/
- **Prometheus:** https://prometheus.io/docs/
- **Grafana:** https://grafana.com/docs/
- **Docker:** https://docs.docker.com/
- **GitHub Actions:** https://docs.github.com/en/actions
- **SonarCloud:** https://sonarcloud.io/explore/projects

---

## ✨ Final Notes

This is a **production-ready** setup used by real DevOps teams!

You've implemented:
- ✅ Continuous Integration
- ✅ Continuous Deployment
- ✅ GitOps principles
- ✅ Infrastructure as Code
- ✅ Monitoring & Observability
- ✅ Security scanning
- ✅ Code quality gates
- ✅ Secrets management

Congratulations! 🎉

---

**Last updated:** April 25, 2026
**Version:** 1.0
**Status:** Complete & Production-Ready
