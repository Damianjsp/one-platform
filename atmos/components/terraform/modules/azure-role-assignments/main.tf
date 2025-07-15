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

locals {
  # Validate that all role assignments have approved role names
  validated_role_assignments = {
    for key, assignment in var.role_assignments : key => assignment
    if contains(var.approved_roles, assignment.role_definition_name)
  }

  # Create assignment matrix when matrix configuration is provided
  matrix_assignments = var.assignment_matrix != null ? {
    for assignment_key, assignment in var.assignment_matrix.assignments : assignment_key => {
      for role in assignment.roles : "${assignment_key}-${replace(role, " ", "-")}" => {
        principal_id         = var.assignment_matrix.principals[assignment.principal_key]
        principal_type       = "user_assigned" # Default for matrix approach
        role_definition_name = role
        scope                = var.assignment_matrix.scopes[assignment.scope_key]
        description          = "Matrix assignment: ${assignment.principal_key} -> ${assignment.scope_key} (${role})"
      }
    }
  } : {}

  # Flatten matrix assignments
  flattened_matrix_assignments = var.assignment_matrix != null ? merge([
    for assignment_key, roles_map in local.matrix_assignments : roles_map
  ]...) : {}

  # Combine direct assignments and matrix assignments
  all_assignments = merge(
    local.validated_role_assignments,
    local.flattened_matrix_assignments
  )

  # Create unique assignment keys to avoid conflicts
  final_assignments = var.enabled ? local.all_assignments : {}
}

# Bulk Role Assignments using for_each
resource "azurerm_role_assignment" "this" {
  for_each = local.final_assignments

  principal_id                     = each.value.principal_id
  role_definition_name             = each.value.role_definition_name
  scope                            = each.value.scope
  description                      = each.value.description
  skip_service_principal_aad_check = var.skip_service_principal_aad_check

  # Prevent assignment conflicts with lifecycle management
  lifecycle {
    create_before_destroy = true
  }
}