"""
Template for Custom Checkov checks for new Azure components
One Platform Infrastructure - Security Policies

Replace COMPONENT_NAME with actual component name (e.g., azure-cosmosdb)
Replace COMPONENT_SHORT with abbreviated name (e.g., COSMOSDB)
Replace RESOURCE_TYPE with actual Azure resource type (e.g., azurerm_cosmosdb_account)
Replace CATEGORY with appropriate category (e.g., database, networking, storage, etc.)

Instructions:
1. Copy this template to a new file: azure_[component_name]_checks.py
2. Replace all placeholders with actual values
3. Implement component-specific checks based on security requirements
4. Update security/checkov.yaml to include the new check IDs
5. Test the checks with the checkov-scan.sh script

ALWAYS include these standard checks for consistency:
- Label module usage (naming and tagging)
- Conditional creation pattern (var.enabled)
- Resource group reference
- Component-specific security requirements
"""

from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult


class Azure{COMPONENT_NAME}UsesLabelModule(BaseResourceCheck):
    """
    Ensure that Azure {COMPONENT_NAME} uses the cloudposse/label/null module for consistent naming and tagging
    """
    def __init__(self):
        name = "Ensure Azure {COMPONENT_NAME} uses cloudposse/label module"
        id = "CKV_OP_AZURE_{COMPONENT_SHORT}_1"
        supported_resources = ["{RESOURCE_TYPE}"]
        categories = ["{CATEGORY}"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if {COMPONENT_NAME} uses label module for naming and tagging
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


class Azure{COMPONENT_NAME}UsesConditionalCreation(BaseResourceCheck):
    """
    Ensure that Azure {COMPONENT_NAME} uses conditional creation with 'enabled' variable
    """
    def __init__(self):
        name = "Ensure Azure {COMPONENT_NAME} uses conditional creation pattern"
        id = "CKV_OP_AZURE_{COMPONENT_SHORT}_2"
        supported_resources = ["{RESOURCE_TYPE}"]
        categories = ["{CATEGORY}"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if {COMPONENT_NAME} uses conditional creation with count parameter
        """
        if "count" in conf:
            count_value = conf["count"][0] if isinstance(conf["count"], list) else conf["count"]
            
            if "var.enabled" in str(count_value):
                return CheckResult.PASSED
            
            self.details = "Count parameter exists but doesn't reference var.enabled"
            return CheckResult.FAILED
        
        self.details = "Missing conditional creation pattern - should use 'count = var.enabled ? 1 : 0'"
        return CheckResult.FAILED


class Azure{COMPONENT_NAME}HasProperResourceGroupReference(BaseResourceCheck):
    """
    Ensure that Azure {COMPONENT_NAME} properly references their resource group
    """
    def __init__(self):
        name = "Ensure Azure {COMPONENT_NAME} properly references resource group"
        id = "CKV_OP_AZURE_{COMPONENT_SHORT}_3"
        supported_resources = ["{RESOURCE_TYPE}"]
        categories = ["{CATEGORY}"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Checks if {COMPONENT_NAME} properly references resource group
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


class Azure{COMPONENT_NAME}HasValidLocation(BaseResourceCheck):
    """
    Ensure that Azure {COMPONENT_NAME} uses approved Azure regions
    """
    def __init__(self):
        name = "Ensure Azure {COMPONENT_NAME} uses approved Azure regions"
        id = "CKV_OP_AZURE_{COMPONENT_SHORT}_4"
        supported_resources = ["{RESOURCE_TYPE}"]
        categories = ["{CATEGORY}"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Looks for approved Azure regions in {COMPONENT_NAME} configuration
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


# TODO: Add component-specific security checks here
# Examples:
# - For databases: encryption at rest, backup configuration, access controls
# - For networking: security groups, network ACLs, private connectivity
# - For compute: secure communication, authentication, monitoring
# - For storage: encryption, access policies, versioning

class Azure{COMPONENT_NAME}ComponentSpecificCheck(BaseResourceCheck):
    """
    Ensure that Azure {COMPONENT_NAME} meets component-specific security requirements
    Replace this with actual security checks relevant to the component
    """
    def __init__(self):
        name = "Ensure Azure {COMPONENT_NAME} meets security requirements"
        id = "CKV_OP_AZURE_{COMPONENT_SHORT}_5"
        supported_resources = ["{RESOURCE_TYPE}"]
        categories = ["{CATEGORY}"]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Implement component-specific security validation
        """
        # TODO: Replace with actual component-specific checks
        # Examples:
        # - Check for encryption settings
        # - Validate access policies
        # - Ensure proper network configuration
        # - Verify backup/disaster recovery settings
        
        self.details = "Replace this check with component-specific security validation"
        return CheckResult.PASSED  # Change to actual validation logic


# Register the checks
check = Azure{COMPONENT_NAME}UsesLabelModule()
check = Azure{COMPONENT_NAME}UsesConditionalCreation()
check = Azure{COMPONENT_NAME}HasProperResourceGroupReference()
check = Azure{COMPONENT_NAME}HasValidLocation()
check = Azure{COMPONENT_NAME}ComponentSpecificCheck()

"""
Checklist for implementing new component checks:

□ Replace all placeholders with actual values
□ Implement component-specific security checks
□ Update security/checkov.yaml with new check IDs
□ Test checks with ./scripts/checkov-scan.sh
□ Document the checks in component README
□ Update CLAUDE.md with new component information

Component-specific check ideas by category:

Database components:
- Encryption at rest enabled
- Backup retention configured
- Access authentication required
- Network isolation configured
- Audit logging enabled

Networking components:
- Security groups configured
- Private connectivity enabled
- Network ACLs defined
- Traffic encryption enforced
- DDoS protection configured

Compute components:
- HTTPS enforcement
- Authentication configured
- Monitoring enabled
- Security patches applied
- Resource limits defined

Storage components:
- Encryption in transit/at rest
- Access policies defined
- Versioning enabled
- Backup configured
- Network restrictions applied
"""