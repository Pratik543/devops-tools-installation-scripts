

## **Detailed Detection Methods to see if**

### **1. Check Running Process (Most Reliable)**
```bash
ps aux | grep -v grep | grep jenkins
```

**WAR File Installation:**
```
root      1234  ... java -jar /opt/jenkins/jenkins.war --httpPort=8080
```
- Shows `-jar` flag
- Path usually custom (`/opt/`, `/home/user/`, etc.)
- Often runs as `root` or current user

**Package Manager Installation:**
```
jenkins   1234  ... /usr/bin/java -Djava.awt.headless=true -jar /usr/share/jenkins/jenkins.war --webroot=/var/cache/jenkins/war --httpPort=8080
```
- Shows system paths (`/usr/share/jenkins/`)
- Runs as `jenkins` user (specific user created by package)
- Extra system parameters (`--webroot=/var/cache/...`)

### **2. Check Systemd Service (Package Indicator)**
```bash
systemctl status jenkins
```

- **Package**: Shows `loaded: /lib/systemd/system/jenkins.service` or `/etc/systemd/system/jenkins.service` (symlink to `/usr/lib/...`)
- **WAR**: Usually no systemd service, or custom service file you created manually

### **3. Check Configuration Files**
```bash
# Package manager leaves these traces:
ls -la /etc/default/jenkins        # Debian/Ubuntu
ls -la /etc/sysconfig/jenkins      # CentOS/RHEL
ls -la /usr/lib/jenkins/           # Package installation dir
dpkg -l | grep jenkins             # Debian check
rpm -qa | grep jenkins             # RHEL check
```

**If these exist → Package installation**

### **4. Check Installation Paths**
```bash
# Package locations (managed by apt/yum)
ls /usr/share/jenkins/jenkins.war
ls /var/lib/jenkins/               # JENKINS_HOME for packages
ls /var/log/jenkins/               # Package log location

# WAR file locations (manual install)
ls /opt/jenkins/
ls ~/jenkins.war
```

### **5. Check User Ownership**
```bash
ps -o user= -p $(pgrep -f "jenkins.war")
```

- Returns `jenkins` → **Package** (created by post-install script)
- Returns `root` or your username → **WAR file** (manual run)

---

## **Automated Detection Script**

```bash
#!/bin/bash
detect_jenkins_install() {
    # Find Jenkins process
    PID=$(pgrep -f "jenkins.war" | head -1)
    
    if [ -z "$PID" ]; then
        echo "❌ Jenkins not running"
        return 1
    fi
    
    CMDLINE=$(cat /proc/$PID/cmdline 2>/dev/null | tr '\0' ' ')
    USER=$(ps -o user= -p $PID 2>/dev/null | tr -d ' ')
    
    echo "Process ID: $PID"
    echo "Running as user: $USER"
    echo ""
    
    # Detection logic
    if [ "$USER" = "jenkins" ] && [ -f /etc/default/jenkins -o -f /etc/sysconfig/jenkins ]; then
        echo "✅ DETECTED: Package Manager Installation (apt/yum)"
        echo "   Config: /etc/default/jenkins or /etc/sysconfig/jenkins"
        echo "   Home: /var/lib/jenkins"
        [ -d /var/log/jenkins ] && echo "   Logs: /var/log/jenkins"
        
    elif echo "$CMDLINE" | grep -q "\-jar" && [ "$USER" != "jenkins" ]; then
        echo "✅ DETECTED: WAR File (Standalone/Manual)"
        echo "   Command: $CMDLINE"
        WAR_PATH=$(echo "$CMDLINE" | grep -o "\-jar [^ ]*" | cut -d' ' -f2)
        echo "   WAR Location: $WAR_PATH"
        echo "   User: $USER (not the 'jenkins' system user)"
        
        # Check if systemd manages it anyway
        if systemctl is-active jenkins >/dev/null 2>&1; then
            echo "   Note: Running under systemd (custom service file)"
        else
            echo "   Note: Likely started manually or via init.d script"
        fi
        
    elif echo "$CMDLINE" | grep -q "/usr/share/jenkins"; then
        echo "✅ DETECTED: Package Manager Installation"
        echo "   Path: /usr/share/jenkins (system directory)"
        
    else
        echo "⚠️  AMBIGUOUS: Custom installation"
        echo "   Command: $CMDLINE"
    fi
    
    # Additional context
    echo ""
    echo "Listening ports:"
    sudo ss -ltnp | grep $PID | awk '{print "   " $4}' | head -2
}

detect_jenkins_install
```

---

## **Key Differences Summary**

| Feature       | Package Manager                  | WAR File                            |
| ------------- | -------------------------------- | ----------------------------------- |
| **User**      | `jenkins` (dedicated)            | `root` or current user              |
| **Process**   | `/usr/share/jenkins/jenkins.war` | Custom path (`/opt/`, `/home/`)     |
| **Config**    | `/etc/default/jenkins`           | Command-line args or env vars       |
| **Home Dir**  | `/var/lib/jenkins`               | `~/.jenkins` or `--webroot=` arg    |
| **Logs**      | `/var/log/jenkins/`              | Console output or custom location   |
| **Service**   | `systemctl status jenkins`       | Manual `java -jar` or custom script |
| **Uninstall** | `apt remove jenkins`             | Kill process + delete files         |

**Pro Tip:** If Jenkins is running on port 8080 but `systemctl status jenkins` shows "inactive," it's definitely a WAR file installation.