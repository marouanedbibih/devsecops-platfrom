#!/bin/bash

set -euo pipefail

echo "🔷 Disabling swap..."
swapoff -a

# Comment out swap in /etc/fstab if present
if grep -q ' swap ' /etc/fstab; then
    sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    echo "✅ Swap disabled and fstab updated"
else
    echo "✅ Swap already disabled"
fi

echo "🔷 Loading kernel modules..."
for module in overlay br_netfilter; do
    if ! lsmod | grep -q "^$module"; then
        modprobe $module
        echo "✅ Loaded module: $module"
    else
        echo "✅ Module already loaded: $module"
    fi
done

# Ensure modules are loaded on boot
cat <<EOF | tee /etc/modules-load.d/k8s.conf >/dev/null
br_netfilter
overlay
EOF

echo "🔷 Setting sysctl parameters for Kubernetes networking..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf >/dev/null
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

echo "✅ Node preparation complete. Ready for RKE2 installation."
