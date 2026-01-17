#!/bin/bash
# Complete setup script for Ollama Podman Compose service on RHEL 9
# This script handles everything: service account, UID/GID mappings, and systemd service

set -e  # Exit on error

echo "=========================================="
echo "Ollama Podman Compose Service Setup"
echo "=========================================="
echo ""

# Check if compose file exists
if [ ! -f /opt/compose.yml ]; then
    echo "ERROR: /opt/compose.yml not found!"
    echo "Please ensure your compose file is at /opt/compose.yml before running this script."
    exit 1
fi

# Stop service if it exists
if systemctl is-active --quiet ollama.service 2>/dev/null; then
    echo "Stopping existing ollama.service..."
    sudo systemctl stop ollama.service
fi

# Check if user exists, create if not
if id "podman-svc" &>/dev/null; then
    echo "Service account 'podman-svc' already exists, skipping creation..."
else
    echo "Creating service account 'podman-svc'..."
    sudo useradd -r -s /sbin/nologin -d /opt/podman-svc -m podman-svc
fi

# Set ownership of compose file
echo "Setting ownership of /opt/compose.yml..."
sudo chown podman-svc:podman-svc /opt/compose.yml

# Enable lingering for the service account
echo "Enabling lingering for podman-svc..."
sudo loginctl enable-linger podman-svc

# Configure subuid/subgid mappings
echo "Configuring UID/GID mappings..."
# Remove existing entries
sudo sed -i '/^podman-svc:/d' /etc/subuid 2>/dev/null || true
sudo sed -i '/^podman-svc:/d' /etc/subgid 2>/dev/null || true

# Add new mappings that include the full range starting at 100000
# This maps container UIDs 0-65535 to host UIDs starting at 100000
echo "podman-svc:100000:65536" | sudo tee -a /etc/subuid > /dev/null
echo "podman-svc:100000:65536" | sudo tee -a /etc/subgid > /dev/null

# Also add a mapping for low UIDs/GIDs (0-999) which many containers need
# This is needed for system users like GID 42
sudo usermod --add-subuids 100000-165535 podman-svc 2>/dev/null || true
sudo usermod --add-subgids 100000-165535 podman-svc 2>/dev/null || true

echo "UID/GID mappings configured:"
grep podman-svc /etc/subuid
grep podman-svc /etc/subgid
echo ""

# Reset and migrate podman for the user
echo "Resetting Podman storage for podman-svc user..."
sudo -u podman-svc podman system reset -f 2>/dev/null || true

echo "Migrating Podman to use new UID/GID mappings..."
sudo -u podman-svc podman system migrate 2>/dev/null || true

# Create systemd service file
echo "Creating systemd service file..."
sudo tee /etc/systemd/system/ollama.service > /dev/null <<'EOF'
[Unit]
Description=Podman Compose for Ollama/OpenAI-Web
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=podman-svc
Group=podman-svc
WorkingDirectory=/opt
ExecStart=/usr/bin/podman-compose -f /opt/compose.yml up -d
ExecStop=/usr/bin/podman-compose -f /opt/compose.yml down
Restart=on-failure
RestartSec=10
TimeoutStartSec=300
TimeoutStopSec=120
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable the service
echo "Enabling ollama.service..."
sudo systemctl enable ollama.service

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Pull container images:"
echo "   sudo -u podman-svc podman-compose -f /opt/compose.yml pull"
echo ""
echo "2. Start the service:"
echo "   sudo systemctl start ollama.service"
echo ""
echo "3. Check service status:"
echo "   sudo systemctl status ollama.service"
echo ""
echo "4. View logs:"
echo "   sudo journalctl -u ollama.service -f"
echo ""
echo "5. Check running containers:"
echo "   sudo -u podman-svc podman ps"
echo ""
echo "Useful commands:"
echo "  - Stop service: sudo systemctl stop ollama.service"
echo "  - Restart service: sudo systemctl restart ollama.service"
echo "  - View compose logs: sudo -u podman-svc podman-compose -f /opt/compose.yml logs -f"
echo ""