# Azure CLI Installation

> Official Documentation: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

## Ubuntu/Debian Installation

```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg

curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-get update
sudo apt-get install azure-cli -y
```

## One Liner Installation (Ubuntu/Debian)

```sh
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

## Amazon Linux Installation

```sh
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo dnf install azure-cli
```

## CentOS/RHEL/Fedora Installation

```sh
sudo rpm --import https://packages.microsoft.com/keys/microsoft-2025.asc
sudo dnf install -y https://packages.microsoft.com/config/rhel/10/packages-microsoft-prod.rpm
sudo dnf install azure-cli -y
```

## Install Azure CLI on Windows

```powershell
# Install Azure CLI on Windows
# Download the MSI installer from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
# Run the installer and follow the instructions
```