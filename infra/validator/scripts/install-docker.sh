#!/bin/bash
set -euo pipefail

# Docker Installation Script for XRPL Validator
# Installs Docker with security hardening

echo "Installing Docker..."

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install docker-compose (standalone)
curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure Docker daemon
echo "Configuring Docker daemon..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "icc": false,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 1048576,
      "Soft": 1048576
    }
  }
}
EOF

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Configure Docker log rotation
cat > /etc/logrotate.d/docker-container <<EOF
/var/lib/docker/containers/*/*.log {
    rotate 5
    daily
    compress
    size=100M
    missingok
    delaycompress
    copytruncate
}
EOF

# Test Docker installation
echo "Testing Docker installation..."
docker run --rm hello-world

echo "✓ Docker installation complete!"
echo "Docker version:"
docker --version
docker-compose --version
