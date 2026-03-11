# AWS Cli Installation

## Ubuntu/Debian
```sh
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then 
    AWS_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ]; then 
    AWS_ARCH="aarch64"
fi

curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip
```

## RHEL / CentOS / Fedora / Amazon Linux
```sh
sudo yum install -y unzip curl

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip
```

# Verify
```sh
aws --version
```