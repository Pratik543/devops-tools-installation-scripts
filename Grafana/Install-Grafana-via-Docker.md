# Grafana Installation via Docker

## Create persistent storage volume

```sh
docker volume create grafana-data
```

## Run Grafana container

```sh
docker run -d \
  --name=grafana \
  -p 3000:3000 \
  -v grafana-data:/var/lib/grafana \
  grafana/grafana:latest
```

## For production with additional settings

```sh
docker run -d \
  --name=grafana \
  -p 3000:3000 \
  -v grafana-data:/var/lib/grafana \
  -e "GF_SECURITY_ADMIN_PASSWORD=your_secure_password" \
  -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" \
  grafana/grafana:latest
```
