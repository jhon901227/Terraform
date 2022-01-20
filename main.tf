terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = "= 1.0.3"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RGVM" {
  name     = "Resource_Group_VM"
  location = "West Europe"
}

resource "azurerm_virtual_network" "VN" {
  name                = "VN"
  address_space       = var.address["vn"]
  location            = azurerm_resource_group.RGVM.location
  resource_group_name = azurerm_resource_group.RGVM.name
}

resource "azurerm_subnet" "SubnetVM" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.RGVM.name
  virtual_network_name = azurerm_virtual_network.VN.name
  address_prefixes     = var.address["subnet"]
}

resource  "azurerm_public_ip" "PublicIP" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.RGVM.name
  location            = azurerm_resource_group.RGVM.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_security_group" "ngs1" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.RGVM.location
  resource_group_name = azurerm_resource_group.RGVM.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "NIC" {
  name                = "nic"
  location            = azurerm_resource_group.RGVM.location
  resource_group_name = azurerm_resource_group.RGVM.name
 

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetVM.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.PublicIP.id
  }
}


resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}




resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.RGVM.name
  location            = azurerm_resource_group.RGVM.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      =  var.pass
  network_interface_ids = [
    azurerm_network_interface.NIC.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  connection {
    type     = "ssh"
    user     = azurerm_linux_virtual_machine.example.admin_username
    password = var.pass
    //host     = azurerm_public_ip.PublicIP.ip_address
    host     = self.public_ip_address
    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "yum update -y"
     
    ]
  }

}

output "output"{  

value = zipmap([azurerm_linux_virtual_machine.example.name],[azurerm_linux_virtual_machine.example.public_ip_address]) 

}  
  
output "tls_private_key" { 
    value = tls_private_key.example_ssh.private_key_pem 
    sensitive = true
}