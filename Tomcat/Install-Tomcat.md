# Tomcat installation

> Official Documentation: https://tomcat.apache.org/

## Prerequisites

1. EC2 instance or Vm or Local machine
2. Java v17.x or more and setup env JAVA_HOME

## Update the system
### Ubuntu/Debian
```sh
sudo apt update && sudo apt upgrade -y
```
### Fedora/RHEL/CentOS
```sh
sudo dnf update -y
```

## Switch to root user
```sh
sudo su
```

## Install Apache Tomcat

Download tomcat packages from  <https://tomcat.apache.org/download-11.cgi> onto /usr/local on EC2 instance. Update the version number as per your requirement

## Create a tomcat directory

```sh
cd /usr/local

wget https://dlcdn.apache.org/tomcat/tomcat-11/v11.0.18/bin/apache-tomcat-11.0.18.tar.gz

tar -xvzf /usr/local/apache-tomcat-11.0.18.tar.gz
```

## Rename the extracted directory to `tomcat` (optional)

```sh
mv apache-tomcat-11.0.18 tomcat
```

## Create soft link files for tomcat startup.sh and shutdown.sh

```sh
ln -s /usr/local/tomcat/bin/startup.sh /usr/local/bin/tomcatup
ln -s /usr/local/tomcat/bin/shutdown.sh /usr/local/bin/tomcatdown
tomcatup
```

### Add tomcat to PATH (requires only in RHEL/CentOs)
```sh
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

# Check point

Access tomcat application from browser on port 8080 (you can't access the tomcat webpage if jenkins is also installed on you server cause both runs on port 8080 so you need to change the port number for tomcat) 
```sh
IP=$(curl -s ifconfig.me); PORT=$(sudo ss -ltnp | grep -i tomcat | awk '{print $4}' | cut -d: -f2 | head -1); [ -n "$PORT" ] && echo "-> Tomcat running at: http://$IP:$PORT" || echo "-> Tomcat not found listening"
```
## Change the default port for tomcat if required

Using unique ports for each application is a best practice in an environment. But tomcat and Jenkins runs on ports number 8080. Hence lets change tomcat port number to your desired custom port. Change port number in `conf/server.xml` file under tomcat home
Update port number in the `Connecter port` field in `server.xml`


## Update port number in the `Connecter port` field in `server.xml` as per your requirement

```sh
# ---------------here--------------------- change 8080 to your custom port
<Connector port="8090" protocol="HTTP/1.1"
                connectionTimeout="20000"
                redirectPort="8443"
                maxParameterCount="1000"
                />
```

```sh
vi /usr/local/tomcat/conf/server.xml
```

## Restart tomcat after configuration update

```sh
tomcatdown
tomcatup
```

## Check Tomcat server status

Access tomcat application from browser on your custom port
```
IP=$(curl -s ifconfig.me); PORT=$(sudo ss -ltnp | grep -i tomcat | awk '{print $4}' | cut -d: -f2 | head -1); [ -n "$PORT" ] && echo "-> Tomcat running at: http://$IP:$PORT" || echo "-> Tomcat not found listening" 
```

```sh
find /usr/local/tomcat/webapps/ -name context.xml -not -path "*/docs/*" -not -path "*/examples/*"
```

> Above command gives 2 context.xml files path excluding the docs/ and examples/ directories if you want to access the /docs and /examples path then update the context.xml files in docs/ and examples/ directories then remove the -not -path "*/docs/*" -not -path "*/examples/*" from the command and comment in all the context.xml files. comment (<!-- & -->) `Value ClassName` field on files which are under webapp directory.
Update the 2 files as per below

## Update the context.xml file in webapps/manager/META-INF/context.xml to allow login from browser

```sh
vi /usr/local/tomcat/webapps/manager/META-INF/context.xml
```

Comment the `Value ClassName` field

```sh
<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\..*|::1|0:0:0:0:0:0:0:1" /> -->
```

## Update the context.xml file in webapps/host-manager/META-INF/context.xml to allow login from browser

```sh
vi /usr/local/tomcat/webapps/host-manager/META-INF/context.xml
```

Comment the `Value ClassName` field

```sh
<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\..*|::1|0:0:0:0:0:0:0:1" /> -->
```

## Update users information in the `tomcat-users.xml` file
goto tomcat home directory and add below users to `conf/tomcat-users.xml` file at the end of file before `</tomcat-users>` and align the indentations

```sh
vi /usr/local/tomcat/conf/tomcat-users.xml
```

```sh
<role rolename="manager-gui"/>
  <role rolename="admin-gui"/>
  <role rolename="manager-script"/>
  <user username="tomcat" password="tomcat" roles="manager-gui"/>
  <user username="admin" password="admin()" roles="manager-gui,admin-gui,manager-script"/>
```

Restart serivce and try to login to tomcat application from the browser. This time it should be Successfull

```sh
tomcatdown
tomcatup
```

## Login with credentials you have set and now you can access the tomcat application from browser. 