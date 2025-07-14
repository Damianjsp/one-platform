"""
Custom Checkov checks for Azure Storage Account (azure-storage-account) component
One Platform Infrastructure - Security Policies
"""

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureStorageAccountHasSecureTransfer(BaseResourceCheck):
    """
    Ensure that Azure Storage Accounts have secure transfer enabled
    """
    def __init__(self):
        name = "Ensure Azure Storage Account has secure transfer enabled"
        id = "CKV_OP_AZURE_SA_1"
        supported_resources = ["azurerm_storage_account"]
        categories = ["storage"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if storage account has HTTPS traffic only enabled
        """
        if "enable_https_traffic_only" in conf:
            https_only = conf["enable_https_traffic_only"][0] if isinstance(conf["enable_https_traffic_only"], list) else conf["enable_https_traffic_only"]
            if str(https_only).lower() in ["true", "1"]:
                return CheckResult.PASSED
            else:
                self.details = "HTTPS traffic only should be enabled"
                return CheckResult.FAILED
        
        self.details = "enable_https_traffic_only not configured - should be true"
        return CheckResult.FAILED


class AzureStorageAccountHasMinimumTLSVersion(BaseResourceCheck):
    """
    Ensure that Azure Storage Accounts use minimum TLS version 1.2
    """
    def __init__(self):
        name = "Ensure Azure Storage Account uses minimum TLS 1.2"
        id = "CKV_OP_AZURE_SA_2"
        supported_resources = ["azurerm_storage_account"]
        categories = ["storage"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks minimum TLS version
        """
        if "min_tls_version" in conf:
            tls_version = conf["min_tls_version"][0] if isinstance(conf["min_tls_version"], list) else conf["min_tls_version"]
            if str(tls_version) in ["TLS1_2", "TLS1_3"]:
                return CheckResult.PASSED
            else:
                self.details = f"Minimum TLS version is {tls_version}, should be TLS1_2 or higher"
                return CheckResult.FAILED
        
        self.details = "min_tls_version not configured - should be TLS1_2"
        return CheckResult.FAILED


class AzureStorageAccountUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure Storage Accounts use the cloudposse/label/null module
    """
    def __init__(self):
        name = "Ensure Azure Storage Account uses cloudposse/label module"
        id = "CKV_OP_AZURE_SA_3"
        supported_resources = ["azurerm_storage_account"]
        categories = ["storage"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if storage account uses label module
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


class AzureStorageAccountHasEncryption(BaseResourceCheck):
    """
    Ensure that Azure Storage Accounts have encryption configured
    """
    def __init__(self):
        name = "Ensure Azure Storage Account has proper encryption configuration"
        id = "CKV_OP_AZURE_SA_4"
        supported_resources = ["azurerm_storage_account"]
        categories = ["storage"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks storage account encryption settings
        """
        # Check for encryption configuration
        if "queue_encryption_key_type" in conf:
            queue_encryption = conf["queue_encryption_key_type"][0] if isinstance(conf["queue_encryption_key_type"], list) else conf["queue_encryption_key_type"]
            if str(queue_encryption).lower() in ["service", "account"]:
                return CheckResult.PASSED
        
        if "table_encryption_key_type" in conf:
            table_encryption = conf["table_encryption_key_type"][0] if isinstance(conf["table_encryption_key_type"], list) else conf["table_encryption_key_type"]
            if str(table_encryption).lower() in ["service", "account"]:
                return CheckResult.PASSED
        
        # Check for customer managed keys (if present)
        if "customer_managed_key" in conf:
            return CheckResult.PASSED
        
        self.details = "Storage account should have encryption configuration defined"
        return CheckResult.FAILED


class AzureStorageAccountHasNetworkRules(BaseResourceCheck):
    """
    Ensure that Azure Storage Accounts have network access rules configured
    """
    def __init__(self):
        name = "Ensure Azure Storage Account has network access rules"
        id = "CKV_OP_AZURE_SA_5"
        supported_resources = ["azurerm_storage_account"]
        categories = ["storage"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if storage account has network rules configured
        """
        if "network_rules" in conf:
            network_rules = conf["network_rules"]
            if isinstance(network_rules, list) and len(network_rules) > 0:
                return CheckResult.PASSED
            elif network_rules:  # Not empty
                return CheckResult.PASSED
        
        # Check for public network access configuration
        if "public_network_access_enabled" in conf:
            public_access = conf["public_network_access_enabled"][0] if isinstance(conf["public_network_access_enabled"], list) else conf["public_network_access_enabled"]
            if str(public_access).lower() == "false":
                return CheckResult.PASSED
        
        self.details = "Storage account should have network access rules or disable public access"
        return CheckResult.FAILED


class AzureStorageAccountUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure Storage Accounts use conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure Storage Account uses conditional creation pattern"
        id = "CKV_OP_AZURE_SA_6"
        supported_resources = ["azurerm_storage_account"]
        categories = ["storage"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if storage account uses conditional creation
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern"
        return CheckResult.FAILED


# Register the checks
check = AzureStorageAccountHasSecureTransfer()
check = AzureStorageAccountHasMinimumTLSVersion()
check = AzureStorageAccountUsesLabelModule()
check = AzureStorageAccountHasEncryption()
check = AzureStorageAccountHasNetworkRules()
check = AzureStorageAccountUsesConditionalCreation()