"""
Custom Checkov checks for Azure Private Endpoint (azure-private-endpoint) component
One Platform Infrastructure - Security Policies
"""

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzurePrivateEndpointHasSubnetConnection(BaseResourceCheck):
    """
    Ensure that Azure Private Endpoints are properly connected to a subnet
    """
    def __init__(self):
        name = "Ensure Azure Private Endpoint is connected to a subnet"
        id = "CKV_OP_AZURE_PE_1"
        supported_resources = ["azurerm_private_endpoint"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if private endpoint has subnet_id configured
        """
        if "subnet_id" in conf:
            subnet_id = conf["subnet_id"][0] if isinstance(conf["subnet_id"], list) else conf["subnet_id"]
            if subnet_id and str(subnet_id).strip():
                # Should reference a variable or subnet resource
                if "var." in str(subnet_id) or "azurerm_subnet" in str(subnet_id):
                    return CheckResult.PASSED
                else:
                    self.details = "Subnet ID should reference a variable or subnet resource"
                    return CheckResult.FAILED
            else:
                self.details = "Subnet ID is empty"
                return CheckResult.FAILED
        
        self.details = "No subnet_id configured"
        return CheckResult.FAILED


class AzurePrivateEndpointHasServiceConnection(BaseResourceCheck):
    """
    Ensure that Azure Private Endpoints have private service connection configured
    """
    def __init__(self):
        name = "Ensure Azure Private Endpoint has private service connection"
        id = "CKV_OP_AZURE_PE_2"
        supported_resources = ["azurerm_private_endpoint"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if private endpoint has private_service_connection
        """
        if "private_service_connection" in conf:
            psc = conf["private_service_connection"]
            if isinstance(psc, list) and len(psc) > 0:
                # Check first connection for required fields
                connection = psc[0] if isinstance(psc[0], dict) else {}
                
                required_fields = ["name", "private_connection_resource_id", "is_manual_connection"]
                missing_fields = []
                
                for field in required_fields:
                    if field not in connection:
                        missing_fields.append(field)
                
                if missing_fields:
                    self.details = f"Missing required fields in private_service_connection: {', '.join(missing_fields)}"
                    return CheckResult.FAILED
                
                return CheckResult.PASSED
            elif psc:  # Not empty
                return CheckResult.PASSED
        
        self.details = "No private_service_connection configured"
        return CheckResult.FAILED


class AzurePrivateEndpointUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure Private Endpoints use the cloudposse/label/null module for naming and tagging
    """
    def __init__(self):
        name = "Ensure Azure Private Endpoint uses cloudposse/label module"
        id = "CKV_OP_AZURE_PE_3"
        supported_resources = ["azurerm_private_endpoint"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if private endpoint uses label module
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


class AzurePrivateEndpointUsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure Private Endpoints use conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure Private Endpoint uses conditional creation pattern"
        id = "CKV_OP_AZURE_PE_4"
        supported_resources = ["azurerm_private_endpoint"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if private endpoint uses conditional creation
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern"
        return CheckResult.FAILED


class AzurePrivateEndpointHasProperResourceGroupReference(BaseResourceCheck):
    """
    Ensure that Azure Private Endpoints properly reference their resource group
    """
    def __init__(self):
        name = "Ensure Azure Private Endpoint properly references resource group"
        id = "CKV_OP_AZURE_PE_5"
        supported_resources = ["azurerm_private_endpoint"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if private endpoint references resource group properly
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


class AzurePrivateEndpointHasValidConnection(BaseResourceCheck):
    """
    Ensure that Azure Private Endpoints have valid target resource connection
    """
    def __init__(self):
        name = "Ensure Azure Private Endpoint has valid target resource connection"
        id = "CKV_OP_AZURE_PE_6"
        supported_resources = ["azurerm_private_endpoint"]
        categories = ["networking"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if private endpoint targets valid Azure service
        """
        if "private_service_connection" in conf:
            psc = conf["private_service_connection"]
            if isinstance(psc, list) and len(psc) > 0:
                connection = psc[0] if isinstance(psc[0], dict) else {}
                
                # Check if target resource ID is properly referenced
                if "private_connection_resource_id" in connection:
                    resource_id = connection["private_connection_resource_id"]
                    if isinstance(resource_id, list):
                        resource_id = resource_id[0] if len(resource_id) > 0 else ""
                    
                    # Should reference a variable or Azure resource
                    if ("var." in str(resource_id) or 
                        "azurerm_" in str(resource_id) or
                        "/subscriptions/" in str(resource_id)):
                        return CheckResult.PASSED
                    else:
                        self.details = "Target resource ID should reference a variable or Azure resource"
                        return CheckResult.FAILED
                
                self.details = "No target resource ID configured"
                return CheckResult.FAILED
        
        self.details = "No private service connection found"
        return CheckResult.FAILED


# Register the checks
check = AzurePrivateEndpointHasSubnetConnection()
check = AzurePrivateEndpointHasServiceConnection()
check = AzurePrivateEndpointUsesLabelModule()
check = AzurePrivateEndpointUsesConditionalCreation()
check = AzurePrivateEndpointHasProperResourceGroupReference()
check = AzurePrivateEndpointHasValidConnection()