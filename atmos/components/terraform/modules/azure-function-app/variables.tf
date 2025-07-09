variable "enabled" {
  description = "Set to false to prevent the module from creating any resources"
  type        = bool
  default     = true
}

variable "location" {
  description = "The Azure Region where the Function App should be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Function App"
  type        = string
}

variable "function_app_name" {
  description = "Custom name for the Function App. If not specified, the module will use the ID from the label module"
  type        = string
  default     = null
}

variable "service_plan_id" {
  description = "The ID of the App Service Plan within which to create this Function App"
  type        = string
}

variable "storage_account_name" {
  description = "The backend storage account name which will be used by this Function App"
  type        = string
}

variable "storage_account_access_key" {
  description = "The access key which will be used to access the backend storage account for the Function App"
  type        = string
  sensitive   = true
}

variable "os_type" {
  description = "The O/S type for the Function App. Possible values are Linux and Windows"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "The os_type must be either Linux or Windows."
  }
}

variable "functions_worker_runtime" {
  description = "The runtime stack of the Function App. Possible values are dotnet, dotnet-isolated, java, node, python, powershell, custom"
  type        = string
  default     = "node"
}

variable "website_run_from_package" {
  description = "Should the Function App run from a deployment package"
  type        = string
  default     = "1"
}

variable "function_app_enabled" {
  description = "Should the Function App be enabled"
  type        = bool
  default     = true
}

variable "always_on" {
  description = "Should the Function App be loaded at all times"
  type        = bool
  default     = false
}

variable "application_insights_connection_string" {
  description = "The Connection String for linking the Function App to Application Insights"
  type        = string
  default     = null
  sensitive   = true
}

variable "application_insights_key" {
  description = "The Instrumentation Key for connecting the Function App to Application Insights"
  type        = string
  default     = null
  sensitive   = true
}

variable "ftps_state" {
  description = "State of FTP / FTPS service for this Function App. Possible values are: AllAllowed, FtpsOnly and Disabled"
  type        = string
  default     = "Disabled"
}

variable "http2_enabled" {
  description = "Should HTTP2 be enabled on the Function App"
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "The minimum supported TLS version for the Function App"
  type        = string
  default     = "1.2"
}

variable "use_32_bit_worker" {
  description = "Should the Function App use 32-bit workers"
  type        = bool
  default     = false
}

variable "websockets_enabled" {
  description = "Should WebSockets be enabled on the Function App"
  type        = bool
  default     = false
}

variable "https_only" {
  description = "Should the Function App only be accessible via HTTPS"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Should the Function App be accessible from the public network"
  type        = bool
  default     = true
}

variable "client_certificate_enabled" {
  description = "Should the Function App use Client Certificates"
  type        = bool
  default     = false
}

variable "client_certificate_mode" {
  description = "The mode of the Function App's client certificates requirement. Possible values are Required and Optional"
  type        = string
  default     = "Optional"
}

variable "content_share_force_disabled" {
  description = "Should the settings for linking the Function App to storage be suppressed"
  type        = bool
  default     = false
}

variable "functions_extension_version" {
  description = "The runtime version associated with the Function App"
  type        = string
  default     = "~4"
}

variable "zip_deploy_file" {
  description = "The local path and filename of the Zip packaged application to deploy to this Function App"
  type        = string
  default     = null
}

variable "app_settings" {
  description = "A map of key-value pairs for App Settings and custom values"
  type        = map(string)
  default     = {}
}

variable "application_stack" {
  description = "Configuration block for the Function App application stack"
  type = object({
    dotnet_version              = optional(string)
    java_version                = optional(string)
    node_version                = optional(string)
    python_version              = optional(string)
    powershell_core_version     = optional(string)
    use_custom_runtime          = optional(bool)
    use_dotnet_isolated_runtime = optional(bool)
  })
  default = null
}

variable "cors" {
  description = "Configuration block for CORS settings"
  type = object({
    allowed_origins     = list(string)
    support_credentials = optional(bool)
  })
  default = null
}

variable "auth_settings" {
  description = "Configuration block for authentication settings"
  type = object({
    enabled                        = bool
    default_provider              = optional(string)
    allowed_external_redirect_urls = optional(list(string))
    runtime_version               = optional(string)
    token_refresh_extension_hours = optional(number)
    token_store_enabled           = optional(bool)
    unauthenticated_client_action = optional(string)
  })
  default = null
}

variable "connection_strings" {
  description = "Map of connection strings"
  type = map(object({
    type  = string
    value = string
  }))
  default = {}
}

variable "identity" {
  description = "Configuration block for managed identity"
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default = null
}

# =============================================================================
# Cloudposse Label Variables
# =============================================================================

variable "namespace" {
  description = "ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique"
  type        = string
  default     = null
}

variable "tenant" {
  description = "ID element (Rarely used, not included by default). A customer identifier, indicating who this instance of a resource is for"
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
  description = "ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`, in the order they appear in the list. New attributes are appended to the end of the list. The elements of the list are joined by the `delimiter` and treated as a single ID element."
  type        = list(string)
  default     = []
}

variable "delimiter" {
  description = "Delimiter to be used between ID elements. Defaults to - (hyphen). Set to empty string to use no delimiter at all."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags (e.g. {'BusinessUnit': 'XYZ'}). Neither the tag keys nor the tag values will be modified by this module."
  type        = map(string)
  default     = {}
}

variable "regex_replace_chars" {
  description = "Terraform regular expression (regex) string. Characters matching the regex will be removed from the ID elements. If not set, /[^a-zA-Z0-9-]/ is used to remove all characters other than hyphens, letters and digits."
  type        = string
  default     = null
}

variable "label_order" {
  description = "The order in which the labels (ID elements) appear in the id. Defaults to [namespace, environment, stage, name, attributes]. You can omit any of the 6 labels (tenant is the 6th), but at least one must be present."
  type        = list(string)
  default     = null
}

variable "label_key_case" {
  description = "Controls the letter case of the tags keys (label names) for tags generated by this module. Does not affect keys of tags passed in via the tags input. Possible values: lower, title, upper. Default value: title."
  type        = string
  default     = null
}

variable "label_value_case" {
  description = "Controls the letter case of ID elements (labels) as included in id, set as tag values, and output by this module individually. Does not affect values of tags passed in via the tags input. Possible values: lower, title, upper and none (no transformation). Set this to title and set delimiter to empty string to yield Pascal Case IDs. Default value: lower."
  type        = string
  default     = null
}

variable "id_length_limit" {
  description = "Limit id to this many characters (minimum 6). Set to 0 for unlimited length. Set to null for keep the existing setting, which defaults to 0. Does not affect id_full."
  type        = number
  default     = null
}