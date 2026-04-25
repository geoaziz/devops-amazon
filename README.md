***
<div align="center">

# 🎬 Amazon Prime Clone Deployment 🚀

**End-to-end cloud-native CI/CD & GitOps pipeline using AWS, Kubernetes, Jenkins, ArgoCD, Prometheus, Grafana, SonarQube, and Trivy**

</div>

***

## 🗂️ Folder & File Map — What Each Contains & Is For

| File/Folder      | Purpose                                                                                       | Next Action/Workflow Step                                    |
|------------------|----------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| `k8s/`           | App & infra Kubernetes manifests: `deployment.yaml`, `service.yaml`                          | Use with ArgoCD to deploy app/services to EKS                |
| `pipeline_script/` | Jenkins pipeline scripts: build, deploy, cleanup pipelines (`build_pipeline`, `cleanup_pipeline`, `deployment_pipeline`, `deployment_eks`) | Use these ready pipeline files to automate build & deploy     |
| `public/`        | Frontend static assets: `index.html`, logos, CSS                                             | App rendering & UI; customize as needed                      |
| `src/`           | Source code (React/Node): major frontend and backend logic                                   | Your main app — modify, add features, commit changes          |
| `terraform/`     | Infrastructure-as-Code: EC2, EKS, VPC etc. (`ec2_server/`, `eks_code/`, files like `main.tf`, `eks.tf`, `vpc.tf`, `provider.tf`)                            | Run Terraform commands here to provision AWS resources        |
| `.gitignore`     | Specifies which files/folders to exclude from version control                                | No action; managed by Git                                    |
| `Dockerfile`     | How to package the app as a Docker container                                                 | Used by pipeline & locally for image builds                   |
| `Project_WriteUp.docx` | Complete walkthrough documentation                                                       | Read for deep insight & process explanations                  |
| `README.md`      | Project summary & setup guide                                                                | Read as your starting point                                   |
| `access.sh`      | Helper shell script for app access/config                                                    | Use for quick control over app management tasks               |
| `package-lock.json`, `package.json` | Defines, locks NPM packages and config for NodeJS                      | NPM install during build; manage packages here                |

***

## 🔨 Tools Used

| Tool         | Why It’s Used                        |
|--------------|--------------------------------------|
| **Terraform**  | Automate AWS EC2, EKS, networking    |
| **Jenkins**    | CI/CD pipelines for build & deploy   |
| **Docker**     | Containerize app for cloud & K8s     |
| **AWS ECR**    | Store built Docker images            |
| **AWS EKS**    | Managed Kubernetes cluster           |
| **ArgoCD**     | GitOps-based automated deployment    |
| **SonarQube**  | Static code quality checks           |
| **Trivy**      | Container vulnerability scanning     |
| **Prometheus** | Kubernetes monitoring & metrics      |
| **Grafana**    | Cluster & app dashboards             |
| **NodeJS/NPM** | Build and run frontend/backend       |

***

## 🚦 Step-by-Step: How To Use Everything

1. **Prepare Cloud Environment**
   - Make sure you have an AWS account, CLI installed, and IAM credentials. (Reference docs provided)[1][2]
   - Create a keypair named `key`.

2. **Provision Infrastructure**
   - Go to `terraform/ec2_server/` for EC2, `terraform/eks_code/` for EKS cluster.
   - Run `terraform init` and `terraform apply --auto-approve`. This sets up servers, networks, clusters.

3. **Configure Jenkins CI/CD**
   - Install plugins (SonarQube, NodeJS, Docker, Prometheus metrics).
   - Add credentials (AWS, SonarQube token).
   - Create pipelines (use files in `pipeline_script/`). Pipelines automate these tasks:
      - Checkout code from GitHub
      - Static analysis with SonarQube
      - Vulnerability scanning with Trivy
      - Build Docker image
      - Push image to AWS ECR

4. **Containerize the App**
   - Use `Dockerfile` to build the app as a container.
   - Jenkins pipeline takes care of this automatically.

5. **Deploy to EKS with ArgoCD**
   - Use `terraform/eks_code/` to create your cluster.
   - Setup ArgoCD (follow docs in writeup and pipeline steps).
   - Sync `k8s/deployment.yaml` and `k8s/service.yaml` with ArgoCD — app will deploy and run automatically in Kubernetes.

6. **Monitor App & Cluster**
   - Install Prometheus and Grafana (Jenkins pipeline/pipeline_script and `k8s/` manifests).
   - Access dashboards for real-time metrics, resource use, custom monitoring.

7. **Access the Application**
   - Get the LoadBalancer IP/name from the service created in EKS (`k8s/service.yaml`).
   - Visit in browser.

8. **App Management**
   - Use `access.sh` for fast management/scripts.
   - Control, test, or troubleshoot your app and cluster as needed.

9. **Cleanup Flow**
   - Use cleanup pipeline (`pipeline_script/cleanup_pipeline`).
   - Run `terraform destroy` in both `ec2_server` and `eks_code` to shut down all AWS resources.

***

## 🛡️ Security & Quality

- SonarQube ensures robust, high-quality code before deployment.
- Trivy scans for vulnerabilities in the containers.
- Credentials are securely managed within Jenkins.

***

## 📈 Monitoring

- Prometheus scrapes metrics from your Kubernetes cluster.
- Grafana visualizes everything in rich dashboards—easy for debugging & scaling.

***

## 📝 Docs

- For full explanations, workflow and troubleshooting steps, open `Project_WriteUp.docx`
- Refer to tips & quick actions via `README.md` and helper scripts.


***

<div align="center">

⭐ **Star the repo if you found this project helpful!**  
🖥️ Powered by DevOps automation

</div>

---
