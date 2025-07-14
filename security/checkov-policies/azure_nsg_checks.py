"""
Custom Checkov checks for Azure Network Security Group (azure-nsg) component
One Platform Infrastructure - Security Policies
"""

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureNSGHasSecurityRules(BaseResourceCheck):
    """
    Ensure that Azure NSGs have security rules defined
    """
    def __init__(self):
        name = "Ensure Azure NSG has security rules defined"
        id = "CKV_OP_AZURE_NSG_1"
        supported_resources = ["azurerm_network_security_group"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if NSG has security rules
        """
        if "security_rule" in conf:
            security_rules = conf["security_rule"]
            if isinstance(security_rules, list) and len(security_rules) > 0:
                return CheckResult.PASSED
            elif security_rules:  # Not empty
                return CheckResult.PASSED
        
        self.details = "NSG should have security rules defined for proper access control"
        return CheckResult.FAILED


class AzureNSGDeniesInternetInbound(BaseResourceCheck):
    """
    Ensure that Azure NSGs don't allow unrestricted inbound access from internet
    """
    def __init__(self):
        name = "Ensure Azure NSG doesn't allow unrestricted inbound internet access"
        id = "CKV_OP_AZURE_NSG_2"
        supported_resources = ["azurerm_network_security_group"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks for overly permissive inbound rules
        """
        if "security_rule" in conf:
            security_rules = conf["security_rule"]
            if not isinstance(security_rules, list):
                security_rules = [security_rules]
            
            for rule in security_rules:
                if isinstance(rule, dict):
                    direction = rule.get("direction", [""])
                    access = rule.get("access", [""])
                    source_address_prefix = rule.get("source_address_prefix", [""])
                    
                    # Extract values from lists if needed
                    direction_val = direction[0] if isinstance(direction, list) else direction
                    access_val = access[0] if isinstance(access, list) else access
                    source_val = source_address_prefix[0] if isinstance(source_address_prefix, list) else source_address_prefix
                    
                    if (str(direction_val).lower() == "inbound" and 
                        str(access_val).lower() == "allow" and
                        str(source_val) in ["*", "0.0.0.0/0", "any", "internet"]):
                        self.details = "Found overly permissive inbound rule allowing access from internet"
                        return CheckResult.FAILED
        
        return CheckResult.PASSED


class AzureNSGUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure NSGs use the cloudposse/label/null module for consistent naming and tagging
    """
    def __init__(self):
        name = "Ensure Azure NSG uses cloudposse/label module for naming"
        id = "CKV_OP_AZURE_NSG_3"
        supported_resources = ["azurerm_network_security_group"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if NSG uses label module
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


class AzureNSGUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure NSGs use conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure NSG uses conditional creation pattern"
        id = "CKV_OP_AZURE_NSG_4"
        supported_resources = ["azurerm_network_security_group"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if NSG uses conditional creation
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern"
        return CheckResult.FAILED


class AzureNSGHasProperResourceGroupReference(BaseResourceCheck):
    """
    Ensure that Azure NSGs properly reference their resource group
    """
    def __init__(self):
        name = "Ensure Azure NSG properly references resource group"
        id = "CKV_OP_AZURE_NSG_5"
        supported_resources = ["azurerm_network_security_group"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if NSG references resource group properly
        """
        if "resource_group_name" in conf:
            rg_name = conf["resource_group_name"][0] if isinstance(conf["resource_group_name"], list) else conf["resource_group_name"]
            if "var." in str(rg_name) or "azurerm_resource_group" in str(rg_name):
                return CheckResult.PASSED
            else:
                self.details = "Resource group name should reference variable or resource"
                return CheckResult.FAILED
        
        self.details = "No resource_group_name defined"
        return CheckResult.FAILED


# Register the checks
check = AzureNSGHasSecurityRules()
check = AzureNSGDeniesInternetInbound()
check = AzureNSGUsesLabelModule()
check = AzureNSGUsesConditionalCreation()
check = AzureNSGHasProperResourceGroupReference()