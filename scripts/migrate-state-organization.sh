#!/bin/bash

# State Migration Script for Hierarchical Organization
# This script migrates from flat state structure to hierarchical structure

set -e

RESOURCE_GROUP="atmos-rsg-core"
STORAGE_ACCOUNT="statomicore"
CONTAINER="corestate"
STACK_NAME="core-eus-dev"

echo "🔄 Migrating Terraform state to hierarchical organization..."
echo "Stack: $STACK_NAME"
echo "Container: $CONTAINER"
echo ""

# Check if Azure CLI is logged in
if ! az account show &> /dev/null; then
    echo "❌ Azure CLI not logged in. Please run 'az login' first."
    exit 1
fi

# Function to migrate a component's state
migrate_component_state() {
    local component=$1
    local old_key=$2
    local new_key=$3
    
    echo "📦 Migrating $component..."
    echo "  From: $old_key"
    echo "  To:   $new_key"
    
    # Check if old state exists
    if az storage blob exists \
        --account-name "$STORAGE_ACCOUNT" \
        --container-name "$CONTAINER" \
        --name "$old_key" \
        --output tsv | grep -q "True"; then
        
        echo "  ✅ Old state file found"
        
        # Check if new state already exists
        if az storage blob exists \
            --account-name "$STORAGE_ACCOUNT" \
            --container-name "$CONTAINER" \
            --name "$new_key" \
            --output tsv | grep -q "True"; then
            echo "  ⚠️  New state file already exists, skipping..."
            return
        fi
        
        # Copy old state to new location
        az storage blob copy start \
            --account-name "$STORAGE_ACCOUNT" \
            --destination-container "$CONTAINER" \
            --destination-blob "$new_key" \
            --source-container "$CONTAINER" \
            --source-blob "$old_key" > /dev/null
            
        echo "  ✅ State copied to new location"
        echo "  ⚠️  Old state file preserved for safety"
    else
        echo "  ℹ️  No existing state found (new component)"
    fi
    echo ""
}

# Migration mappings: component_name:old_key:new_key
declare -a migrations=(
    "azure-resource-group:azure-rsg.terraform.tfstate:$STACK_NAME/azure-resource-group.tfstate"
    "azure-vnet:azure-vnet.terraform.tfstate:$STACK_NAME/azure-vnet.tfstate"
    "azure-subnet:azure-subnet.terraform.tfstate:$STACK_NAME/azure-subnet.tfstate"
    "azure-nsg:azure-nsg.terraform.tfstate:$STACK_NAME/azure-nsg.tfstate"
    "azure-storage-account-general:azure-storage-account.terraform.tfstateenv\\:core-eus-dev-azure-storage-account-general:$STACK_NAME/azure-storage-account-general.tfstate"
    "azure-storage-account-private:azure-storage-account.terraform.tfstateenv\\:core-eus-dev-azure-storage-account-private:$STACK_NAME/azure-storage-account-private.tfstate"
    "azure-storage-account-datalake:azure-storage-account.terraform.tfstateenv\\:core-eus-dev-azure-storage-account-datalake:$STACK_NAME/azure-storage-account-datalake.tfstate"
    "azure-keyvault-dev:azure-keyvault.terraform.tfstateenv\\:core-eus-dev-azure-keyvault-dev:$STACK_NAME/azure-keyvault-dev.tfstate"
    "azure-keyvault-secure:azure-keyvault.terraform.tfstateenv\\:core-eus-dev-azure-keyvault-secure:$STACK_NAME/azure-keyvault-secure.tfstate"
    "azure-private-endpoint-storage-blob:azure-private-endpoint.terraform.tfstateenv\\:core-eus-dev-azure-private-endpoint-storage-blob:$STACK_NAME/azure-private-endpoint-storage-blob.tfstate"
    "azure-private-endpoint-datalake-blob:azure-private-endpoint.terraform.tfstateenv\\:core-eus-dev-azure-private-endpoint-datalake-blob:$STACK_NAME/azure-private-endpoint-datalake-blob.tfstate"
    "azure-private-endpoint-datalake-dfs:azure-private-endpoint.terraform.tfstateenv\\:core-eus-dev-azure-private-endpoint-datalake-dfs:$STACK_NAME/azure-private-endpoint-datalake-dfs.tfstate"
    "azure-private-endpoint-keyvault:azure-private-endpoint.terraform.tfstateenv\\:core-eus-dev-azure-private-endpoint-keyvault:$STACK_NAME/azure-private-endpoint-keyvault.tfstate"
)

# Perform migrations
for migration in "${migrations[@]}"; do
    IFS=':' read -r component old_key new_key <<< "$migration"
    migrate_component_state "$component" "$old_key" "$new_key"
done

echo "🎉 Migration completed!"
echo ""
echo "Next steps:"
echo "1. Test that all components can plan successfully with new state structure"
echo "2. Once verified, you can safely delete old state files"
echo "3. All new components will automatically use the hierarchical structure"
echo ""
echo "⚠️ Important: Old state files are preserved for safety"
echo "   Delete them manually only after thorough testing"