#!/usr/bin/env python3
"""
Test script for the Terraform Plan Dashboard
Creates sample plan outputs and tests the dashboard generation
"""

import os
import sys
from pathlib import Path

# Sample Terraform plan outputs for testing
SAMPLE_PLANS = {
    "azure-resource-group": """
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_resource_group.this[0] will be created
  + resource "azurerm_resource_group" "this" {
      + id       = (known after apply)
      + location = "East US"
      + name     = "lalb-services-eus"
      + tags     = {
          + "Environment" = "dev"
          + "ManagedBy"   = "atmos"
          + "Name"        = "lalb-services-eus"
          + "Namespace"   = "lazylabs"
          + "Stage"       = "dev"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:

  + id = (known after apply)
  + location = "East US"
  + name = "lalb-services-eus"
""",

    "azure-keyvault": """
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  ~ update in-place
  + create

Terraform will perform the following actions:

  # azurerm_key_vault.this[0] will be updated in-place
  ~ resource "azurerm_key_vault" "this" {
        id                              = "/subscriptions/xxx/resourceGroups/lalb-services-eus/providers/Microsoft.KeyVault/vaults/lalbsecretseus"
        name                            = "lalbsecretseus"
      ~ public_network_access_enabled   = true -> false
        # (12 unchanged attributes hidden)

      ~ network_acls {
          ~ default_action = "Allow" -> "Deny"
            # (3 unchanged attributes hidden)
        }
    }

  # azurerm_key_vault_secret.example will be created
  + resource "azurerm_key_vault_secret" "example" {
      + id           = (known after apply)
      + key_vault_id = "/subscriptions/xxx/resourceGroups/lalb-services-eus/providers/Microsoft.KeyVault/vaults/lalbsecretseus"
      + name         = "database-connection"
      + value        = (sensitive value)
      + version      = (known after apply)
      + versionless_id = (known after apply)
    }

Plan: 1 to add, 1 to change, 0 to destroy.
""",

    "azure-storage-account": """
Terraform used the selected providers to generate the following execution plan.
Resource actions are indicated with the following symbols:
  -/+ destroy and then create replacement
  - destroy

Terraform will perform the following actions:

  # azurerm_storage_account.this[0] must be replaced
  -/+ resource "azurerm_storage_account" "this" {
      ~ access_tier                       = "Hot" -> "Cool"
      ~ account_replication_type          = "LRS" -> "GRS"
        id                                = "/subscriptions/xxx/resourceGroups/lalb-services-eus/providers/Microsoft.Storage/storageAccounts/lalbgeneraleusybp2"
        name                              = "lalbgeneraleusybp2"
        # (20 unchanged attributes hidden)

      # Warning: this will destroy the existing storage account
    }

  # azurerm_storage_container.old will be destroyed
  - resource "azurerm_storage_container" "old" {
      - container_access_type   = "private" -> null
      - id                      = "https://lalbgeneraleusybp2.blob.core.windows.net/old-container"
      - name                    = "old-container"
      - storage_account_name    = "lalbgeneraleusybp2"
    }

  # azurerm_private_endpoint.storage_blob will be created
  + resource "azurerm_private_endpoint" "storage_blob" {
      + id                            = (known after apply)
      + location                      = "East US"
      + name                          = "lalb-storage-blob-pe"
      + network_interface             = (known after apply)
      + private_dns_zone_configs      = (known after apply)
      + resource_group_name           = "lalb-services-eus"
      + subnet_id                     = "/subscriptions/xxx/resourceGroups/lalb-services-eus/providers/Microsoft.Network/virtualNetworks/lalbnetworkeus/subnets/lalbeusdevweb"

      + private_service_connection {
          + is_manual_connection           = false
          + name                           = "storage-blob-connection"
          + private_connection_resource_id = (known after apply)
          + subresource_names              = [
              + "blob",
            ]
        }
    }

Plan: 2 to add, 0 to change, 2 to destroy.
"""
}

def create_sample_plans():
    """Create sample plan files for testing"""
    os.makedirs('/tmp/test-plans', exist_ok=True)
    
    for component, plan_content in SAMPLE_PLANS.items():
        plan_file = f'/tmp/test-plans/{component}.plan'
        with open(plan_file, 'w') as f:
            f.write(plan_content)
        print(f"Created sample plan: {plan_file}")

def test_dashboard():
    """Test the dashboard generation"""
    # Import the dashboard generator
    script_dir = Path(__file__).parent
    
    # Load the module directly
    parse_module = {}
    with open(script_dir / 'parse-terraform-plan.py', 'r') as f:
        exec(f.read(), parse_module)
    
    generate_dashboard = parse_module['generate_dashboard']
    
    # Read all sample plan files
    component_plans = {}
    for component, plan_content in SAMPLE_PLANS.items():
        component_plans[component] = plan_content
    
    # Generate dashboard
    print("🎨 Generating dashboard...")
    dashboard = generate_dashboard(component_plans)
    
    # Save to file
    output_file = '/tmp/test-dashboard.md'
    with open(output_file, 'w') as f:
        f.write(dashboard)
    
    print(f"\n✅ Dashboard generated successfully!")
    print(f"📄 Saved to: {output_file}")
    print(f"🔍 Preview:")
    print("=" * 80)
    print(dashboard)
    print("=" * 80)

def main():
    """Main test function"""
    print("🚀 Testing Terraform Plan Dashboard")
    print("-" * 40)
    
    # Check if tabulate is installed
    try:
        import tabulate
        print("✅ tabulate module found")
    except ImportError:
        print("❌ tabulate module not found")
        print("💡 Install with: pip install tabulate")
        return 1
    
    # Create sample plan files
    print("\n📋 Creating sample plan files...")
    create_sample_plans()
    
    # Test dashboard generation
    print("\n🎨 Testing dashboard generation...")
    test_dashboard()
    
    print("\n🎉 Test completed successfully!")
    print("\n💡 Tips:")
    print("  • Review the generated dashboard in /tmp/test-dashboard.md")
    print("  • You can modify sample plans in this script to test different scenarios")
    print("  • Run 'cat /tmp/test-dashboard.md' to see the full output")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())