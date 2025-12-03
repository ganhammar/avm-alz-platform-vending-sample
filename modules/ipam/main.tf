resource "azureipam_space" "europe" {
  name        = "Europe"
  description = "Azure Europe Space"
}

resource "azureipam_block" "europe" {
  space = azureipam_space.europe.name
  name  = "Azure IPAM Europe Block"
  cidr  = "10.50.0.0/18" # 16,384 IP addresses
}
