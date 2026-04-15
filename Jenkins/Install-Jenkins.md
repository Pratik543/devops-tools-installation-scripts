# Jenkins Installation

> Official Documentation: https://www.jenkins.io/doc/book/installing/

## Prerequisites

1. Java

# Ubuntu/Debian

## Download the Jenkins repository key (Both works fine you can use any of them)
```sh
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
```
## or
```sh
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
```

## Add the Jenkins repository to your system's package index
```sh
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install jenkins -y
```

# Fedora/RHEL/CentOs


## Add Jenkins repository
```sh
sudo wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf update -y
```

## Install Jenkins
```sh
sudo dnf install -y jenkins
```

## Start Jenkins service
```sh
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

## Check status
```sh
sudo systemctl status jenkins
```

## Configure firewall (only if you are using a virtual machine/linux server) (not requires in cloud servers)
```sh
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

## Access Jenkins
```sh
IP=$(curl -s ifconfig.me); PORT=$(sudo ss -ltnp | grep -i java | awk '{print $4}' | cut -d: -f2 | head -1); [ -n "$PORT" ] && echo "-> Jenkins running at: http://$IP:$PORT" || echo "-> Jenkins not found listening"
```
