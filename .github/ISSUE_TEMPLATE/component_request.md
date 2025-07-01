---
name: New Component Request
about: Request a new Azure service component
title: '[COMPONENT] Add Azure [Service Name] component'
labels: 'enhancement, new-component'
assignees: ''

---

## Azure Service Information
- **Service Name**: [e.g., Key Vault, Storage Account, SQL Database]
- **Azure Provider Resource**: [e.g., azurerm_key_vault, azurerm_storage_account]
- **Service Documentation**: [Link to Azure docs]
- **Terraform Provider Docs**: [Link to Terraform provider docs]

## Component Requirements
- [ ] **Resource Creation**: Basic resource creation functionality
- [ ] **Configuration Options**: Support for common configuration scenarios
- [ ] **Dependencies**: Integration with existing components (RG, VNet, Subnet)
- [ ] **Private Endpoints**: Support for private endpoint connectivity
- [ ] **Naming Convention**: Follow established naming patterns
- [ ] **Tagging**: Consistent resource tagging

## Dependencies
This component will depend on:
- [ ] azure-resource-group
- [ ] azure-vnet (if network integration needed)
- [ ] azure-subnet (if private endpoints needed)
- [ ] Other: [specify]

## Private Endpoint Support
- [ ] **Required**: This service needs private endpoint support
- [ ] **Optional**: Private endpoints would be beneficial
- [ ] **Not Applicable**: Service doesn't support private endpoints

If private endpoints are supported:
- **Subresource Names**: [e.g., vault, blob, file, sqlServer]
- **Private DNS Zone**: [e.g., privatelink.vaultcore.azure.net]

## Implementation Checklist
- [ ] Terraform module created
- [ ] Variables defined with descriptions
- [ ] Outputs provided for dependent components
- [ ] Catalog defaults created
- [ ] Environment mixins created (dev/prod)
- [ ] Stack integration example provided
- [ ] Component README with usage examples
- [ ] Validation tests passing
- [ ] Private endpoint compatibility verified

## References
- [Azure Service Documentation]
- [Terraform Provider Documentation]
- [Similar implementations or examples]