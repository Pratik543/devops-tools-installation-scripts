# NodeJs Installation

> Official Documentation: https://nodejs.org/en/download

# Ubuntu/Debian, Fedora, RHEL

```sh
# Fetch latest nvm version dynamically and install:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | awk -F'"' '/"tag_name":/ {print $4}')/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 24

# Verify the Node.js version:
node -v

# Verify npm version:
npm -v
```