# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
    backend "azurerm" {
        resource_group_name  = "pers-efe_kaya-rg"
        storage_account_name = "storageprovision"
        container_name       = "terrastate"
        key                  = "terraform.tfstate"
    }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id   = "41e50375-b926-4bc4-9045-348f359cf721"
  tenant_id         = "f82b3c62-b635-402b-afa2-a1a807bbfd42"
  client_id         = "471d5149-8626-4887-a6f4-ce34c3e4e69e"
  client_secret     = "OiJ8Q~2ojys9AGpLZ1aGTuESIv5CAab8hh1Eda1l"

}

# Create a resource group
#  resource "azurerm_resource_group" "rg" {
#    name     = "pet_provision_rg"
#    location = "West Europe"
#  }

# Create virtual network
resource "azurerm_virtual_network" "virtualnetwork" {
    name                = "pet_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "westeurope"
    resource_group_name = "pers-efe_kaya-rg"
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "pet_subnet"
    resource_group_name  = "pers-efe_kaya-rg"
     #azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.virtualnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "petpublicip" {
  name                = "myPublicIP"
  location            = "West Europe"
  resource_group_name = "pers-efe_kaya-rg"
  allocation_method   = "Static"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "networksecuritygroup" {
    name                = "nsg_pet"
    location            = "West Europe"
    resource_group_name = "pers-efe_kaya-rg"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "port_8080"
        priority                   = 1011
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
     security_rule {
        name                       = "port_80"
        priority                   = 1021
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
     security_rule {
        name                       = "port_443"
        priority                   = 1031
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}


# Create network interface
resource "azurerm_network_interface" "pet_nic" {
  name                = "myNIC"
  location            = "West Europe"
  resource_group_name = "pers-efe_kaya-rg"

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.petpublicip.id
    #public_ip_address_id =  "/subscriptions/982abf2e-ad19-4895-ae55-8fc1da966f38/resourceGroups/terraform-rg/providers/Microsoft.Network/publicIPAddresses/VMsshKeyPublicIP"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "pet_nic_sga" {
  network_interface_id      = azurerm_network_interface.pet_nic.id
  network_security_group_id = azurerm_network_security_group.networksecuritygroup.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "pers-efe_kaya-rg"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = "West Europe"
  resource_group_name      = "pers-efe_kaya-rg"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#Insert Public key
resource "azurerm_ssh_public_key" "publickey" {
    name = "prov_publickey"
    resource_group_name = "pers-efe_kaya-rg"
    location = "West Europe"
    public_key = tls_private_key.ssh_key.public_key_openssh
   # public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXnhqn0X3gSJTHzy2btQtNBt4QziQBPa11CgfC3TaR1vOsnr21lxKgURDt4qRvEcyrP2eyi0N1BaYcAvSuz8PpjiKv6BG3ky9P3mNRB1txXVZdvCa1Xy2GgaaUPJ3Z5MJW1xp7WCWBwpvWUmlFjvujFFRoE0x3qLSwDXDIc+EBIUiQ4UtsAnDlEl1pqKNVXoMfvKxPVu4T0CIsvW1jiqYX+AeXtj8SB/5WJJwekiwMVskEN30QcwBJULmpa1Otkvy0Q5SQaJeOQ2q8DVEKPu0fjXarqFtQZC1x1qrK0HpysS0zzddZe7JFEeE05DxRVjmfKqpnmup6J1BMRzRvyGAXozWDv1CIRy2GBhjsClP4MXH37isN1Y83WRr2OA3bNVIVcieHTPfdo+lKrJiCo+AQwxN3myGCY9LfLeSkpwiYx3MYdmwi/IUYk255K8plfRppVNY8T6wkW70d4nZXut5pBayk+NCPQFC8GAVoIKBBztVXXtIgZ5nQK6Hv6Tsi1TE= efe.kaya@devoteam.com"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                  = "myVM"
  location              = "West Europe"
  resource_group_name   = "pers-efe_kaya-rg"
  network_interface_ids = [azurerm_network_interface.pet_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "myvm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
   #  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXnhqn0X3gSJTHzy2btQtNBt4QziQBPa11CgfC3TaR1vOsnr21lxKgURDt4qRvEcyrP2eyi0N1BaYcAvSuz8PpjiKv6BG3ky9P3mNRB1txXVZdvCa1Xy2GgaaUPJ3Z5MJW1xp7WCWBwpvWUmlFjvujFFRoE0x3qLSwDXDIc+EBIUiQ4UtsAnDlEl1pqKNVXoMfvKxPVu4T0CIsvW1jiqYX+AeXtj8SB/5WJJwekiwMVskEN30QcwBJULmpa1Otkvy0Q5SQaJeOQ2q8DVEKPu0fjXarqFtQZC1x1qrK0HpysS0zzddZe7JFEeE05DxRVjmfKqpnmup6J1BMRzRvyGAXozWDv1CIRy2GBhjsClP4MXH37isN1Y83WRr2OA3bNVIVcieHTPfdo+lKrJiCo+AQwxN3myGCY9LfLeSkpwiYx3MYdmwi/IUYk255K8plfRppVNY8T6wkW70d4nZXut5pBayk+NCPQFC8GAVoIKBBztVXXtIgZ5nQK6Hv6Tsi1TE= efe.kaya@devoteam.com"
     public_key = tls_private_key.ssh_key.public_key_openssh
  #  public_key = azurerm_ssh_public_key.publickey.public_key
  #  public_key = file("~/.ssh/id_rsa.pub")
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

    connection {
        type = "ssh"
        user = "azureuser"
        host = azurerm_public_ip.petpublicip.id
        private_key = tls_private_key.ssh_key.private_key_pem
    }
}