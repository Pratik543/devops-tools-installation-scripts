#!/bin/bash

# =========================================
# Author : Pratik Gupta
# Date : 07-03-2026
# Version : 1.0.1
# Portfolio : https://devopschamp.vercel.app/
# Description : DevOps Tool Installation Script
# =========================================

# =========================================
# Exit on error, but handle gracefully
# =========================================
set -e

# =========================================
# Colors and Logging Helpers
# =========================================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✔ $1${NC}"; }
log_error() { echo -e "${RED}✘ $1${NC}"; }
log_info() { echo -e "${YELLOW}➜ $1${NC}"; }
log_header() { echo -e "${BLUE}═══ $1 ═══${NC}"; }
log_step() { echo -e "${CYAN}  ▸ $1${NC}"; }
log_service() { echo -e "${MAGENTA}  ◆ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# =========================================
# Global Variables - Initialize ALL
# =========================================
PKG_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""
IS_AMAZON_LINUX="false"
AMAZON_LINUX_VERSION=""
NEEDS_REBOOT="false"
OS_ID=""
OS_VERSION=""
ARCH=""
ARCH_ALT=""

# =========================================
# Helper: Detect Architecture
# =========================================
detect_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            ARCH_ALT="amd64"
            ;;
        aarch64|arm64)
            ARCH_ALT="arm64"
            ARCH="aarch64"
            ;;
        armv7l)
            ARCH_ALT="armv7"
            ;;
        *)
            ARCH_ALT="$ARCH"
            ;;
    esac
    log_info "Architecture: $ARCH ($ARCH_ALT)"
}

# =========================================
# Helper: Detect OS and Package Manager
# =========================================
detect_os() {
    OS_ID="unknown"
    OS_VERSION="unknown"
    
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_VERSION="${VERSION_ID:-unknown}"
    elif [ -f /etc/redhat-release ]; then
        OS_ID="rhel"
        OS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+' | head -1)
    elif [ -f /etc/debian_version ]; then
        OS_ID="debian"
        OS_VERSION=$(cat /etc/debian_version)
    fi
    
    log_info "Detected OS: $OS_ID $OS_VERSION"
}

detect_package_manager() {
    detect_os
    
    # Check for Amazon Linux first
    if [ "$OS_ID" = "amzn" ]; then
        IS_AMAZON_LINUX="true"
        AMAZON_LINUX_VERSION="$OS_VERSION"
        log_info "Detected Amazon Linux $AMAZON_LINUX_VERSION"
        
        if [ "$AMAZON_LINUX_VERSION" = "2023" ]; then
            PKG_MANAGER="dnf"
            INSTALL_CMD="sudo dnf install -y"
            UPDATE_CMD="sudo dnf makecache"
        else
            PKG_MANAGER="yum"
            INSTALL_CMD="sudo yum install -y"
            UPDATE_CMD="sudo yum makecache"
        fi
        return 0
    fi
    
    # Check for package managers
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update -y"
        log_info "Detected apt package manager (Debian/Ubuntu)"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf makecache"
        log_info "Detected dnf package manager (Fedora/RHEL)"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        INSTALL_CMD="sudo yum install -y"
        UPDATE_CMD="sudo yum makecache"
        log_info "Detected yum package manager (CentOS/RHEL)"
    else
        log_error "Unsupported package manager. Only apt, yum, and dnf are supported."
        exit 1
    fi
}

# =========================================
# Helper: Safe download with retry
# =========================================
safe_download() {
    local url="$1"
    local output="$2"
    local retries=3
    local count=0
    
    while [ $count -lt $retries ]; do
        if curl -fsSL --connect-timeout 30 --max-time 300 -o "$output" "$url" 2>/dev/null; then
            # Verify file was downloaded and has content
            if [ -f "$output" ] && [ -s "$output" ]; then
                return 0
            fi
        fi
        if wget -q --timeout=30 -O "$output" "$url" 2>/dev/null; then
            if [ -f "$output" ] && [ -s "$output" ]; then
                return 0
            fi
        fi
        count=$((count + 1))
        log_info "Download attempt $count failed, retrying..."
        sleep 2
    done
    
    log_error "Failed to download: $url"
    return 1
}

# =========================================
# Helper: Get Latest GitHub Release
# =========================================
get_github_release() {
    local repo="$1"
    local version=""
    
    version=$(curl -fsSL --connect-timeout 10 "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | \
        grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    if [ -z "$version" ]; then
        log_error "Could not fetch version for $repo"
        return 1
    fi
    
    echo "$version"
}

# =========================================
# Helper: Check if command exists
# =========================================
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =========================================
# Helper: Install base dependencies
# =========================================
install_base_deps() {
    log_info "Installing base dependencies..."
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD curl wget unzip tar gnupg2 ca-certificates lsb-release apt-transport-https software-properties-common || true
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        $INSTALL_CMD curl wget unzip tar gnupg2 ca-certificates which || true
    else
        $INSTALL_CMD curl wget unzip tar gnupg2 ca-certificates which || true
    fi
}

# =========================================
# Helper: Show System Info
# =========================================
show_system_info() {
    echo "═══════════════════════════════════════════"
    echo "          SYSTEM INFORMATION               "
    echo "═══════════════════════════════════════════"
    echo "OS: $OS_ID $OS_VERSION"
    echo "Architecture: $ARCH ($ARCH_ALT)"
    echo "Package Manager: $PKG_MANAGER"
    
    if [ -f /proc/cpuinfo ]; then
        local cpu_cores
        cpu_cores=$(grep -c processor /proc/cpuinfo 2>/dev/null || echo "Unknown")
        echo "CPU Cores: $cpu_cores"
    fi
    
    if command_exists free; then
        local memory
        memory=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown")
        echo "Memory: $memory"
    fi
    
    if command_exists df; then
        local disk
        disk=$(df -h / 2>/dev/null | awk 'NR==2 {print $4 " available of " $2}' || echo "Unknown")
        echo "Disk: $disk"
    fi
    
    echo "═══════════════════════════════════════════"
    echo ""
}

# =========================================
# Show Versions and Locations
# =========================================
show_versions() {
    # Temporarily disable exit on error for this function
    set +e
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              📦 INSTALLED TOOLS STATUS REPORT                  ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Source cargo env if exists
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env" 2>/dev/null || true
    fi

    # --- Languages & Build Tools ---
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  LANGUAGES & BUILD TOOLS                                        │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${WHITE}--- Java (OpenJDK) ---${NC}"
    if command -v java >/dev/null 2>&1; then
        java -version 2>&1 | head -n 1
        log_success "Location: $(command -v java)"
        if [ -n "$JAVA_HOME" ]; then
            log_success "JAVA_HOME: $JAVA_HOME"
        fi
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Git ---${NC}"
    if command -v git >/dev/null 2>&1; then
        git --version
        log_success "Location: $(command -v git)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Maven ---${NC}"
    if command -v mvn >/dev/null 2>&1; then
        mvn -version 2>&1 | head -n 1
        log_success "Location: $(command -v mvn)"
        if [ -d "/opt/maven" ]; then
            log_success "Maven Home: /opt/maven"
        fi
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Gradle ---${NC}"
    if command -v gradle >/dev/null 2>&1; then
        gradle --version 2>&1 | grep -E "^Gradle" | head -n1 || echo "Gradle installed"
        log_success "Location: $(command -v gradle)"
        if [ -d "/opt/gradle" ]; then
            log_success "Gradle Home: /opt/gradle"
        fi
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Node.js ---${NC}"
    if command -v node >/dev/null 2>&1; then
        echo "Node: $(node --version 2>/dev/null)"
        if command -v npm >/dev/null 2>&1; then
            echo "NPM: $(npm --version 2>/dev/null)"
        fi
        log_success "Location: $(command -v node)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Python 3 ---${NC}"
    if command -v python3 >/dev/null 2>&1; then
        python3 --version 2>&1
        if command -v pip3 >/dev/null 2>&1; then
            echo "Pip: $(pip3 --version 2>&1 | head -n1)"
        fi
        log_success "Location: $(command -v python3)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Rust & Cargo ---${NC}"
    if command -v rustc >/dev/null 2>&1; then
        rustc --version 2>&1
        if command -v cargo >/dev/null 2>&1; then
            cargo --version 2>&1
            log_success "Location: $(command -v cargo)"
        fi
    else
        log_error "Not installed"
    fi
    echo ""

    # --- DevOps & CI/CD ---
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  DEVOPS & CI/CD TOOLS                                           │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"

    echo -e "${WHITE}--- Ansible ---${NC}"
    if command -v ansible >/dev/null 2>&1; then
        ansible --version 2>&1 | head -n 1
        log_success "Location: $(command -v ansible)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Docker ---${NC}"
    if command -v docker >/dev/null 2>&1; then
        docker --version 2>&1
        log_success "Location: $(command -v docker)"
        if systemctl is-active --quiet docker 2>/dev/null; then
            log_success "Service: Active (Running)"
        else
            log_info "Service: Inactive"
        fi
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Jenkins ---${NC}"
    local jenkins_found=false
    local jenkins_war=""
    local jenkins_ver=""
    
    # Find Jenkins WAR file location
    if [ -f /usr/share/jenkins/jenkins.war ]; then
        jenkins_war="/usr/share/jenkins/jenkins.war"
        jenkins_found=true
    elif [ -f /usr/share/java/jenkins.war ]; then
        jenkins_war="/usr/share/java/jenkins.war"
        jenkins_found=true
    elif [ -f /var/lib/jenkins/jenkins.war ]; then
        jenkins_war="/var/lib/jenkins/jenkins.war"
        jenkins_found=true
    elif [ -f /opt/jenkins/jenkins.war ]; then
        jenkins_war="/opt/jenkins/jenkins.war"
        jenkins_found=true
    fi
    
    if [ -n "$jenkins_war" ]; then
        log_success "Jenkins WAR: $jenkins_war"
        
        # Try to get version from the WAR file manifest
        if command -v unzip >/dev/null 2>&1; then
            jenkins_ver=$(unzip -p "$jenkins_war" META-INF/MANIFEST.MF 2>/dev/null | grep -i "Jenkins-Version" | cut -d':' -f2 | tr -d ' \r\n')
            
            # Alternative: check Implementation-Version
            if [ -z "$jenkins_ver" ]; then
                jenkins_ver=$(unzip -p "$jenkins_war" META-INF/MANIFEST.MF 2>/dev/null | grep -i "Implementation-Version" | cut -d':' -f2 | tr -d ' \r\n')
            fi
            
            # Alternative: check Specification-Version
            if [ -z "$jenkins_ver" ]; then
                jenkins_ver=$(unzip -p "$jenkins_war" META-INF/MANIFEST.MF 2>/dev/null | grep -i "^Specification-Version" | cut -d':' -f2 | tr -d ' \r\n')
            fi
            
            # Alternative: check Main-Class path in pom.properties
            if [ -z "$jenkins_ver" ]; then
                jenkins_ver=$(unzip -p "$jenkins_war" WEB-INF/classes/jenkins/model/Jenkins.class 2>/dev/null | strings | grep -E "^[0-9]+\.[0-9]+" | head -1)
            fi
        fi
        
        # Check version from dpkg/rpm if available
        if [ -z "$jenkins_ver" ]; then
            if command -v dpkg >/dev/null 2>&1; then
                jenkins_ver=$(dpkg -l jenkins 2>/dev/null | grep "^ii" | awk '{print $3}')
            elif command -v rpm >/dev/null 2>&1; then
                jenkins_ver=$(rpm -q jenkins 2>/dev/null | sed 's/jenkins-//')
            fi
        fi
        
        if [ -n "$jenkins_ver" ]; then
            log_success "Version: $jenkins_ver"
        else
            log_info "Version: installed (unable to detect)"
        fi
    fi
    
    # Check systemd service
    if systemctl list-unit-files 2>/dev/null | grep -q "^jenkins"; then
        jenkins_found=true
        if systemctl is-active --quiet jenkins 2>/dev/null; then
            log_success "Service: Active (Running)"
            # Try to get version from running instance (only if we don't have it yet)
            if [ -z "$jenkins_ver" ]; then
                local running_ver
                running_ver=$(curl -s --connect-timeout 2 http://localhost:8080/api/json 2>/dev/null | grep -oP '"version"\s*:\s*"\K[^"]+' || true)
                if [ -n "$running_ver" ]; then
                    log_success "Running Version: $running_ver"
                fi
            fi
        else
            log_info "Service: Installed (not running)"
        fi
    fi
    
    if [ "$jenkins_found" = false ]; then
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- ArgoCD CLI ---${NC}"
    if command -v argocd >/dev/null 2>&1; then
        argocd version --client 2>&1 | head -n1
        log_success "Location: $(command -v argocd)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Terraform ---${NC}"
    if command -v terraform >/dev/null 2>&1; then
        terraform --version 2>&1 | head -n 1
        log_success "Location: $(command -v terraform)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Trivy ---${NC}"
    if command -v trivy >/dev/null 2>&1; then
        trivy --version 2>&1 | head -n1
        log_success "Location: $(command -v trivy)"
    else
        log_error "Not installed"
    fi
    echo ""

    # --- Cloud CLIs ---
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  CLOUD CLIs                                                     │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"

    echo -e "${WHITE}--- AWS CLI ---${NC}"
    if command -v aws >/dev/null 2>&1; then
        aws --version 2>&1
        log_success "Location: $(command -v aws)"
    else
        log_error "Not installed"
    fi
    echo ""

    #  Azure CLI - suppress update warnings completely
    echo -e "${WHITE}--- Azure CLI ---${NC}"
    if command -v az >/dev/null 2>&1; then
        local az_ver=""
        
        # Method 1: Use az version with output filtering (suppress update warnings)
        az_ver=$(az version --output tsv 2>/dev/null | grep "^azure-cli" | awk '{print $2}' | head -1)
        
        # Method 2: Query with JMESPath
        if [ -z "$az_ver" ]; then
            az_ver=$(az version --query '"azure-cli"' -o tsv 2>/dev/null | head -1)
        fi
        
        # Method 3: Parse JSON output
        if [ -z "$az_ver" ]; then
            az_ver=$(az version -o json 2>/dev/null | grep -oP '"azure-cli":\s*"\K[^"]+' | head -1)
        fi
        
        # Method 4: Try az --version with stderr suppression
        if [ -z "$az_ver" ]; then
            az_ver=$(az --version 2>/dev/null | grep -E "^azure-cli" | head -n1 | awk '{print $2}')
        fi
        
        # Method 5: Check from package manager
        if [ -z "$az_ver" ]; then
            if command -v dpkg >/dev/null 2>&1; then
                az_ver=$(dpkg -l azure-cli 2>/dev/null | grep "^ii" | awk '{print $3}')
            elif command -v rpm >/dev/null 2>&1; then
                az_ver=$(rpm -q azure-cli 2>/dev/null | sed 's/azure-cli-//')
            fi
        fi
        
        if [ -n "$az_ver" ]; then
            echo "azure-cli $az_ver"
        else
            log_info "Version: installed (unable to detect)"
        fi
        
        log_success "Location: $(command -v az)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Google Cloud CLI ---${NC}"
    if command -v gcloud >/dev/null 2>&1; then
        gcloud --version 2>&1 | head -n 1
        log_success "Location: $(command -v gcloud)"
    else
        local gcloud_dir=""
        for gdir in /opt/google-cloud-sdk /usr/share/google-cloud-sdk /usr/lib/google-cloud-sdk "$HOME/google-cloud-sdk"; do
            if [ -f "$gdir/bin/gcloud" ]; then
                gcloud_dir="$gdir"
                break
            fi
        done
        if [ -n "$gcloud_dir" ]; then
            "$gcloud_dir/bin/gcloud" --version 2>&1 | head -n1
            log_success "Location: $gcloud_dir/bin/gcloud"
        else
            log_error "Not installed"
        fi
    fi
    echo ""

    # --- Kubernetes ---
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  KUBERNETES TOOLS                                               │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"

    echo -e "${WHITE}--- kubectl ---${NC}"
    if command -v kubectl >/dev/null 2>&1; then
        kubectl version --client 2>&1 | head -n1
        log_success "Location: $(command -v kubectl)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Helm ---${NC}"
    if command -v helm >/dev/null 2>&1; then
        helm version --short 2>&1
        log_success "Location: $(command -v helm)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- k9s ---${NC}"
    if command -v k9s >/dev/null 2>&1; then
        k9s version --short 2>&1 | head -n1
        log_success "Location: $(command -v k9s)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Minikube ---${NC}"
    if command -v minikube >/dev/null 2>&1; then
        minikube version 2>&1 | head -n1
        log_success "Location: $(command -v minikube)"
    else
        log_error "Not installed"
    fi
    echo ""

    # --- Monitoring ---
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  MONITORING                                                     │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"

    echo -e "${WHITE}--- Prometheus ---${NC}"
    if command -v prometheus >/dev/null 2>&1; then
        prometheus --version 2>&1 | head -n1
        log_success "Location: $(command -v prometheus)"
    elif [ -d "/opt/prometheus" ]; then
        log_success "Prometheus detected at /opt/prometheus"
        if [ -x /opt/prometheus/prometheus ]; then
            /opt/prometheus/prometheus --version 2>&1 | head -n1
        fi
    else
        log_error "Not installed"
    fi
    if systemctl is-active --quiet prometheus 2>/dev/null; then
        log_success "Service: Active (Running)"
    elif systemctl list-unit-files 2>/dev/null | grep -q "^prometheus"; then
        log_info "Service: Installed (not running)"
    fi
    echo ""

    echo -e "${WHITE}--- Grafana ---${NC}"
    if command -v grafana-server >/dev/null 2>&1; then
        grafana-server -v 2>&1 | head -n1
        log_success "Location: $(command -v grafana-server)"
    elif command -v grafana >/dev/null 2>&1; then
        grafana -v 2>&1 | head -n1
        log_success "Location: $(command -v grafana)"
    else
        # Check if installed but not in PATH
        if [ -f /usr/sbin/grafana-server ]; then
            /usr/sbin/grafana-server -v 2>&1 | head -n1
            log_success "Location: /usr/sbin/grafana-server"
        else
            log_info "Binary not in PATH"
        fi
    fi
    if systemctl is-active --quiet grafana-server 2>/dev/null; then
        log_success "Service: Active (Running)"
    elif systemctl list-unit-files 2>/dev/null | grep -q "^grafana-server"; then
        log_info "Service: Installed (not running)"
    fi
    echo ""

    # --- Web Servers ---
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  WEB SERVERS                                                    │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"

    echo -e "${WHITE}--- Nginx ---${NC}"
    if command -v nginx >/dev/null 2>&1; then
        nginx -v 2>&1 | head -n 1
        log_success "Location: $(command -v nginx)"
        if systemctl is-active --quiet nginx 2>/dev/null; then
            log_success "Service: Active (Running)"
        else
            log_info "Service: Inactive"
        fi
    else
        log_error "Not installed"
    fi
    echo ""

    # Tomcat version and service detection - improved for all OS
    echo -e "${WHITE}--- Tomcat ---${NC}"
    local tomcat_dir=""
    # Find tomcat directory with additional common paths
    if [ -d "/usr/local/tomcat" ]; then
        tomcat_dir="/usr/local/tomcat"
    elif [ -d "/opt/tomcat" ]; then
        tomcat_dir="/opt/tomcat"
    elif [ -d "/var/lib/tomcat" ]; then
        tomcat_dir="/var/lib/tomcat"
    elif [ -d "/usr/share/tomcat" ]; then
        tomcat_dir="/usr/share/tomcat"
    fi
    
    if [ -n "$tomcat_dir" ]; then
        log_success "Tomcat detected at $tomcat_dir"
        local tomcat_ver=""
        
        # Method 1: Check RELEASE-NOTES first (most reliable, no Java/sudo needed)
        if [ -r "${tomcat_dir}/RELEASE-NOTES" ]; then
            tomcat_ver=$(grep -i "Apache Tomcat Version" "${tomcat_dir}/RELEASE-NOTES" 2>/dev/null | head -1 | sed 's/.*Version //;s/^[[:space:]]*//')
        fi
        
        # Method 2: Check jar manifest (no Java runtime needed, just unzip)
        if [ -z "$tomcat_ver" ]; then
            local catalina_jar=""
            # Check common paths directly before resorting to find
            if [ -r "${tomcat_dir}/lib/catalina.jar" ]; then
                catalina_jar="${tomcat_dir}/lib/catalina.jar"
            else
                catalina_jar=$(find "${tomcat_dir}" -name "catalina.jar" -readable 2>/dev/null | head -1)
                if [ -z "$catalina_jar" ] && command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
                    catalina_jar=$(sudo find "${tomcat_dir}" -name "catalina.jar" 2>/dev/null | head -1)
                fi
            fi
            
            if [ -n "$catalina_jar" ] && command -v unzip >/dev/null 2>&1; then
                if [ -r "$catalina_jar" ]; then
                    tomcat_ver=$(unzip -p "$catalina_jar" META-INF/MANIFEST.MF 2>/dev/null | grep -i "Implementation-Version" | cut -d':' -f2 | tr -d ' \r\n' | head -c 20)
                elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
                    tomcat_ver=$(sudo unzip -p "$catalina_jar" META-INF/MANIFEST.MF 2>/dev/null | grep -i "Implementation-Version" | cut -d':' -f2 | tr -d ' \r\n' | head -c 20)
                fi
            fi
        fi
        
        # Method 3: Use version.sh if it exists (requires Java)
        if [ -z "$tomcat_ver" ] && [ -f "${tomcat_dir}/bin/version.sh" ]; then
            local java_home_bak="${JAVA_HOME:-}"
            if [ -z "$JAVA_HOME" ] && command -v java >/dev/null 2>&1; then
                JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
                export JAVA_HOME
            fi
            
            if [ -x "${tomcat_dir}/bin/version.sh" ]; then
                tomcat_ver=$(${tomcat_dir}/bin/version.sh 2>/dev/null | grep -i "Server version" | sed 's/Server version: //;s/Apache Tomcat\///;s/^[[:space:]]*//')
            elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
                tomcat_ver=$(sudo "${tomcat_dir}/bin/version.sh" 2>/dev/null | grep -i "Server version" | sed 's/Server version: //;s/Apache Tomcat\///;s/^[[:space:]]*//')
            elif [ -r "${tomcat_dir}/bin/version.sh" ]; then
                tomcat_ver=$(bash "${tomcat_dir}/bin/version.sh" 2>/dev/null | grep -i "Server version" | sed 's/Server version: //;s/Apache Tomcat\///;s/^[[:space:]]*//')
            fi
            
            if [ -n "$java_home_bak" ]; then
                JAVA_HOME="$java_home_bak"
                export JAVA_HOME
            elif [ -n "${JAVA_HOME:-}" ]; then
                unset JAVA_HOME
            fi
        fi
        
        # Method 4: Try catalina.sh version (requires Java)
        if [ -z "$tomcat_ver" ] && [ -f "${tomcat_dir}/bin/catalina.sh" ]; then
            if command -v java >/dev/null 2>&1; then
                local java_home_bak="${JAVA_HOME:-}"
                if [ -z "$JAVA_HOME" ]; then
                    JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
                    export JAVA_HOME
                fi
                
                if [ -x "${tomcat_dir}/bin/catalina.sh" ]; then
                    tomcat_ver=$(${tomcat_dir}/bin/catalina.sh version 2>/dev/null | grep -i "Server version" | sed 's/Server version: //;s/Apache Tomcat\///;s/^[[:space:]]*//')
                elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
                    tomcat_ver=$(sudo "${tomcat_dir}/bin/catalina.sh" version 2>/dev/null | grep -i "Server version" | sed 's/Server version: //;s/Apache Tomcat\///;s/^[[:space:]]*//')
                fi
                
                if [ -n "$java_home_bak" ]; then
                    JAVA_HOME="$java_home_bak"
                    export JAVA_HOME
                elif [ -n "${JAVA_HOME:-}" ]; then
                    unset JAVA_HOME
                fi
            fi
        fi
        
        # Method 5: Check from systemd service file if exists
        if [ -z "$tomcat_ver" ]; then
            local systemd_ver
            systemd_ver=$(systemctl cat tomcat 2>/dev/null | grep -i "description.*tomcat" | grep -oP '\d+\.\d+\.\d+' | head -1)
            if [ -n "$systemd_ver" ]; then
                tomcat_ver="$systemd_ver"
            fi
        fi
        
        if [ -n "$tomcat_ver" ]; then
            log_success "Version: $tomcat_ver"
        else
            log_info "Version: installed (unable to detect)"
        fi
        
        # Check for systemd service with various naming patterns
        local tomcat_service=""
        if systemctl list-unit-files 2>/dev/null | grep -qE "^tomcat\.service"; then
            tomcat_service="tomcat"
        elif systemctl list-unit-files 2>/dev/null | grep -qE "^tomcat[0-9]*\.service"; then
            tomcat_service=$(systemctl list-unit-files 2>/dev/null | grep -E "^tomcat[0-9]*\.service" | head -1 | awk '{print $1}' | sed 's/.service//')
        fi
        
        if [ -n "$tomcat_service" ]; then
            if systemctl is-active --quiet "$tomcat_service" 2>/dev/null; then
                log_success "Service: Active (Running)"
            else
                log_info "Service: Installed (not running)"
            fi
        else
            log_info "Service: No systemd service configured"
            log_info "Start manually: ${tomcat_dir}/bin/startup.sh"
        fi
        
        # Check if Tomcat is running by checking the process
        if pgrep -f "catalina" >/dev/null 2>&1 || pgrep -f "tomcat" >/dev/null 2>&1; then
            log_success "Process: Running"
        fi
    else
        log_error "Not installed"
    fi
    echo ""

    # --- Terminal Utilities ---
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  TERMINAL UTILITIES                                             │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"

    echo -e "${WHITE}--- Lazydocker ---${NC}"
    if command -v lazydocker >/dev/null 2>&1; then
        lazydocker --version 2>&1 | head -n1
        log_success "Location: $(command -v lazydocker)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Yazi ---${NC}"
    if command -v yazi >/dev/null 2>&1; then
        yazi --version 2>&1 | head -n1
        log_success "Location: $(command -v yazi)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Bat ---${NC}"
    if command -v bat >/dev/null 2>&1; then
        bat --version 2>&1 | head -n1
        log_success "Location: $(command -v bat)"
    elif command -v batcat >/dev/null 2>&1; then
        batcat --version 2>&1 | head -n1
        log_success "Location: $(command -v batcat)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Croc ---${NC}"
    if command -v croc >/dev/null 2>&1; then
        croc --version 2>&1 | head -n1
        log_success "Location: $(command -v croc)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Btop ---${NC}"
    if command -v btop >/dev/null 2>&1; then
        btop --version 2>&1 | head -n1
        log_success "Location: $(command -v btop)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Fzf ---${NC}"
    if command -v fzf >/dev/null 2>&1; then
        fzf --version 2>&1 | head -n1
        log_success "Location: $(command -v fzf)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Zoxide ---${NC}"
    if command -v zoxide >/dev/null 2>&1; then
        zoxide --version 2>&1 | head -n1
        log_success "Location: $(command -v zoxide)"
    elif [ -f "$HOME/.local/bin/zoxide" ]; then
        "$HOME/.local/bin/zoxide" --version 2>&1 | head -n1
        log_success "Location: $HOME/.local/bin/zoxide"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Atuin ---${NC}"
    if command -v atuin >/dev/null 2>&1; then
        atuin --version 2>&1 | head -n1
        log_success "Location: $(command -v atuin)"
    elif [ -f "$HOME/.atuin/bin/atuin" ]; then
        "$HOME/.atuin/bin/atuin" --version 2>&1 | head -n1
        log_success "Location: $HOME/.atuin/bin/atuin"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Gdu ---${NC}"
    if command -v gdu >/dev/null 2>&1; then
        gdu --version 2>&1 | head -n1
        log_success "Location: $(command -v gdu)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- JQ ---${NC}"
    if command -v jq >/dev/null 2>&1; then
        local jq_ver
        # jq --version outputs "jq-1.6" or similar
        jq_ver=$(jq --version 2>&1 | head -n1)
        if [ -n "$jq_ver" ]; then
            # Clean up version string - strip "jq-" prefix
            local jq_clean="${jq_ver#jq-}"
            if [ -n "$jq_clean" ]; then
                echo "jq version: $jq_clean"
            else
                echo "jq version: $jq_ver"
            fi
        else
            log_info "Version: installed"
        fi
        log_success "Location: $(command -v jq)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${WHITE}--- Eza ---${NC}"
    if command -v eza >/dev/null 2>&1; then
        local eza_ver
        # eza --version outputs: "eza - A modern..." then "v0.20.14 [+git]" on next line
        eza_ver=$(eza --version 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+[^ ]*' | head -1)
        if [ -z "$eza_ver" ]; then
            # Fallback: try to get any version-like string
            eza_ver=$(eza --version 2>&1 | grep -iE '[0-9]+\.[0-9]+' | head -1)
        fi
        if [ -n "$eza_ver" ]; then
            echo "eza $eza_ver"
        else
            log_info "Version: installed (version detection unavailable)"
        fi
        log_success "Location: $(command -v eza)"
    else
        log_error "Not installed"
    fi
    echo ""

    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    # Re-enable exit on error
    set -e
}

# =========================================
# Helper: Dynamically detect configured port
# =========================================
get_configured_port() {
    local service="$1"
    local port=""

    case "$service" in

        # ── TOMCAT ──
        tomcat)
            local server_xml=""
            for dir in /usr/local/tomcat /opt/tomcat /var/lib/tomcat /usr/share/tomcat; do
                if [ -f "$dir/conf/server.xml" ]; then
                    server_xml="$dir/conf/server.xml"
                    break
                fi
            done

            if [ -n "$server_xml" ]; then
                local xml_content=""
                if [ -r "$server_xml" ]; then
                    xml_content=$(cat "$server_xml")
                elif command -v sudo >/dev/null 2>&1; then
                    xml_content=$(sudo cat "$server_xml" 2>/dev/null)
                fi

                if [ -n "$xml_content" ]; then
                    # Strip XML comments, collapse to one line
                    local clean_xml
                    clean_xml=$(echo "$xml_content" | \
                        awk 'BEGIN{c=0} /<!--/{c=1} {if(!c) print} /-->/{c=0}' | \
                        tr '\n' ' ')

                    # Method 1: Find <Connector> with protocol="HTTP/1.1" — extract port
                    port=$(echo "$clean_xml" | \
                        grep -oP '<Connector\b[^>]*>' | \
                        grep -i 'HTTP/1\.1' | head -1 | \
                        grep -oP 'port\s*=\s*"\K\d+')

                    # Method 2: First Connector that is NOT AJP
                    if [ -z "$port" ]; then
                        port=$(echo "$clean_xml" | \
                            grep -oP '<Connector\b[^>]*>' | \
                            grep -iv 'AJP' | head -1 | \
                            grep -oP 'port\s*=\s*"\K\d+')
                    fi

                    # Method 3: Any Connector port excluding 8009 (AJP) and 8443 (HTTPS redirect)
                    if [ -z "$port" ]; then
                        port=$(echo "$clean_xml" | \
                            grep -oP '<Connector\b[^>]*port\s*=\s*"\K\d+' | \
                            grep -vE '^(8009|8443)$' | head -1)
                    fi
                fi
            fi
            ;;

        # ── JENKINS ──
        jenkins)
            # Method 1: systemd unit file (WAR-based installs)
            port=$(systemctl cat jenkins 2>/dev/null | \
                grep -oP '\-\-httpPort=\K\d+' | head -1)

            # Method 2: /etc/default/jenkins (Debian/Ubuntu package)
            if [ -z "$port" ] && [ -f /etc/default/jenkins ]; then
                port=$(grep -E '^\s*HTTP_PORT=' /etc/default/jenkins 2>/dev/null | \
                    cut -d= -f2 | tr -d '"'"'" | tr -d ' ' | head -1)
                if [ -z "$port" ]; then
                    port=$(grep -E '^\s*JENKINS_PORT=' /etc/default/jenkins 2>/dev/null | \
                        cut -d= -f2 | tr -d '"'"'" | tr -d ' ' | head -1)
                fi
            fi

            # Method 3: /etc/sysconfig/jenkins (RHEL/CentOS package)
            if [ -z "$port" ] && [ -f /etc/sysconfig/jenkins ]; then
                port=$(grep -E '^\s*JENKINS_PORT=' /etc/sysconfig/jenkins 2>/dev/null | \
                    cut -d= -f2 | tr -d '"'"'" | tr -d ' ' | head -1)
            fi

            # Method 4: jenkins.yaml (Configuration as Code)
            if [ -z "$port" ] && [ -f /var/lib/jenkins/jenkins.yaml ]; then
                port=$(grep -oP '^\s*httpPort:\s*\K\d+' /var/lib/jenkins/jenkins.yaml 2>/dev/null | head -1)
            fi
            ;;

        # ── PROMETHEUS ──
        prometheus)
            # Method 1: systemd unit file
            port=$(systemctl cat prometheus 2>/dev/null | \
                grep -oP '\-\-web\.listen-address=\S*:\K\d+' | head -1)

            # Method 2: prometheus.yml (web section, less common)
            if [ -z "$port" ] && [ -f /etc/prometheus/prometheus.yml ]; then
                port=$(grep -oP '^\s*listen-address\s*:\s*.*:\K\d+' \
                    /etc/prometheus/prometheus.yml 2>/dev/null | head -1)
            fi

            # Method 3: /etc/default/prometheus or /etc/sysconfig/prometheus
            if [ -z "$port" ]; then
                for cfg in /etc/default/prometheus /etc/sysconfig/prometheus; do
                    if [ -f "$cfg" ]; then
                        port=$(grep -oP '\-\-web\.listen-address=\S*:\K\d+' "$cfg" 2>/dev/null | head -1)
                        [ -n "$port" ] && break
                    fi
                done
            fi
            ;;

        # ── GRAFANA ──
        grafana|grafana-server)
            # Method 1: grafana.ini (uncommented http_port)
            if [ -f /etc/grafana/grafana.ini ]; then
                port=$(grep -E '^\s*http_port\s*=' /etc/grafana/grafana.ini 2>/dev/null | \
                    sed 's/.*=\s*//' | tr -d ' ' | head -1)
            fi

            # Method 2: custom.ini override
            if [ -z "$port" ] && [ -f /etc/grafana/custom.ini ]; then
                port=$(grep -E '^\s*http_port\s*=' /etc/grafana/custom.ini 2>/dev/null | \
                    sed 's/.*=\s*//' | tr -d ' ' | head -1)
            fi

            # Method 3: grafana.ini in provisioning or other paths
            if [ -z "$port" ]; then
                for cfg in /etc/grafana/grafana.ini /usr/share/grafana/conf/defaults.ini; do
                    if [ -f "$cfg" ]; then
                        port=$(grep -E '^\s*http_port\s*=' "$cfg" 2>/dev/null | \
                            sed 's/.*=\s*//' | tr -d ' ' | head -1)
                        [ -n "$port" ] && break
                    fi
                done
            fi
            ;;

        # ── NGINX ──
        nginx)
            # Method 1: Main nginx.conf
            if [ -f /etc/nginx/nginx.conf ]; then
                port=$(grep -E '^\s*listen\s+' /etc/nginx/nginx.conf 2>/dev/null | \
                    grep -v '^\s*#' | head -1 | grep -oP '\d+' | head -1)
            fi

            # Method 2: sites-enabled (Debian/Ubuntu style)
            if [ -z "$port" ] && [ -d /etc/nginx/sites-enabled ]; then
                port=$(grep -rhE '^\s*listen\s+' /etc/nginx/sites-enabled/ 2>/dev/null | \
                    grep -v '^\s*#' | head -1 | grep -oP '\d+' | head -1)
            fi

            # Method 3: conf.d (RHEL/CentOS style)
            if [ -z "$port" ] && [ -d /etc/nginx/conf.d ]; then
                port=$(grep -rhE '^\s*listen\s+' /etc/nginx/conf.d/ 2>/dev/null | \
                    grep -v '^\s*#' | head -1 | grep -oP '\d+' | head -1)
            fi
            ;;
    esac

    # Return the detected port (empty string if not found — caller uses fallback)
    echo "$port"
}
# =========================================
# Check Services and Ports
# =========================================
check_services_ports() {
    # Temporarily disable exit on error
    set +e
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              🌐 SERVICES & PORTS STATUS                         ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Get public/local IP
    local IP
    IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || curl -s --connect-timeout 5 icanhazip.com 2>/dev/null || echo "localhost")
    local LOCAL_IP
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1")
    
    echo -e "${CYAN}📍 Public IP:  ${WHITE}$IP${NC}"
    echo -e "${CYAN}📍 Local IP:   ${WHITE}$LOCAL_IP${NC}"
    echo ""

    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  WEB SERVICES & PORTS                                           │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    # ── Dynamically detect each service's configured port ──
    local jenkins_port prometheus_port grafana_port nginx_port tomcat_port

    jenkins_port=$(get_configured_port jenkins)
    prometheus_port=$(get_configured_port prometheus)
    grafana_port=$(get_configured_port grafana)
    nginx_port=$(get_configured_port nginx)
    tomcat_port=$(get_configured_port tomcat)

    # Use detected port or fall back to well-known default
    check_service_port_item "jenkins"    "jenkins|java.*jenkins"  "${jenkins_port:-8080}"    "$IP"
    check_service_port_item "prometheus" "prometheus"             "${prometheus_port:-9090}"  "$IP"
    check_service_port_item "grafana"    "grafana"                "${grafana_port:-3000}"     "$IP"
    check_service_port_item "nginx"      "nginx"                  "${nginx_port:-80}"         "$IP"
    check_service_port_item "tomcat"     "tomcat|catalina"        "${tomcat_port:-8080}"      "$IP"

    # Docker status (uses Unix socket, not TCP port)
    printf "%-15s: " "docker"
    if systemctl is-active --quiet docker 2>/dev/null; then
        echo -e "${GREEN}● Service: Active (Running via Unix socket)${NC}"
    elif systemctl list-unit-files 2>/dev/null | grep -q "^docker"; then
        echo -e "${YELLOW}○ Service installed but not running${NC}"
    elif command -v docker >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Docker installed but service not detected${NC}"
    else
        echo -e "${RED}✘  Not installed${NC}"
    fi

    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  ALL LISTENING PORTS                                            │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Show all listening ports
    echo -e "${WHITE}Port      Process${NC}"
    echo "────────────────────────────────────────"
    
    if command -v ss >/dev/null 2>&1; then
        sudo ss -tlnp 2>/dev/null | grep LISTEN | while read -r line; do
            local port=$(echo "$line" | awk '{print $4}' | grep -oE '[0-9]+$')
            local process=$(echo "$line" | grep -oP '(?<=users:\(\()[^,]+' | tr -d '"')
            if [ -n "$port" ] && [ -n "$process" ]; then
                printf "%-9s %s\n" "$port" "$process"
            fi
        done | sort -t' ' -k1 -n | uniq
    elif command -v netstat >/dev/null 2>&1; then
        sudo netstat -tlnp 2>/dev/null | grep LISTEN | while read -r line; do
            local port=$(echo "$line" | awk '{print $4}' | grep -oE '[0-9]+$')
            local process=$(echo "$line" | awk '{print $7}' | cut -d'/' -f2)
            if [ -n "$port" ] && [ -n "$process" ]; then
                printf "%-9s %s\n" "$port" "$process"
            fi
        done | sort -t' ' -k1 -n | uniq
    else
        log_info "Neither ss nor netstat available for port listing"
    fi

    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    # Re-enable exit on error
    set -e
}

# Helper function to check individual service port
check_service_port_item() {
    local name="$1"
    local pattern="$2"
    local default_port="$3"
    local ip="$4"
    
    local port=""
    local port_source=""
    
    # ── Method 1: ss (find listening port by process name) ──
    if command -v ss >/dev/null 2>&1; then
        port=$(sudo ss -tlnp 2>/dev/null | grep -iE "$pattern" | \
               awk '{print $4}' | grep -oE '[0-9]+$' | head -1)
        [ -n "$port" ] && port_source="detected via ss"
    fi
    
    # ── Method 2: lsof ──
    if [ -z "$port" ] && command -v lsof >/dev/null 2>&1; then
        port=$(sudo lsof -i -P -n 2>/dev/null | grep -iE "$pattern" | \
               grep LISTEN | awk '{print $9}' | cut -d: -f2 | head -1)
        [ -n "$port" ] && port_source="detected via lsof"
    fi
    
    # ── Method 3: netstat ──
    if [ -z "$port" ] && command -v netstat >/dev/null 2>&1; then
        port=$(sudo netstat -tlnp 2>/dev/null | grep -iE "$pattern" | \
               awk '{print $4}' | grep -oE '[0-9]+$' | head -1)
        [ -n "$port" ] && port_source="detected via netstat"
    fi
    
    # ── Method 4: Check if the configured/default port is listening ──
    # Catches Java-based services where process name is "java" not the service name
    if [ -z "$port" ] && [ -n "$default_port" ]; then
        local port_listening=false
        if command -v ss >/dev/null 2>&1; then
            if sudo ss -tlnp 2>/dev/null | grep -qE ":${default_port}\b"; then
                port_listening=true
            fi
        elif command -v netstat >/dev/null 2>&1; then
            if sudo netstat -tlnp 2>/dev/null | grep -qE ":${default_port}\b"; then
                port_listening=true
            fi
        fi
        if [ "$port_listening" = true ]; then
            port="$default_port"
            port_source="from config"
        fi
    fi
    
    # Check systemd service status
    local service_status=""
    if systemctl is-active --quiet "$name" 2>/dev/null; then
        service_status="systemd:active"
    elif systemctl list-unit-files 2>/dev/null | grep -q "^${name}"; then
        service_status="systemd:inactive"
    fi
    
    # Check if process is running
    local process_running=false
    if pgrep -f "$pattern" >/dev/null 2>&1; then
        process_running=true
    fi
    
    # ── Output result ──
    printf "%-15s: " "$name"
    
    if [ -n "$port" ]; then
        echo -e "${GREEN}🌐 Running at: http://${ip}:${port}  ${CYAN}(${port_source})${NC}"
        echo -e "               ${CYAN}Local: http://localhost:${port}${NC}"
    elif [ "$process_running" = true ]; then
        if [ -n "$service_status" ]; then
            echo -e "${YELLOW}⚠️  Process running (port not detected) - $service_status${NC}"
        else
            echo -e "${YELLOW}⚠️  Process running but port not detected${NC}"
        fi
        # Show the configured port as a hint
        if [ -n "$default_port" ]; then
            echo -e "               ${CYAN}Configured port: ${default_port}${NC}"
        fi
    elif [ "$service_status" = "systemd:active" ]; then
        echo -e "${YELLOW}⚠️  Service active but port not detected${NC}"
        if [ -n "$default_port" ]; then
            echo -e "               ${CYAN}Configured port: ${default_port}${NC}"
        fi
    elif [ "$service_status" = "systemd:inactive" ]; then
        echo -e "${RED}○  Service installed but not running${NC}"
        if [ -n "$default_port" ]; then
            echo -e "               ${CYAN}Configured port: ${default_port}${NC}"
        fi
    else
        echo -e "${RED}✘  Not running${NC}"
    fi
}

# =========================================
# Helper: Find first existing directory from candidates
# =========================================
find_tool_dir() {
    for dir in "$@"; do
        # Support glob patterns (e.g., /var/lib/tomcat*)
        for expanded in $dir; do
            if [ -d "$expanded" ]; then
                echo "$expanded"
                return 0
            fi
        done
    done
    return 1
}

# =========================================
# Quick Status Summary
# =========================================
show_quick_status() {
    # Temporarily disable exit on error for this function
    set +e
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}              ⚡ QUICK STATUS SUMMARY                            ${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Source cargo env if exists
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env" 2>/dev/null || true
    fi

    local installed=0
    local not_installed=0

    # CLI Tools to check - using simple array
    local cli_tools="java git mvn gradle node python3 rustc cargo ansible docker terraform trivy argocd aws az gcloud kubectl helm k9s minikube prometheus nginx lazydocker yazi bat croc btop fzf zoxide atuin gdu jq eza"

    echo -e "${CYAN}CLI Tools:${NC}"
    echo -n "  Installed: "
    local installed_list=""
    local missing_list=""
    
    for tool in $cli_tools; do
        if command -v "$tool" >/dev/null 2>&1; then
            installed_list="$installed_list $tool"
            installed=$((installed + 1))
        else
            missing_list="$missing_list $tool"
            not_installed=$((not_installed + 1))
        fi
    done
    
    # Print installed tools
    for tool in $installed_list; do
        echo -n -e "${GREEN}$tool${NC} "
    done
    echo ""
    
    echo -n "  Missing:   "
    # Print missing tools
    for tool in $missing_list; do
        echo -n -e "${RED}$tool${NC} "
    done
    echo ""
    echo ""

    # Directory-based installations (dynamic multi-path detection)
    echo -e "${CYAN}Directory Installations:${NC}"
    
    # Format: "Display Name|path1|path2|path3|..."
    local tool_dir_entries="
Maven|/opt/maven|/usr/share/maven|/opt/devops-tools/maven
Gradle|/opt/gradle|/usr/share/gradle|/opt/devops-tools/gradle
Prometheus|/opt/prometheus|/usr/share/prometheus|/opt/devops-tools/prometheus
Tomcat|/usr/local/tomcat|/opt/tomcat|/var/lib/tomcat|/usr/share/tomcat
GCloud SDK|/opt/google-cloud-sdk|/usr/share/google-cloud-sdk|/usr/lib/google-cloud-sdk|$HOME/google-cloud-sdk
Jenkins|/usr/share/jenkins|/var/lib/jenkins|/opt/jenkins
"
    
    local IFS_BAK="$IFS"
    echo "$tool_dir_entries" | while IFS='|' read -r name candidates_raw; do
        # Skip empty lines
        [ -z "$name" ] && continue
        
        local found_dir=""
        # Split remaining fields on | 
        local old_ifs="$IFS"
        IFS='|'
        for candidate in $candidates_raw; do
            # Trim whitespace
            candidate=$(echo "$candidate" | tr -d '[:space:]' | sed "s|~|$HOME|g")
            [ -z "$candidate" ] && continue
            # Support glob expansion
            for expanded in $candidate; do
                if [ -d "$expanded" ]; then
                    found_dir="$expanded"
                    break 2
                fi
            done
        done
        IFS="$old_ifs"
        
        printf "  %-25s: " "$name"
        if [ -n "$found_dir" ]; then
            echo -e "${GREEN}✔ $found_dir${NC}"
        else
            echo -e "${RED}✘ Not found${NC}"
        fi
    done
    IFS="$IFS_BAK"
    echo ""

    # Services Status
    echo -e "${CYAN}Services:${NC}"
    local services="docker jenkins prometheus grafana-server nginx"
    
    for svc in $services; do
        printf "  %-20s: " "$svc"
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "${GREEN}● Running${NC}"
        elif systemctl list-unit-files 2>/dev/null | grep -q "^${svc}"; then
            echo -e "${YELLOW}○ Stopped${NC}"
        else
            echo -e "${RED}✘ Not installed${NC}"
        fi
    done
    echo ""

    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${WHITE}Total CLI Tools: ${GREEN}$installed installed${NC} | ${RED}$not_installed not found${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    # Re-enable exit on error
    set -e
}

# =========================================
# Installation Functions
# =========================================

install_java() {
    log_header "Installing Java OpenJDK 21"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD openjdk-21-jdk || $INSTALL_CMD openjdk-17-jdk || $INSTALL_CMD default-jdk
    elif [ "$IS_AMAZON_LINUX" = "true" ]; then
        $INSTALL_CMD java-21-amazon-corretto-devel || $INSTALL_CMD java-17-amazon-corretto-devel || $INSTALL_CMD java-11-amazon-corretto-devel
    else
        $INSTALL_CMD java-21-openjdk-devel || $INSTALL_CMD java-17-openjdk-devel || $INSTALL_CMD java-11-openjdk-devel
    fi
    
    # Dynamically get Java path from alternatives
    local java_path=""
    
    # Method 1: Get from update-alternatives
    if command -v update-alternatives >/dev/null 2>&1; then
        local java_bin
        java_bin=$(update-alternatives --display java 2>/dev/null | grep "link currently points to" | awk '{print $NF}')
        if [ -n "$java_bin" ] && [ -f "$java_bin" ]; then
            # Get the JAVA_HOME by removing /bin/java from the path
            java_path=$(dirname "$(dirname "$java_bin")")
        fi
    fi
    
    # Method 2: Use readlink on which java
    if [ -z "$java_path" ] || [ ! -d "$java_path" ]; then
        if command -v java >/dev/null 2>&1; then
            local java_bin
            java_bin=$(readlink -f "$(which java)" 2>/dev/null)
            if [ -n "$java_bin" ] && [ -f "$java_bin" ]; then
                # Get the JAVA_HOME by removing /bin/java from the path
                java_path=$(dirname "$(dirname "$java_bin")")
            fi
        fi
    fi
    
    # Method 3: Alternative system-specific paths
    if [ -z "$java_path" ] || [ ! -d "$java_path" ]; then
        if [ "$PKG_MANAGER" = "apt" ]; then
            # Ubuntu/Debian - find the installed JDK
            java_path=$(find /usr/lib/jvm -maxdepth 1 -type d -name "java-*-openjdk-*" 2>/dev/null | sort -V | tail -1)
            if [ -z "$java_path" ]; then
                java_path=$(find /usr/lib/jvm -maxdepth 1 -type d -name "java-*" 2>/dev/null | sort -V | tail -1)
            fi
        elif [ "$IS_AMAZON_LINUX" = "true" ]; then
            # Amazon Linux - Corretto path
            java_path=$(find /usr/lib/jvm -maxdepth 1 -type d -name "java-*-amazon-corretto*" 2>/dev/null | sort -V | tail -1)
            if [ -z "$java_path" ]; then
                java_path="/usr/lib/jvm/java"
            fi
        else
            # RHEL/CentOS
            java_path=$(find /usr/lib/jvm -maxdepth 1 -type d -name "java-*-openjdk-*" 2>/dev/null | sort -V | tail -1)
            if [ -z "$java_path" ]; then
                java_path="/usr/lib/jvm/java"
            fi
        fi
    fi
    
    # Validate the java_path
    if [ -n "$java_path" ] && [ -d "$java_path" ]; then
        log_step "Detected JAVA_HOME: $java_path"
        
        # Set JAVA_HOME in /etc/environment (system-wide)
        log_step "Setting JAVA_HOME in /etc/environment..."
        
        # Remove existing JAVA_HOME if present
        sudo sed -i '/^JAVA_HOME=/d' /etc/environment 2>/dev/null || true
        
        # Add new JAVA_HOME
        echo "JAVA_HOME=$java_path" | sudo tee -a /etc/environment > /dev/null
        
        # Also update PATH in /etc/environment if not already containing JAVA_HOME/bin
        if ! grep -q 'JAVA_HOME/bin' /etc/environment 2>/dev/null; then
            # Check if PATH exists in /etc/environment
            if grep -q '^PATH=' /etc/environment 2>/dev/null; then
                # Append to existing PATH
                sudo sed -i 's|^PATH=\(.*\)|PATH=\1:$JAVA_HOME/bin|' /etc/environment
            fi
        fi
        
        # Export for current session
        export JAVA_HOME="$java_path"
        export PATH="$JAVA_HOME/bin:$PATH"
        
        # Also add to user's .bashrc for interactive shells
        if ! grep -q "^export JAVA_HOME=" ~/.bashrc 2>/dev/null; then
            cat >> ~/.bashrc << 'EOF'

# Java Environment
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=$JAVA_HOME/bin:$PATH
EOF
        fi
        
        log_success "JAVA_HOME set to: $java_path"
        log_info "JAVA_HOME configured in /etc/environment (system-wide)"
        log_info "Run 'source /etc/environment' or log out/in to apply"
    else
        log_error "Could not determine JAVA_HOME path"
        log_info "Please set JAVA_HOME manually"
    fi
    
    log_success "Java installed"
    java -version 2>&1 | head -n1 || true
    
    # Show current JAVA_HOME
    if [ -n "$JAVA_HOME" ]; then
        log_info "Current JAVA_HOME: $JAVA_HOME"
    fi
}

install_git() {
    log_header "Installing Git"
    $INSTALL_CMD git
    log_success "Git installed"
    git --version || true
}

install_maven() {
    log_header "Installing Maven"
    
    local maven_version="3.9.9"
    
    # Try to get latest version
    local latest
    latest=$(curl -fsSL --connect-timeout 10 "https://maven.apache.org/download.cgi" 2>/dev/null | \
        grep -oP 'apache-maven-\K[0-9.]+(?=-bin\.tar\.gz)' | head -1) || true
    
    if [ -n "$latest" ]; then
        maven_version="$latest"
    fi
    
    log_step "Downloading Maven $maven_version..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    local maven_url="https://dlcdn.apache.org/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz"
    
    if ! safe_download "$maven_url" "maven.tar.gz"; then
        # Fallback to archive
        maven_url="https://archive.apache.org/dist/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz"
        if ! safe_download "$maven_url" "maven.tar.gz"; then
            cd -
            rm -rf "$tmp_dir"
            return 1
        fi
    fi
    
    sudo rm -rf /opt/maven
    sudo mkdir -p /opt/maven
    sudo tar xzf maven.tar.gz -C /opt/maven --strip-components=1
    
    cd -
    rm -rf "$tmp_dir"
    
    sudo ln -sf /opt/maven/bin/mvn /usr/local/bin/mvn
    
    # Add to PATH
    if ! grep -q "MAVEN_HOME" /etc/environment 2>/dev/null; then
        echo 'MAVEN_HOME="/opt/maven"' | sudo tee -a /etc/environment >/dev/null
        sudo sed -i 's|^PATH="\(.*\)"|PATH="\1:/opt/maven/bin"|' /etc/environment
    fi
    
    log_success "Maven installed to /opt/maven"
    /opt/maven/bin/mvn -version 2>&1 | head -n1 || true
}

install_gradle() {
    log_header "Installing Gradle"
    
    local gradle_version="8.12"
    
    # Try to get latest version
    local latest
    latest=$(curl -fsSL --connect-timeout 10 "https://services.gradle.org/versions/current" 2>/dev/null | \
        grep -oP '"version"\s*:\s*"\K[^"]+') || true
    
    if [ -n "$latest" ]; then
        gradle_version="$latest"
    fi
    
    log_step "Downloading Gradle $gradle_version..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://services.gradle.org/distributions/gradle-${gradle_version}-bin.zip" "gradle.zip"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    sudo rm -rf /opt/gradle
    sudo mkdir -p /opt/gradle
    sudo unzip -q gradle.zip -d /opt
    sudo mv /opt/gradle-*/* /opt/gradle/ 2>/dev/null || true
    sudo rm -rf /opt/gradle-*
    
    cd -
    rm -rf "$tmp_dir"
    
    sudo ln -sf /opt/gradle/bin/gradle /usr/local/bin/gradle
    
    # Add to PATH
    if ! grep -q "GRADLE_HOME" /etc/environment 2>/dev/null; then
        echo 'GRADLE_HOME="/opt/gradle"' | sudo tee -a /etc/environment >/dev/null
        sudo sed -i 's|^PATH="\(.*\)"|PATH="\1:/opt/gradle/bin"|' /etc/environment
    fi
    
    log_success "Gradle installed to /opt/gradle"
    /opt/gradle/bin/gradle --version 2>&1 | grep Gradle || true
}

install_nodejs() {
    log_header "Installing Node.js LTS"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        # Install using NodeSource
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - || {
            # Fallback to package manager
            $INSTALL_CMD nodejs npm
        }
        $INSTALL_CMD nodejs || true
    else
        # For RHEL/CentOS/Amazon Linux
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash - || {
            # Fallback
            $INSTALL_CMD nodejs npm || true
        }
        $INSTALL_CMD nodejs || true
    fi
    
    log_success "Node.js installed"
    node --version 2>/dev/null || true
    npm --version 2>/dev/null || true
}

install_python() {
    log_header "Installing Python 3"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD python3 python3-pip python3-venv python3-dev
    else
        $INSTALL_CMD python3 python3-pip python3-devel || $INSTALL_CMD python3 python3-pip
    fi
    
    log_success "Python 3 installed"
    python3 --version || true
}

install_rust() {
    log_header "Installing Rust & Cargo"
    
    # Install build dependencies
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD build-essential || true
    else
        $INSTALL_CMD gcc make || true
    fi
    
    # Install rustup
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Source cargo env
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.cargo/env"
    fi
    
    log_success "Rust & Cargo installed"
    rustc --version 2>/dev/null || true
    cargo --version 2>/dev/null || true
}

install_ansible() {
    log_header "Installing Ansible"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD software-properties-common || true
        sudo add-apt-repository --yes --update ppa:ansible/ansible 2>/dev/null || true
        $UPDATE_CMD || true
        $INSTALL_CMD ansible || {
            # Fallback to pip
            $INSTALL_CMD python3-pip
            pip3 install ansible --user
        }
    elif [ "$IS_AMAZON_LINUX" = "true" ]; then
        $INSTALL_CMD ansible || {
            $INSTALL_CMD python3-pip
            pip3 install ansible --user
        }
    else
        $INSTALL_CMD ansible-core || $INSTALL_CMD ansible || {
            $INSTALL_CMD python3-pip
            pip3 install ansible --user
        }
    fi
    
    log_success "Ansible installed"
    ansible --version 2>&1 | head -n1 || true
}

install_docker() {
    log_header "Installing Docker"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        # Remove old versions
        sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # Install prerequisites
        $INSTALL_CMD ca-certificates curl gnupg
        
        # Add Docker's official GPG key
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        sudo chmod a+r /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        
        # Set up repository
        local codename
        codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo 'jammy')}}")
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $codename stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        $UPDATE_CMD || true
        $INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
            # Fallback to default docker.io
            $INSTALL_CMD docker.io
        }
        
    elif [ "$IS_AMAZON_LINUX" = "true" ]; then
        if [ "$AMAZON_LINUX_VERSION" = "2" ]; then
            sudo amazon-linux-extras install docker -y 2>/dev/null || $INSTALL_CMD docker
        else
            $INSTALL_CMD docker
        fi
    else
        # RHEL/CentOS
        sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
        
        $INSTALL_CMD yum-utils || true
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 2>/dev/null || true
        $INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || $INSTALL_CMD docker
    fi
    
    # Start and enable docker
    sudo systemctl start docker 2>/dev/null || true
    sudo systemctl enable docker 2>/dev/null || true
    
    # Add user to docker group
    sudo usermod -aG docker "$USER" 2>/dev/null || true
    
    log_success "Docker installed"
    docker --version 2>/dev/null || true
    
    NEEDS_REBOOT="true"
    log_info "You may need to log out and back in to use Docker without sudo"
}

install_jenkins() {
    log_header "Installing Jenkins"
    
    # Check for Java
    if ! command_exists java; then
        log_info "Java is required. Installing Java first..."
        install_java || { log_error "Java installation failed"; return 1; }
    fi
    
    # Helper function to configure Jenkins service
    configure_jenkins_service() {
        sudo systemctl daemon-reload 2>/dev/null || true
        sudo systemctl enable jenkins 2>/dev/null || true
        sudo systemctl start jenkins 2>/dev/null || true
    }
    
    # Helper function to display post-installation information
    show_jenkins_info() {
        log_success "Jenkins installed successfully"
        log_info "Access Jenkins at: http://$(curl -s ifconfig.me):8080"
        log_info "Get initial password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    }
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        log_step "Adding Jenkins repository for Debian/Ubuntu..."
        
        # Clean up any previous Jenkins repo config
        sudo rm -f /usr/share/keyrings/jenkins-keyring.asc \
                   /usr/share/keyrings/jenkins-keyring.gpg \
                   /etc/apt/keyrings/jenkins-keyring.asc \
                   /etc/apt/sources.list.d/jenkins.list \
                   /etc/apt/trusted.gpg.d/jenkins.gpg 2>/dev/null || true
        
        # Ensure keyrings directory exists
        sudo install -m 0755 -d /etc/apt/keyrings
        
        log_step "Downloading and installing Jenkins GPG key..."
        local key_file="/etc/apt/keyrings/jenkins-keyring.asc"
        if ! sudo wget -O "$key_file" "https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key" 2>/dev/null || [ ! -s "$key_file" ]; then
            log_error "Failed to download or install GPG key"
            log_info "Falling back to WAR file installation..."
            install_jenkins_war
            return $?
        fi
        log_step "GPG key installed successfully"
        
        log_step "Adding Jenkins repository..."
        local repo_file="/etc/apt/sources.list.d/jenkins.list"
        echo "deb [signed-by=${key_file}] https://pkg.jenkins.io/debian-stable binary/" | sudo tee "$repo_file" > /dev/null
        
        log_step "Updating package lists..."
        if ! sudo apt-get update 2>&1; then
            log_error "Failed to update package lists"
            log_info "Falling back to WAR file installation..."
            sudo rm -f "$repo_file"
            install_jenkins_war
            return $?
        fi
        
        log_step "Installing Jenkins package..."
        if sudo apt-get install -y jenkins 2>&1; then
            configure_jenkins_service
            show_jenkins_info
            return 0
        fi
        
        log_warning "Standard installation failed, trying with --allow-unauthenticated..."
        if sudo apt-get install -y --allow-unauthenticated jenkins 2>&1; then
            configure_jenkins_service
            log_success "Jenkins installed (with --allow-unauthenticated)"
            log_info "Access Jenkins at: http://$(curl -s ifconfig.me):8080"
            log_info "Get initial password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
            return 0
        fi
        
        log_error "Package installation failed"
        sudo rm -f "$repo_file"
        log_info "Falling back to WAR file installation..."
        install_jenkins_war
        return $?
        
    else
        # RHEL/CentOS/Amazon Linux
        log_step "Adding Jenkins repository for RHEL/CentOS/Amazon Linux..."
        local repo_file="/etc/yum.repos.d/jenkins.repo"
        
        if ! sudo wget -q -O "$repo_file" "https://pkg.jenkins.io/redhat-stable/jenkins.repo" 2>&1; then
            log_error "Failed to download Jenkins repo file"
            log_info "Falling back to WAR file installation..."
            install_jenkins_war
            return $?
        fi
        
        log_step "Importing Jenkins GPG key..."
        if ! sudo rpm --import "https://pkg.jenkins.io/redhat-stable/jenkins.io-2026.key" 2>&1; then
            log_error "Failed to import GPG key"
            log_info "Falling back to WAR file installation..."
            install_jenkins_war
            return $?
        fi
        
        log_step "Installing required fontconfig package..."
        if ! $INSTALL_CMD fontconfig 2>&1; then
            log_error "Failed to install fontconfig"
            log_info "Falling back to WAR file installation..."
            install_jenkins_war
            return $?
        fi
        
        log_step "Installing Jenkins package..."
        if $INSTALL_CMD jenkins 2>&1; then
            configure_jenkins_service
            show_jenkins_info
            return 0
        fi
        
        log_error "Package installation failed"
        log_info "Falling back to WAR file installation..."
        install_jenkins_war
        return $?
    fi
}

# =========================================
# Install Jenkins via WAR file
# =========================================
install_jenkins_war() {
    log_header "Installing Jenkins via WAR file"
    
    # Check for Java
    if ! command_exists java; then
        log_info "Java is required. Installing Java first..."
        install_java
    fi
    
    # Create jenkins user and group
    if ! id jenkins &>/dev/null; then
        sudo useradd --system --home-dir /var/lib/jenkins --shell /bin/false jenkins 2>/dev/null || true
    fi
    
    # Create directories with proper permissions
    sudo mkdir -p /var/lib/jenkins
    sudo mkdir -p /var/log/jenkins
    sudo mkdir -p /var/cache/jenkins
    sudo mkdir -p /usr/share/jenkins
    
    # Get latest stable version
    log_step "Fetching latest Jenkins version..."
    local jenkins_version
    jenkins_version=$(curl -fsSL https://updates.jenkins.io/stable/latestCore.txt 2>/dev/null) || jenkins_version="2.479.3"
    log_info "Latest stable version: $jenkins_version"
    
    # Create temp directory for download
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    log_step "Downloading Jenkins WAR file..."
    
    # Try multiple download URLs
    local download_success=false
    local urls=(
        "https://get.jenkins.io/war-stable/${jenkins_version}/jenkins.war"
        "https://updates.jenkins.io/download/war/${jenkins_version}/jenkins.war"
        "https://ftp.halifax.rwth-aachen.de/jenkins/war-stable/${jenkins_version}/jenkins.war"
        "https://mirrors.jenkins.io/war-stable/${jenkins_version}/jenkins.war"
        "https://get.jenkins.io/war-stable/latest/jenkins.war"
    )
    
    for url in "${urls[@]}"; do
        log_step "Trying: $url"
        if curl -fSL --connect-timeout 30 --max-time 600 --progress-bar -o jenkins.war "$url" 2>/dev/null; then
            # Verify the file is valid (should be > 50MB)
            if [ -f jenkins.war ]; then
                local file_size
                file_size=$(stat -c%s jenkins.war 2>/dev/null || stat -f%z jenkins.war 2>/dev/null || echo "0")
                if [ "$file_size" -gt 50000000 ]; then
                    download_success=true
                    log_success "Downloaded successfully ($(numfmt --to=iec-i --suffix=B $file_size 2>/dev/null || echo "${file_size} bytes"))"
                    break
                else
                    log_info "File too small ($file_size bytes), trying next mirror..."
                    rm -f jenkins.war
                fi
            fi
        fi
    done
    
    if [ "$download_success" = false ]; then
        # Last resort: try wget with progress
        log_step "Trying with wget..."
        for url in "${urls[@]}"; do
            log_step "wget: $url"
            if wget --timeout=60 --tries=2 -O jenkins.war "$url" 2>&1; then
                if [ -f jenkins.war ]; then
                    local file_size
                    file_size=$(stat -c%s jenkins.war 2>/dev/null || stat -f%z jenkins.war 2>/dev/null || echo "0")
                    if [ "$file_size" -gt 50000000 ]; then
                        download_success=true
                        log_success "Downloaded successfully with wget"
                        break
                    fi
                fi
                rm -f jenkins.war
            fi
        done
    fi
    
    if [ "$download_success" = false ]; then
        log_error "Failed to download Jenkins WAR file from all mirrors"
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    # Move WAR file to final location
    sudo mv jenkins.war /usr/share/jenkins/jenkins.war
    
    # Set proper ownership
    sudo chown -R jenkins:jenkins /var/lib/jenkins
    sudo chown -R jenkins:jenkins /var/log/jenkins
    sudo chown -R jenkins:jenkins /var/cache/jenkins
    sudo chown -R jenkins:jenkins /usr/share/jenkins
    
    cd -
    rm -rf "$tmp_dir"
    
    # Detect Java path
    local java_path
    java_path=$(which java)
    
    # Create systemd service file
    log_step "Creating systemd service..."
    cat <<EOF | sudo tee /etc/systemd/system/jenkins.service
[Unit]
Description=Jenkins Continuous Integration Server
Documentation=https://www.jenkins.io/doc/
After=network.target

[Service]
Type=simple
User=jenkins
Group=jenkins
Environment="JENKINS_HOME=/var/lib/jenkins"
Environment="JENKINS_WEBROOT=/var/cache/jenkins/war"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Xmx512m"
WorkingDirectory=/var/lib/jenkins
ExecStart=${java_path} \$JAVA_OPTS -jar /usr/share/jenkins/jenkins.war --httpPort=8080 --webroot=\$JENKINS_WEBROOT
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and start Jenkins
    sudo systemctl daemon-reload
    sudo systemctl enable jenkins 2>/dev/null || true
    
    log_step "Starting Jenkins service..."
    if sudo systemctl start jenkins; then
        # Wait a bit for Jenkins to initialize
        log_info "Waiting for Jenkins to initialize..."
        sleep 5
        
        if sudo systemctl is-active --quiet jenkins; then
            log_success "Jenkins installed and running!"
        else
            log_info "Jenkins service started (may still be initializing)"
        fi
    else
        log_error "Failed to start Jenkins service"
        log_info "Check logs with: sudo journalctl -u jenkins -f"
    fi
    
    log_info "Access Jenkins at: http://$(curl -s ifconfig.me):8080"
    log_info "Get initial password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    log_info "View logs: sudo journalctl -u jenkins -f"
}

install_argocd_cli() {
    log_header "Installing ArgoCD CLI"
    
    local version
    version=$(get_github_release "argoproj/argo-cd") || version="2.13.3"
    
    log_step "Downloading ArgoCD CLI v$version..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://github.com/argoproj/argo-cd/releases/download/v${version}/argocd-linux-${ARCH_ALT}" "argocd"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    chmod +x argocd
    sudo mv argocd /usr/local/bin/argocd
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "ArgoCD CLI installed"
    argocd version --client 2>&1 | head -n1 || true
}

install_terraform() {
    log_header "Installing Terraform"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null || true
        
        local codename
        codename=$(lsb_release -cs 2>/dev/null || echo "jammy")
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $codename main" | \
            sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
        
        $UPDATE_CMD
        $INSTALL_CMD terraform
        
    elif [ "$IS_AMAZON_LINUX" = "true" ]; then
        $INSTALL_CMD yum-utils || true
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
        $INSTALL_CMD terraform
    else
        $INSTALL_CMD yum-utils || true
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        $INSTALL_CMD terraform
    fi
    
    log_success "Terraform installed"
    terraform --version 2>&1 | head -n1 || true
}

install_trivy() {
    log_header "Installing Trivy"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/trivy.gpg 2>/dev/null || true
        echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | \
            sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
        $UPDATE_CMD
        $INSTALL_CMD trivy
    else
        cat <<'EOF' | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
gpgcheck=0
enabled=1
EOF
        $INSTALL_CMD trivy
    fi
    
    log_success "Trivy installed"
    trivy --version 2>&1 | head -n1 || true
}

install_aws_cli() {
    log_header "Installing AWS CLI v2"
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if [ "$ARCH" = "aarch64" ]; then
        safe_download "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" "awscliv2.zip" || { cd -; rm -rf "$tmp_dir"; return 1; }
    else
        safe_download "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" "awscliv2.zip" || { cd -; rm -rf "$tmp_dir"; return 1; }
    fi
    
    unzip -q awscliv2.zip
    sudo ./aws/install --update || sudo ./aws/install
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "AWS CLI installed"
    aws --version 2>/dev/null || true
}

install_azure_cli() {
    log_header "Installing Azure CLI"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    else
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        
        cat <<'EOF' | sudo tee /etc/yum.repos.d/azure-cli.repo
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        $INSTALL_CMD azure-cli
    fi
    
    log_success "Azure CLI installed"
    az --version 2>&1 | head -n1 || true
}

install_gcloud_cli() {
    log_header "Installing Google Cloud CLI"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        # For Debian/Ubuntu
        log_step "Adding Google Cloud repository for Debian/Ubuntu..."
        
        # Remove old files
        sudo rm -f /usr/share/keyrings/cloud.google.gpg 2>/dev/null || true
        sudo rm -f /etc/apt/sources.list.d/google-cloud-sdk.list 2>/dev/null || true
        
        # Import key
        # for new ubuntu version
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - 2>/dev/null
        # for old ubuntu version
        # curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/cloud.google.gpg 2>/dev/null || true
        
        # for new ubuntu version
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list 
        # for old ubuntu version
        # echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
        #     sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
        
        $UPDATE_CMD
        $INSTALL_CMD google-cloud-cli || {
            log_info "Package installation failed, trying standalone installer..."
            install_gcloud_standalone
            return
        }
    else
        # For RHEL/CentOS/Amazon Linux - Use standalone installer as it's more reliable across different versions
        log_step "Installing Google Cloud CLI via standalone installer (recommended for RHEL)..."
        install_gcloud_standalone
    fi
    
    log_success "Google Cloud CLI installed"
    gcloud --version 2>&1 | head -n1 || true
}

install_gcloud_standalone() {
    log_header "Installing Google Cloud CLI (Standalone)"
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    local gcloud_arch="x86_64"
    if [ "$ARCH" = "aarch64" ]; then
        gcloud_arch="arm"
    fi
    
    log_step "Downloading Google Cloud CLI..."
    
    # Download the archive
    if ! safe_download "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-${gcloud_arch}.tar.gz" "gcloud.tar.gz"; then
        # Try with version number
        local gcloud_version="504.0.1"
        if ! safe_download "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${gcloud_version}-linux-${gcloud_arch}.tar.gz" "gcloud.tar.gz"; then
            cd -
            rm -rf "$tmp_dir"
            return 1
        fi
    fi
    
    # Extract
    tar -xzf gcloud.tar.gz
    
    # Install to /opt
    sudo rm -rf /opt/google-cloud-sdk
    sudo mv google-cloud-sdk /opt/
    
    # Run install script non-interactively
    sudo /opt/google-cloud-sdk/install.sh --quiet --path-update=true --command-completion=true --rc-path=/etc/bash.bashrc 2>/dev/null || true
    
    # Create symlinks
    sudo ln -sf /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud
    sudo ln -sf /opt/google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil
    sudo ln -sf /opt/google-cloud-sdk/bin/bq /usr/local/bin/bq
    
    # Add to PATH in bashrc
    if ! grep -q "google-cloud-sdk" ~/.bashrc 2>/dev/null; then
        echo 'export PATH=$PATH:/opt/google-cloud-sdk/bin' >> ~/.bashrc
        echo 'source /opt/google-cloud-sdk/completion.bash.inc 2>/dev/null || true' >> ~/.bashrc
    fi
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "Google Cloud CLI installed to /opt/google-cloud-sdk"
    /opt/google-cloud-sdk/bin/gcloud --version 2>&1 | head -n1 || true
}

install_prometheus() {
    log_header "Installing Prometheus"
    
    local version
    version=$(get_github_release "prometheus/prometheus") || version="2.54.1"
    
    log_step "Downloading Prometheus v$version..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://github.com/prometheus/prometheus/releases/download/v${version}/prometheus-${version}.linux-${ARCH_ALT}.tar.gz" "prometheus.tar.gz"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    tar xzf prometheus.tar.gz
    
    sudo rm -rf /opt/prometheus
    sudo mv prometheus-*/ /opt/prometheus
    
    sudo ln -sf /opt/prometheus/prometheus /usr/local/bin/prometheus
    sudo ln -sf /opt/prometheus/promtool /usr/local/bin/promtool
    
    # Create prometheus user
    sudo useradd --system --no-create-home --shell /bin/false prometheus 2>/dev/null || true
    
    # Create directories
    sudo mkdir -p /var/lib/prometheus /etc/prometheus
    sudo cp /opt/prometheus/prometheus.yml /etc/prometheus/ 2>/dev/null || true
    sudo chown -R prometheus:prometheus /var/lib/prometheus /etc/prometheus /opt/prometheus 2>/dev/null || true
    
    # Create systemd service
 cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    if [ "$OS_ID" = "rhel" ]; then
        sudo systemctl enable prometheus 2>/dev/null || true
        sudo systemctl start prometheus 2>/dev/null || true
        log_info "Disabling SELinux for Prometheus"
        log_info "Run 'sudo setenforce 0 && sudo systemctl restart prometheus' to disable SELinux permanently"
    else
        sudo systemctl enable prometheus 2>/dev/null || true
        sudo systemctl start prometheus 2>/dev/null || true
    fi
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "Prometheus installed"
    log_info "Access at: http://$(curl -s ifconfig.me):9090/graph"
}

install_grafana() {
    log_header "Installing Grafana"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD apt-transport-https software-properties-common
        wget -q -O - https://packages.grafana.com/gpg.key | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/grafana.gpg 2>/dev/null || true
        echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | \
            sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null
        $UPDATE_CMD
        $INSTALL_CMD grafana
    else
        cat <<'EOF' | sudo tee /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
        $INSTALL_CMD grafana
    fi
    
    sudo systemctl daemon-reload
    sudo systemctl enable grafana-server 2>/dev/null || true
    sudo systemctl start grafana-server 2>/dev/null || true
    
    log_success "Grafana installed"
    log_info "Access at: http://$(curl -s ifconfig.me):3000 (admin/admin)"
}

install_kubectl() {
    log_header "Installing kubectl"
    
    local version
    version=$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null) || version="v1.31.0"
    
    log_step "Downloading kubectl $version..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://dl.k8s.io/release/${version}/bin/linux/${ARCH_ALT}/kubectl" "kubectl"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
    
    cd -
    rm -rf "$tmp_dir"
    
    # Enable bash completion
    $INSTALL_CMD bash-completion 2>/dev/null || true
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null 2>/dev/null || true
    
    log_success "kubectl installed"
    kubectl version --client 2>&1 | head -n1 || true
}

install_helm() {
    log_header "Installing Helm"
    
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Enable bash completion
    helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null 2>/dev/null || true
    
    log_success "Helm installed"
    helm version --short 2>&1 || true
}

install_k9s() {
    log_header "Installing k9s"
    
    local version
    version=$(get_github_release "derailed/k9s") || version="0.32.7"
    
    log_step "Downloading k9s v$version..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://github.com/derailed/k9s/releases/download/v${version}/k9s_Linux_${ARCH_ALT}.tar.gz" "k9s.tar.gz"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    tar xzf k9s.tar.gz
    sudo mv k9s /usr/local/bin/k9s
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "k9s installed"
    k9s version --short 2>&1 | head -n1 || true
}

install_minikube() {
    log_header "Installing Minikube"
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${ARCH_ALT}" "minikube"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    chmod +x minikube
    sudo mv minikube /usr/local/bin/minikube
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "Minikube installed"
    minikube version 2>&1 | head -n1 || true
}

install_nginx() {
    log_header "Installing Nginx"
    
    $INSTALL_CMD nginx
    
    sudo systemctl enable nginx 2>/dev/null || true
    sudo systemctl start nginx 2>/dev/null || true
    
    log_success "Nginx installed"
    nginx -v 2>&1 || true
}

install_tomcat() {
    log_header "Installing Tomcat"
    
    local version
    version=$(curl -fsSL https://dlcdn.apache.org/tomcat/tomcat-11/ | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1) || version="11.0.15"
    
    log_step "Downloading Tomcat $version..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://dlcdn.apache.org/tomcat/tomcat-11/v${version}/bin/apache-tomcat-${version}.tar.gz" "tomcat.tar.gz"; then
        # Try archive
        if ! safe_download "https://archive.apache.org/dist/tomcat/tomcat-11/v${version}/bin/apache-tomcat-${version}.tar.gz" "tomcat.tar.gz"; then
            cd -
            rm -rf "$tmp_dir"
            return 1
        fi
    fi
    
    sudo rm -rf /usr/local/tomcat
    sudo mkdir -p /usr/local/tomcat
    sudo tar xzf tomcat.tar.gz -C /usr/local/tomcat --strip-components=1
    sudo /usr/local/tomcat/bin/startup.sh || true
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "Tomcat installed to /usr/local/tomcat"
    log_info "Start with: /usr/local/tomcat/bin/startup.sh"
}

# Terminal utilities
install_lazydocker() {
    log_header "Installing Lazydocker"
    
    local version
    version=$(get_github_release "jesseduffield/lazydocker") || version="0.24.1"
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://github.com/jesseduffield/lazydocker/releases/download/v${version}/lazydocker_${version}_Linux_${ARCH}.tar.gz" "lazydocker.tar.gz"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    tar xf lazydocker.tar.gz
    sudo mv lazydocker /usr/local/bin/lazydocker
    
    cd -
    rm -rf "$tmp_dir"
    
    grep -q "alias lz=" ~/.bashrc 2>/dev/null || echo "alias lz='lazydocker'" >> ~/.bashrc
    
    log_success "Lazydocker installed"
}

install_yazi() {
    log_header "Installing Yazi"
    
    local yazi_arch="x86_64-unknown-linux-musl"
    if [ "$PKG_MANAGER" = "apt" ]; then
        yazi_arch="x86_64-unknown-linux-gnu"
    fi
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${yazi_arch}.zip" "yazi.zip"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    unzip -q yazi.zip
    sudo mv yazi-*/yazi /usr/local/bin/yazi 2>/dev/null || sudo mv */yazi /usr/local/bin/yazi 2>/dev/null || true
    sudo mv yazi-*/ya /usr/local/bin/ya 2>/dev/null || sudo mv */ya /usr/local/bin/ya 2>/dev/null || true
    
    cd -
    rm -rf "$tmp_dir"
    
    grep -q "alias y=" ~/.bashrc 2>/dev/null || echo "alias y='yazi'" >> ~/.bashrc
    
    log_success "Yazi installed"
}

install_bat() {
    log_header "Installing Bat"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD bat
        if [ -f /usr/bin/batcat ] && [ ! -f /usr/bin/bat ]; then
            sudo ln -sf /usr/bin/batcat /usr/bin/bat
        fi
        log_success "Bat installed"
        bat --version 2>/dev/null || batcat --version 2>/dev/null || true
        return 0
    fi
    
    # For non-apt systems, install from GitHub releases
    local version
    version=$(get_github_release "sharkdp/bat") || version="0.26.1"
    
    log_step "Downloading Bat v$version..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    # Correct URL format: bat-v{VERSION}-x86_64-unknown-linux-musl.tar.gz
    local bat_url="https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-${ARCH}-unknown-linux-musl.tar.gz"
    
    log_step "URL: $bat_url"
    
    if ! safe_download "$bat_url" "bat.tar.gz"; then
        # Try alternative version as fallback
        log_info "Trying fallback version 0.26.1..."
        version="0.26.1"
        bat_url="https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-${ARCH}-unknown-linux-musl.tar.gz"
        
        if ! safe_download "$bat_url" "bat.tar.gz"; then
            log_error "Failed to download Bat"
            cd -
            rm -rf "$tmp_dir"
            return 1
        fi
    fi
    
    # Extract the tarball
    tar xzf bat.tar.gz
    
    # The extracted directory is named: bat-v{VERSION}-x86_64-unknown-linux-musl
    local extract_dir="bat-v${version}-${ARCH}-unknown-linux-musl"
    
    # Find and install the bat binary
    if [ -f "${extract_dir}/bat" ]; then
        sudo install -m 755 "${extract_dir}/bat" /usr/local/bin/bat
        log_step "Installed from ${extract_dir}"
    elif ls -d bat-v*/bat 1>/dev/null 2>&1; then
        # Fallback: find any bat-v* directory
        sudo install -m 755 bat-v*/bat /usr/local/bin/bat
    else
        # Last resort: search for bat binary
        local bat_bin
        bat_bin=$(find . -name "bat" -type f | head -1)
        if [ -n "$bat_bin" ] && [ -f "$bat_bin" ]; then
            sudo install -m 755 "$bat_bin" /usr/local/bin/bat
        else
            log_error "Could not find bat binary in extracted archive"
            ls -la
            cd -
            rm -rf "$tmp_dir"
            return 1
        fi
    fi
    
    # Optionally install the man page if present
    if [ -f "${extract_dir}/bat.1" ]; then
        sudo mkdir -p /usr/local/share/man/man1
        sudo install -m 644 "${extract_dir}/bat.1" /usr/local/share/man/man1/
    fi
    
    # Optionally install autocomplete if present
    if [ -f "${extract_dir}/autocomplete/bat.bash" ]; then
        sudo mkdir -p /etc/bash_completion.d
        sudo install -m 644 "${extract_dir}/autocomplete/bat.bash" /etc/bash_completion.d/
    fi
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "Bat installed"
    bat --version 2>/dev/null || true
}

install_croc() {
    log_header "Installing Croc"
    curl -fsSL https://getcroc.schollz.com | bash
    log_success "Croc installed"
}

install_btop() {
    log_header "Installing Btop"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        # Try apt first on Debian/Ubuntu
        if $INSTALL_CMD btop 2>/dev/null; then
            log_success "Btop installed via apt"
            btop --version 2>/dev/null || true
            return 0
        fi
        # Fall through to binary install if apt fails
    fi
    
    if [ "$IS_AMAZON_LINUX" = "true" ]; then
        # Amazon Linux - use binary
        log_step "Installing Btop binary for Amazon Linux..."
        
        local tmp_dir
        tmp_dir=$(mktemp -d)
        cd "$tmp_dir"
        
        if ! safe_download "https://github.com/aristocratos/btop/releases/latest/download/btop-${ARCH}-unknown-linux-musl.tbz" "btop.tbz"; then
            cd -
            rm -rf "$tmp_dir"
            return 1
        fi
        
        sudo tar xf btop.tbz --strip-components=2 -C /usr/local ./btop/bin/btop
        
        cd -
        rm -rf "$tmp_dir"
        
        log_success "Btop installed"
        btop --version 2>/dev/null || true
        return 0
        
    elif [ "$OS_ID" = "rhel" ]; then
        # RHEL - use EPEL repository
        log_step "Installing Btop via EPEL for RHEL..."
        
        # Get major version (trim 10.0 to 10, 9.3 to 9, etc.)
        local rhel_version="${OS_VERSION%%.*}"
        log_step "RHEL version: $rhel_version"
        
        # Enable CodeReady Builder repository
        log_step "Enabling CodeReady Builder repository..."
        sudo subscription-manager repos --enable "codeready-builder-for-rhel-${rhel_version}-$(arch)-rpms" 2>/dev/null || {
            # Alternative method for systems not using subscription-manager
            sudo dnf config-manager --set-enabled crb 2>/dev/null || true
        }
        
        # Install EPEL repository
        log_step "Installing EPEL repository..."
        sudo dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${rhel_version}.noarch.rpm" 2>/dev/null || {
            $INSTALL_CMD epel-release 2>/dev/null || true
        }
        
        # Install btop
        log_step "Installing btop..."
        if sudo dnf install -y btop; then
            log_success "Btop installed via EPEL"
            btop --version 2>/dev/null || true
            return 0
        else
            log_info "EPEL installation failed, falling back to binary..."
        fi
        
    elif [ "$OS_ID" = "centos" ] && [ "${OS_VERSION%%.*}" -ge 8 ]; then
        # CentOS Stream 8/9 - use EPEL
        log_step "Installing Btop via EPEL for CentOS..."
        
        local centos_version="${OS_VERSION%%.*}"
        
        # Enable PowerTools/CRB
        sudo dnf config-manager --set-enabled powertools 2>/dev/null || \
        sudo dnf config-manager --set-enabled crb 2>/dev/null || true
        
        # Install EPEL
        $INSTALL_CMD epel-release 2>/dev/null || \
        sudo dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${centos_version}.noarch.rpm" 2>/dev/null || true
        
        # Install btop
        if sudo dnf install -y btop 2>/dev/null; then
            log_success "Btop installed via EPEL"
            btop --version 2>/dev/null || true
            return 0
        else
            log_info "EPEL installation failed, falling back to binary..."
        fi
        
    elif [ "$OS_ID" = "fedora" ]; then
        # Fedora - btop is in default repos
        log_step "Installing Btop for Fedora..."
        if sudo dnf install -y btop; then
            log_success "Btop installed"
            btop --version 2>/dev/null || true
            return 0
        fi
    fi
    
    # Fallback: Install from binary for any other system
    log_step "Installing Btop from binary..."
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://github.com/aristocratos/btop/releases/latest/download/btop-${ARCH}-linux-musl.tbz" "btop.tbz"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    # Extract btop binary
    tar xf btop.tbz
    
    # Install the binary
    if [ -f "btop/bin/btop" ]; then
        sudo install -m 755 btop/bin/btop /usr/local/bin/btop
    else
        # Alternative extraction method
        sudo tar xf btop.tbz --strip-components=2 -C /usr/local ./btop/bin/btop 2>/dev/null || {
            # Find and install the binary
            local btop_bin
            btop_bin=$(find . -name "btop" -type f | head -1)
            if [ -n "$btop_bin" ]; then
                sudo install -m 755 "$btop_bin" /usr/local/bin/btop
            else
                log_error "Could not find btop binary"
                cd -
                rm -rf "$tmp_dir"
                return 1
            fi
        }
    fi
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "Btop installed"
    btop --version 2>/dev/null || true
}

install_fzf() {
    log_header "Installing Fzf"
    
    local version
    version=$(get_github_release "junegunn/fzf") || version="0.56.3"
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-linux_${ARCH_ALT}.tar.gz" "fzf.tar.gz"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    tar xf fzf.tar.gz
    sudo mv fzf /usr/local/bin/fzf
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "Fzf installed"
}

install_zoxide() {
    log_header "Installing Zoxide"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD zoxide 2>/dev/null || {
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        }
    else
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi
    
    grep -q "zoxide init bash" ~/.bashrc 2>/dev/null || {
        echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
    }
    
    log_success "Zoxide installed"
}

install_atuin() {
    log_header "Installing Atuin"
    
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    
    if [ -f "$HOME/.atuin/bin/atuin" ]; then
        sudo ln -sf "$HOME/.atuin/bin/atuin" /usr/local/bin/atuin 2>/dev/null || true
    fi
    
    if ! grep -q "ATUIN_NOBIND" ~/.bashrc 2>/dev/null; then
        cat <<'EOF' >> ~/.bashrc

# Atuin History
export ATUIN_NOBIND="true"
eval "$(atuin init bash)"
bind -x '"\C-r": __atuin_history'
EOF
    fi

    log_success "Atuin installed"
}

install_gdu() {
    log_header "Installing Gdu"
    
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    if ! safe_download "https://github.com/dundee/gdu/releases/latest/download/gdu_linux_${ARCH_ALT}.tgz" "gdu.tgz"; then
        cd -
        rm -rf "$tmp_dir"
        return 1
    fi
    
    tar xzf gdu.tgz
    sudo mv gdu_linux_${ARCH_ALT} /usr/local/bin/gdu
    
    cd -
    rm -rf "$tmp_dir"
    
    log_success "Gdu installed"
}

install_jq() {
    log_header "Installing JQ"
    
    if [ "$PKG_MANAGER" != "apt" ] && [ "$IS_AMAZON_LINUX" = "false" ]; then
        $INSTALL_CMD epel-release 2>/dev/null || true
    fi
    
    $INSTALL_CMD jq
    
    log_success "JQ installed"
}

install_eza() {
    log_header "Installing Eza"
    
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list 2>/dev/null || true
        $UPDATE_CMD
        $INSTALL_CMD eza
    else
        local version
        version=$(get_github_release "eza-community/eza") || version="0.20.14"
        
        local tmp_dir
        tmp_dir=$(mktemp -d)
        cd "$tmp_dir"
        
        if ! safe_download "https://github.com/eza-community/eza/releases/download/v${version}/eza_x86_64-unknown-linux-musl.tar.gz" "eza.tar.gz"; then
            cd -
            rm -rf "$tmp_dir"
            return 1
        fi
        
        tar xf eza.tar.gz
        sudo mv eza /usr/local/bin/eza
        
        cd -
        rm -rf "$tmp_dir"
    fi
    
    grep -q "alias ls='eza" ~/.bashrc 2>/dev/null || {
        echo 'alias ls="eza --git --icons"' >> ~/.bashrc
        echo 'alias ll="eza -lah --group-directories-first --git --icons"' >> ~/.bashrc
        echo 'alias la="eza -la"' >> ~/.bashrc
    }
    
    log_success "Eza installed"
}

# =========================================
# Menu Display
# =========================================
show_menu() {
    cat <<'MENU'
╔═══════════════════════════════════════════════════════════════╗
║              DevOps Tools Installation Menu                   ║
╠═══════════════════════════════════════════════════════════════╣
║  STATUS & MONITORING                                          ║
║   0) Check installed tools (versions & locations)             ║
║  00) Check services & ports                                   ║
║ 000) Quick status summary                                     ║
╠═══════════════════════════════════════════════════════════════╣
║  LANGUAGES & BUILD TOOLS                                      ║
║   1) Java OpenJDK 21       2) Git                             ║
║   3) Maven                 4) Gradle                          ║
║   5) Node.js (LTS)         6) Python 3                        ║
║   7) Rust & Cargo                                             ║
╠═══════════════════════════════════════════════════════════════╣
║  DEVOPS & CI/CD                                               ║
║   8) Ansible               9) Docker                          ║
║  10) Jenkins              11) ArgoCD CLI                      ║
║  12) Terraform            13) Trivy                           ║
╠═══════════════════════════════════════════════════════════════╣
║  CLOUD CLIs                                                   ║
║  14) AWS CLI              15) Azure CLI                       ║
║  16) GCloud CLI                                               ║
╠═══════════════════════════════════════════════════════════════╣
║  KUBERNETES                                                   ║
║  17) kubectl              18) Helm                            ║
║  19) k9s                  20) Minikube                        ║
╠═══════════════════════════════════════════════════════════════╣
║  MONITORING                                                   ║
║  21) Prometheus           22) Grafana                         ║
╠═══════════════════════════════════════════════════════════════╣
║  WEB SERVERS                                                  ║
║  23) Nginx                24) Tomcat 11                       ║
╠═══════════════════════════════════════════════════════════════╣
║  TERMINAL UTILITIES                                           ║
║  25) Lazydocker           26) Yazi                            ║
║  27) Bat                  28) Croc                            ║
║  29) Btop                 30) Fzf                             ║
║  31) Zoxide               32) Atuin                           ║
║  33) Gdu                  34) JQ                              ║
║  35) Eza                                                      ║
╠═══════════════════════════════════════════════════════════════╣
║  BUNDLES                                                      ║
║  50) Essential DevOps (1-6,8-12,14,17-18)                     ║
║  51) Full Kubernetes Stack (9,17-20)                          ║
║  52) Monitoring Stack (21-22)                                 ║
║  53) All Terminal Utils (25-35)                               ║
║  99) Install Everything                                       ║
╚═══════════════════════════════════════════════════════════════╝
MENU
}

# =========================================
# Process Installation Choice
# =========================================
process_choice() {
    local choice="$1"
    
    case "$choice" in
        0)   show_versions ;;
        00)  check_services_ports ;;
        000) show_quick_status ;;
        1)   install_java ;;
        2)   install_git ;;
        3)   install_maven ;;
        4)   install_gradle ;;
        5)   install_nodejs ;;
        6)   install_python ;;
        7)   install_rust ;;
        8)   install_ansible ;;
        9)   install_docker ;;
        10)  install_jenkins ;;
        11)  install_argocd_cli ;;
        12)  install_terraform ;;
        13)  install_trivy ;;
        14)  install_aws_cli ;;
        15)  install_azure_cli ;;
        16)  install_gcloud_cli ;;
        17)  install_kubectl ;;
        18)  install_helm ;;
        19)  install_k9s ;;
        20)  install_minikube ;;
        21)  install_prometheus ;;
        22)  install_grafana ;;
        23)  install_nginx ;;
        24)  install_tomcat ;;
        25)  install_lazydocker ;;
        26)  install_yazi ;;
        27)  install_bat ;;
        28)  install_croc ;;
        29)  install_btop ;;
        30)  install_fzf ;;
        31)  install_zoxide ;;
        32)  install_atuin ;;
        33)  install_gdu ;;
        34)  install_jq ;;
        35)  install_eza ;;
        *)   log_error "Invalid choice: $choice" ;;
    esac
}

# =========================================
# Expand Bundles
# =========================================
expand_bundles() {
    local input="$1"
    local expanded=""
    
    for c in $input; do
        case "$c" in
            50) expanded="$expanded 1 2 3 4 5 6 8 9 10 11 12 14 17 18" ;;
            51) expanded="$expanded 9 17 18 19 20" ;;
            52) expanded="$expanded 21 22" ;;
            53) expanded="$expanded 25 26 27 28 29 30 31 32 33 34 35" ;;
            99) expanded="$expanded 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35" ;;
            *)  expanded="$expanded $c" ;;
        esac
    done
    
    # Remove duplicates and sort
    echo "$expanded" | tr ' ' '\n' | grep -v '^$' | sort -nu | tr '\n' ' '
}

# =========================================
# Setup bashrc configurations
# =========================================
setup_bashrc() {
    # Vi mode
    if ! grep -q "set -o vi" ~/.bashrc 2>/dev/null; then
        cat <<'EOF' >> ~/.bashrc

# vi mode
set -o vi
bind -m vi-insert '"\C-l": clear-screen'
EOF
        log_success "vi mode added to .bashrc"
    fi
}

# =========================================
# Main Script
# =========================================
main() {
    echo ""
    log_header "DevOps Tools Installer"
    echo ""
    
    # Detect system
    detect_architecture
    detect_package_manager
    echo ""
    show_system_info
    
    # Show menu
    show_menu
    echo ""
    
    # Get user input
    read -rp "Enter choices (e.g., 1 3 5, 50 for bundle, 0/00/000 for status): " input
    
    # Handle empty input
    if [ -z "$input" ]; then
        log_error "No selection made. Exiting."
        exit 0
    fi
    
    # Clean input
    input=$(echo "$input" | tr -d '(),')
    
    # Check for status options first (they don't need bundle expansion)
    case "$input" in
        0)
            show_versions
            exit 0
            ;;
        00)
            check_services_ports
            exit 0
            ;;
        000)
            show_quick_status
            exit 0
            ;;
    esac
    
    # Expand bundles
    local choices
    choices=$(expand_bundles "$input")
    
    if [ -z "$choices" ]; then
        log_error "No valid choices. Exiting."
        exit 0
    fi
    
    log_info "Selected tools: $choices"
    echo ""
    
    # Update package manager
    log_info "Updating package repositories..."
    $UPDATE_CMD || true
    
    # Install base dependencies
    install_base_deps
    
    # Setup bashrc only when terminal utilities are selected (items 25-35)
    if echo "$choices" | grep -qE '\b(2[5-9]|3[0-5])\b'; then
        setup_bashrc
    fi
    
    # Process each choice
    for choice in $choices; do
        echo ""
        process_choice "$choice"
    done
    
    echo ""
    log_header "Installation Complete"
    
    if [ "$NEEDS_REBOOT" = "true" ]; then
        log_info "Docker group changes require logout/login or reboot."
        echo ""
        read -rp "Reboot now? [y/N]: " reboot_choice
        if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
            sudo reboot
        else
            log_info "Please reboot or logout/login to apply Docker group changes."
        fi
    else
        log_success "All selected tools installed successfully!"
        log_info "Run 'source ~/.bashrc' or restart your terminal to apply changes."
    fi
}

# Run main
main "$@"