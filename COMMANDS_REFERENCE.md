# Quick Commands Reference

Copy-paste commands for common DevOps tasks.

## 🔧 Cluster Management

### Check Cluster Status
```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
kubectl top nodes
```

### View Node Details
```bash
kubectl describe node
kubectl get nodes -o wide
```

### Restart Cluster
```bash
sudo systemctl restart k3s
sudo systemctl status k3s
```

---

## 🚀 Deployment Management

### View Deployments
```bash
kubectl get deployments
kubectl get deployment amazon-prime-app
kubectl describe deployment amazon-prime-app
```

### Check Pod Status
```bash
kubectl get pods -l app=amazon-prime-app
kubectl logs deployment/amazon-prime-app
kubectl logs deployment/amazon-prime-app -f  # Follow logs
kubectl logs deployment/amazon-prime-app --tail=50  # Last 50 lines
```

### Restart Deployment
```bash
kubectl rollout restart deployment/amazon-prime-app
kubectl delete pod -l app=amazon-prime-app  # Force new pods
```

### Watch Deployment
```bash
kubectl get pods -l app=amazon-prime-app -w  # Watch for changes
```

---

## 🔄 ArgoCD Management

### Check ArgoCD Status
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
kubectl get application -n argocd
```

### View Application Status
```bash
kubectl describe application amazon-prime-app -n argocd
kubectl get application amazon-prime-app -n argocd -o yaml
```

### Manually Sync Application
```bash
argocd app sync amazon-prime-app
# Or via kubectl
kubectl patch application amazon-prime-app -n argocd --type merge \
  -p '{"metadata":{"labels":{"sync":"true"}}}'
```

### Get ArgoCD Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo ""
```

### Port-Forward to ArgoCD
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# Access at https://localhost:8080
```

---

## 📊 Monitoring & Observability

### Check Prometheus
```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### Port-Forward to Prometheus
```bash
PROM=$(kubectl get svc -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward svc/$PROM -n monitoring 9090:9090 &
# Access at http://localhost:9090
```

### Port-Forward to Grafana
```bash
GRAFANA=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n monitoring pod/$GRAFANA 3000:3000 &
# Access at http://localhost:3000
```

### Check Metrics
```bash
kubectl top nodes
kubectl top pods -A
kubectl top pods -n monitoring
```

---

## 🔐 Secrets & Configuration

### View Secrets
```bash
kubectl get secrets -A
kubectl get secret -n argocd  # ArgoCD secrets
```

### Decode Secret Value
```bash
kubectl get secret <secret-name> -o jsonpath='{.data.password}' | base64 -d
```

### Create Secret
```bash
kubectl create secret generic my-secret --from-literal=key=value
```

---

## 📝 Logs & Events

### View Events
```bash
kubectl get events -A --sort-by='.lastTimestamp'
kubectl get events -A | grep -i error
```

### Logs from Pod
```bash
kubectl logs pod/<pod-name>
kubectl logs pod/<pod-name> -c <container-name>  # Specific container
```

### Logs from Deployment
```bash
kubectl logs deployment/<deployment-name>
kubectl logs deployment/<deployment-name> -f  # Follow
```

### System Logs (k3s)
```bash
sudo journalctl -u k3s -n 50  # Last 50 lines
sudo journalctl -u k3s -f     # Follow
sudo journalctl -u k3s --since "5 minutes ago"
```

---

## 🌐 Services & Networking

### View Services
```bash
kubectl get svc -A
kubectl describe svc amazon-prime-app
kubectl get endpoints -A
```

### Port Forward to Service
```bash
kubectl port-forward svc/amazon-prime-app 3000:3000
```

### Access Service from Pod
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://amazon-prime-app:3000
```

### Check DNS
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup amazon-prime-app.default.svc.cluster.local
```

---

## 📦 Namespace Management

### List Namespaces
```bash
kubectl get namespaces
```

### View Resources in Namespace
```bash
kubectl get all -n argocd
kubectl get all -n monitoring
kubectl get all  # default namespace
```

### Create Namespace
```bash
kubectl create namespace myapp
```

### Delete Namespace
```bash
kubectl delete namespace myapp
```

---

## 🐳 Container & Image Management

### List Images in Cluster
```bash
kubectl get pods -A -o jsonpath='{range .items[*].spec.containers[*]}{.image}{"\n"}{end}' | sort -u
```

### Pull Image from k3s
```bash
# k3s uses containerd, not Docker
sudo k3s crictl images
```

### Clear Unused Images
```bash
sudo k3s crictl rmi -f  # Force remove all unused
```

---

## ⚙️ Configuration Management

### Apply Manifest
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/  # Apply all files in directory
```

### Check Manifest Changes
```bash
kubectl diff -f k8s/deployment.yaml
```

### Update Field
```bash
kubectl set image deployment/amazon-prime-app \
  amazon-prime-container=geoaziz/amazon-prime-app:v2
```

### Update Resource Limits
```bash
kubectl set resources deployment amazon-prime-app \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=250m,memory=256Mi
```

---

## 🔍 Debugging

### Shell into Pod
```bash
kubectl exec -it pod/<pod-name> -- /bin/sh
kubectl exec -it deployment/amazon-prime-app -- /bin/bash
```

### Describe Pod (Full Details)
```bash
kubectl describe pod <pod-name>
```

### Port-Forward for Testing
```bash
kubectl port-forward pod/amazon-prime-app-xyz 3000:3000
```

### Check Resource Requests
```bash
kubectl get pods -o json | jq '.items[] | {name: .metadata.name, resources: .spec.containers[].resources}'
```

---

## 📁 YAML & Manifest

### Generate Manifest (Don't Apply)
```bash
kubectl create deployment test --image=nginx --dry-run=client -o yaml
```

### Edit Manifest Live
```bash
kubectl edit deployment amazon-prime-app
```

### Export Manifest
```bash
kubectl get deployment amazon-prime-app -o yaml > deployment-backup.yaml
```

---

## 🔄 Git & Commits

### Check Git Status
```bash
git status
git log --oneline -5
git diff k8s/deployment.yaml
```

### Force Push (Use Carefully)
```bash
git push -f origin main  # Overwrites remote history
```

### Tag Release
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

---

## 🧪 Testing

### Local Test (Before Commit)
```bash
# Run validation
./scripts/validate.sh

# Check specific component
./scripts/test-pipeline.sh

# Dry-run kubectl
kubectl apply -f k8s/ --dry-run=client
```

### Port-Forward & Test
```bash
kubectl port-forward svc/amazon-prime-app 3000:3000 &
curl http://localhost:3000
```

---

## 🧹 Cleanup & Reset

### Delete All in Namespace
```bash
kubectl delete all -n monitoring
```

### Delete Specific Resource
```bash
kubectl delete deployment amazon-prime-app
kubectl delete svc amazon-prime-app
```

### Full Reset
```bash
./scripts/cleanup.sh
sudo systemctl restart k3s
./scripts/setup-all.sh
```

### Clear k3s
```bash
sudo /usr/local/bin/k3s-uninstall.sh
rm -rf ~/.kube/config
```

---

## 📊 Helm Commands

### List Releases
```bash
helm list -A
helm list -n monitoring
```

### Check Helm Values
```bash
helm get values prometheus -n monitoring
```

### Upgrade Release
```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.retention=48h
```

### Uninstall Release
```bash
helm uninstall prometheus -n monitoring
```

---

## 🚨 Emergency Commands

### Force Delete Pod
```bash
kubectl delete pod <pod-name> --grace-period=0 --force
```

### Kill Process in Container
```bash
kubectl exec -it pod/<pod-name> -- kill -9 <PID>
```

### Restart All Pods in Deployment
```bash
kubectl rollout restart deployment/amazon-prime-app
```

### Cordon Node (Prevent Scheduling)
```bash
kubectl cordon <node-name>
kubectl uncordon <node-name>
```

---

## 💡 Tips & Tricks

### Watch Resources in Real-Time
```bash
watch 'kubectl top nodes && echo "---" && kubectl top pods -A | head -10'
```

### Get Resource YAML
```bash
kubectl get pod <pod-name> -o yaml | head -50
```

### Find Pods by Label
```bash
kubectl get pods -l app=amazon-prime-app
kubectl get pods -l component=server
```

### Get Multiple Resources
```bash
kubectl get pods,svc,deploy
```

### Pretty-Print JSON
```bash
kubectl get pod -o json | jq .
```

### Use Aliases
```bash
# Add to ~/.bashrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kdesc='kubectl describe'
alias klog='kubectl logs'

# Usage: k get pods, klog <pod-name>
```

---

## 🆘 When Nothing Works

```bash
# 1. Check cluster
kubectl cluster-info

# 2. Check nodes
kubectl get nodes

# 3. Check resources
kubectl top nodes
kubectl top pods -A

# 4. Check events
kubectl get events -A | grep -i error

# 5. Restart k3s
sudo systemctl restart k3s

# 6. Full diagnostic
./scripts/validate.sh

# 7. Nuclear option (lose data)
./scripts/cleanup.sh
sudo systemctl restart k3s
./scripts/setup-all.sh
```

---

## 📚 More Information

- **kubectl docs:** https://kubernetes.io/docs/reference/kubectl/
- **k8s API:** https://kubernetes.io/docs/reference/
- **ArgoCD docs:** https://argo-cd.readthedocs.io/
- **Helm docs:** https://helm.sh/docs/
- **Prometheus:** https://prometheus.io/docs/
- **Grafana:** https://grafana.com/docs/
