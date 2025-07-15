variable "enabled" {
  description = "Set to false to prevent the module from creating any resources"
  type        = bool
  default     = true
}

variable "location" {
  description = "The Azure Region where the Key Vault should be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Key Vault"
  type        = string
}

# Key Vault Configuration
variable "sku_name" {
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "The sku_name must be either standard or premium."
  }
}

variable "enabled_for_deployment" {
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions"
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Is Purge Protection enabled for this Key Vault? Once enabled, it cannot be disabled"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted. Valid values are between 7 and 90"
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "The soft_delete_retention_days must be between 7 and 90."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this Key Vault"
  type        = bool
  default     = false
}

# Network Access Control
variable "network_acls" {
  description = "Network rules restricting access to the key vault"
  type = object({
    default_action             = string
    bypass                     = optional(string, "AzureServices")
    ip_rules                   = optional(set(string))
    virtual_network_subnet_ids = optional(set(string))
  })
  default = null
}

# Access Policies
variable "add_current_user_access" {
  description = "Whether to add the current user/service principal to the Key Vault access policy with full permissions"
  type        = bool
  default     = true
}

variable "access_policies" {
  description = "Map of access policies for the Key Vault"
  type = map(object({
    tenant_id               = optional(string)
    object_id               = string
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = {}
}

# Certificate Contacts
variable "certificate_contacts" {
  description = "Contact information to associate with the Key Vault for certificate operations"
  type = list(object({
    email = string
    name  = optional(string)
    phone = optional(string)
  }))
  default = []
}

# Diagnostic Settings
variable "diagnostic_settings" {
  description = "Diagnostic settings for the Key Vault"
  type = object({
    log_analytics_workspace_id = optional(string)
    storage_account_id         = optional(string)
    log_categories             = optional(list(string), ["AuditEvent", "AzurePolicyEvaluationDetails"])
    metric_categories          = optional(list(string), ["AllMetrics"])
  })
  default = null
}

# Secrets
variable "secrets" {
  description = "Map of secrets to create in the Key Vault"
  type = map(object({
    value           = string
    content_type    = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default = {}
}

# Keys
variable "keys" {
  description = "Map of keys to create in the Key Vault"
  type = map(object({
    key_type        = string
    key_size        = optional(number)
    curve           = optional(string)
    key_opts        = list(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    rotation_policy = optional(object({
      automatic = object({
        time_after_creation = optional(string)
        time_before_expiry  = optional(string)
      })
      expire_after         = optional(string)
      notify_before_expiry = optional(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

# Certificates
variable "certificates" {
  description = "Map of certificates to create in the Key Vault"
  type = map(object({
    certificate_contents = optional(string)
    certificate_password = optional(string)
    certificate_policy = object({
      issuer_parameters = object({
        name = string
      })
      key_properties = object({
        exportable = bool
        key_size   = number
        key_type   = string
        reuse_key  = bool
      })
      lifetime_action = object({
        action = object({
          action_type = string
        })
        trigger = object({
          days_before_expiry  = optional(number)
          lifetime_percentage = optional(number)
        })
      })
      secret_properties = object({
        content_type = string
      })
      x509_certificate_properties = optional(object({
        key_usage          = list(string)
        subject            = string
        validity_in_months = number
        subject_alternative_names = optional(object({
          dns_names = optional(list(string))
          emails    = optional(list(string))
          upns      = optional(list(string))
        }))
      }))
    })
    tags = optional(map(string), {})
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