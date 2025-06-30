variable "enabled" {
  description = "Set to false to prevent the module from creating any resources"
  type        = bool
  default     = true
}

variable "location" {
  description = "The Azure Region where the Network Security Group should exist"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Network Security Group"
  type        = string
}

variable "nsg_name" {
  description = "Custom name for the Network Security Group. If not specified, the module will use the ID from the label module"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with this Network Security Group"
  type        = list(string)
  default     = []
}

variable "default_security_rules" {
  description = "Map of default security rules to create"
  type = map(object({
    priority                     = number
    direction                    = string
    access                      = string
    protocol                    = string
    source_port_range           = optional(string)
    destination_port_range      = optional(string)
    source_port_ranges          = optional(list(string))
    destination_port_ranges     = optional(list(string))
    source_address_prefix       = optional(string)
    destination_address_prefix  = optional(string)
    source_address_prefixes     = optional(list(string))
    destination_address_prefixes = optional(list(string))
  }))
  default = {
    "DenyRDP" = {
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Deny" 
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    "DenySSH" = {
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    "DenyWinRM" = {
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["5985", "5986"]
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    "DenySQL" = {
      priority                   = 1003
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    "DenyMySQL" = {
      priority                   = 1004
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    "DenyPostgreSQL" = {
      priority                   = 1005
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    "DenyMongoDB" = {
      priority                   = 1006
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "27017"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    "DenyRedis" = {
      priority                   = 1007
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "6379"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
  }
}

variable "custom_security_rules" {
  description = "Map of custom security rules to create in addition to default rules"
  type = map(object({
    priority                     = number
    direction                    = string
    access                      = string
    protocol                    = string
    source_port_range           = optional(string)
    destination_port_range      = optional(string)
    source_port_ranges          = optional(list(string))
    destination_port_ranges     = optional(list(string))
    source_address_prefix       = optional(string)
    destination_address_prefix  = optional(string)
    source_address_prefixes     = optional(list(string))
    destination_address_prefixes = optional(list(string))
  }))
  default = {}
}

# Label module variables
variable "namespace" {
  description = "ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique"
  type        = string
  default     = null
}

variable "tenant" {
  description = "ID element _(Rarely used, not included by default)_. A customer identifier, indicating who this instance of a resource is for"
  type        = string
  default     = null
}

variable "environment" {
  description = "ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT'"
  type        = string
  default     = null
}

variable "stage" {
  description = "ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release'"
  type        = string
  default     = null
}

variable "name" {
  description = "ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'"
  type        = string
  default     = null
}

variable "attributes" {
  description = "ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id` in the order they appear in the list"
  type        = list(string)
  default     = []
}

variable "delimiter" {
  description = "Delimiter to be used between ID elements"
  type        = string
  default     = "-"
}

variable "tags" {
  description = "Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`)"
  type        = map(string)
  default     = {}
}

variable "regex_replace_chars" {
  description = "Terraform regular expression (regex) string. Characters matching the regex will be removed from the ID elements"
  type        = string
  default     = null
}

variable "label_order" {
  description = "The order in which the labels (ID elements) appear in the id"
  type        = list(string)
  default     = null
}

variable "label_key_case" {
  description = "Controls the letter case of the tags keys (label names) for tags generated by this module"
  type        = string
  default     = null
}

variable "label_value_case" {
  description = "Controls the letter case of the tags values for tags generated by this module"
  type        = string
  default     = null
}

variable "id_length_limit" {
  description = "Limit `id` to this many characters (minimum 6)"
  type        = number
  default     = null
}