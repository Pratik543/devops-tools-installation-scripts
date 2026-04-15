# Prometheus Installation using Docker

```sh
# Create docker volume for Prometheus data
docker volume create prometheus-data

# Run Prometheus container if you prometheus container to work with node_exporter container use this

docker run -d \
  --name prometheus \
  --net host \
  --pid host \
  -v $(pwd)/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v prometheus-data:/prometheus \
  prom/prometheus
```

```sh
docker run -d \
  --name prometheus \
  --net host \
  --pid host \
  -v $(pwd)/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v prometheus_data:/prometheus \
  prom/prometheus
```