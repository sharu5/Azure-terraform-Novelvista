variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "my_public_ip" {
  description = "Your public IP address with /32 CIDR"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "subnets_config" {
  description = "Configuration for subnets"
  type = object({
    public = object({
      id   = string
      cidr = string
    })
    private = object({
      id   = string
      cidr = string
    })
  })
}

variable "vm_config" {
  description = "Configuration for Virtual Machines"
  type = object({
    public_vms = list(object({
      name       = string
      size       = string
      admin_user = string
    }))
    private_vms = list(object({
      name       = string
      size       = string
      admin_user = string
    }))
    ssh_public_key_path = string
  })
}

variable "app_config" {
  description = "Application configuration"
  type = object({
    name        = string
    port        = number
    environment = string
  })
}