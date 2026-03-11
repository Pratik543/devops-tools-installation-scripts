# Gradle Installation

> Official Documentation: https://docs.gradle.org/current/userguide/installation.html

## Binary Installation

```sh
latest=$(curl -fsSL --connect-timeout 10 "https://services.gradle.org/versions/current" 2>/dev/null | \
    grep -oP '"version"\s*:\s*"\K[^"]+')

if [ -z "$latest" ]; then
    echo "Failed to fetch latest Gradle version. Using 8.13 as fallback."
    latest="8.13"
fi

# Download the latest binary distribution
wget https://services.gradle.org/distributions/gradle-${latest}-bin.zip

# Unzip the distribution
unzip gradle-${latest}-bin.zip

# Move to a permanent location
sudo mv gradle-${latest} /opt/gradle
```

```sh
# Add to PATH
echo 'export PATH="/opt/gradle/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```