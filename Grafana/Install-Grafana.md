# Grafana Installation

> Official Documentation: https://grafana.com/docs/grafana/latest/setup-grafana/installation/

# Ubuntu/Debian Installation

## Install required dependencies

```sh
sudo apt-get install -y software-properties-common
wget -q -O - https://apt.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

sudo apt-get update
sudo apt-get install grafana -y
```

[Post Configuration Steps](#post-installation-configuration)

# CentOS/RHEL/Fedora/Amazon Linux Installation

## Add repository key
```sh
wget -q -O gpg.key https://rpm.grafana.com/gpg.key
sudo rpm --import gpg.key

cat << EOF | sudo tee /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

sudo dnf install grafana -y
```


# Binary Installation (Recommended)

## Download latest Grafana

```sh
# Fetch latest version from GitHub API (works for OSS, adapt for Enterprise)
GRAFANA_LATEST_VERSION=$(curl -s https://api.github.com/repos/grafana/grafana/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
wget "https://dl.grafana.com/enterprise/release/grafana-enterprise-${GRAFANA_LATEST_VERSION}.linux-amd64.tar.gz"
```

## Extract archive

```sh
tar -zxvf grafana-enterprise-${GRAFANA_LATEST_VERSION}.linux-amd64.tar.gz
```

## Move to /opt

```sh
sudo mv grafana-${GRAFANA_LATEST_VERSION} /opt/grafana
```

## Create Grafana user and group

```sh
sudo groupadd --system grafana
sudo useradd -s /sbin/nologin --system -g grafana grafana
```

## Set permissions

```sh
sudo chown -R grafana:grafana /opt/grafana
```

# Create systemd service

```sh
sudo tee /etc/systemd/system/grafana-server.service << EOF
[Unit]
Description=Grafana
Documentation=<https://grafana.com/docs/>
Wants=network-online.target
After=network-online.target

[Service]
User=grafana
Group=grafana
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/opt/grafana/bin/grafana-server \
--config=/opt/grafana/conf/defaults.ini \
--homepath=/opt/grafana

[Install]
WantedBy=multi-user.target
EOF
```

# Post-Installation Configuration

## Initial Setup

## Start Grafana service

```sh
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

1. Access Grafana web interface:
```sh
IP=$(curl -s ifconfig.me); PORT=$(sudo ss -ltnp | grep -i grafana | awk '{print $4}' | cut -d: -f2 | head -1); [ -n "$PORT" ] && echo "-> Grafana running at: http://$IP:$PORT" || echo "-> Grafana not found listening"
```

2. Default login credentials:
   Username: admin
   Password: admin
3. You'll be prompted to change the password on first login

## Basic Configuration File (grafana.ini)

```sh
[server]
http_port = 3000
domain = localhost

[security]
admin_user = admin

# Disable user signup

allow_sign_up = false

[auth.anonymous]
enabled = false

[smtp]
enabled = false

# Configure for email alerts
# host = smtp.gmail.com:587
# user = your-email@gmail.com
# password = your-app-specific-password
```

# Adding Data Sources

1. Click on Configuration (gear icon) > Data Sources
2. Click "Add data source"
3. Select your data source type (e.g., Prometheus)
4. Configure the connection details:

```
URL: http://localhost:9090 # For local Prometheus
Access: Server (default)
Scrape interval: 15s
```

# Verification

1. Check service status:

```sh
sudo systemctl status grafana-server
```

2. Verify logs:

```sh
sudo journalctl -u grafana-server
```

3. Test API endpoint:

```sh
curl http://localhost:3000/api/health
```

# Common Configuration Options

Enable HTTPS

1. Generate SSL certificate:

```sh
sudo mkdir -p /etc/grafana/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
 -keyout /etc/grafana/ssl/grafana.key \
 -out /etc/grafana/ssl/grafana.crt
```

2. Update configuration:

```sh
[server]
protocol = https
cert_file = /etc/grafana/ssl/grafana.crt
cert_key = /etc/grafana/ssl/grafana.key
```

Configure SMTP for Alerts

```sh
[smtp]
enabled = true
host = smtp.gmail.com:587
user = your-email@gmail.com
password = your-app-specific-password
from_address = grafana@your-domain.com
from_name = Grafana Alert
```

# Troubleshooting

Common Issues

1. Cannot Access Web Interface

- Verify service is running
- Check firewall settings
- Confirm port 3000 is not in use
- Check logs for errors

2. Database Connection Issues

- Verify database permissions
- Check connection string
- Ensure database service is running
- Plugin Installation Failures

3. Check internet connectivity

- Verify plugin compatibility
- Check disk space
- Review plugin installation logs
