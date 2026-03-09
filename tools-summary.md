# Tool Download Locations Analysis

## Current State: Where Every Tool Goes

Below is a complete audit of every installation function in [tools.sh], showing **where files are downloaded** (temp dir) and **where they are finally placed** (install dir).

---

### Legend

| Symbol | Meaning                                                                    |
| ------ | -------------------------------------------------------------------------- |
| 📦      | Package manager install (apt/yum/dnf) — goes to system paths automatically |
| 📥      | Downloaded to `mktemp -d` then moved to final location                     |
| 🔗      | Symlinked to a PATH directory                                              |
| 🌐      | Installed via external script (curl \| bash)                               |

---

### Category 1: Binary Tools Downloaded to `mktemp -d` → Moved to Final Location

These tools download to a random `/tmp/tmp.XXXXX` directory, then move the binary to the install path.

| Tool                 | Temp Dir    | Final Install Path                         | Symlink / PATH                          |
| -------------------- | ----------- | ------------------------------------------ | --------------------------------------- |
| **Maven**            | `mktemp -d` | `/opt/maven/`                              | `/usr/local/bin/mvn`                    |
| **Gradle**           | `mktemp -d` | `/opt/gradle/`                             | `/usr/local/bin/gradle`                 |
| **Jenkins WAR**      | `mktemp -d` | `/usr/share/jenkins/jenkins.war`           | systemd service                         |
| **ArgoCD CLI**       | `mktemp -d` | `/usr/local/bin/argocd`                    | — (direct)                              |
| **AWS CLI**          | `mktemp -d` | `/usr/local/aws-cli/`                      | `/usr/local/bin/aws`                    |
| **Google Cloud CLI** | `mktemp -d` | `/opt/google-cloud-sdk/`                   | `/usr/local/bin/gcloud`, `gsutil`, `bq` |
| **Prometheus**       | `mktemp -d` | `/opt/prometheus/`                         | `/usr/local/bin/prometheus`, `promtool` |
| **kubectl**          | `mktemp -d` | `/usr/local/bin/kubectl`                   | — (direct)                              |
| **k9s**              | `mktemp -d` | `/usr/local/bin/k9s`                       | — (direct)                              |
| **Minikube**         | `mktemp -d` | `/usr/local/bin/minikube`                  | — (direct)                              |
| **Tomcat**           | `mktemp -d` | `/usr/local/tomcat/`                       | — (run from install dir)                |
| **Lazydocker**       | `mktemp -d` | `/usr/local/bin/lazydocker`                | — (direct)                              |
| **Yazi**             | `mktemp -d` | `/usr/local/bin/yazi`, `/usr/local/bin/ya` | — (direct)                              |
| **Bat** (non-apt)    | `mktemp -d` | `/usr/local/bin/bat`                       | — (direct)                              |
| **Btop** (binary)    | `mktemp -d` | `/usr/local/bin/btop`                      | — (direct)                              |
| **Fzf**              | `mktemp -d` | `/usr/local/bin/fzf`                       | — (direct)                              |
| **Gdu**              | `mktemp -d` | `/usr/local/bin/gdu`                       | — (direct)                              |
| **Eza** (non-apt)    | `mktemp -d` | `/usr/local/bin/eza`                       | — (direct)                              |

---

### Category 2: Package Manager Installs (apt / yum / dnf)

These go wherever the package manager puts them — typically `/usr/bin/` or `/usr/sbin/`. **No temp download directory is involved** in the script itself.

| Tool                       | Install Method                                                             |
| -------------------------- | -------------------------------------------------------------------------- |
| **Java (OpenJDK)**         | 📦 `apt/yum` → `/usr/lib/jvm/` (JAVA_HOME)                                  |
| **Git**                    | 📦 `apt/yum` → `/usr/bin/git`                                               |
| **Node.js**                | 📦 via NodeSource repo → `/usr/bin/node`                                    |
| **Python 3**               | 📦 `apt/yum` → `/usr/bin/python3`                                           |
| **Ansible**                | 📦 `apt/yum` or `pip3` → `/usr/bin/ansible`                                 |
| **Docker**                 | 📦 via Docker repo → `/usr/bin/docker`                                      |
| **Jenkins** (apt/yum)      | 📦 via Jenkins repo → `/usr/bin/jenkins` (or `/usr/share/java/jenkins.war`) |
| **Terraform**              | 📦 via HashiCorp repo → `/usr/bin/terraform`                                |
| **Trivy**                  | 📦 via Aqua repo → `/usr/bin/trivy`                                         |
| **Azure CLI**              | 📦 via Microsoft repo → `/usr/bin/az`                                       |
| **Google Cloud CLI** (apt) | 📦 via Google repo → `/usr/bin/gcloud`                                      |
| **Grafana**                | 📦 via Grafana repo → `/usr/sbin/grafana-server`                            |
| **Nginx**                  | 📦 `apt/yum` → `/usr/sbin/nginx`                                            |
| **Bat** (apt)              | 📦 apt → `/usr/bin/batcat` 🔗 `/usr/bin/bat`                                 |
| **Btop** (apt/dnf)         | 📦 apt/dnf/EPEL → `/usr/bin/btop`                                           |
| **Zoxide** (apt)           | 📦 apt → `/usr/bin/zoxide`                                                  |
| **Eza** (apt)              | 📦 via gierens repo → `/usr/bin/eza`                                        |
| **JQ**                     | 📦 `apt/yum` → `/usr/bin/jq`                                                |

---

### Category 3: External Script Installers (curl | bash)

These tools use their own install script — the download path and final location are controlled by the external script.

| Tool                 | Install Method          | Final Location                                    |
| -------------------- | ----------------------- | ------------------------------------------------- |
| **Rust/Cargo**       | 🌐 `rustup.rs`           | `$HOME/.cargo/bin/` (`rustc`, `cargo`)            |
| **Helm**             | 🌐 `get-helm-3` script   | `/usr/local/bin/helm`                             |
| **Croc**             | 🌐 `getcroc.schollz.com` | `/usr/local/bin/croc`                             |
| **Zoxide** (non-apt) | 🌐 zoxide install script | `$HOME/.local/bin/zoxide`                         |
| **Atuin**            | 🌐 `setup.atuin.sh`      | `$HOME/.atuin/bin/atuin` 🔗 `/usr/local/bin/atuin` |

---
