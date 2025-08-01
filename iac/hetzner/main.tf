# Create SSH key (optional - you can also create this manually in Hetzner Console)
resource "hcloud_ssh_key" "default" {
  name       = var.ssh_key_name
  public_key = file("~/.ssh/rke2/id_rsa.pub") # Adjust path to your public key
}

# Create private network
resource "hcloud_network" "rke2_network" {
  name     = "rke2-network"
  ip_range = "10.0.0.0/16"
  labels = {
    environment = "rke2"
    purpose     = "kubernetes"
  }
}

# Create subnet within the private network
resource "hcloud_network_subnet" "rke2_subnet" {
  network_id   = hcloud_network.rke2_network.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = "10.0.1.0/24"
}

# Create the three RKE2 master servers
resource "hcloud_server" "rke2_masters" {
  count       = 3
  name        = "rke2-master-${count.index + 1}"
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.default.id]
  
  # Attach to private network
  network {
    network_id = hcloud_network.rke2_network.id
    ip         = "10.0.1.${count.index + 10}" # IPs: 10.0.1.10, 10.0.1.11, 10.0.1.12
  }
  
  # Ensure network is created before servers
  depends_on = [hcloud_network_subnet.rke2_subnet]
  
  labels = {
    environment = "rke2"
    role        = "master"
    node        = "rke2-master-${count.index + 1}"
  }
  
  # Basic firewall rules
  firewall_ids = [hcloud_firewall.rke2_firewall.id]
}

# Create firewall for RKE2 masters
resource "hcloud_firewall" "rke2_firewall" {
  name = "rke2-masters-firewall"
  
  # SSH access
  rule {
    direction = "in"
    port      = "22"
    protocol  = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  
  # Kubernetes API Server
  rule {
    direction = "in"
    port      = "6443"
    protocol  = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  
  # RKE2 specific ports (adjust as needed)
  rule {
    direction = "in"
    port      = "9345"
    protocol  = "tcp"
    source_ips = ["10.0.0.0/16"]
  }
  
  # HTTP/HTTPS for ingress
  rule {
    direction = "in"
    port      = "80"
    protocol  = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
  
  rule {
    direction = "in"
    port      = "443"
    protocol  = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}