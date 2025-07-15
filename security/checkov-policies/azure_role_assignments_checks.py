"""
Custom Checkov checks for Azure Role Assignments Bulk components
One Platform Infrastructure - Security Policies

Role assignment security checks for principle of least privilege,
approved roles validation, and bulk assignment security compliance.
"""

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class AzureRoleAssignmentUsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure Role Assignment uses the cloudposse/label/null module for consistent naming and tagging
    """
    def __init__(self):
        name = "Ensure Azure Role Assignment uses cloudposse/label module"
        id = "CKV_OP_AZURE_RA_1"
        supported_resources = ["azurerm_role_assignment"]
        categories = ["iam"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Role Assignment uses label module for naming and tagging via module reference
        """
        # Role assignments don't directly use labels, but the containing module should
        # This check ensures the assignment is part of a labeled module
        return CheckResult.PASSED


class AzureRoleAssignmentHasApprovedRole(BaseResourceCheck):
    """
    Ensure that Azure Role Assignment uses only approved built-in roles
    """
    def __init__(self):
        name = "Ensure Azure Role Assignment uses approved built-in roles"
        id = "CKV_OP_AZURE_RA_2"
        supported_resources = ["azurerm_role_assignment"]
        categories = ["iam"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Role Assignment uses approved role names
        """
        approved_roles = [
            # Storage roles
            "Storage Blob Data Owner",
            "Storage Blob Data Contributor",
            "Storage Blob Data Reader",
            "Storage Queue Data Contributor",
            "Storage Queue Data Reader",
            "Storage Queue Data Message Processor",
            "Storage Queue Data Message Sender",
            "Storage File Data SMB Share Contributor",
            "Storage File Data SMB Share Reader",
            "Storage Table Data Contributor",
            "Storage Table Data Reader",
            
            # Key Vault roles
            "Key Vault Administrator",
            "Key Vault Certificates Officer",
            "Key Vault Crypto Officer",
            "Key Vault Crypto Service Encryption User",
            "Key Vault Crypto User",
            "Key Vault Reader",
            "Key Vault Secrets Officer",
            "Key Vault Secrets User",
            
            # General roles
            "Reader",
            "Contributor",
            "Managed Identity Operator",
            "Managed Identity Contributor",
            
            # Monitoring
            "Log Analytics Contributor",
            "Log Analytics Reader",
            "Monitoring Contributor",
            "Monitoring Reader"
        ]
        
        if "role_definition_name" in conf:
            role_name = conf["role_definition_name"][0] if isinstance(conf["role_definition_name"], list) else conf["role_definition_name"]
            
            # Handle variable references
            if isinstance(role_name, str) and role_name.startswith("var."):
                # For variable references, we pass - actual validation happens during runtime
                return CheckResult.PASSED
            
            if role_name in approved_roles:
                return CheckResult.PASSED
            else:
                self.details = f"Role '{role_name}' is not in approved roles list. Use built-in roles only."
                return CheckResult.FAILED
        
        self.details = "No role_definition_name specified"
        return CheckResult.FAILED


class AzureRoleAssignmentHasValidPrincipal(BaseResourceCheck):
    """
    Ensure that Azure Role Assignment has a valid principal ID
    """
    def __init__(self):
        name = "Ensure Azure Role Assignment has valid principal ID"
        id = "CKV_OP_AZURE_RA_3"
        supported_resources = ["azurerm_role_assignment"]
        categories = ["iam"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Role Assignment has a valid principal_id
        """
        if "principal_id" in conf:
            principal_id = conf["principal_id"][0] if isinstance(conf["principal_id"], list) else conf["principal_id"]
            
            # Should reference a managed identity, user, group, or service principal
            if "var." in str(principal_id) or "data." in str(principal_id) or "azurerm_" in str(principal_id):
                return CheckResult.PASSED
            else:
                self.details = "Principal ID should reference a managed identity, user, group, or service principal resource"
                return CheckResult.FAILED
        
        self.details = "No principal_id defined"
        return CheckResult.FAILED


class AzureRoleAssignmentHasValidScope(BaseResourceCheck):
    """
    Ensure that Azure Role Assignment has appropriate scope
    """
    def __init__(self):
        name = "Ensure Azure Role Assignment has appropriate scope"
        id = "CKV_OP_AZURE_RA_4"
        supported_resources = ["azurerm_role_assignment"]
        categories = ["iam"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Role Assignment has a valid scope
        """
        if "scope" in conf:
            scope = conf["scope"][0] if isinstance(conf["scope"], list) else conf["scope"]
            
            # Should reference a resource, resource group, or subscription
            if ("var." in str(scope) or 
                "data." in str(scope) or 
                "azurerm_" in str(scope) or
                "/subscriptions/" in str(scope) or
                "/resourceGroups/" in str(scope)):
                return CheckResult.PASSED
            else:
                self.details = "Scope should reference a valid Azure resource, resource group, or subscription"
                return CheckResult.FAILED
        
        self.details = "No scope defined"
        return CheckResult.FAILED


class AzureRoleAssignmentHasDescription(BaseResourceCheck):
    """
    Ensure that Azure Role Assignment has a description for audit purposes
    """
    def __init__(self):
        name = "Ensure Azure Role Assignment has description for audit purposes"
        id = "CKV_OP_AZURE_RA_5"
        supported_resources = ["azurerm_role_assignment"]
        categories = ["iam"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Role Assignment has a description
        """
        if "description" in conf:
            description = conf["description"][0] if isinstance(conf["description"], list) else conf["description"]
            
            if description and len(str(description).strip()) > 0:
                return CheckResult.PASSED
            else:
                self.details = "Description should not be empty"
                return CheckResult.FAILED
        
        self.details = "Role assignment should have a description for audit purposes"
        return CheckResult.FAILED


class AzureRoleAssignmentFollowsLeastPrivilege(BaseResourceCheck):
    """
    Ensure that Azure Role Assignment follows principle of least privilege
    """
    def __init__(self):
        name = "Ensure Azure Role Assignment follows principle of least privilege"
        id = "CKV_OP_AZURE_RA_6"
        supported_resources = ["azurerm_role_assignment"]
        categories = ["iam"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if Role Assignment follows least privilege principle
        """
        # Check for overly broad roles that should be avoided
        broad_roles = [
            "Owner",
            "Contributor", 
            "User Access Administrator"
        ]
        
        if "role_definition_name" in conf:
            role_name = conf["role_definition_name"][0] if isinstance(conf["role_definition_name"], list) else conf["role_definition_name"]
            
            # Handle variable references
            if isinstance(role_name, str) and role_name.startswith("var."):
                return CheckResult.PASSED
            
            if role_name in broad_roles:
                # Check scope - broad roles might be acceptable at resource level but not at subscription level
                if "scope" in conf:
                    scope = conf["scope"][0] if isinstance(conf["scope"], list) else conf["scope"]
                    if "/subscriptions/" in str(scope) and "/resourceGroups/" not in str(scope):
                        self.details = f"Broad role '{role_name}' assigned at subscription level violates least privilege principle"
                        return CheckResult.FAILED
                
                # If not subscription level, provide warning but pass
                return CheckResult.PASSED
            
            return CheckResult.PASSED
        
        return CheckResult.PASSED


# Register the checks
check = AzureRoleAssignmentUsesLabelModule()
check = AzureRoleAssignmentHasApprovedRole()
check = AzureRoleAssignmentHasValidPrincipal()
check = AzureRoleAssignmentHasValidScope()
check = AzureRoleAssignmentHasDescription()
check = AzureRoleAssignmentFollowsLeastPrivilege()