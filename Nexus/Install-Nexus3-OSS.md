# Installing Nexus3 OSS

## Installing Pre-requisites

switch as root user

```sh
sudo su -
```

Update the system packages

```sh
apt-get update
```

Install java-1.8 (Only java-1.8 is compatible right now)

```sh
apt install openjdk-8-jdk -y
```

Install net-tools to very on which port nexus is running after installation

```sh
apt install net-tools -y
```

Install wget to download packages from external download link

```sh
apt install wget -y
```

## Downloading packages

Downloading packages in /opt directory

```sh
cd /opt
wget https://download.sonatype.com/nexus/3/nexus-3.37.3-02-unix.tar.gz
```

unzip the package

```sh
tar -zxvf nexus-3.37.3-02-unix.tar.gz
```

## Create a new user to run nexus

In ubuntu `add user` command works better and creates home directory whereas `useradd` is not recommeded because it does not creaes home directory which runs into error for that user

```sh
add user nexus
```

Switch to the /opt and change the package ownership to nexus

```sh
cd /opt
chown -R nexus:nexus nexus-3.37.3-02
chown -R nexus:nexus sonatype-work
```

## Set `nexus` user to run `nexus repository`

Open `nexus.rc` file using vi editor

```sh
vi nexus-3.37.3-02/bin/nexus.rc
```

Add nexus in the file to run as user

```sh
run_as_user="nexus"
```

## Switch to the user `nexus` and start `nexus`

```sh
su - nexus
/opt/nexus-3.37.3-02/bin/nexus start
```

## Verify if the services are running and on which port it is running

```sh
ps aux | grep nexus
netstat -lnpt
```

> ***Note:***
 Usually all the artifactory repositories including `nexus` runs on the port `8081` and you can access the repository at <http://localhost:8081>

 You also need to complete post installation steps to start using nexus.