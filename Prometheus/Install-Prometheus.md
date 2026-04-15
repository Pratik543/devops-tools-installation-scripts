# Ubuntu/Debian & CentOS/RHEL Installation

```
# Create Prometheus system user
sudo useradd --system --no-create-home --shell /bin/false prometheus

# Create directories
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus

# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz

# Extract and move files
tar xvf prometheus-*.tar.gz
cd prometheus-*/
sudo mv prometheus /usr/local/bin/
sudo mv promtool /usr/local/bin/
#sudo mv consoles/ /etc/prometheus
#sudo mv console_libraries/ /etc/prometheus
#sudo mv prometheus.yml /etc/prometheus

# Create systemd service
sudo tee /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R prometheus:prometheus /var/lib/prometheus

# Start Prometheus
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
```

[Post Installation Steps](#post-installation-configuration)

# Post-Installation Configuration

Basic Configuration File (prometheus.yml)

```
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first.rules"
  # - "second.rules"

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  - job_name: node_exporter
    static_configs:
      - targets: ['localhost:9100']
```

# Adding Node Exporter

## Install Node Exporter (Ubuntu/Debian)

```
sudo useradd --system --no-create-home --shell /bin/false node_exporter

wget https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz
tar xvf node*exporter-*.tar.gz
sudo mv node*exporter-*/node_exporter /usr/local/bin
rm -rf node_exporter*
```

## Create systemd service for Node Exporter

```
sudo tee /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter --collector.logind

[Install]
WantedBy=multi-user.target
EOF
```

## Start Node Exporter

```
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

# Adding Node Exporter through Docker

Best & Standard Way: Run Node Exporter as a Separate Container
Use this docker run command (adapted for your EC2 / Amazon Linux setup):

```
docker run -d \
 --name node-exporter \
 --restart unless-stopped \
 --net host \
 --pid host \
 -v "/:/host:ro,rslave" \
 prom/node-exporter:latest \
 --path.rootfs=/host
```

1. --net host & --pid host: Allows access to real host network/pids (important for accurate metrics).
2. -v "/:/host:ro,rslave": Mounts the host root filesystem read-only so Node Exporter can see real /proc, /sys, disks, etc.
3. --path.rootfs=/host: Tells Node Exporter to prefix paths with /host.

Alternative version (more explicit mounts, sometimes more reliable on newer kernels):

- -p 9100:9100 # optional if you don't use host network

```
docker run -d \
 --name node-exporter \
 --restart unless-stopped \
 -p 9100:9100 \
 -v /proc:/host/proc:ro \
 -v /sys:/host/sys:ro \
 -v /:/rootfs:ro \
 prom/node-exporter:latest \
 --path.procfs=/host/proc \
 --path.sysfs=/host/sys \
 --path.rootfs=/rootfs \
 --collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|etc)($$|/)"
```

## For Scraping Node Data from node_exporter container

Edit your prometheus.yml (the one you mount into Prometheus) and add this job under scrape_configs:

```
  - job_name: 'node'
    static_configs:
      - targets: ['host.docker.internal:9100']   #  if using --net host
```

- If you used --net host on Node Exporter → use localhost:9100.
- If not → use the container name if on the same Docker network (e.g. node-exporter:9100), or host.docker.internal:9100 (works on Docker Desktop, sometimes on Linux too).

## Restart Prometheus for updating the node_exporter metrics

```
sudo systemctl restart prometheus
```

OR

```
docker restart prometheus
```

## Verification

Verify the installation by:

1. Checking the Prometheus service status:
   sudo systemctl status prometheus

2. Accessing the Prometheus web interface:
   http://localhost:9090

3. Verifying metrics collection:
   http://localhost:9090/metrics

## Common Configuration Options

Setting Up Basic Authentication

1. Create password file:

```
  sudo apt install apache2-utils
  sudo htpasswd -c /etc/prometheus/.htpasswd admin
```

2. Update Prometheus configuration:

```
  web:
  basic_auth_users:
  admin: <hashed-password>
```

## Configuring Retention

Update the Prometheus service file with retention settings:

```
ExecStart=/usr/local/bin/prometheus \
 --storage.tsdb.retention.time=15d \
 --storage.tsdb.retention.size=50GB
```
