"""
Custom Checkov checks for Azure Function App (azure-function-app) component
One Platform Infrastructure - Security Policies
"""

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureFunctionAppHasHttpsOnly(BaseResourceCheck):
    """
    Ensure that Azure Function Apps enforce HTTPS only
    """
    def __init__(self):
        name = "Ensure Azure Function App enforces HTTPS only"
        id = "CKV_OP_AZURE_FA_1"
        supported_resources = ["azurerm_linux_function_app", "azurerm_windows_function_app"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Function App enforces HTTPS only
        """
        if "https_only" in conf:
            https_only = conf["https_only"][0] if isinstance(conf["https_only"], list) else conf["https_only"]
            if str(https_only).lower() in ["true", "1"]:
                return CheckResult.PASSED
            else:
                self.details = "HTTPS only should be enabled"
                return CheckResult.FAILED
        
        self.details = "https_only not configured - should be true"
        return CheckResult.FAILED


class AzureFunctionAppHasMinimumTlsVersion(BaseResourceCheck):
    """
    Ensure that Azure Function Apps use minimum TLS version 1.2
    """
    def __init__(self):
        name = "Ensure Azure Function App uses minimum TLS 1.2"
        id = "CKV_OP_AZURE_FA_2"
        supported_resources = ["azurerm_linux_function_app", "azurerm_windows_function_app"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks minimum TLS version in site_config
        """
        if "site_config" in conf:
            site_config = conf["site_config"]
            if isinstance(site_config, list) and len(site_config) > 0:
                config = site_config[0] if isinstance(site_config[0], dict) else {}
                
                if "minimum_tls_version" in config:
                    tls_version = config["minimum_tls_version"]
                    if isinstance(tls_version, list):
                        tls_version = tls_version[0]
                    
                    if str(tls_version) in ["1.2", "1.3"]:
                        return CheckResult.PASSED
                    else:
                        self.details = f"Minimum TLS version is {tls_version}, should be 1.2 or higher"
                        return CheckResult.FAILED
        
        self.details = "minimum_tls_version not configured in site_config - should be 1.2"
        return CheckResult.FAILED


class AzureFunctionAppUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure Function Apps use the cloudposse/label/null module
    """
    def __init__(self):
        name = "Ensure Azure Function App uses cloudposse/label module"
        id = "CKV_OP_AZURE_FA_3"
        supported_resources = ["azurerm_linux_function_app", "azurerm_windows_function_app"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Function App uses label module
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


class AzureFunctionAppHasStorageAccount(BaseResourceCheck):
    """
    Ensure that Azure Function Apps have storage account configured
    """
    def __init__(self):
        name = "Ensure Azure Function App has storage account configured"
        id = "CKV_OP_AZURE_FA_4"
        supported_resources = ["azurerm_linux_function_app", "azurerm_windows_function_app"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Function App has storage account configured
        """
        storage_checks = []
        
        if "storage_account_name" in conf:
            storage_name = conf["storage_account_name"][0] if isinstance(conf["storage_account_name"], list) else conf["storage_account_name"]
            if storage_name and str(storage_name).strip():
                storage_checks.append(True)
            else:
                storage_checks.append(False)
                self.details = "Storage account name is empty"
        else:
            storage_checks.append(False)
            self.details = "No storage_account_name configured"
        
        if "storage_account_access_key" in conf:
            storage_key = conf["storage_account_access_key"][0] if isinstance(conf["storage_account_access_key"], list) else conf["storage_account_access_key"]
            if storage_key and str(storage_key).strip():
                storage_checks.append(True)
            else:
                storage_checks.append(False)
                self.details += " | Storage account access key is empty"
        else:
            storage_checks.append(False)
            self.details += " | No storage_account_access_key configured"
        
        return CheckResult.PASSED if all(storage_checks) else CheckResult.FAILED


class AzureFunctionAppHasServicePlan(BaseResourceCheck):
    """
    Ensure that Azure Function Apps reference a service plan
    """
    def __init__(self):
        name = "Ensure Azure Function App references service plan"
        id = "CKV_OP_AZURE_FA_5"
        supported_resources = ["azurerm_linux_function_app", "azurerm_windows_function_app"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Function App references service plan
        """
        if "service_plan_id" in conf:
            service_plan_id = conf["service_plan_id"][0] if isinstance(conf["service_plan_id"], list) else conf["service_plan_id"]
            
            if service_plan_id and str(service_plan_id).strip():
                # Should reference a variable or service plan resource
                if ("var." in str(service_plan_id) or 
                    "azurerm_service_plan" in str(service_plan_id) or
                    "/subscriptions/" in str(service_plan_id)):
                    return CheckResult.PASSED
                else:
                    self.details = "Service plan ID should reference a variable or service plan resource"
                    return CheckResult.FAILED
            else:
                self.details = "Service plan ID is empty"
                return CheckResult.FAILED
        
        self.details = "No service_plan_id configured"
        return CheckResult.FAILED


class AzureFunctionAppHasApplicationStack(BaseResourceCheck):
    """
    Ensure that Azure Function Apps have application stack configured in site_config
    """
    def __init__(self):
        name = "Ensure Azure Function App has application stack configured"
        id = "CKV_OP_AZURE_FA_6"
        supported_resources = ["azurerm_linux_function_app", "azurerm_windows_function_app"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Function App has application stack in site_config
        """
        if "site_config" in conf:
            site_config = conf["site_config"]
            if isinstance(site_config, list) and len(site_config) > 0:
                config = site_config[0] if isinstance(site_config[0], dict) else {}
                
                # Check for application_stack configuration
                if "application_stack" in config:
                    app_stack = config["application_stack"]
                    if isinstance(app_stack, list) and len(app_stack) > 0:
                        return CheckResult.PASSED
                    elif app_stack:  # Not empty
                        return CheckResult.PASSED
        
        self.details = "No application_stack configured in site_config"
        return CheckResult.FAILED


class AzureFunctionAppUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure Function Apps use conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure Function App uses conditional creation pattern"
        id = "CKV_OP_AZURE_FA_7"
        supported_resources = ["azurerm_linux_function_app", "azurerm_windows_function_app"]
        categories = ["app_service"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Function App uses conditional creation
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
check = AzureFunctionAppHasHttpsOnly()
check = AzureFunctionAppHasMinimumTlsVersion()
check = AzureFunctionAppUsesLabelModule()
check = AzureFunctionAppHasStorageAccount()
check = AzureFunctionAppHasServicePlan()
check = AzureFunctionAppHasApplicationStack()
check = AzureFunctionAppUsesConditionalCreation()