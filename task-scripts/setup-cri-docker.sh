#!/bin/bash
# Automation for Setup Docker CRI (cri-dockerd)

set -e

echo "🔧 Starting CRI-Docker Setup..."

# Validate environment
if ! command -v systemctl >/dev/null 2>&1; then
  echo "❌ systemctl is required but not available."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "❌ sudo is required but not installed."
  exit 1
fi

if ! command -v cri-dockerd >/dev/null 2>&1; then
  echo "❌ cri-dockerd is not installed."
  echo "Please install the local cri-dockerd package before running this script."
  exit 1
fi

echo "✓ Environment validated"

echo ""
echo "✓ Loading required kernel modules..."
sudo modprobe br_netfilter
sudo modprobe overlay

# 1. Enable and Start Services
echo "✓ Enabling cri-docker services..."
sudo systemctl daemon-reload
sudo systemctl enable --now cri-docker.socket cri-docker.service

# 2. Configure Sysctl Parameters
echo "✓ Configuring kernel parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/99-k8s-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.netfilter.nf_conntrack_max = 131072
EOF

# 3. Apply Sysctl without reboot
sudo sysctl --system

# 4. Restart kubelet to pick up new CRI
if systemctl is-active --quiet kubelet; then
  echo "✓ Restarting kubelet to use the new CRI socket..."
  sudo systemctl restart kubelet
fi

# 5. Verification
echo "----------------------------------"
echo "✅ CRI-Docker Setup Complete!"

echo "
✓ Service status:"
sudo systemctl status cri-docker.socket --no-pager

echo "
✓ Socket status:"
sudo ss -lx | grep -E 'cri-dockerd|docker.sock' || true

echo "
✓ Kernel parameter check:"
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
