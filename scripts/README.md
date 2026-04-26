# Scripts Reference Guide

All setup and automation scripts are located in the `scripts/` directory.

## Quick Reference

| Script | Purpose | When to Run |
|--------|---------|------------|
| `setup-all.sh` | Complete setup orchestrator | First time installation |
| `setup-k3s.sh` | Install k3s cluster | First time (part of setup-all.sh) |
| `setup-argocd.sh` | Install ArgoCD | First time (part of setup-all.sh) |
| `setup-monitoring.sh` | Install Prometheus & Grafana | First time (part of setup-all.sh) |
| `test-pipeline.sh` | Verify all components | After setup, before testing |
| `validate.sh` | Check system configuration | Troubleshooting |
| `validate-creds.sh` | Validate Sonar/GitHub/Docker credentials | Before running CI/CD |
| `port-forward.sh` | Start all port-forwards | Every session |
| `cleanup.sh` | Remove all k8s components | Reset or cleanup |

---

## Detailed Scripts

### setup-all.sh
**Interactive orchestrator that runs all setup scripts in sequence.**

```bash
./scripts/setup-all.sh
```

**Prompts you for:**
- Install k3s? (y/N)
- Install ArgoCD? (y/N)
- Install Prometheus & Grafana? (y/N)

**Output:**
- Creates all namespaces and components
- Provides access instructions
- Shows credentials and URLs

---

### setup-k3s.sh
**Installs lightweight Kubernetes distribution on your local machine.**

```bash
./scripts/setup-k3s.sh
```

**Prerequisites:**
- Ubuntu 20.04+ or WSL2 with Ubuntu
- 2+ GB RAM, 2+ CPU cores
- sudo access

**What it does:**
1. Checks OS compatibility
2. Downloads and installs k3s
3. Waits for k3s to be ready
4. Sets up kubeconfig at ~/.kube/config
5. Verifies kubectl access

**Output:**
- k3s version info
- Cluster status
- kubeconfig location

**Troubleshooting:**
- If stuck: `sudo systemctl status k3s`
- If failed: `sudo journalctl -u k3s -n 50`

---

### setup-argocd.sh
**Installs ArgoCD (GitOps deployment controller) on k3s.**

```bash
./scripts/setup-argocd.sh
```

**Prerequisites:**
- kubectl configured and working
- k3s cluster running

**Prompts for:**
- Your GitHub repository URL (e.g., https://github.com/yourusername/repo)

**What it does:**
1. Creates argocd namespace
2. Deploys ArgoCD manifests
3. Waits for pods to be ready
4. Creates ArgoCD Application pointing to your repo
5. Retrieves admin credentials

**Output:**
- ArgoCD pod status
- Admin password
- Repository configuration
- Port-forward instructions
- Access URL

**Key Configuration:**
- `k8s` path in manifests
- `main` branch
- Auto-sync enabled
- Self-heal enabled

---

### setup-monitoring.sh
**Installs Prometheus (metrics) and Grafana (visualization).**

```bash
./scripts/setup-monitoring.sh
```

**Prerequisites:**
- kubectl configured
- Helm installed (auto-installs if missing)
- k3s cluster running

**Installs:**
- Prometheus operator
- Prometheus service
- Grafana
- All dependencies

**What it does:**
1. Adds Helm repositories
2. Creates monitoring namespace
3. Installs Prometheus stack
4. Installs Grafana
5. Waits for pods to be ready
6. Provides configuration instructions

**Output:**
- Port-forward commands
- Access URLs
- Login credentials
- Configuration steps

**Configuration:**
- Prometheus retention: 24 hours
- Storage: 5GB local-path
- Grafana password: admin

---

### test-pipeline.sh
**Comprehensive validation of the entire setup.**

```bash
./scripts/test-pipeline.sh
```

**Checks:**
1. kubectl availability
2. k3s cluster connectivity
3. Git configuration
4. ArgoCD namespace and pods
5. App deployment status
6. Service availability
7. Monitoring components
8. Port availability
9. GitHub repo configuration

**Output:**
- Component status
- Pod health
- Configuration details
- Test instructions

**Use when:**
- First time after setup
- Troubleshooting
- Verifying installation before testing

---

### validate.sh
**Detailed system validation and health check.**

```bash
./scripts/validate.sh
```

**Validates:**
- System OS
- Tool availability (git, docker, kubectl, k3s)
- Kubernetes cluster
- kubeconfig
- Project files (.github, k8s/, Dockerfile, etc.)
- Automation scripts
- Runtime components (ArgoCD, Prometheus, etc.)
- Git configuration
- Port availability

**Output:**
- Color-coded results (Green=Pass, Yellow=Warning, Red=Fail)
- Summary counts
- Detailed component status
- Configuration details

**Use when:**
- Troubleshooting issues
- After major changes
- Before reporting issues

---

### validate-creds.sh
**Validates SonarCloud, GitHub, and Docker Hub credentials used by CI/CD.**

```bash
./scripts/validate-creds.sh
```

**Expected environment variables:**
- `SONAR_TOKEN`
- `SONAR_ORG`
- `SONAR_PROJECT`
- `GIT_TOKEN`
- `DOCKER_USERNAME`
- `DOCKER_PAT`

**What it checks:**
1. SonarCloud token validity
2. SonarCloud organization and project accessibility
3. GitHub token authentication
4. Docker Hub PAT authentication

**Notes:**
- Automatically loads `.env` from repo root if present.
- Prints only pass/fail status and service identity, never token values.

---

### port-forward.sh
**Starts all port-forward tunnels to local services.**

```bash
./scripts/port-forward.sh
```

**Sets up access to:**
- ArgoCD (localhost:8080)
- Prometheus (localhost:9090)
- Grafana (localhost:3000)
- Your App (localhost:3001)

**Run in dedicated terminal:**
```bash
# Terminal 1
./scripts/port-forward.sh

# Terminal 2 - Access services while port-forward runs
open https://localhost:8080  # ArgoCD
open http://localhost:3000   # Grafana
```

**Stops with:** Ctrl+C

---

### cleanup.sh
**Removes all Kubernetes components.**

```bash
./scripts/cleanup.sh
```

**Removes:**
- ArgoCD namespace and all resources
- Monitoring namespace and all resources
- App deployments and services

**Preserves:**
- k3s cluster
- kubeconfig
- Source code
- Configuration files

**Asks for confirmation:** "Are you sure you want to proceed? (yes/no)"

**Use when:**
- Resetting everything
- Starting fresh
- Before reinstalling

---

## Usage Patterns

### Fresh Installation
```bash
# Step 1: Run complete setup
./scripts/setup-all.sh

# Step 2: Verify everything
./scripts/test-pipeline.sh

# Step 3: Start port-forwards
./scripts/port-forward.sh

# Step 4: Test the pipeline (in another terminal)
# Make code changes and push to main
```

### Daily Usage
```bash
# Terminal 1: Port-forwards
./scripts/port-forward.sh

# Terminal 2: Work on code, commit, and push
# GitHub Actions runs automatically
# ArgoCD deploys automatically
# Monitor in Grafana
```

### Troubleshooting
```bash
# Run validation
./scripts/validate.sh

# Check specific component
kubectl get pods -n argocd
kubectl logs deployment/amazon-prime-app

# If problems persist
./scripts/cleanup.sh
./scripts/setup-all.sh
```

### Reset Everything
```bash
# Remove components
./scripts/cleanup.sh

# Restart k3s
sudo systemctl restart k3s

# Reinstall everything
./scripts/setup-all.sh
```

---

## Making Scripts Executable

If scripts lose execute permissions:

```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Or individual script
chmod +x scripts/setup-k3s.sh
```

---

## Script Anatomy

All scripts follow this pattern:

```bash
#!/bin/bash
set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Header
echo -e "${BLUE}=================${NC}"
echo -e "${BLUE}Script Purpose${NC}"
echo -e "${BLUE}=================${NC}"

# Check prerequisites
if ! command -v required-tool &> /dev/null; then
    echo -e "${RED}✗ Error: required-tool not found${NC}"
    exit 1
fi

# Do work
echo -e "${BLUE}→ Working...${NC}"
# ... commands ...
echo -e "${GREEN}✓ Done${NC}"

# Report results
echo -e "\n${GREEN}✓ Summary${NC}"
```

---

## Environment Variables

Scripts use these variables:

```bash
# kubectl
export KUBECONFIG=~/.kube/config

# k3s
/usr/local/bin/k3s            # Executable
/etc/rancher/k3s/k3s.yaml     # Config

# Helm
$HOME/.local/share/helm        # Cache
$HOME/.config/helm             # Config

# Git
GIT_TOKEN                       # Used in GitHub Actions
GITHUB_TOKEN                    # Default GitHub token
```

---

## Common Script Errors

### "Permission denied"
```bash
chmod +x scripts/*.sh
```

### "command not found"
```bash
# Check if tool is installed
which kubectl
which helm

# Or use full path
/usr/local/bin/k3s kubectl get nodes
```

### "Connection refused"
```bash
# k3s not running
sudo systemctl status k3s
sudo systemctl restart k3s
```

### Script hangs
- Press Ctrl+C to interrupt
- Check logs: `sudo journalctl -u k3s -n 50`
- Increase timeout or run with `timeout` command

---

## Tips & Tricks

### Run all setups non-interactively
```bash
# Automate yes responses
yes | ./scripts/setup-all.sh
```

### Run single setup step
```bash
# Skip setup-all.sh and run individual script
./scripts/setup-k3s.sh
# (in new shell)
./scripts/setup-argocd.sh
# etc
```

### Keep logs
```bash
# Save logs to file
./scripts/setup-all.sh 2>&1 | tee setup.log
```

### Dry-run validation
```bash
# See what would change without making changes
./scripts/validate.sh
```

### Get help
```bash
# Read script source
cat scripts/setup-k3s.sh | head -50

# Check for comments
grep "^#" scripts/setup-k3s.sh
```

---

## Next Steps

1. **First time:** Run `./scripts/setup-all.sh`
2. **Verify:** Run `./scripts/test-pipeline.sh`
3. **Access services:** Run `./scripts/port-forward.sh`
4. **Test pipeline:** Make code change and push to main
5. **Troubleshoot:** Run `./scripts/validate.sh`
