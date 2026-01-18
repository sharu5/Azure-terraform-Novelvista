terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}
provider "azurerm" {
  features {}

  subscription_id            = var.subscription_id
  skip_provider_registration = var.resource_provider_registrations == "none" ? true : false
}



# Fetch existing resource group
data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

# Get current public IP for NSG rules (Your IP: 119.8.97.34)
data "http" "myip" {
  url = "https://api.ipify.org"
}

locals {
  my_public_ip = "${chomp(data.http.myip.response_body)}/32"
}