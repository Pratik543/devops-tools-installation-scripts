# Google Cloud Cli Installation

> Official Documentation: https://docs.cloud.google.com/sdk/docs/install-sdk

## Ubuntu / Debian (Official Google Repo)
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates gnupg curl

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt update
sudo apt install -y google-cloud-cli
```

## RHEL / CentOS / Fedora
```bash
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el10-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key-v10.gpg
EOM

sudo yum install -y google-cloud-cli
```

## Verify Installation
```bash
gcloud --version
```

## Standalone Installation

### Linux
| Platform              | File Name                            | Size     | SHA256                                                           |
| --------------------- | ------------------------------------ | -------- | ---------------------------------------------------------------- |
| Linux 64-bit (x86_64) | google-cloud-cli-linux-x86_64.tar.gz | 203.9 MB | 848bd5a9118f52e42fbbf690fbd7bc7686477ac41640ef4962bcb8fda7050781 |
| Linux 64-bit (Arm)    | google-cloud-cli-linux-arm.tar.gz    | 58.8 MB  | b90992b8dea95e8ba0afcdd387836494018a3061c85379222b72b33c858449be |
| Linux 32-bit (x86)    | google-cloud-cli-linux-x86.tar.gz    | 58.8 MB  | f1ea7162b3882f4d25a4d7d9dee1c552ee80cbc506f36bcffff81a862c85a8e5 |

To download the Linux archive file, run the following command:

```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
```
Refer to the table above and replace google-cloud-cli-linux-x86_64.tar.gz with the *.tar.gz package name that applies to your configuration.

To extract the contents of the file to your file system, run the following command:

```bash
tar -xf google-cloud-cli-linux-x86_64.tar.gz
```
To replace an existing installation, delete the existing google-cloud-sdk directory and then extract the archive to the same location.
Run the installation script from the root of the folder you extracted:

```bash
./google-cloud-sdk/install.sh
```