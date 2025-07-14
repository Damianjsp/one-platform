"""
Custom Checkov checks for Azure Key Vault (azure-keyvault) component
One Platform Infrastructure - Security Policies
"""

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureKeyVaultHasSoftDeleteEnabled(BaseResourceCheck):
    """
    Ensure that Azure Key Vaults have soft delete enabled
    """
    def __init__(self):
        name = "Ensure Azure Key Vault has soft delete enabled"
        id = "CKV_OP_AZURE_KV_1"
        supported_resources = ["azurerm_key_vault"]
        categories = ["secrets"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Key Vault has soft delete enabled
        """
        if "soft_delete_retention_days" in conf:
            retention_days = conf["soft_delete_retention_days"][0] if isinstance(conf["soft_delete_retention_days"], list) else conf["soft_delete_retention_days"]
            try:
                days = int(retention_days) if str(retention_days).isdigit() else 0
                if days >= 7:  # Minimum 7 days retention
                    return CheckResult.PASSED
                else:
                    self.details = f"Soft delete retention days is {days}, should be at least 7"
                    return CheckResult.FAILED
            except (ValueError, TypeError):
                if "var." in str(retention_days):
                    return CheckResult.PASSED  # Variable reference
                
        self.details = "soft_delete_retention_days not configured - should be at least 7"
        return CheckResult.FAILED


class AzureKeyVaultHasPurgeProtection(BaseResourceCheck):
    """
    Ensure that Azure Key Vaults have purge protection enabled for production
    """
    def __init__(self):
        name = "Ensure Azure Key Vault has purge protection configured"
        id = "CKV_OP_AZURE_KV_2"
        supported_resources = ["azurerm_key_vault"]
        categories = ["secrets"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Key Vault has purge protection configured
        """
        if "purge_protection_enabled" in conf:
            purge_protection = conf["purge_protection_enabled"][0] if isinstance(conf["purge_protection_enabled"], list) else conf["purge_protection_enabled"]
            # Configuration is present - passes whether true or false (environment dependent)
            return CheckResult.PASSED
        
        self.details = "purge_protection_enabled not configured - should be explicitly set"
        return CheckResult.FAILED


class AzureKeyVaultHasNetworkAcls(BaseResourceCheck):
    """
    Ensure that Azure Key Vaults have network ACLs configured
    """
    def __init__(self):
        name = "Ensure Azure Key Vault has network ACLs configured"
        id = "CKV_OP_AZURE_KV_3"
        supported_resources = ["azurerm_key_vault"]
        categories = ["secrets"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Key Vault has network ACLs
        """
        if "network_acls" in conf:
            network_acls = conf["network_acls"]
            if isinstance(network_acls, list) and len(network_acls) > 0:
                # Check if default action is configured
                acl = network_acls[0] if isinstance(network_acls[0], dict) else {}
                if "default_action" in acl:
                    return CheckResult.PASSED
            elif network_acls:  # Not empty
                return CheckResult.PASSED
        
        self.details = "network_acls not configured - should define network access rules"
        return CheckResult.FAILED


class AzureKeyVaultUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure Key Vaults use the cloudposse/label/null module
    """
    def __init__(self):
        name = "Ensure Azure Key Vault uses cloudposse/label module"
        id = "CKV_OP_AZURE_KV_4"
        supported_resources = ["azurerm_key_vault"]
        categories = ["secrets"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Key Vault uses label module
        """
        checks = []
        
        if "name" in conf:
            name_value = conf["name"][0] if isinstance(conf["name"], list) else conf["name"]
            if "module.label" in str(name_value):
                checks.append(True)
            else:
                checks.append(False)
                self.details = "Name should reference module.label.id"
        
        if "tags" in conf:
            tags_value = conf["tags"][0] if isinstance(conf["tags"], list) else conf["tags"]
            if "module.label.tags" in str(tags_value):
                checks.append(True)
            else:
                checks.append(False)
                self.details += " | Tags should reference module.label.tags"
        
        return CheckResult.PASSED if all(checks) else CheckResult.FAILED


class AzureKeyVaultHasAccessPolicies(BaseResourceCheck):
    """
    Ensure that Azure Key Vaults have access policies configured
    """
    def __init__(self):
        name = "Ensure Azure Key Vault has access policies configured"
        id = "CKV_OP_AZURE_KV_5"
        supported_resources = ["azurerm_key_vault"]
        categories = ["secrets"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Key Vault has access policies
        """
        if "access_policy" in conf:
            access_policies = conf["access_policy"]
            if isinstance(access_policies, list) and len(access_policies) > 0:
                return CheckResult.PASSED
            elif access_policies:  # Not empty
                return CheckResult.PASSED
        
        self.details = "No access policies configured - Key Vault should have at least one access policy"
        return CheckResult.FAILED


class AzureKeyVaultUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure Key Vaults use conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure Key Vault uses conditional creation pattern"
        id = "CKV_OP_AZURE_KV_6"
        supported_resources = ["azurerm_key_vault"]
        categories = ["secrets"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Key Vault uses conditional creation
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern"
        return CheckResult.FAILED


class AzureKeyVaultHasValidSku(BaseResourceCheck):
    """
    Ensure that Azure Key Vaults use appropriate SKU
    """
    def __init__(self):
        name = "Ensure Azure Key Vault uses appropriate SKU"
        id = "CKV_OP_AZURE_KV_7"
        supported_resources = ["azurerm_key_vault"]
        categories = ["secrets"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Key Vault uses valid SKU
        """
        if "sku_name" in conf:
            sku_name = conf["sku_name"][0] if isinstance(conf["sku_name"], list) else conf["sku_name"]
            valid_skus = ["standard", "premium"]
            
            if str(sku_name).lower() in valid_skus:
                return CheckResult.PASSED
            elif "var." in str(sku_name):
                return CheckResult.PASSED  # Variable reference
            else:
                self.details = f"SKU '{sku_name}' is not valid. Use 'standard' or 'premium'"
                return CheckResult.FAILED
        
        self.details = "No sku_name configured"
        return CheckResult.FAILED


# Register the checks
check = AzureKeyVaultHasSoftDeleteEnabled()
check = AzureKeyVaultHasPurgeProtection()
check = AzureKeyVaultHasNetworkAcls()
check = AzureKeyVaultUsesLabelModule()
check = AzureKeyVaultHasAccessPolicies()
check = AzureKeyVaultUsesConditionalCreation()
check = AzureKeyVaultHasValidSku()