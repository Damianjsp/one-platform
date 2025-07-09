data "azurerm_client_config" "current" {}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace   = var.namespace
  tenant      = var.tenant
  environment = var.environment
  stage       = var.stage
  name        = var.name
  attributes  = var.attributes
  delimiter   = var.delimiter
  tags        = var.tags

  regex_replace_chars = var.regex_replace_chars
  label_order         = var.label_order
  label_key_case      = var.label_key_case
  label_value_case    = var.label_value_case
  id_length_limit     = var.id_length_limit
}

resource "azurerm_linux_function_app" "this" {
  count = var.enabled && var.os_type == "Linux" ? 1 : 0

  name                = coalesce(var.function_app_name, module.label.id)
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.service_plan_id

  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  # App settings
  app_settings = merge(var.app_settings, {
    "FUNCTIONS_WORKER_RUNTIME" = var.functions_worker_runtime
    "WEBSITE_RUN_FROM_PACKAGE" = var.website_run_from_package
  })

  # Site configuration
  site_config {
    always_on                              = var.always_on
    application_insights_connection_string = var.application_insights_connection_string
    application_insights_key               = var.application_insights_key
    ftps_state                            = var.ftps_state
    http2_enabled                         = var.http2_enabled
    minimum_tls_version                   = var.minimum_tls_version
    use_32_bit_worker                     = var.use_32_bit_worker
    websockets_enabled                    = var.websockets_enabled
    
    # Application stack
    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version              = application_stack.value.dotnet_version
        java_version                = application_stack.value.java_version
        node_version                = application_stack.value.node_version
        python_version              = application_stack.value.python_version
        powershell_core_version     = application_stack.value.powershell_core_version
        use_custom_runtime          = application_stack.value.use_custom_runtime
        use_dotnet_isolated_runtime = application_stack.value.use_dotnet_isolated_runtime
      }
    }

    # CORS settings
    dynamic "cors" {
      for_each = var.cors != null ? [var.cors] : []
      content {
        allowed_origins                     = cors.value.allowed_origins
        support_credentials                 = cors.value.support_credentials
      }
    }
  }

  # Authentication settings
  dynamic "auth_settings" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []
    content {
      enabled                        = auth_settings.value.enabled
      default_provider              = auth_settings.value.default_provider
      allowed_external_redirect_urls = auth_settings.value.allowed_external_redirect_urls
      runtime_version               = auth_settings.value.runtime_version
      token_refresh_extension_hours = auth_settings.value.token_refresh_extension_hours
      token_store_enabled           = auth_settings.value.token_store_enabled
      unauthenticated_client_action = auth_settings.value.unauthenticated_client_action
    }
  }

  # Connection strings
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Identity configuration
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled
  client_certificate_enabled    = var.client_certificate_enabled
  client_certificate_mode       = var.client_certificate_mode
  enabled                       = var.function_app_enabled
  content_share_force_disabled  = var.content_share_force_disabled
  functions_extension_version   = var.functions_extension_version
  zip_deploy_file              = var.zip_deploy_file

  tags = module.label.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
      zip_deploy_file,
    ]
  }
}

resource "azurerm_windows_function_app" "this" {
  count = var.enabled && var.os_type == "Windows" ? 1 : 0

  name                = coalesce(var.function_app_name, module.label.id)
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.service_plan_id

  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key

  # App settings
  app_settings = merge(var.app_settings, {
    "FUNCTIONS_WORKER_RUNTIME" = var.functions_worker_runtime
    "WEBSITE_RUN_FROM_PACKAGE" = var.website_run_from_package
  })

  # Site configuration
  site_config {
    always_on                              = var.always_on
    application_insights_connection_string = var.application_insights_connection_string
    application_insights_key               = var.application_insights_key
    ftps_state                            = var.ftps_state
    http2_enabled                         = var.http2_enabled
    minimum_tls_version                   = var.minimum_tls_version
    use_32_bit_worker                     = var.use_32_bit_worker
    websockets_enabled                    = var.websockets_enabled
    
    # Application stack
    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        dotnet_version              = application_stack.value.dotnet_version
        java_version                = application_stack.value.java_version
        node_version                = application_stack.value.node_version
        powershell_core_version     = application_stack.value.powershell_core_version
        use_custom_runtime          = application_stack.value.use_custom_runtime
        use_dotnet_isolated_runtime = application_stack.value.use_dotnet_isolated_runtime
      }
    }

    # CORS settings
    dynamic "cors" {
      for_each = var.cors != null ? [var.cors] : []
      content {
        allowed_origins                     = cors.value.allowed_origins
        support_credentials                 = cors.value.support_credentials
      }
    }
  }

  # Authentication settings
  dynamic "auth_settings" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []
    content {
      enabled                        = auth_settings.value.enabled
      default_provider              = auth_settings.value.default_provider
      allowed_external_redirect_urls = auth_settings.value.allowed_external_redirect_urls
      runtime_version               = auth_settings.value.runtime_version
      token_refresh_extension_hours = auth_settings.value.token_refresh_extension_hours
      token_store_enabled           = auth_settings.value.token_store_enabled
      unauthenticated_client_action = auth_settings.value.unauthenticated_client_action
    }
  }

  # Connection strings
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Identity configuration
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled
  client_certificate_enabled    = var.client_certificate_enabled
  client_certificate_mode       = var.client_certificate_mode
  enabled                       = var.function_app_enabled
  content_share_force_disabled  = var.content_share_force_disabled
  functions_extension_version   = var.functions_extension_version
  zip_deploy_file              = var.zip_deploy_file

  tags = module.label.tags

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
      zip_deploy_file,
    ]
  }
}