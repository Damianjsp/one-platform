output "role_assignment_ids" {
  description = "Map of role assignment IDs keyed by assignment name"
  value = {
    for key, assignment in azurerm_role_assignment.this : key => assignment.id
  }
}

output "role_assignment_details" {
  description = "Complete details of all role assignments created"
  value = {
    for key, assignment in azurerm_role_assignment.this : key => {
      id                   = assignment.id
      principal_id         = assignment.principal_id
      role_definition_name = assignment.role_definition_name
      scope                = assignment.scope
      description          = assignment.description
    }
  }
}

output "assignment_count" {
  description = "Total number of role assignments created"
  value       = length(azurerm_role_assignment.this)
}

output "assignments_by_principal" {
  description = "Role assignments grouped by principal ID"
  value = {
    for principal_id in distinct([for assignment in azurerm_role_assignment.this : assignment.principal_id]) :
    principal_id => [
      for key, assignment in azurerm_role_assignment.this :
      {
        assignment_key       = key
        role_definition_name = assignment.role_definition_name
        scope                = assignment.scope
        description          = assignment.description
      }
      if assignment.principal_id == principal_id
    ]
  }
}

output "assignments_by_role" {
  description = "Role assignments grouped by role definition name"
  value = {
    for role_name in distinct([for assignment in azurerm_role_assignment.this : assignment.role_definition_name]) :
    role_name => [
      for key, assignment in azurerm_role_assignment.this :
      {
        assignment_key = key
        principal_id   = assignment.principal_id
        scope          = assignment.scope
        description    = assignment.description
      }
      if assignment.role_definition_name == role_name
    ]
  }
}

output "assignments_by_scope" {
  description = "Role assignments grouped by scope (target resource)"
  value = {
    for scope in distinct([for assignment in azurerm_role_assignment.this : assignment.scope]) :
    scope => [
      for key, assignment in azurerm_role_assignment.this :
      {
        assignment_key       = key
        principal_id         = assignment.principal_id
        role_definition_name = assignment.role_definition_name
        description          = assignment.description
      }
      if assignment.scope == scope
    ]
  }
}

output "validated_role_count" {
  description = "Number of roles that passed validation"
  value       = length(local.validated_role_assignments)
}

output "matrix_assignment_count" {
  description = "Number of assignments created from matrix configuration"
  value       = length(local.flattened_matrix_assignments)
}

output "tags" {
  description = "The tags applied to the role assignments"
  value       = module.label.tags
}

output "context" {
  description = "Exported context for use by other modules"
  value       = module.label.context
}