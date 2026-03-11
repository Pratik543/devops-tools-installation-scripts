# Docker Installation

> Official Documentation: https://docs.docker.com/engine/install/

# Ubuntu/Debian

```sh
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

## Install Docker Engine

```sh
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

[Click to Configure Docker](#configure-docker)

# RHEL/CentOS

## Remove old versions

```sh
sudo dnf remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  podman \
                  runc
```

## Install required packages

```sh
sudo dnf -y install dnf-plugins-core
```

## Add Docker repository

```sh
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
```

## Install Docker Engine

```sh
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

[Click to Configure Docker](#configure-docker)

# Amazon Linux

## Install Docker using Amazon Linux's repository

```sh
sudo dnf install docker -y
```

## Create plugin directory for Docker Compose

```sh
sudo mkdir -p /usr/local/lib/docker/cli-plugins
```

## Download latest Docker Compose plugin

```sh
sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
```

## Make the plugin executable

```sh
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

[Click to Configure Docker](#configure-docker)

---

# Configure Docker

## Start and enable Docker

```sh
sudo systemctl start docker
sudo systemctl enable --now docker
```

## Verify installation

```sh
sudo docker --version
sudo docker compose version
sudo docker run hello-world
```

```sh
sudo chmod 666 /var/run/docker.sock
```

## Adding user to docker group to avoid sudo or to resolve docker access related errors

```sh
# for default user
sudo usermod -aG docker $USER

# for specific user
sudo usermod -aG docker <username>
```

## Refresh group permissions

> Logout and login again or use the following command to get access to docker commands without sudo or docker access related errors

```sh
newgrp docker
```

## Verify user is added to docker group

```sh
groups <username>
```

## Status of Docker

```sh
sudo systemctl status docker
```

## Logs of Docker

```sh
sudo journalctl -u docker.service
```

## One Liner Script Installation (Not Supported in Amazon Linux)
# 1. Download the script first
```sh
curl -fsSL https://get.docker.com -o install-docker.sh
```

# 2. Preview / review what it does (RECOMMENDED)
```sh
cat install-docker.sh
```

# 3. Dry run (shows what it WOULD do without actually installing)
```sh
sh install-docker.sh --dry-run
```

# 4. Actually install
```sh
sudo sh install-docker.sh
```
