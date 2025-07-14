"""
Custom Checkov checks for Azure App Service Plan (azure-app-service-plan) component
One Platform Infrastructure - Security Policies
"""

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureAppServicePlanUsesValidSku(BaseResourceCheck):
    """
    Ensure that Azure App Service Plans use appropriate SKU for production workloads
    """
    def __init__(self):
        name = "Ensure Azure App Service Plan uses appropriate SKU"
        id = "CKV_OP_AZURE_ASP_1"
        supported_resources = ["azurerm_service_plan"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if App Service Plan uses appropriate SKU
        """
        if "sku_name" in conf:
            sku_name = conf["sku_name"][0] if isinstance(conf["sku_name"], list) else conf["sku_name"]
            
            # Valid SKUs for production workloads
            production_skus = ["P1v3", "P2v3", "P3v3", "P1v2", "P2v2", "P3v2", "S1", "S2", "S3"]
            development_skus = ["F1", "D1", "B1", "B2", "B3"]
            
            sku_str = str(sku_name).upper()
            
            if "var." in str(sku_name):
                return CheckResult.PASSED  # Variable reference
            elif sku_str in production_skus or sku_str in development_skus:
                return CheckResult.PASSED
            else:
                self.details = f"SKU '{sku_name}' may not be optimal. Consider using production SKUs for critical workloads"
                return CheckResult.FAILED
        
        self.details = "No sku_name configured"
        return CheckResult.FAILED


class AzureAppServicePlanUsesLinux(BaseResourceCheck):
    """
    Ensure that Azure App Service Plans specify OS type
    """
    def __init__(self):
        name = "Ensure Azure App Service Plan has OS type specified"
        id = "CKV_OP_AZURE_ASP_2"
        supported_resources = ["azurerm_service_plan"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if App Service Plan has OS type configured
        """
        if "os_type" in conf:
            os_type = conf["os_type"][0] if isinstance(conf["os_type"], list) else conf["os_type"]
            valid_os_types = ["Linux", "Windows"]
            
            if str(os_type) in valid_os_types:
                return CheckResult.PASSED
            elif "var." in str(os_type):
                return CheckResult.PASSED
            else:
                self.details = f"OS type '{os_type}' is not valid. Use 'Linux' or 'Windows'"
                return CheckResult.FAILED
        
        self.details = "No os_type configured - should specify Linux or Windows"
        return CheckResult.FAILED


class AzureAppServicePlanUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure App Service Plans use the cloudposse/label/null module
    """
    def __init__(self):
        name = "Ensure Azure App Service Plan uses cloudposse/label module"
        id = "CKV_OP_AZURE_ASP_3"
        supported_resources = ["azurerm_service_plan"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if App Service Plan uses label module
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


class AzureAppServicePlanUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure App Service Plans use conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure App Service Plan uses conditional creation pattern"
        id = "CKV_OP_AZURE_ASP_4"
        supported_resources = ["azurerm_service_plan"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if App Service Plan uses conditional creation
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern"
        return CheckResult.FAILED


class AzureAppServicePlanHasProperResourceGroupReference(BaseResourceCheck):
    """
    Ensure that Azure App Service Plans properly reference their resource group
    """
    def __init__(self):
        name = "Ensure Azure App Service Plan properly references resource group"
        id = "CKV_OP_AZURE_ASP_5"
        supported_resources = ["azurerm_service_plan"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if App Service Plan references resource group properly
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


class AzureAppServicePlanHasValidLocation(BaseResourceCheck):
    """
    Ensure that Azure App Service Plans use approved Azure regions
    """
    def __init__(self):
        name = "Ensure Azure App Service Plan uses approved Azure regions"
        id = "CKV_OP_AZURE_ASP_6"
        supported_resources = ["azurerm_service_plan"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if App Service Plan uses approved regions
        """
        approved_regions = [
            "East US", "East US 2", "West US", "West US 2", "Central US",
            "North Central US", "South Central US", "West Central US",
            "Canada Central", "Canada East", "UK South", "UK West",
            "West Europe", "North Europe"
        ]
        
        if "location" in conf:
            location = conf["location"][0] if isinstance(conf["location"], list) else conf["location"]
            
            if "var." in str(location):
                return CheckResult.PASSED  # Variable reference
            elif location in approved_regions:
                return CheckResult.PASSED
            else:
                self.details = f"Location '{location}' is not in approved regions list"
                return CheckResult.FAILED
        
        self.details = "No location specified"
        return CheckResult.FAILED


# Register the checks
check = AzureAppServicePlanUsesValidSku()
check = AzureAppServicePlanUsesLinux()
check = AzureAppServicePlanUsesLabelModule()
check = AzureAppServicePlanUsesConditionalCreation()
check = AzureAppServicePlanHasProperResourceGroupReference()
check = AzureAppServicePlanHasValidLocation()