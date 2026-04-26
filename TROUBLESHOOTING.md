# Troubleshooting Guide

## General Diagnostics

### Run Full Validation
```bash
./scripts/validate.sh
```

This checks all critical components and provides detailed status.

---

## Common Issues & Solutions

### 1. kubectl: command not found

**Symptoms:**
- `kubectl: command not found`
- `sudo kubectl get nodes` works, but `kubectl get nodes` doesn't

**Solutions:**

Option A - Set KUBECONFIG:
```bash
export KUBECONFIG=~/.kube/config
# Add to ~/.bashrc to persist
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
source ~/.bashrc
```

Option B - Use sudo:
```bash
alias kubectl='sudo kubectl'
# Add to ~/.bashrc to persist
echo "alias kubectl='sudo kubectl'" >> ~/.bashrc
```

Option C - Fix permissions:
```bash
sudo chown $USER ~/.kube/config
sudo chmod 600 ~/.kube/config
```

---

### 2. Kubernetes Cluster Not Accessible

**Symptoms:**
- `The connection to the server localhost:6443 was refused`
- `Unable to connect to server`

**Diagnosis:**
```bash
# Check if k3s service is running
sudo systemctl status k3s

# Check logs
sudo journalctl -u k3s -n 50
```

**Solutions:**

Restart k3s:
```bash
sudo systemctl restart k3s
sleep 10
kubectl get nodes
```

Or reinstall k3s:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
./scripts/setup-k3s.sh
```

---

### 3. ArgoCD Pod Stuck in Pending

**Symptoms:**
- `kubectl get pods -n argocd` shows pods in `Pending`
- ArgoCD UI not accessible

**Diagnosis:**
```bash
# Check pod status
kubectl describe pod -n argocd <pod-name>

# Check resource requests
kubectl get resourcequota -A
```

**Solutions:**

Option A - Check k3s capacity:
```bash
kubectl top nodes
kubectl top pods -n argocd
```

Option B - Delete and reinstall:
```bash
kubectl delete namespace argocd
./scripts/setup-argocd.sh
```

---

### 4. GitHub Actions Workflow Fails

**Symptoms:**
- Workflow shows red X in Actions tab
- Build step fails

**Diagnosis:**
1. Click on the failed workflow run
2. Expand each step to see detailed output
3. Check for common errors

**Common Failures:**

#### SonarCloud Fails
```
Error: Invalid sonar.projectKey or sonar.organization
```
**Solution:**
- Verify secrets in GitHub: `SONAR_TOKEN`, `SONAR_ORGANIZATION`, `SONAR_PROJECT_KEY`
- Check project exists in SonarCloud
- Regenerate token if expired

#### Docker Login Fails
```
Error: authentication failed, status: 401 Unauthorized
```
**Solution:**
- Verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are correct
- Check token hasn't expired
- Regenerate token: Docker Hub → Account Settings → Security → New Access Token

#### Manifest Update Fails
```
Error: Failed to commit changes
```
**Solution:**
- Verify `GIT_TOKEN` has repo write permissions
- Check token hasn't expired
- Regenerate if needed

#### Trivy Scan Fails
```
trivy: command not found
```
**Solution:**
- This usually continues safely (continue-on-error is set)
- If blocking, ensure Docker Hub image is available

---

### 5. App Not Deploying

**Symptoms:**
- Pod stuck in `ImagePullBackOff`
- Deployment replicas show 0/2 Ready

**Diagnosis:**
```bash
# Check pod status
kubectl describe pod -l app=amazon-prime-app

# Check logs
kubectl logs deployment/amazon-prime-app

# Check image availability
kubectl get deployment amazon-prime-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

**Solutions:**

Option A - Verify image exists:
```bash
# Check Docker Hub
docker pull geoaziz/amazon-prime-app:latest

# Or in workflow output, ensure push succeeded
```

Option B - Check manifest:
```bash
cat k8s/deployment.yaml | grep image
```

Option C - Force pod restart:
```bash
kubectl delete pod -l app=amazon-prime-app
# New pod will pull image
```

---

### 6. Port Forward Connection Refused

**Symptoms:**
- `Unable to forward port`
- `Address already in use`

**Diagnosis:**
```bash
# Check which process uses the port
sudo lsof -i :8080

# Or try netstat
sudo netstat -tlnp | grep 8080
```

**Solutions:**

Option A - Use different port:
```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
# Access at https://localhost:8081
```

Option B - Kill existing process:
```bash
# Find PID from lsof output
sudo kill -9 <PID>

# Restart port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Option C - Restart the service:
```bash
kubectl rollout restart deployment/argocd-server -n argocd
sleep 5
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

### 7. ArgoCD Application Stuck "OutOfSync"

**Symptoms:**
- ArgoCD UI shows app as `OutOfSync` for >5 minutes
- Auto-sync not working

**Diagnosis:**
```bash
# Check application status
kubectl describe application amazon-prime-app -n argocd

# Check sync status
kubectl get application amazon-prime-app -n argocd -o jsonpath='{.status.sync.status}'

# Check if auto-sync is enabled
kubectl get application amazon-prime-app -n argocd -o jsonpath='{.spec.syncPolicy.automated}'
```

**Solutions:**

Option A - Manual sync:
```bash
# In ArgoCD UI, click app → Sync button
# Or via CLI:
argocd app sync amazon-prime-app
```

Option B - Check repository access:
```bash
# Verify repo URL is correct
kubectl get application amazon-prime-app -n argocd -o jsonpath='{.spec.source.repoURL}'

# Try SSHKey or Token authentication in ArgoCD
```

Option C - Recreate application:
```bash
kubectl delete application amazon-prime-app -n argocd
./scripts/setup-argocd.sh
```

---

### 8. Prometheus/Grafana Pod Issues

**Symptoms:**
- Prometheus pods not starting
- Grafana stuck in `Pending`

**Diagnosis:**
```bash
# Check monitoring namespace
kubectl get all -n monitoring

# Check for errors
kubectl describe pod -n monitoring prometheus-0

# Check PVC status (may need persistent volume)
kubectl get pvc -n monitoring
```

**Solutions:**

Option A - Check storage:
```bash
# k3s includes local storage
kubectl get storageclass

# If not available, create it:
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=local-path
```

Option B - Reduce resource requests:
```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.resources.requests.memory="256Mi"
```

Option C - Reinstall monitoring:
```bash
kubectl delete namespace monitoring
./scripts/setup-monitoring.sh
```

---

### 9. No Changes Visible After Deployment

**Symptoms:**
- Changed code but changes not showing in browser
- Old image still running

**Diagnosis:**
```bash
# Check what image is running
kubectl get deployment amazon-prime-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check current pods
kubectl get pods -l app=amazon-prime-app

# Check logs for startup errors
kubectl logs -l app=amazon-prime-app
```

**Solutions:**

Option A - Force refresh:
```bash
# Delete pods to pull new image
kubectl delete pod -l app=amazon-prime-app

# Check they restart with new image
kubectl get pods -l app=amazon-prime-app -w
```

Option B - Verify manifest was updated:
```bash
# Pull latest from git
git pull origin main

# Check deployment.yaml
cat k8s/deployment.yaml | grep image
```

Option C - Check browser cache:
```bash
# Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)
```

---

### 10. GitHub Actions Stuck Running

**Symptoms:**
- Workflow running for 30+ minutes
- One step not completing

**Diagnosis:**
1. Click into the running workflow
2. Check which step is running
3. Look for timeout or hanging process

**Solutions:**

Option A - Cancel and retry:
```bash
# In GitHub UI: Click "Cancel workflow"
# Then push again to retry
```

Option B - Check step logs:
```bash
# See what the step is doing
# Common culprits:
# - npm install taking too long (node_modules caching issue)
# - Docker build failing silently
# - Scanning taking too long
```

Option C - Increase timeouts:
```yaml
# In .github/workflows/build.yml, add:
- name: Long Running Step
  timeout-minutes: 15
  run: ...
```

---

## Recovery Commands

### Start Fresh (Complete Reset)

```bash
# 1. Remove everything
./scripts/cleanup.sh

# 2. Restart k3s
sudo systemctl restart k3s

# 3. Reinstall everything
./scripts/setup-all.sh

# 4. Verify
./scripts/validate.sh
```

### Quick Restart

```bash
# Just restart components without full reinstall
kubectl rollout restart deployment -n argocd
kubectl rollout restart deployment -n monitoring
kubectl rollout restart deployment amazon-prime-app
```

### Clear Logs

```bash
# Clear kubectl logs (rebuild from pod events)
# Note: kubectl doesn't store historical logs, only current pod
```

### Force Garbage Collection

```bash
# k3s cleanup
sudo k3s crictl rmi -f

# Clear old containers
sudo k3s crictl rm -f $(sudo k3s crictl ps -a -q)
```

---

## Debugging Commands

### Cluster Health

```bash
# Node status
kubectl get nodes
kubectl describe node

# Pod status
kubectl get pods -A
kubectl get events -A --sort-by='.lastTimestamp'

# Resource usage
kubectl top nodes
kubectl top pods -A
```

### Service & Networking

```bash
# Service endpoints
kubectl get svc -A
kubectl get endpoints -A

# DNS resolution (from pod)
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup argocd-server.argocd.svc.cluster.local

# Port connectivity (from pod)
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090
```

### Logs & Events

```bash
# Pod logs
kubectl logs pod/argocd-server-* -n argocd
kubectl logs deployment/amazon-prime-app
kubectl logs -l app=amazon-prime-app --tail=50 -f

# Pod events
kubectl describe pod -n argocd
kubectl get events -A

# System logs
sudo journalctl -u k3s -n 100 | tail -50
```

### ArgoCD Specific

```bash
# ArgoCD CLI login
argocd login localhost:8080 --insecure --username admin

# Check application
argocd app get amazon-prime-app

# Get application manifest
kubectl get application amazon-prime-app -n argocd -o yaml

# Check sync status
kubectl get application amazon-prime-app -n argocd -o jsonpath='{.status.sync}'
```

---

## Performance Issues

### Slow Pod Startup

**Check:**
```bash
# Time from request to ready
kubectl get pods -l app=amazon-prime-app -w

# Check resource limits
kubectl get deployment amazon-prime-app -o yaml | grep -A5 resources

# Monitor node resources
watch 'kubectl top nodes && echo "---" && kubectl top pods -A | head -20'
```

**Solutions:**
- Increase resource limits in deployment.yaml
- Check image size (docker image ls)
- Verify network connectivity to Docker Hub

### High Memory Usage

```bash
# Check which pods use memory
kubectl top pods -A --sort-by=memory

# Check Prometheus retention
kubectl get prometheus -n monitoring -o yaml | grep retention

# Reduce retention
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.retention=6h
```

---

## Getting More Help

### Useful Commands

```bash
# Complete cluster status
kubectl cluster-info
kubectl get componentstatuses

# Check API server
kubectl api-versions
kubectl api-resources

# Check RBAC (permissions)
kubectl auth can-i get pods
kubectl auth can-i create deployments

# Check what's different
kubectl diff -f k8s/deployment.yaml
```

### Log Collection

```bash
# Collect all logs to file
mkdir -p ~/devops-logs
kubectl get events -A > ~/devops-logs/events.txt
kubectl get pods -A > ~/devops-logs/pods.txt
kubectl describe pods -A > ~/devops-logs/pods-describe.txt
kubectl logs -n argocd --all-containers=true deployment/argocd-server > ~/devops-logs/argocd.txt
```

### Support

- Check `.github/workflows/build.yml` logs in GitHub Actions
- Read ArgoCD UI error messages
- Review `./scripts/validate.sh` output
- Look at pod events: `kubectl describe pod <pod-name>`
