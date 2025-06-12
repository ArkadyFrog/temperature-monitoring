variable "subscription_id" {
  type = string
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type = string
}

variable "ssh_public_key" {
  description = "Public SSH key for VM access"
  type        = string
}

variable "ssh_private_key" {
  description = "Private SSH key content"
  type        = string
  sensitive   = true
}

variable "openweathermap_api_key" {
  type      = string
  sensitive = true
}

variable "allow_secret_creation" {
  description = "Whether to allow creation of new secrets if they don't exist"
  type        = bool
  default     = true
}

# variable "create_new_secret" {
#   description = "Whether to create a new secret or use existing one"
#   type        = bool
#   default     = false
# }

# variable "secret_name" {
#   description = "Base name for the secret (without random suffix)"
#   type        = string
#   default     = "vm-ssh-private-key"
# }