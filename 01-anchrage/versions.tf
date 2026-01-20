

terraform {
  required_providers {
    ionoscloud = {
      source = "ionos-cloud/ionoscloud"
      version = "6.7.21"
    }
    # proxmox = {
    #   source = "Telmate/proxmox"
    #   version = "3.0.2-rc07"
    # }
  }
}

# provider "proxmox" {
#   # Configuration options
# }

provider "ionoscloud" {
  # Configuration options
}

