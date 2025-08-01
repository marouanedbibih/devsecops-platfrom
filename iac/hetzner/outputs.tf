output "network_id" {
  description = "ID of the created network"
  value       = hcloud_network.rke2_network.id
}

output "subnet_id" {
  description = "ID of the created subnet"
  value       = hcloud_network_subnet.rke2_subnet.id
}

output "server_details" {
  description = "Details of the created servers"
  value = {
    for server in hcloud_server.rke2_masters : server.name => {
      id          = server.id
      public_ip   = server.ipv4_address
      private_ip = tolist(server.network)[0].ip
      location    = server.location
    }
  }
}

output "ssh_connection_commands" {
  description = "SSH commands to connect to servers"
  value = {
    for server in hcloud_server.rke2_masters : server.name => 
      "ssh root@${server.ipv4_address}"
  }
}