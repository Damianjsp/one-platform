"""
Custom Checkov checks for Azure Resource Group (azure-rsg) component
One Platform Infrastructure - Security Policies
"""

from checkov.common.models.enums import TRUE_VALUES
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureResourceGroupHasRequiredTags(BaseResourceCheck):
    """
    Ensure that Azure Resource Groups have required tags according to One Platform standards
    """
    def __init__(self):
        name = "Ensure Azure Resource Group has required One Platform tags"
        id = "CKV_OP_AZURE_RG_1"
        supported_resources = ["azurerm_resource_group"]
        categories = ["resource_group"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Looks for required tags in Azure Resource Group configuration
        """
        if "tags" in conf:
            tags = conf["tags"][0] if isinstance(conf["tags"], list) else conf["tags"]
            required_tags = ["environment", "namespace", "name"]
            
            missing_tags = []
            for required_tag in required_tags:
                if required_tag not in tags:
                    missing_tags.append(required_tag)
            
            if missing_tags:
                self.details = f"Missing required tags: {', '.join(missing_tags)}"
                return CheckResult.FAILED
            
            return CheckResult.PASSED
        
        self.details = "No tags defined - required tags: environment, namespace, name"
        return CheckResult.FAILED


class AzureResourceGroupHasValidLocation(BaseResourceCheck):
    """
    Ensure that Azure Resource Groups use approved Azure regions
    """
    def __init__(self):
        name = "Ensure Azure Resource Group uses approved Azure regions"
        id = "CKV_OP_AZURE_RG_2"
        supported_resources = ["azurerm_resource_group"]
        categories = ["resource_group"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Looks for approved Azure regions in Resource Group configuration
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


class AzureResourceGroupUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure Resource Groups use conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure Resource Group uses conditional creation pattern"
        id = "CKV_OP_AZURE_RG_3"
        supported_resources = ["azurerm_resource_group"]
        categories = ["resource_group"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Resource Group uses conditional creation with count parameter
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            
            # Check if count references var.enabled
            if isinstance(count_value, str) and "var.enabled" in count_value:
                return CheckResult.PASSED
            
            # Check if count is a conditional expression with var.enabled
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern - should use 'count = var.enabled ? 1 : 0'"
        return CheckResult.FAILED


class AzureResourceGroupUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure Resource Groups use the cloudposse/label/null module for consistent naming
    """
    def __init__(self):
        name = "Ensure Azure Resource Group uses cloudposse/label module for naming"
        id = "CKV_OP_AZURE_RG_4"
        supported_resources = ["azurerm_resource_group"]
        categories = ["resource_group"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Resource Group references the label module for tags and naming
        """
        # Check if name uses module.label reference
        if "name" in conf:
            name_value = conf["name"][0] if isinstance(conf["name"], list) else conf["name"]
            
            # Should reference module.label.id or use coalesce with module.label.id
            if "module.label" in str(name_value):
                # Check if tags also reference module.label
                if "tags" in conf:
                    tags_value = conf["tags"][0] if isinstance(conf["tags"], list) else conf["tags"]
                    if "module.label.tags" in str(tags_value):
                        return CheckResult.PASSED
                    else:
                        self.details = "Name uses label module but tags don't reference module.label.tags"
                        return CheckResult.FAILED
                else:
                    self.details = "Name uses label module but no tags defined"
                    return CheckResult.FAILED
            else:
                self.details = "Name should reference module.label.id for consistent naming"
                return CheckResult.FAILED
        
        self.details = "No name parameter found"
        return CheckResult.FAILED


class AzureResourceGroupHasValidNamingPattern(BaseResourceCheck):
    """
    Ensure that Azure Resource Groups follow One Platform naming conventions
    """
    def __init__(self):
        name = "Ensure Azure Resource Group follows One Platform naming pattern"
        id = "CKV_OP_AZURE_RG_5"
        supported_resources = ["azurerm_resource_group"]
        categories = ["resource_group"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Validates Resource Group naming pattern against One Platform standards
        """
        if "name" in conf:
            name_value = conf["name"][0] if isinstance(conf["name"], list) else conf["name"]
            
            # If using module.label, we assume it follows the correct pattern
            if "module.label" in str(name_value):
                return CheckResult.PASSED
            
            # If hardcoded name, check if it follows pattern
            if isinstance(name_value, str) and not name_value.startswith("var."):
                # Basic pattern check - should not contain spaces or special chars except hyphens
                if " " in name_value or any(char in name_value for char in "!@#$%^&*()+=[]{}|\\:;\"'<>?,./`~"):
                    self.details = f"Resource Group name '{name_value}' contains invalid characters"
                    return CheckResult.FAILED
                
                # Should be lowercase
                if name_value != name_value.lower():
                    self.details = f"Resource Group name '{name_value}' should be lowercase"
                    return CheckResult.FAILED
            
            return CheckResult.PASSED
        
        self.details = "No name parameter found"
        return CheckResult.FAILED


# Register the checks
check = AzureResourceGroupHasRequiredTags()
check = AzureResourceGroupHasValidLocation()
check = AzureResourceGroupUsesConditionalCreation()
check = AzureResourceGroupUsesLabelModule()
check = AzureResourceGroupHasValidNamingPattern()