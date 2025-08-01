# Download and install RKE2
curl -sfL https://get.rke2.io | sh -

# Create RKE2 config directory
mkdir -p /etc/rancher/rke2

# Create RKE2 config for first master
cat > /etc/rancher/rke2/config.yaml << EOF
# Basic cluster configuration
token: 16e84f6f6a375a22e3a9f06267b5c3a65bebaf9cf04fa2d4da975ef9606fe4fb
cluster-cidr: 10.42.0.0/16
service-cidr: 10.43.0.0/16
cluster-dns: 10.43.0.10

# TLS SAN for API server
tls-san:
  - 78.46.205.118
  - 49.13.196.113
  - 157.90.227.97
  - rke2-master-1
  - rke2-master-2
  - rke2-master-3

# Network configuration
cni: canal
disable-kube-proxy: false
disable-cloud-controller: true

# etcd configuration
etcd-expose-metrics: true
etcd-disable-snapshots: false
etcd-snapshot-retention: 5
etcd-snapshot-schedule-cron: "0 */12 * * *"

# Security
protect-kernel-defaults: true
secrets-encryption: true

# Logging
log: /var/log/rke2.log
EOF

# Replace token in config file
sed -i "s/16e84f6f6a375a22e3a9f06267b5c3a65bebaf9cf04fa2d4da975ef9606fe4fb/$(cat /tmp/rke2-token)/" /etc/rancher/rke2/config.yaml

# Enable and start RKE2 server
systemctl enable rke2-server.service
systemctl start rke2-server.service

# Wait for service to be ready
echo "Waiting for RKE2 server to start..."
sleep 60

# Check status
systemctl status rke2-server.service


## RKE2 Master 2
# Download and install RKE2
curl -sfL https://get.rke2.io | sh -

# Create RKE2 config directory
mkdir -p /etc/rancher/rke2

# Create RKE2 config for second master
cat > /etc/rancher/rke2/config.yaml << EOF
# Cluster join configuration
server: https://78.46.205.118:9345
token: 16e84f6f6a375a22e3a9f06267b5c3a65bebaf9cf04fa2d4da975ef9606fe4fb
cluster-cidr: 10.42.0.0/16
service-cidr: 10.43.0.0/16
cluster-dns: 10.43.0.10

# TLS SAN for API server
tls-san:
  - 78.46.205.118
  - 49.13.196.113
  - 157.90.227.97
  - rke2-master-1
  - rke2-master-2
  - rke2-master-3

# Network configuration
cni: canal
disable-kube-proxy: false
disable-cloud-controller: true

# etcd configuration
etcd-expose-metrics: true
etcd-disable-snapshots: false

# Security
protect-kernel-defaults: true
secrets-encryption: true

# Logging
log: /var/log/rke2.log
EOF

# Replace token (use the same token from step 4)
sed -i "s/16e84f6f6a375a22e3a9f06267b5c3a65bebaf9cf04fa2d4da975ef9606fe4fb/$(cat /tmp/rke2-token)/" /etc/rancher/rke2/config.yaml

# Enable and start RKE2 server
systemctl enable rke2-server.service
systemctl start rke2-server.service

# Wait for service to be ready
echo "Waiting for RKE2 server to start..."
sleep 60

# Check status
systemctl status rke2-server.service




####### RKE2 Master 3
# Download and install RKE2
curl -sfL https://get.rke2.io | sh -

# Create RKE2 config directory
mkdir -p /etc/rancher/rke2

# Create RKE2 config for third master (same as second master)
cat > /etc/rancher/rke2/config.yaml << EOF
# Cluster join configuration
server: https://78.46.205.118:9345
token: 16e84f6f6a375a22e3a9f06267b5c3a65bebaf9cf04fa2d4da975ef9606fe4fb
cluster-cidr: 10.42.0.0/16
service-cidr: 10.43.0.0/16
cluster-dns: 10.43.0.10

# TLS SAN for API server
tls-san:
  - 78.46.205.118
  - 49.13.196.113
  - 157.90.227.97
  - rke2-master-1
  - rke2-master-2
  - rke2-master-3

# Network configuration
cni: canal
disable-kube-proxy: false
disable-cloud-controller: true

# etcd configuration
etcd-expose-metrics: true
etcd-disable-snapshots: false

# Security
protect-kernel-defaults: true
secrets-encryption: true

# Logging
log: /var/log/rke2.log
EOF

# Replace token (use the same token from step 4)
sed -i "s/16e84f6f6a375a22e3a9f06267b5c3a65bebaf9cf04fa2d4da975ef9606fe4fb/$(cat /tmp/rke2-token)/" /etc/rancher/rke2/config.yaml

# Enable and start RKE2 server
systemctl enable rke2-server.service
systemctl start rke2-server.service

# Wait for service to be ready
echo "Waiting for RKE2 server to start..."
sleep 60

# Check status
systemctl status rke2-server.service