

# Run Tomcat on Port 8090

There are **3 approaches**:

---

## Approach 1: Change Only at Runtime (Easiest ✅)

**Don't change Dockerfile at all** — just map the port when running:

```bash
# Tomcat still runs on 8080 INSIDE container
# But YOU access it on 8090 on your machine
docker run -d -p 8090:8080 --name myapp myimage
#              ^^^^  ^^^^
#              HOST   CONTAINER
#              8090   8080

# Access: http://localhost:8090
```

```
┌─────────────────────────────────────────┐
│  Your Machine (Host)                    │
│                                         │
│  Browser → http://localhost:8090        │
│                    │                    │
│                    │ Port 8090 (host)   │
│                    ▼                    │
│  ┌──── Docker Container ─────────┐     │
│  │                               │     │
│  │  Tomcat listening on :8080    │     │
│  │  (mapped to host's 8090)     │     │
│  │                               │     │
│  └───────────────────────────────┘     │
└─────────────────────────────────────────┘
```

> ✅ **This is the recommended way.** No Dockerfile change needed.

---

## Approach 2: Change Tomcat's Internal Port to 8090

If you truly want Tomcat to **listen on 8090 inside the container**:

### Modified Dockerfile

```dockerfile
# --------------- Stage 1 : WAR Builder --------------- #
FROM maven:3.8.3-openjdk-17 AS builder

WORKDIR /app

# Copy project files
COPY . /app

# Build the WAR
RUN mvn clean package -DskipTests=true

# --------------- Stage 2 : Application Runner --------------- #
FROM tomcat:10-jdk17

# Optional: Remove default Tomcat example apps
RUN rm -rf /usr/local/tomcat/webapps/*

# ─── Change Tomcat port from 8080 to 8090 ───
RUN sed -i 's/port="8080"/port="8090"/' /usr/local/tomcat/conf/server.xml

# Copy the WAR from builder
COPY --from=builder /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Expose the NEW port
EXPOSE 8090

# Tomcat base image CMD ["catalina.sh", "run"] handles startup
```

### Key Change Explained

```bash
RUN sed -i 's/port="8080"/port="8090"/' /usr/local/tomcat/conf/server.xml
│   │       │                            │
│   │       │                            └── File: Tomcat's main config
│   │       └── Replace port="8080" with port="8090"
│   └── sed = stream editor (find & replace)
└── RUN = execute during image build
```

### What `server.xml` looks like:

```xml
<!-- BEFORE -->
<Connector port="8080" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />

<!-- AFTER sed command -->
<Connector port="8090" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />
```

### Run it

```bash
# Build
docker build -t myapp .

# Run (now map 8090:8090)
docker run -d -p 8090:8090 --name myapp myapp
#              ^^^^  ^^^^
#              HOST  CONTAINER (both 8090 now)

# Access: http://localhost:8090
```

---

## Approach 3: Use Environment Variable (Most Flexible)

### Dockerfile

```dockerfile
# --------------- Stage 1 : WAR Builder --------------- #
FROM maven:3.8.3-openjdk-17 AS builder

WORKDIR /app
COPY . /app
RUN mvn clean package -DskipTests=true

# --------------- Stage 2 : Application Runner --------------- #
FROM tomcat:10-jdk17

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=builder /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Default port (can be overridden)
ENV TOMCAT_PORT=8090

# Replace port at container START time (not build time)
CMD sed -i "s/port=\"8080\"/port=\"${TOMCAT_PORT}\"/" \
    /usr/local/tomcat/conf/server.xml && \
    catalina.sh run

EXPOSE 8090
```

### Run with different ports

```bash
# Default (8090)
docker run -d -p 8090:8090 myapp

# Override to 7070
docker run -d -p 7070:7070 -e TOMCAT_PORT=7070 myapp

# Override to 3000
docker run -d -p 3000:3000 -e TOMCAT_PORT=3000 myapp
```

---

## Comparison

```
┌──────────────┬────────────────────┬──────────────────────────┐
│  Approach    │  Dockerfile Change │  docker run              │
├──────────────┼────────────────────┼──────────────────────────┤
│              │                    │                          │
│  1. Port     │  ❌ None           │  -p 8090:8080            │
│     Mapping  │  (RECOMMENDED)     │  (map host 8090 →       │
│              │                    │   container 8080)        │
│              │                    │                          │
│  2. sed in   │  ✅ sed command    │  -p 8090:8090            │
│     Dockerfile│  + EXPOSE 8090    │                          │
│              │                    │                          │
│  3. ENV      │  ✅ ENV + CMD      │  -p 8090:8090            │
│     Variable │  (most flexible)   │  -e TOMCAT_PORT=8090     │
│              │                    │                          │
└──────────────┴────────────────────┴──────────────────────────┘
```

---

## TL;DR — Just Do This

```bash
# Don't change Dockerfile. Just run:
docker run -d -p 8090:8080 --name myapp myimage

# Access: http://localhost:8090 ✅
```

> 🔑 **The `-p HOST:CONTAINER` flag is the Docker way to change ports.** You rarely need to modify the application's internal port.
