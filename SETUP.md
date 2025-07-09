# One Platform Setup Guide

This guide provides step-by-step instructions for setting up the One Platform infrastructure.

## Prerequisites

- Azure CLI installed and logged in
- Terraform >= 1.9.0
- Atmos CLI installed
- Azure subscription with appropriate permissions

## 1. Azure Service Principal Setup

Create a service principal for Terraform authentication:

```bash
# Create service principal
az ad sp create-for-rbac --name "atmos-terraform" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
```

This will output:
```json
{
  "appId": "YOUR_CLIENT_ID",
  "displayName": "atmos-terraform",
  "password": "YOUR_CLIENT_SECRET",
  "tenant": "YOUR_TENANT_ID"
}
```

## 2. Get Service Principal Object ID

Get the Object ID of your service principal:

```bash
az ad sp show --id YOUR_CLIENT_ID --query objectId --output tsv
```

## 3. Create Backend Storage Account

Create the storage account for Terraform state:

```bash
# Create resource group
az group create --name atmos-rsg-core --location eastus

# Create storage account
az storage account create \
  --name statomicore \
  --resource-group atmos-rsg-core \
  --location eastus \
  --sku Standard_LRS

# Create container
az storage container create \
  --name corestate \
  --account-name statomicore
```

## 4. Configure Organization Defaults

Edit `atmos/stacks/orgs/lazylabs/_defaults.yaml` and uncomment/update:

```yaml
vars:
  # Azure Configuration - REPLACE WITH YOUR VALUES
  subscription_id: "YOUR_AZURE_SUBSCRIPTION_ID"
  service_principal_object_id: "YOUR_SERVICE_PRINCIPAL_OBJECT_ID"
```

## 5. Update Stack Configuration

Edit `atmos/stacks/azure/dev/dev.yaml` and replace placeholders:

```yaml
# Replace in Key Vault access policies
object_id: "YOUR_SERVICE_PRINCIPAL_OBJECT_ID"
```

## 6. Set Environment Variables

For GitHub Actions, set the following secrets:

```json
{
  "clientId": "YOUR_CLIENT_ID",
  "clientSecret": "YOUR_CLIENT_SECRET",
  "subscriptionId": "YOUR_SUBSCRIPTION_ID",
  "tenantId": "YOUR_TENANT_ID"
}
```

For local development:
```bash
export ARM_CLIENT_ID="YOUR_CLIENT_ID"
export ARM_CLIENT_SECRET="YOUR_CLIENT_SECRET"
export ARM_SUBSCRIPTION_ID="YOUR_SUBSCRIPTION_ID"
export ARM_TENANT_ID="YOUR_TENANT_ID"
```

## 7. Backend Configuration (Optional)

If using different backend storage, update:

```bash
export ATMOS_BACKEND_RESOURCE_GROUP="your-backend-rg"
export ATMOS_BACKEND_STORAGE_ACCOUNT="your-backend-storage"
export ATMOS_BACKEND_CONTAINER="your-backend-container"
```

## 8. Validate Setup

```bash
cd atmos
atmos validate stacks
atmos terraform plan azure-resource-group -s core-eus-dev
```

## Security Best Practices

1. **Never commit sensitive values** - Use environment variables or Azure Key Vault
2. **Use separate service principals** for different environments
3. **Enable MFA** on accounts with elevated permissions
4. **Rotate secrets regularly** 
5. **Use Azure RBAC** for fine-grained access control

## Environment-Specific Configuration

Create separate organization defaults files for each environment:

```
atmos/stacks/orgs/lazylabs/
├── _defaults.yaml          # Common defaults
├── dev/_defaults.yaml      # Development overrides
├── staging/_defaults.yaml  # Staging overrides
└── prod/_defaults.yaml     # Production overrides
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Verify ARM_* environment variables are set
2. **Backend Access**: Ensure storage account permissions are correct
3. **Service Principal**: Verify Object ID is correct (not Client ID)

### Validation Commands

```bash
# Test authentication
az account show

# Test backend access
az storage blob list --container-name corestate --account-name statomicore

# Test service principal
az ad sp show --id YOUR_CLIENT_ID
```

## Next Steps

1. Deploy core infrastructure: `atmos terraform apply azure-resource-group -s core-eus-dev`
2. Deploy networking: `atmos terraform apply azure-vnet -s core-eus-dev`
3. Deploy storage and security components
4. Set up monitoring and alerting