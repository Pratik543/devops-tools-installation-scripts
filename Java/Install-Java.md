# Java Installation

> Official Documentation: https://openjdk.org/install/

To check whether java is installed or not execute the below command.

```sh
java -version
```

## Install Java

We will be using open java for our demo, Get the latest version from <http://openjdk.org/install/>

**Choose below command with respect to your OS:**

**To check your os type execute the below command:**

```sh
cat /etc/os-release | grep ID_LIKE
```

# Using OpenJDK

## Ubuntu/Debian
```sh
sudo apt update
sudo apt install openjdk-21-jdk
```

## Amazon Linux
```sh
sudo yum install java-21-amazon-corretto-devel
```

## Fedora/CentOs/RHEL
```sh
sudo yum install java-21-openjdk
```


<details>
<summary>Using Temurin</summary>

# Using Temurin
## CentOs/RHEL

> Add the RPM repo to /etc/yum.repos.d/adoptium.repo making sure to change the distribution name if you are not using CentOS/RHEL/Fedora. To check the full list of versions supported take a look at the list in the tree at https://packages.adoptium.net/ui/native/rpm/.


> Uncomment and change the distribution name if you are not using CentOS/RHEL/Fedora
> DISTRIBUTION_NAME=centos

```sh
cat <<EOF > /etc/yum.repos.d/adoptium.repo
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/${DISTRIBUTION_NAME:-$(. /etc/os-release; echo $ID)}/\$releasever/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
```
Install the Temurin version you require using dnf:

```sh
dnf update
dnf install temurin-17-jdk
```

Alternatively, if you are using yum:

```sh
yum update
yum install temurin-17-jdk
```

## Amazon Linux

```sh
sudo yum install java-21-amazon-corretto-devel
```


## Debian/Ubuntu

Ensure the necessary packages are present:

```sh
apt install -y wget apt-transport-https gpg
```

Download the Eclipse Adoptium GPG key:

```sh
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null
```

Configure the Eclipse Adoptium apt repository. To check the full list of versions supported take a look at the list in the tree at https://packages.adoptium.net/ui/native/deb/dists/.

```sh
echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
```

For Linux Mint (based on Ubuntu) you have to replace VERSION_CODENAME with UBUNTU_CODENAME.

Install the Temurin version you require:

```sh
apt update
apt install temurin-21-jdk
```
</details>

## Check for installed java version

```sh
java -version
```

## Check java installation path

```sh
readlink -f "$(which java)"
```

Output would be like `/usr/bin/java` (This is default installation path of java)

## Set Java to enviroment variables path

Check the path of your java installation using this command:

***Fedora/Debian/CentOs:***
```sh
# show multiple java versions if installed
sudo update-alternatives --config java

# show path of current java installation
readlink -f "$(which java)"
```

## OR Just One Liner Command for adding JAVA_HOME (Recommended)
```sh
echo "JAVA_HOME=$(readlink -f $(which java))" | sudo tee -a /etc/environment && source /etc/environment
```

> Copy the path of java installation from the output and save it in "/etc/environment"

## Set "JAVA_HOME" as environment variable (manually)

> Copy the java path in last line of output and save it in "/etc/environment"

```sh
vi /etc/environment
```

Add below statements at the end of the file

```sh
PATH=$PATH:$HOME/bin:$JAVA_HOME:$JAVA_HOME/bin
JAVA_HOME="/usr/lib/jvm/your-java-path"
```

save & close the file (by using :wq!)

> ***Note:*** provide your correct Java installation path

## Reload the configuration file

## Debian/Fedora/RHEL/CentOs
```sh
source /etc/environment
```

## Now check the path

```sh
which java
```

Or you can also check in the environment variables path

```sh
echo $PATH
echo $JAVA_HOME
```

Output should be like:

> /usr/lib/jvm/java-21-openjdk/bin/

Now, Java path has been succesfully installed and set in environment variables.