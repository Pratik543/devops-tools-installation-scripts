# DevOps Tools Installation Script

This script automates the installation of various DevOps tools and utilities on Linux systems. It supports multiple distributions including Ubuntu/Debian, RHEL/CentOS/Fedora, and Amazon Linux 2023.

## Supported Operating Systems

- **Ubuntu / Debian** (via `apt`)
- **RHEL / CentOS / Fedora** (via `yum`/`dnf`)
- **Amazon Linux 2023** (via `yum`/`dnf`)

## Installation & Usage

You can download and run the script directly using the following commands:

# Download the script in the home directory : ~/
```bash
wget -O tools.sh https://raw.githubusercontent.com/Pratik543/devops-tools-installation-scripts/main/tools.sh
```

# Make it executable
```bash
chmod +x tools.sh
```

# Run the script
```bash
./tools.sh
```

## Features

The script provides an interactive menu to install the following tools:

### Programming & Build
- **Java OpenJDK 21**
- **Python 3**
- **Rust & Cargo** (Latest Stable)
- **Maven**
- **Gradle** (Latest Stable)
- **NodeJS** (Latest Stable)

### DevOps & Cloud
- **Ansible**
- **Docker Engine** (with Compose)
- **Jenkins**
- **ArgoCD** (Latest Stable)
- **Terraform**
- **Trivy** (Latest Stable)

### Cloud Provider CLIs
- **AWS CLI v2**
- **Azure CLI**
- **Google Cloud CLI**

### Web Servers
- **Nginx**
- **Tomcat**

### Monitoring & Observability
- **Prometheus** (In order to start the prometheus service on rhel based system, you need to first run `sudo setenforce 0` what this does is it disables the selinux policy which is by default enabled on rhel based system and then you can start the prometheus service)
- **Grafana**

### Terminal Utilities
- **Lazydocker**: Terminal UI for Docker
- **Yazi**: Blazing fast terminal file manager
- **Bat**: A cat clone with wings (syntax highlighting)
- **Croc**: Easily and securely send things from one computer to another
- **Btop**: Resource monitor
- **Fzf**: Command-line fuzzy finder
- **Zoxide**: Smarter cd command
- **Atuin**: Magical shell history
- **Gdu**: Disk usage analyzer
- **JQ**: Command-line JSON processor
- **Eza**: Modern ls command

## ⚠️ Notes (Must Read)

- The script automatically detects your package manager (`apt`, `yum`, or `dnf`).
- Some tools (like Docker) may require a system reboot or session restart to apply group changes.
- This script is tested on Ubuntu 24.04, RHEL 10, and Amazon Linux 2023. It should work on other distributions as well, but it is not guaranteed.
- This script is mainly created for installing DevOps tools on a new system of ec2 instance/google cloud vm/any other cloud vm. It is not recommended to run it on a production system.

# Here are the tools sorted by functional categories, with **Web/UI ports** marked where applicable:

## Programming Languages & Runtimes
- **java** – None (JVM/Compiler)
- **nodejs** – None (JS Runtime)
- **python** – None (Interpreter)
- **rust** – None (Compiler/Runtime)

## Build Tools
- **maven** – None (Java Build)
- **gradle** – None (JVM Build)

## Container & Kubernetes Ecosystem
- **docker** – None (Container Runtime – API 2375/2376 if exposed)
- **minikube** – **8443** (Local K8s Cluster – Dashboard via proxy)
- **kubectl-cli** – None (K8s Control CLI)
- **helm** – None (K8s Package Manager)
- **k9s** – None (K8s Terminal UI)
- **argocd-cli** – None (GitOps CLI – Server uses 80/443/8080)

## CI/CD & Infrastructure Automation
- **jenkins** – **8080** (Web/UI)
- **ansible** – None (Config Management via SSH)
- **terraform-cli** – None (IaC Provisioning)

## Cloud Provider CLIs
- **aws-cli** – None (AWS API Client)
- **azure-cli** – None (Azure API Client)  
- **gcloud-cli** – None (GCP API Client)

## Security & Code Quality
- **trivy-cli** – None (Vulnerability Scanner)
- **sonarqube** – **9000** (Web/UI) (Installation Using Docker, Recommended)

## Monitoring & Observability
- **prometheus** – **9090** (Web/UI)
- **grafana** – **3000** (Web/UI)

## Web & Application Servers
- **nginx** – **80**, **443** (Web/UI)
- **tomcat** – **8080** (Web/UI – Manager App)