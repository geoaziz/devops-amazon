***
<div align="center">

# 🎬 Amazon Prime Clone Free-Stack Deployment 🚀

**End-to-end cloud-native CI/CD & GitOps pipeline using GitHub Actions, Docker Hub, k3s, ArgoCD, Prometheus, Grafana, SonarCloud, and Trivy**

</div>

***

## 🗂️ Folder & File Map — What Each Contains & Is For

| File/Folder | Purpose | Next Action / Workflow Step |
|---|---|---|
| `bin/` | Archived legacy assets from the AWS/Jenkins era | Keep for reference; do not use for active deployment |
| `bin/terraform/` | Legacy Terraform for the old EC2 and EKS setup | Archived infrastructure reference only |
| `bin/pipeline_script/` | Legacy Jenkins pipelines for build, deploy, cleanup | Archived pipeline reference only |
| `k8s/` | Kubernetes manifests for the app deployment and service | ArgoCD watches this folder for sync |
| `public/` | Frontend static assets | App UI resources |
| `src/` | React app source code | Main application logic |
| `scripts/` | Cluster and operator helpers | Use for k3s, ArgoCD, monitoring, and GitHub secret bootstrap tasks |
| `Dockerfile` | Container build definition | Used by GitHub Actions and local builds |
| `README.md` | Overview and setup guide | Start here |
| `package-lock.json`, `package.json` | Node dependencies and project metadata | Installed during CI and local development |

***

## 🔨 Tools Used

| Tool | Why It’s Used |
|---|---|
| **GitHub Actions** | CI pipeline execution on free runners |
| **Docker Hub** | Free image registry for build artifacts |
| **k3s** | Lightweight local Kubernetes cluster |
| **ArgoCD** | GitOps deployment controller |
| **SonarCloud** | Code quality analysis for public repos |
| **Trivy** | Filesystem and image vulnerability scanning |
| **Prometheus** | Metrics collection |
| **Grafana** | Dashboards and visualization |
| **NodeJS/NPM** | Build and run the application |

***

## 🚦 Current Workflow

1. **Add repository secrets**
   - Use `scripts/bootstrap-github-secrets.sh` to load the required GitHub secrets.
   - The workflow expects `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `SONAR_TOKEN`, `SONAR_ORGANIZATION`, `SONAR_PROJECT_KEY`, and `GIT_TOKEN`.

2. **Run the platform locally**
   - Start and verify `k3s` on the target machine.
   - Install or verify ArgoCD on the cluster.
   - Install Prometheus and Grafana via Helm.

3. **Deploy the app**
   - ArgoCD watches `k8s/` and syncs the deployment whenever the manifest changes.
   - `k8s/deployment.yaml` points at the Docker Hub image used by GitHub Actions.

4. **Trigger CI/CD**
   - Push a change to `main`.
   - GitHub Actions installs dependencies, runs SonarCloud, scans with Trivy, builds and pushes the image, and updates the manifest for ArgoCD.

5. **Validate monitoring**
   - Confirm Prometheus is scraping the cluster.
   - Confirm Grafana dashboards reflect cluster activity and the new deployment.

***

## 🛡️ Security & Quality

- SonarCloud handles code quality checks.
- Trivy scans the repository and built image for vulnerabilities.
- GitHub secrets are loaded through the bootstrap script rather than being managed manually in the workflow.

***

## 📈 Monitoring

- Prometheus collects cluster and workload metrics.
- Grafana visualizes the health and activity of the k3s cluster.

***

## 📝 Notes

- The Dockerfile, application source, and service manifest are intentionally unchanged.
- The old AWS/Jenkins material is preserved under `bin/` for reference and rollback context.

***

<div align="center">

⭐ Keep the repo focused on the current free-stack migration.

</div>

---
