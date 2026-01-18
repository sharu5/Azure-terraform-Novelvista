variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_id" {
  description = "Virtual network ID"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = optional(list(string))
  }))
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}