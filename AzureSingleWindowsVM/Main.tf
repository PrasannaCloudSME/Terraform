terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.73.0"
    }
  }
}

provider "azurerm" {
   subscription_id = "*******************"
   client_id       = "*******************"
   client_secret   = "*******************"
   tenant_id       = "*******************"
features {}
   
 }


resource "azurerm_resource_group" "prarg" {

  name = "prasannaTerraformRG"
  location = "eastus"  
}

resource "azurerm_virtual_network" "Pvnet" {

  name = "Prasannavnet"
  address_space = [ "10.0.0.0/16" ]
  location = azurerm_resource_group.prarg.location
  resource_group_name = azurerm_resource_group.prarg.name
  
}

resource "azurerm_subnet" "Psubnet" {
  
  name="internal"
  address_prefixes = [ "10.0.2.0/24" ]
  resource_group_name = azurerm_resource_group.prarg.name
  virtual_network_name = azurerm_virtual_network.Pvnet.name
}

resource "azurerm_public_ip" "ppip" {
  
   name = "ppublic_ip"
   resource_group_name = azurerm_resource_group.prarg.name
   location = azurerm_resource_group.prarg.location
   allocation_method = "Dynamic"
}

resource "azurerm_network_security_group" "Pnsg" {

  name = "prasannaNSG"
  location = azurerm_resource_group.prarg.location
  resource_group_name = azurerm_resource_group.prarg.name

  security_rule {
    name                       = "allow_RDP"
    description                = "Allow RDP access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
}

resource "azurerm_network_interface" "pnetworkinterface" {
  
  name = "vnet-nic"
  location = azurerm_resource_group.prarg.location
  resource_group_name = azurerm_resource_group.prarg.name
  

  ip_configuration {
    
     name = "internal"
     subnet_id = azurerm_subnet.Psubnet.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id = azurerm_public_ip.ppip.id
  }
}

resource "azurerm_windows_virtual_machine" "example" {
   name                = "example-vm"
   resource_group_name = azurerm_resource_group.prarg.name
   location = azurerm_resource_group.prarg.location
   size                = "Standard_F2"
   admin_username      = "adminuser"
   admin_password      = "P@$$w0rd1234!"
  
  network_interface_ids = [ 
    azurerm_network_interface.pnetworkinterface.id,  
]
os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
