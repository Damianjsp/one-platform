# Terraform State Organization

This document describes the hierarchical state organization implemented in One Platform to manage multiple stacks and environments efficiently.

## 🏗️ State Structure

### Hierarchical Organization

The Terraform state files are organized hierarchically in Azure Storage to provide better isolation and management:

```
Azure Storage Container: corestate
├── core-eus-dev/                          # Development Stack
│   ├── azure-resource-group.tfstate       # Resource Group state
│   ├── azure-vnet.tfstate                 # Virtual Network state
│   ├── azure-subnet.tfstate               # Subnet state
│   ├── azure-nsg.tfstate                  # Network Security Group state
│   ├── azure-storage-account-general.tfstate
│   ├── azure-storage-account-private.tfstate
│   ├── azure-storage-account-datalake.tfstate
│   ├── azure-keyvault-dev.tfstate
│   ├── azure-keyvault-secure.tfstate
│   ├── azure-private-endpoint-storage-blob.tfstate
│   ├── azure-private-endpoint-datalake-blob.tfstate
│   ├── azure-private-endpoint-datalake-dfs.tfstate
│   └── azure-private-endpoint-keyvault.tfstate
│
├── prod-eus-prod/                         # Future Production Stack
│   ├── azure-resource-group.tfstate
│   ├── azure-vnet.tfstate
│   └── ...
│
└── staging-eus-staging/                   # Future Staging Stack
    ├── azure-resource-group.tfstate
    ├── azure-vnet.tfstate
    └── ...
```

### Benefits

1. **Stack Isolation**: Each environment/stack has its own folder
2. **Component Clarity**: Easy to identify which state belongs to which component
3. **Scalability**: Simple to add new stacks without naming conflicts
4. **Management**: Easier backup, migration, and cleanup operations
5. **Security**: Better access control per environment

## ⚙️ Configuration

### Backend Template

The hierarchical structure is configured in `atmos/stacks/orgs/lazylabs/_defaults.yaml`:

```yaml
terraform:
  backend_type: azurerm
  backend:
    azurerm:
      resource_group_name: "atmos-rsg-core"
      storage_account_name: "statomicore"
      container_name: "corestate"
      # Hierarchical state organization: {stack}/{component}.tfstate
      key: "{{ .atmos_stack }}/{{ .atmos_component }}.tfstate"
```

### Atmos Configuration

Additional settings in `atmos/atmos.yaml` support the hierarchical backend:

```yaml
components:
  terraform:
    auto_generate_backend_file: true
    backend_config_template_file: "{component}/backend.tf.json"
    backend_config_template_type: "json"
```

## 🔄 Migration from Flat Structure

### Before Migration (Flat Structure)
```
corestate/
├── azure-rsg.terraform.tfstate
├── azure-vnet.terraform.tfstate
├── azure-keyvault.terraform.tfstateenv:core-eus-dev-azure-keyvault-dev
├── azure-keyvault.terraform.tfstateenv:core-eus-dev-azure-keyvault-secure
└── ...
```

### After Migration (Hierarchical Structure)
```
corestate/
├── core-eus-dev/
│   ├── azure-resource-group.tfstate
│   ├── azure-vnet.tfstate
│   ├── azure-keyvault-dev.tfstate
│   ├── azure-keyvault-secure.tfstate
│   └── ...
└── [other-stacks]/
    └── ...
```

### Migration Process

1. **Run Migration Script**:
   ```bash
   ./scripts/migrate-state-organization.sh
   ```

2. **Verify New Structure**:
   ```bash
   # Test each component can plan successfully
   atmos terraform plan azure-resource-group -s core-eus-dev
   atmos terraform plan azure-keyvault-dev -s core-eus-dev
   # ... test all components
   ```

3. **Clean Up Old States** (after verification):
   ```bash
   # Only after thorough testing
   az storage blob delete --account-name statomicore \
     --container-name corestate \
     --name "azure-rsg.terraform.tfstate"
   ```

## 🆕 New Stack Creation

### Adding New Environments

When creating new stacks (e.g., production, staging), the state files will automatically be organized under the new stack name:

```yaml
# Example: staging-eus-staging stack
corestate/
├── core-eus-dev/           # Existing development
├── staging-eus-staging/    # New staging environment
│   ├── azure-resource-group.tfstate
│   ├── azure-vnet.tfstate
│   └── ...
└── prod-eus-prod/         # Future production environment
```

### Stack Naming Convention

Stack names follow the pattern defined in `atmos.yaml`:
```yaml
stacks:
  name_pattern: "{tenant}-{environment}-{stage}-{region}"
```

Examples:
- `core-eus-dev` (core tenant, East US, development)
- `core-eus-prod` (core tenant, East US, production)
- `core-wus-dev` (core tenant, West US, development)

## 🔍 State Management Commands

### List State Files
```bash
# List all state files in a stack
az storage blob list \
  --account-name statomicore \
  --container-name corestate \
  --prefix "core-eus-dev/" \
  --output table
```

### Backup State Files
```bash
# Backup entire stack
az storage blob download-batch \
  --account-name statomicore \
  --source corestate \
  --destination ./backups \
  --pattern "core-eus-dev/*"
```

### State File Operations
```bash
# Plan with specific component
atmos terraform plan azure-keyvault-dev -s core-eus-dev

# Apply with specific component
atmos terraform apply azure-keyvault-dev -s core-eus-dev

# Import existing resources
atmos terraform import azure-keyvault-dev -s core-eus-dev -- \
  'azurerm_key_vault.this[0]' '/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/...'
```

## 🛡️ Best Practices

### State Management

1. **Regular Backups**: Backup state files before major changes
2. **State Locking**: Always enabled via Azure Storage
3. **Environment Isolation**: Never share state files between environments
4. **Access Control**: Use Azure RBAC to control state file access

### Component Development

1. **State Dependencies**: Ensure components reference correct state outputs
2. **Testing**: Always test state changes in development first
3. **Documentation**: Document any state structure changes
4. **Rollback Plan**: Have rollback procedures for state migrations

### Troubleshooting

#### State Lock Issues
```bash
# Force unlock if needed (use carefully)
atmos terraform force-unlock azure-keyvault-dev -s core-eus-dev <lock-id>
```

#### State Corruption
```bash
# Restore from backup
az storage blob upload \
  --account-name statomicore \
  --container-name corestate \
  --name "core-eus-dev/azure-keyvault-dev.tfstate" \
  --file "./backup/azure-keyvault-dev.tfstate"
```

#### Missing State File
```bash
# Check if state exists in storage
az storage blob exists \
  --account-name statomicore \
  --container-name corestate \
  --name "core-eus-dev/azure-keyvault-dev.tfstate"
```

## 📋 Checklist for New Stacks

When creating a new stack:

- [ ] Define stack in `atmos/stacks/azure/{env}/{env}.yaml`
- [ ] Configure component imports and variables
- [ ] Test with `atmos terraform plan` for each component
- [ ] Verify state files are created in correct hierarchy
- [ ] Document any stack-specific configurations
- [ ] Set up backup procedures for the new stack
- [ ] Configure appropriate Azure RBAC permissions

## 🔗 Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Development guidance
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Overall architecture
- [README.md](../README.md) - Project overview
- [Atmos Documentation](https://atmos.tools/) - Atmos framework