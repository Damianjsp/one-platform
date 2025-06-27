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

## Use Cases
Describe the primary use cases for this component:

1. **Development Environment**:
   - [Describe dev environment requirements]

2. **Production Environment**:
   - [Describe prod environment requirements]

3. **Security Requirements**:
   - [Describe security considerations]

## Configuration Example
Provide an example of how this component would be configured:

```yaml
components:
  terraform:
    azure-[service-name]:
      vars:
        name: "[service-name]"
        # Additional configuration options
        
    # Example with private endpoint
    azure-private-endpoint-[service]:
      metadata:
        component: azure-private-endpoint
      vars:
        name: "[service]"
        private_connection_resource_id: "${components.terraform.azure-[service-name].outputs.[resource-id]}"
        subresource_names: ["[subresource]"]
```

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

## Additional Context
Add any other context, requirements, or considerations for this component:

- Security requirements
- Compliance considerations  
- Integration patterns
- Performance requirements
- Cost considerations

## References
- [Azure Service Documentation]
- [Terraform Provider Documentation]
- [Similar implementations or examples]