"""
Custom Checkov checks for Azure User Managed Identity components
One Platform Infrastructure - Security Policies

User Managed Identity security checks for consistent naming, tagging,
and security configuration compliance.
"""

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureUserManagedIdentityUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure User Managed Identity uses the cloudposse/label/null module for consistent naming and tagging
    """
    def __init__(self):
        name = "Ensure Azure User Managed Identity uses cloudposse/label module"
        id = "CKV_OP_AZURE_UMI_1"
        supported_resources = ["azurerm_user_assigned_identity"]
        categories = ["identity"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if User Managed Identity uses label module for naming and tagging
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


class AzureUserManagedIdentityUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure User Managed Identity uses conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure User Managed Identity uses conditional creation pattern"
        id = "CKV_OP_AZURE_UMI_2"
        supported_resources = ["azurerm_user_assigned_identity"]
        categories = ["identity"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if User Managed Identity uses conditional creation with count parameter
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern - should use 'count = var.enabled ? 1 : 0'"
        return CheckResult.FAILED


class AzureUserManagedIdentityHasProperResourceGroupReference(BaseResourceCheck):
    """
    Ensure that Azure User Managed Identity properly references their resource group
    """
    def __init__(self):
        name = "Ensure Azure User Managed Identity properly references resource group"
        id = "CKV_OP_AZURE_UMI_3"
        supported_resources = ["azurerm_user_assigned_identity"]
        categories = ["identity"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if User Managed Identity properly references resource group
        """
        if "resource_group_name" in conf:
            rg_name = conf["resource_group_name"][0] if isinstance(conf["resource_group_name"], list) else conf["resource_group_name"]
            
            # Should reference a variable or resource group resource
            if "var." in str(rg_name) or "azurerm_resource_group" in str(rg_name):
                return CheckResult.PASSED
            else:
                self.details = "Resource group name should reference variable or resource group resource"
                return CheckResult.FAILED
        
        self.details = "No resource_group_name defined"
        return CheckResult.FAILED


class AzureUserManagedIdentityHasValidLocation(BaseResourceCheck):
    """
    Ensure that Azure User Managed Identity uses approved Azure regions
    """
    def __init__(self):
        name = "Ensure Azure User Managed Identity uses approved Azure regions"
        id = "CKV_OP_AZURE_UMI_4"
        supported_resources = ["azurerm_user_assigned_identity"]
        categories = ["identity"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Looks for approved Azure regions in User Managed Identity configuration
        """
        # One Platform approved regions
        approved_regions = [
            "East US",
            "East US 2", 
            "West US",
            "West US 2",
            "Central US",
            "North Central US",
            "South Central US",
            "West Central US",
            "Canada Central",
            "Canada East",
            "UK South",
            "UK West",
            "West Europe",
            "North Europe"
        ]
        
        if "location" in conf:
            location = conf["location"][0] if isinstance(conf["location"], list) else conf["location"]
            
            # Handle variable references
            if isinstance(location, str) and location.startswith("var."):
                # For variable references, we pass - actual validation happens during runtime
                return CheckResult.PASSED
            
            if location not in approved_regions:
                self.details = f"Location '{location}' is not in approved regions list"
                return CheckResult.FAILED
            
            return CheckResult.PASSED
        
        self.details = "No location specified"
        return CheckResult.FAILED


class AzureUserManagedIdentityHasStandardNaming(BaseResourceCheck):
    """
    Ensure that Azure User Managed Identity follows standard naming conventions
    """
    def __init__(self):
        name = "Ensure Azure User Managed Identity follows standard naming conventions"
        id = "CKV_OP_AZURE_UMI_5"
        supported_resources = ["azurerm_user_assigned_identity"]
        categories = ["identity"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if User Managed Identity follows One Platform naming standards
        """
        if "name" in conf:
            name_value = conf["name"][0] if isinstance(conf["name"], list) else conf["name"]
            
            # Should use coalesce with custom name or module.label.id
            if "coalesce" in str(name_value) and "module.label.id" in str(name_value):
                return CheckResult.PASSED
            elif "module.label.id" in str(name_value):
                return CheckResult.PASSED
            else:
                self.details = "Name should use coalesce(var.user_assigned_identity_name, module.label.id) pattern"
                return CheckResult.FAILED
        
        self.details = "No name parameter found"
        return CheckResult.FAILED


# Register the checks
check = AzureUserManagedIdentityUsesLabelModule()
check = AzureUserManagedIdentityUsesConditionalCreation()
check = AzureUserManagedIdentityHasProperResourceGroupReference()
check = AzureUserManagedIdentityHasValidLocation()
check = AzureUserManagedIdentityHasStandardNaming()