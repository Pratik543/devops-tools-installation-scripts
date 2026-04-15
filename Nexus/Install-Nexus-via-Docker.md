# Installing Nexus3 OSS via Docker

```sh
docker run -d \ 
--name nexus \ 
-p 8081:8081 \ 
-v nexus-data:/nexus-data \ 
sonatype/nexus3
```