# Security Directory

This directory contains security tools, configurations, and reports for the One Platform infrastructure.

## 📁 Directory Structure

```
security/
├── README.md                           # This file - explains security directory structure
├── checkov.yaml                        # Checkov configuration for security scanning
├── checkov.baseline                    # Baseline file for existing security issues (when created)
├── checkov-policies/                   # Custom One Platform security checks
│   ├── azure_resource_group_checks.py  # Resource group validation (5 checks)
│   ├── azure_vnet_checks.py            # Virtual network security (6 checks)
│   ├── azure_subnet_checks.py          # Subnet configuration (5 checks)
│   ├── azure_nsg_checks.py             # Network security groups (5 checks)
│   ├── azure_private_endpoint_checks.py # Private endpoint validation (6 checks)
│   ├── azure_storage_account_checks.py # Storage security (6 checks)
│   ├── azure_keyvault_checks.py        # Key vault security (7 checks)
│   ├── azure_app_service_plan_checks.py # App service plans (6 checks)
│   ├── azure_function_app_checks.py    # Function app security (7 checks)
│   └── component_template.py           # Template for new component checks
└── reports/                            # Generated security reports with date-based naming
    ├── checkov-all-all-09072025-1430.html
    ├── checkov-azure-keyvault-core-eus-dev-09072025-1445.html
    └── checkov-azure-storage-account-core-eus-dev-09072025-1500.html
```

## 🔒 Security Scanning with Checkov

### Overview
[Checkov](https://www.checkov.io/) is a static code analysis tool for infrastructure as code (IaC) that scans cloud infrastructure provisioned using Terraform and detects security and compliance misconfigurations.

**One Platform Enhancement**: Every component in the stack has custom Checkov checks to ensure consistency, security, and compliance with platform standards.

### Configuration
- **File**: `checkov.yaml`
- **Purpose**: Defines Azure-specific security policies and scanning rules
- **Custom Policies**: `checkov-policies/` directory with One Platform specific checks
- **Built-in Policies**: Azure security best practices and CIS benchmarks
- **Total Checks**: 58+ custom checks covering all stack components
- **Policies**: Focuses on CRITICAL and HIGH severity issues

### Report Generation
Reports are automatically generated with the following features:

#### Naming Convention
- **Format**: `checkov-{component}-{stack}-{DDMMYYYY-HHMM}.{extension}`
- **Date Format**: DD/MM/YYYY-HH:MM (e.g., 09072025-1430 for July 9, 2025 at 2:30 PM)
- **Examples**:
  - `checkov-azure-keyvault-core-eus-dev-09072025-1430.html`
  - `checkov-all-all-09072025-1445.html`
  - `checkov-azure-storage-account-core-eus-dev-09072025-1500.json`

#### HTML Reports (Default)
HTML reports are designed for easy reading by both technical and non-technical stakeholders:

- **📊 Executive Summary**: Visual cards showing total checks, passed/failed counts, and severity breakdown
- **🚨 Failed Checks**: Detailed findings with severity badges and descriptions
- **✅ Passed Checks**: Summary of successful security validations
- **⏭️ Skipped Checks**: List of checks that were skipped with reasons
- **📱 Responsive Design**: Works on desktop and mobile devices
- **🎨 Color-coded Severity**: Critical (red), High (orange), Medium (yellow), Low (green)

#### Other Formats
- **JSON**: Machine-readable format for integration with other tools
- **SARIF**: Static Analysis Results Interchange Format for security tools
- **JUnit**: XML format for CI/CD integration
- **CSV**: Spreadsheet-compatible format for analysis

### Baseline Management
Use baselines to manage existing security issues and focus on new problems:

- **File**: `checkov.baseline`
- **Purpose**: Ignore known existing issues to focus on new security problems
- **Creation**: Run `./scripts/checkov-scan.sh --create-baseline`
- **Usage**: Automatically used when the baseline file exists

## 🛠️ Usage Examples

### Basic Scanning
```bash
# Scan single component (generates HTML report)
./scripts/checkov-scan.sh azure-keyvault core-eus-dev

# Scan all components
./scripts/checkov-scan.sh --all

# Scan with specific format
./scripts/checkov-scan.sh --format json azure-keyvault core-eus-dev
```

### Advanced Options
```bash
# Create baseline for existing issues
./scripts/checkov-scan.sh --create-baseline

# Scan using baseline (ignore existing issues)
./scripts/checkov-scan.sh --baseline security/checkov.baseline azure-keyvault core-eus-dev

# Skip specific checks
./scripts/checkov-scan.sh --skip-check CKV_AZURE_1,CKV_AZURE_2 azure-keyvault core-eus-dev

# Warning mode (don't fail on issues)
./scripts/checkov-scan.sh --no-fail azure-keyvault core-eus-dev
```

## 🎯 Security Policy Coverage

### One Platform Custom Checks
- **Resource Groups**: Required tags, approved regions, naming patterns (5 checks)
- **Virtual Networks**: IP ranges, DDoS protection, subnet planning (6 checks)
- **Subnets**: Private endpoints, address validation, VNet references (5 checks)
- **Network Security Groups**: Security rules, inbound restrictions (5 checks)
- **Private Endpoints**: Service connections, subnet placement (6 checks)
- **Storage Accounts**: Encryption, HTTPS, network rules (6 checks)
- **Key Vaults**: Soft delete, purge protection, access policies (7 checks)
- **App Service Plans**: SKU validation, OS configuration (6 checks)
- **Function Apps**: HTTPS, TLS, runtime configuration (7 checks)

### Standard Pattern Enforcement
- **Label Module Usage**: Consistent naming and tagging across all components
- **Conditional Creation**: `var.enabled` pattern for resource management
- **Resource References**: Proper dependency management
- **Location Validation**: Approved Azure regions enforcement

### Compliance Standards
- **CIS Benchmarks**: Industry-standard security configurations
- **Azure Security Center**: Microsoft recommended security practices
- **One Platform Standards**: Consistency and operational excellence
- **GDPR/HIPAA**: Compliance-ready configurations where applicable

### Severity Levels
- **🔴 CRITICAL**: Must fix immediately - blocking deployment
- **🟠 HIGH**: Fix soon - blocking deployment
- **🟡 MEDIUM**: Fix when possible - warning only
- **🟢 LOW**: Consider fixing - informational
- **🔵 INFO**: Informational - no action required

## 🔄 CI/CD Integration

Security scanning is automatically integrated into the CI/CD pipeline:

- **GitHub Actions**: Runs on every PR and merge to main
- **Component-specific**: Scans only changed components for efficiency
- **Report Upload**: Failed scans upload reports as artifacts
- **PR Comments**: Failure notifications posted to pull requests

## 📋 Best Practices

### For Developers
1. **Run locally before committing**: Use `./scripts/checkov-scan.sh` to catch issues early
2. **Review HTML reports**: Easy-to-read format explains what needs to be fixed
3. **Use baselines wisely**: Create baselines for gradual security improvement
4. **Fix CRITICAL/HIGH first**: Focus on high-impact security issues

### For Security Teams
1. **Monitor reports regularly**: Check `security/reports/` for latest scans
2. **Update policies**: Modify `checkov.yaml` to add new security requirements
3. **Baseline management**: Regularly review and update baseline files
4. **Compliance tracking**: Use reports for audit and compliance documentation

### For Management
1. **HTML reports are executive-friendly**: Visual summaries and clear severity indicators
2. **Historical tracking**: Date-based naming allows trend analysis
3. **Compliance reporting**: Reports can be used for security audits
4. **Risk assessment**: Severity levels help prioritize security investments

## 🆕 Adding Checks for New Components

### Required Process
**🚨 IMPORTANT**: Every new component MUST have custom Checkov checks before deployment.

1. **Copy Template**
   ```bash
   cp security/checkov-policies/component_template.py security/checkov-policies/azure_{component}_checks.py
   ```

2. **Customize for Component**
   - Replace placeholders (`{COMPONENT_NAME}`, `{RESOURCE_TYPE}`, etc.)
   - Implement component-specific security validations
   - Follow standard check patterns (label module, conditional creation)

3. **Update Configuration**
   ```bash
   # Add new check IDs to security/checkov.yaml
   - CKV_OP_AZURE_{COMPONENT}_1  # Label module usage
   - CKV_OP_AZURE_{COMPONENT}_2  # Conditional creation
   # ... additional component-specific checks
   ```

4. **Test Implementation**
   ```bash
   ./scripts/checkov-scan.sh {component} core-eus-dev
   ```

### Check Categories by Component Type
- **Database**: Encryption, backup, access controls, network isolation
- **Networking**: Security groups, ACLs, private connectivity, traffic rules
- **Compute**: HTTPS enforcement, authentication, monitoring, resource limits
- **Storage**: Encryption policies, access controls, versioning, backup

## 🔧 Troubleshooting

### Common Issues
- **Checkov not found**: Install with `pip install checkov`
- **Permission denied**: Ensure script is executable: `chmod +x scripts/checkov-scan.sh`
- **Config not found**: Script will create default `checkov.yaml` if missing
- **No reports generated**: Check if `security/reports/` directory exists
- **Custom checks not loading**: Verify `external-checks-dir: checkov-policies` in config
- **Check ID conflicts**: Use unique `CKV_OP_AZURE_{COMPONENT}_{NUMBER}` format

### Getting Help
- **Checkov Documentation**: https://www.checkov.io/
- **Azure Security Benchmarks**: https://docs.microsoft.com/en-us/security/benchmark/azure/
- **Script Usage**: Run `./scripts/checkov-scan.sh --help`
- **Custom Check Development**: See `component_template.py` for guidance

## 📞 Support

For security-related questions or issues:
1. Check this README for common solutions
2. Review the generated HTML reports for detailed explanations
3. Consult the Checkov documentation for specific check details
4. Contact the infrastructure team for policy questions