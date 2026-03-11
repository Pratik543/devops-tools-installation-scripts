# Ansible Installation

> Official Documentation: https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html

# Ubuntu/Debian
```sh
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y
```

# Fedora/Amazon Linux
```sh
sudo yum install ansible -y
```

# RedHat/CentOS
```sh
sudo yum install ansible-core -y
```

# Verify Installation
```sh
ansible --version
```

# Ansible Installation Using Pip

# Debian/Ubuntu
## Install Prerequisites
```sh
sudo apt update
sudo apt install python3 python3-pip python3-venv -y
```

## Create Virtual Environment and Install Ansible on Ubuntu
```sh
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate

pip3 install ansible
```

# Fedora/Amazon Linux/RHEL/CentOS
## Install Prerequisites
```sh
sudo dnf install python3 python3-pip -y
```

## Upgrade pip and Install Ansible
```sh
python3 -m pip install --upgrade pip
pip3 install ansible
```

## Verify Installation
```sh
ansible --version
```
