"""
Custom Checkov checks for Azure Subnet (azure-subnet) component
One Platform Infrastructure - Security Policies
"""

import ipaddress
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureSubnetHasValidAddressPrefix(BaseResourceCheck):
    """
    Ensure that Azure Subnets use valid private IP address prefixes
    """
    def __init__(self):
        name = "Ensure Azure Subnet uses valid private IP address prefix"
        id = "CKV_OP_AZURE_SUBNET_1"
        supported_resources = ["azurerm_subnet"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Validates subnet address prefix
        """
        if "address_prefixes" in conf:
            prefixes = conf["address_prefixes"][0] if isinstance(conf["address_prefixes"], list) else conf["address_prefixes"]
            
            if isinstance(prefixes, list):
                addresses = prefixes
            else:
                addresses = [prefixes]
            
            for addr in addresses:
                if isinstance(addr, str) and not addr.startswith("var."):
                    try:
                        network = ipaddress.ip_network(addr, strict=False)
                        if not network.is_private:
                            self.details = f"Subnet prefix '{addr}' is not a private IP range"
                            return CheckResult.FAILED
                        
                        # Ensure subnet is not too large (should be /24 or smaller)
                        if network.prefixlen < 16:
                            self.details = f"Subnet prefix '{addr}' is too large (/{network.prefixlen})"
                            return CheckResult.FAILED
                            
                    except ValueError:
                        if "var." not in addr:
                            self.details = f"Invalid IP address format: '{addr}'"
                            return CheckResult.FAILED
            
            return CheckResult.PASSED
        
        self.details = "No address_prefixes defined"
        return CheckResult.FAILED


class AzureSubnetHasPrivateEndpointSupport(BaseResourceCheck):
    """
    Ensure that Azure Subnets support private endpoints when needed
    """
    def __init__(self):
        name = "Ensure Azure Subnet has proper private endpoint configuration"
        id = "CKV_OP_AZURE_SUBNET_2"
        supported_resources = ["azurerm_subnet"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks subnet private endpoint configuration
        """
        # Check for private endpoint network policies
        if "private_endpoint_network_policies_enabled" in conf:
            pe_policies = conf["private_endpoint_network_policies_enabled"][0] if isinstance(conf["private_endpoint_network_policies_enabled"], list) else conf["private_endpoint_network_policies_enabled"]
            
            # Should be explicitly configured
            if pe_policies is not None:
                return CheckResult.PASSED
        
        # Check for service endpoints
        if "service_endpoints" in conf:
            return CheckResult.PASSED
        
        self.details = "Subnet should have private endpoint network policies explicitly configured"
        return CheckResult.FAILED


class AzureSubnetUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure Subnets use the cloudposse/label/null module for consistent naming
    """
    def __init__(self):
        name = "Ensure Azure Subnet uses cloudposse/label module for naming"
        id = "CKV_OP_AZURE_SUBNET_3"
        supported_resources = ["azurerm_subnet"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if subnet uses label module for naming
        """
        if "name" in conf:
            name_value = conf["name"][0] if isinstance(conf["name"], list) else conf["name"]
            if "module.label" in str(name_value):
                return CheckResult.PASSED
            else:
                self.details = "Name should reference module.label.id"
                return CheckResult.FAILED
        
        self.details = "No name parameter found"
        return CheckResult.FAILED


class AzureSubnetUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure Subnets use conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure Subnet uses conditional creation pattern"
        id = "CKV_OP_AZURE_SUBNET_4"
        supported_resources = ["azurerm_subnet"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if subnet uses conditional creation
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern"
        return CheckResult.FAILED


class AzureSubnetHasVNetReference(BaseResourceCheck):
    """
    Ensure that Azure Subnets properly reference their Virtual Network
    """
    def __init__(self):
        name = "Ensure Azure Subnet properly references Virtual Network"
        id = "CKV_OP_AZURE_SUBNET_5"
        supported_resources = ["azurerm_subnet"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if subnet properly references VNet and Resource Group
        """
        checks = []
        
        # Check virtual_network_name
        if "virtual_network_name" in conf:
            vnet_name = conf["virtual_network_name"][0] if isinstance(conf["virtual_network_name"], list) else conf["virtual_network_name"]
            if "var." in str(vnet_name) or "azurerm_virtual_network" in str(vnet_name):
                checks.append(True)
            else:
                checks.append(False)
                self.details = "Virtual network name should reference variable or VNet resource"
        else:
            checks.append(False)
            self.details = "No virtual_network_name defined"
        
        # Check resource_group_name
        if "resource_group_name" in conf:
            rg_name = conf["resource_group_name"][0] if isinstance(conf["resource_group_name"], list) else conf["resource_group_name"]
            if "var." in str(rg_name) or "azurerm_resource_group" in str(rg_name):
                checks.append(True)
            else:
                checks.append(False)
                self.details += " | Resource group name should reference variable or RG resource"
        else:
            checks.append(False)
            self.details += " | No resource_group_name defined"
        
        return CheckResult.PASSED if all(checks) else CheckResult.FAILED


# Register the checks
check = AzureSubnetHasValidAddressPrefix()
check = AzureSubnetHasPrivateEndpointSupport()
check = AzureSubnetUsesLabelModule()
check = AzureSubnetUsesConditionalCreation()
check = AzureSubnetHasVNetReference()