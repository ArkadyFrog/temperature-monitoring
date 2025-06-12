resource "random_id" "suffix" {
  byte_length = 4
}

# RG
resource "azurerm_resource_group" "rg" {
  name     = "rg-app-temperature-exporter-vm"
  location = "West Europe"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_public_ip" "vm_ip" {
  name                = "vm-public-ip"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-app-temperature-exporter"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name           = "subnet-default"
    address_prefix = "10.0.1.0/24"
    security_group = azurerm_network_security_group.subnet_nsg.id
  }

}

data "azurerm_subnet" "existing_subnet" {
  name                 = "subnet-default"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.existing_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_ip.id
  }
}

resource "azurerm_network_security_group" "subnet_nsg" {
  name                = "nsg-subnet-default"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  
}

# Key Vault Resources
resource "azurerm_key_vault" "ssh_vault" {
  name                       = "kv-ssh-${random_id.suffix.hex}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    
    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]
  }
}

# Secret creation with proper error handling
resource "azurerm_key_vault_secret" "vm_ssh_private" {
  name         = "vm-ssh-private-key"
  value        = var.ssh_private_key
  key_vault_id = azurerm_key_vault.ssh_vault.id
  content_type = "text/plain"

  lifecycle {
    ignore_changes = [value] # Prevent updates to existing secrets
  }
}

# VM Access Policy with minimal required permissions
resource "azurerm_key_vault_access_policy" "vm_policy" {
  key_vault_id = azurerm_key_vault.ssh_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.minikube_vm.identity[0].principal_id
  
  secret_permissions = ["Get"]
}

data "azurerm_client_config" "current" {}

# VM Resources
resource "azurerm_linux_virtual_machine" "minikube_vm" {
  name                = "minikube-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "westeurope"
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  custom_data = filebase64("${path.module}/scripts/setup.sh")
}
