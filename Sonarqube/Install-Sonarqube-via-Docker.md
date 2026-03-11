# Sonarqube Installation using Docker

```sh
docker run -d --name sonarqube \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:26.2.0.119303-community
```
or `sonarqube:latest` which points to 26.2.0 version


> To known the version of sonarqube
http://localhost:9000/api/system/status returns sonarqube details in browser

or Enter the container and check the version 
```sh
docker exec -it sonarqube bash
```
then
```sh
ls /opt/sonarqube/lib/sonar-application-*.jar
```
