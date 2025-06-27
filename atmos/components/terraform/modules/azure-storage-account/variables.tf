variable "enabled" {
  description = "Set to false to prevent the module from creating any resources"
  type        = bool
  default     = true
}

variable "location" {
  description = "The Azure Region where the storage account should be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the storage account"
  type        = string
}

variable "storage_account_name" {
  description = "Custom name for the storage account. If not specified, the module will use the ID from the label module with optional random suffix"
  type        = string
  default     = null
}

variable "use_random_suffix" {
  description = "Add a random suffix to the storage account name to ensure global uniqueness"
  type        = bool
  default     = true
}

# Storage Account Configuration
variable "account_tier" {
  description = "Defines the Tier to use for this storage account. Valid options are Standard and Premium"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "The account_tier must be either Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS"
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "The account_replication_type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "account_kind" {
  description = "Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2"
  type        = string
  default     = "StorageV2"
  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "The account_kind must be one of: BlobStorage, BlockBlobStorage, FileStorage, Storage, StorageV2."
  }
}

variable "access_tier" {
  description = "Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool"
  type        = string
  default     = "Hot"
  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "The access_tier must be either Hot or Cool."
  }
}

variable "https_traffic_only_enabled" {
  description = "Boolean flag which forces HTTPS if enabled"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account. Possible values are TLS1_0, TLS1_1, and TLS1_2"
  type        = string
  default     = "TLS1_2"
  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "The min_tls_version must be one of: TLS1_0, TLS1_1, TLS1_2."
  }
}

variable "allow_nested_items_to_be_public" {
  description = "Allow or disallow nested items within this Account to opt into being public"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether the public network access is enabled"
  type        = bool
  default     = false
}

variable "default_to_oauth_authentication" {
  description = "Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account"
  type        = bool
  default     = true
}

# Data Lake Gen2 Configuration
variable "is_hns_enabled" {
  description = "Is Hierarchical Namespace enabled? This can be used with Azure Data Lake Storage Gen 2"
  type        = bool
  default     = false
}

# Service Configuration
variable "enabled_services" {
  description = "List of storage services to enable. Valid options are blob, file, queue, table"
  type        = list(string)
  default     = ["blob"]
  validation {
    condition = alltrue([
      for service in var.enabled_services : contains(["blob", "file", "queue", "table"], service)
    ])
    error_message = "All enabled_services must be one of: blob, file, queue, table."
  }
}

# Network Rules
variable "network_rules" {
  description = "Network rules restricting access to the storage account"
  type = object({
    default_action             = string
    bypass                     = optional(set(string))
    ip_rules                   = optional(set(string))
    virtual_network_subnet_ids = optional(set(string))
  })
  default = null
}

# Blob Properties
variable "blob_properties" {
  description = "Blob service properties for the storage account"
  type = object({
    versioning_enabled            = optional(bool)
    change_feed_enabled           = optional(bool)
    change_feed_retention_in_days = optional(number)
    default_service_version       = optional(string)
    last_access_time_enabled      = optional(bool)
    cors_rules = optional(list(object({
      allowed_origins    = list(string)
      allowed_methods    = list(string)
      allowed_headers    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    delete_retention_policy = optional(object({
      days = optional(number)
    }))
    container_delete_retention_policy = optional(object({
      days = optional(number)
    }))
  })
  default = null
}

# Queue Properties
variable "queue_properties" {
  description = "Queue service properties for the storage account"
  type = object({
    cors_rules = optional(list(object({
      allowed_origins    = list(string)
      allowed_methods    = list(string)
      allowed_headers    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    logging = optional(object({
      delete                = bool
      read                  = bool
      write                 = bool
      version               = string
      retention_policy_days = optional(number)
    }))
    minute_metrics = optional(object({
      enabled               = bool
      version               = string
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
    }))
    hour_metrics = optional(object({
      enabled               = bool
      version               = string
      include_apis          = optional(bool)
      retention_policy_days = optional(number)
    }))
  })
  default = null
}

# Share Properties (File Service)
variable "share_properties" {
  description = "File share service properties for the storage account"
  type = object({
    cors_rules = optional(list(object({
      allowed_origins    = list(string)
      allowed_methods    = list(string)
      allowed_headers    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    retention_policy = optional(object({
      days = optional(number)
    }))
    smb = optional(object({
      versions                        = optional(set(string))
      authentication_types            = optional(set(string))
      kerberos_ticket_encryption_type = optional(set(string))
      channel_encryption_type         = optional(set(string))
    }))
  })
  default = null
}

# Private Endpoint Configuration
variable "create_private_endpoints" {
  description = "Whether to create private endpoints for the storage account services"
  type        = bool
  default     = false
}

variable "private_endpoint_services" {
  description = "List of storage services to create private endpoints for. Valid options are blob, file, queue, table, dfs (Data Lake)"
  type        = list(string)
  default     = ["blob"]
  validation {
    condition = alltrue([
      for service in var.private_endpoint_services : contains(["blob", "file", "queue", "table", "dfs"], service)
    ])
    error_message = "All private_endpoint_services must be one of: blob, file, queue, table, dfs."
  }
}

variable "private_endpoint_subnet_id" {
  description = "The ID of the subnet from which the private IP will be allocated for private endpoints"
  type        = string
  default     = null
}

variable "private_endpoint_manual_connection" {
  description = "Does the private endpoint require manual approval from the remote resource owner?"
  type        = bool
  default     = false
}

# Private DNS Zone Groups for each service
variable "private_endpoint_dns_zone_group_blob" {
  description = "Private DNS zone group configuration for blob service private endpoint"
  type = object({
    name                 = string
    private_dns_zone_ids = list(string)
  })
  default = null
}

variable "private_endpoint_dns_zone_group_file" {
  description = "Private DNS zone group configuration for file service private endpoint"
  type = object({
    name                 = string
    private_dns_zone_ids = list(string)
  })
  default = null
}

variable "private_endpoint_dns_zone_group_queue" {
  description = "Private DNS zone group configuration for queue service private endpoint"
  type = object({
    name                 = string
    private_dns_zone_ids = list(string)
  })
  default = null
}

variable "private_endpoint_dns_zone_group_table" {
  description = "Private DNS zone group configuration for table service private endpoint"
  type = object({
    name                 = string
    private_dns_zone_ids = list(string)
  })
  default = null
}

variable "private_endpoint_dns_zone_group_dfs" {
  description = "Private DNS zone group configuration for dfs (Data Lake) service private endpoint"
  type = object({
    name                 = string
    private_dns_zone_ids = list(string)
  })
  default = null
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