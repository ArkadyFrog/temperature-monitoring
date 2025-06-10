output "vm_public_ip" {
  value = azurerm_public_ip.vm_ip.ip_address
}

output "key_vault_name" {
  value = azurerm_key_vault.ssh_vault.name
}