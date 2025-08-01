network_id = "11256161"
server_details = {
  "rke2-master-1" = {
    "id" = "104560828"
    "location" = "nbg1"
    "private_ip" = "10.0.1.10"
    "public_ip" = "78.46.205.118"
  }
  "rke2-master-2" = {
    "id" = "104560827"
    "location" = "nbg1"
    "private_ip" = "10.0.1.11"
    "public_ip" = "49.13.196.113"
  }
  "rke2-master-3" = {
    "id" = "104560826"
    "location" = "nbg1"
    "private_ip" = "10.0.1.12"
    "public_ip" = "157.90.227.97"
  }
}
ssh_connection_commands = {
  "rke2-master-1" = "ssh root@78.46.205.118"
  "rke2-master-2" = "ssh root@49.13.196.113"
  "rke2-master-3" = "ssh root@157.90.227.97"
}
subnet_id = "11256161-10.0.1.0/24"
