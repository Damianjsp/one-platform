"""
Custom Checkov checks for Azure Virtual Network (azure-vnet) component
One Platform Infrastructure - Security Policies
"""

import ipaddress
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureVNetHasValidAddressSpace(BaseResourceCheck):
    """
    Ensure that Azure Virtual Networks use approved private IP address ranges
    """
    def __init__(self):
        name = "Ensure Azure VNet uses approved private IP address ranges"
        id = "CKV_OP_AZURE_VNET_1"
        supported_resources = ["azurerm_virtual_network"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Validates that VNet address space uses private IP ranges
        """
        if "address_space" in conf:
            address_space = conf["address_space"][0] if isinstance(conf["address_space"], list) else conf["address_space"]
            
            # Handle list of address spaces
            if isinstance(address_space, list):
                addresses = address_space
            else:
                addresses = [address_space]
            
            for addr in addresses:
                if isinstance(addr, str) and not addr.startswith("var."):
                    try:
                        network = ipaddress.ip_network(addr, strict=False)
                        if not network.is_private:
                            self.details = f"Address space '{addr}' is not a private IP range"
                            return CheckResult.FAILED
                    except ValueError:
                        if "var." not in addr:  # Skip variable references
                            self.details = f"Invalid IP address format: '{addr}'"
                            return CheckResult.FAILED
            
            return CheckResult.PASSED
        
        self.details = "No address_space defined"
        return CheckResult.FAILED


class AzureVNetHasResourceGroupReference(BaseResourceCheck):
    """
    Ensure that Azure Virtual Networks reference the correct resource group
    """
    def __init__(self):
        name = "Ensure Azure VNet references proper resource group"
        id = "CKV_OP_AZURE_VNET_2"
        supported_resources = ["azurerm_virtual_network"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if VNet properly references resource group
        """
        if "resource_group_name" in conf:
            rg_name = conf["resource_group_name"][0] if isinstance(conf["resource_group_name"], list) else conf["resource_group_name"]
            
            # Should reference a variable or output from resource group component
            if isinstance(rg_name, str):
                if "var." in rg_name or "azurerm_resource_group" in rg_name:
                    return CheckResult.PASSED
                else:
                    self.details = "Resource group name should reference var.resource_group_name or azurerm_resource_group output"
                    return CheckResult.FAILED
            
            return CheckResult.PASSED
        
        self.details = "No resource_group_name defined"
        return CheckResult.FAILED


class AzureVNetUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure Virtual Networks use the cloudposse/label/null module for consistent naming
    """
    def __init__(self):
        name = "Ensure Azure VNet uses cloudposse/label module for naming"
        id = "CKV_OP_AZURE_VNET_3"
        supported_resources = ["azurerm_virtual_network"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if VNet uses label module for naming and tagging
        """
        checks = []
        
        # Check name
        if "name" in conf:
            name_value = conf["name"][0] if isinstance(conf["name"], list) else conf["name"]
            if "module.label" in str(name_value):
                checks.append(True)
            else:
                checks.append(False)
                self.details = "Name should reference module.label.id"
        else:
            checks.append(False)
            self.details = "No name parameter found"
        
        # Check tags
        if "tags" in conf:
            tags_value = conf["tags"][0] if isinstance(conf["tags"], list) else conf["tags"]
            if "module.label.tags" in str(tags_value):
                checks.append(True)
            else:
                checks.append(False)
                self.details += " | Tags should reference module.label.tags"
        else:
            checks.append(False)
            self.details += " | No tags parameter found"
        
        return CheckResult.PASSED if all(checks) else CheckResult.FAILED


class AzureVNetUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure Virtual Networks use conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure VNet uses conditional creation pattern"
        id = "CKV_OP_AZURE_VNET_4"
        supported_resources = ["azurerm_virtual_network"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if VNet uses conditional creation with count parameter
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern - should use 'count = var.enabled ? 1 : 0'"
        return CheckResult.FAILED


class AzureVNetHasDDosProtectionConfiguration(BaseResourceCheck):
    """
    Ensure that Azure Virtual Networks have DDoS protection configuration defined
    """
    def __init__(self):
        name = "Ensure Azure VNet has DDoS protection configuration"
        id = "CKV_OP_AZURE_VNET_5"
        supported_resources = ["azurerm_virtual_network"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if VNet has DDoS protection plan configuration
        """
        # Check if ddos_protection_plan block exists
        if "ddos_protection_plan" in conf:
            ddos_config = conf["ddos_protection_plan"]
            # Even if it's null/empty, having the configuration defined is good practice
            return CheckResult.PASSED
        
        # Check if there's a dynamic block for ddos_protection_plan
        if any("ddos_protection_plan" in str(value) for value in conf.values()):
            return CheckResult.PASSED
        
        self.details = "No DDoS protection configuration found - consider adding ddos_protection_plan configuration"
        return CheckResult.FAILED


class AzureVNetHasValidSubnetConfiguration(BaseResourceCheck):
    """
    Ensure that Azure Virtual Networks have appropriate address space for subnets
    """
    def __init__(self):
        name = "Ensure Azure VNet has sufficient address space for subnets"
        id = "CKV_OP_AZURE_VNET_6"
        supported_resources = ["azurerm_virtual_network"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Validates that VNet address space is appropriate for subnet allocation
        """
        if "address_space" in conf:
            address_space = conf["address_space"][0] if isinstance(conf["address_space"], list) else conf["address_space"]
            
            # Handle list of address spaces
            if isinstance(address_space, list):
                addresses = address_space
            else:
                addresses = [address_space]
            
            for addr in addresses:
                if isinstance(addr, str) and not addr.startswith("var."):
                    try:
                        network = ipaddress.ip_network(addr, strict=False)
                        # Ensure network is at least /24 or larger (smaller prefix number)
                        if network.prefixlen > 24:
                            self.details = f"Address space '{addr}' has prefix /{network.prefixlen} which may be too small for multiple subnets"
                            return CheckResult.FAILED
                    except ValueError:
                        if "var." not in addr:
                            self.details = f"Invalid IP address format: '{addr}'"
                            return CheckResult.FAILED
            
            return CheckResult.PASSED
        
        self.details = "No address_space defined"
        return CheckResult.FAILED


# Register the checks
check = AzureVNetHasValidAddressSpace()
check = AzureVNetHasResourceGroupReference()
check = AzureVNetUsesLabelModule()
check = AzureVNetUsesConditionalCreation()
check = AzureVNetHasDDosProtectionConfiguration()
check = AzureVNetHasValidSubnetConfiguration()