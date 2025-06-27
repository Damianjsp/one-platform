# One Platform

[![Latest Release](https://img.shields.io/github/v/release/Damianjsp/one-platform)](https://github.com/Damianjsp/one-platform/releases)
[![License](https://img.shields.io/github/license/Damianjsp/one-platform)](LICENSE)
[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.9.0-blue)](https://www.terraform.io/)
[![Azure Provider](https://img.shields.io/badge/azurerm-4.23.0-blue)](https://registry.terraform.io/providers/hashicorp/azurerm/)
[![Atmos](https://img.shields.io/badge/atmos-latest-green)](https://atmos.tools/)
[![Semantic Versioning](https://img.shields.io/badge/semver-enabled-brightgreen)](https://semver.org/)

One Platform is a comprehensive infrastructure-as-code solution designed to manage Azure deployments across multiple environments with consistency, reliability, and best practices using Atmos orchestration.

## 🚀 Overview

This repository provides a centralized platform for managing infrastructure deployments, leveraging [Atmos](https://atmos.tools/) as an orchestration layer to manage Terraform components and stacks across environments. It provides a scalable and maintainable approach to infrastructure management using component-based architecture.

## ✨ Key Features

- **🏗️ Component-Based Architecture**: Reusable Terraform modules organized by functionality
- **🌍 Multi-Environment Support**: Deploy to development, staging, and production environments with consistent configurations
- **☁️ Azure Native**: Comprehensive Azure Public Cloud support with proper resource naming and tagging
- **🏷️ Standardized Naming**: Consistent resource naming using optimized `{environment}{stage}{name}{namespace}` pattern
- **♻️ DRY Configuration**: Reduce duplication using Atmos stacks and component inheritance
- **🔒 Private Connectivity**: Secure Azure services connectivity using private endpoints
- **🔧 Validation Tools**: Automated stack and component validation scripts
- **📋 Semantic Versioning**: Automated tagging and versioning on PR merges

## 🧩 Available Components

| Component | Description | Dependencies |
|-----------|-------------|--------------|
| `azure-resource-group` | Azure Resource Groups | None |
| `azure-vnet` | Azure Virtual Networks | Resource Groups |
| `azure-subnet` | Azure Subnets | Resource Groups, VNets |
| `azure-private-endpoint` | Azure Private Endpoints | Resource Groups, Subnets |
| `azure-storage-account` | Azure Storage Accounts (V2, Data Lake Gen2) | Resource Groups, Private Endpoints |

## 🏗️ Architecture

### Stack Structure
```
atmos/
├── components/terraform/modules/     # Reusable Terraform modules
├── stacks/catalog/                   # Component defaults and mixins
├── stacks/orgs/                      # Organization defaults
└── stacks/azure/                     # Environment-specific configurations
```

### Naming Convention
Resources follow the pattern: `{environment}{stage}{name}{namespace}`

**Example**: `eusdevnetworklazylabs`
- `eus` = environment (East US)
- `dev` = stage (development)
- `network` = component name
- `lazylabs` = namespace (organization)

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.9.0
- [Atmos CLI](https://atmos.tools/quick-start/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) with active subscription
- [jq](https://stedolan.github.io/jq/) for JSON processing

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Damianjsp/one-platform.git
   cd one-platform
   ```

2. **Navigate to Atmos directory**
   ```bash
   cd atmos
   ```

3. **Authenticate with Azure**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

4. **Validate configuration**
   ```bash
   atmos validate stacks
   ```

### Basic Usage

```bash
# List available stacks
atmos list stacks

# Plan a component
atmos terraform plan azure-resource-group -s core-eus-dev

# Apply a component
atmos terraform apply azure-resource-group -s core-eus-dev

# Validate all components
./scripts/validate-all-stacks.sh
```

## 📋 Validation & Testing

### Individual Component Validation
```bash
./scripts/validate-component.sh <component> <stack>
```

### All Stacks Validation
```bash
# Validate all stacks
./scripts/validate-all-stacks.sh

# Validate specific environment
./scripts/validate-all-stacks.sh dev
```

## 🔧 Development

### Adding New Components

1. **Create Terraform module**
   ```bash
   mkdir atmos/components/terraform/modules/azure-<service>
   ```

2. **Create catalog structure**
   ```bash
   mkdir -p atmos/stacks/catalog/azure-<service>/mixins
   ```

3. **Follow the patterns**
   - Use `cloudposse/label/null` for naming
   - Include `var.enabled` for conditional creation
   - Follow the established file structure
   - Add to stack imports

### Component Development Guidelines

- **Naming**: Use clear, descriptive component names
- **Dependencies**: Reference other components using Atmos interpolation
- **Variables**: Include all standard label module variables
- **Outputs**: Provide comprehensive outputs for dependent components
- **Documentation**: Include README.md with usage examples

## 🔗 Multiple Instance Support

The platform supports creating multiple instances of the same component with different configurations:

```yaml
# Multiple private endpoints for different services
azure-private-endpoint-storage:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "storage"
    subresource_names: ["blob"]

azure-private-endpoint-keyvault:
  metadata:
    component: azure-private-endpoint
  vars:
    name: "keyvault"
    subresource_names: ["vault"]
```

See [Multiple Private Endpoints Patterns](docs/multiple-private-endpoints-patterns.md) for detailed examples.

## 📁 Project Structure

```
one-platform/
├── atmos/
│   ├── atmos.yaml                    # Atmos configuration
│   ├── components/terraform/modules/ # Terraform modules
│   │   ├── azure-resource-group/
│   │   ├── azure-vnet/
│   │   ├── azure-subnet/
│   │   ├── azure-private-endpoint/
│   │   └── azure-storage-account/
│   └── stacks/
│       ├── catalog/                  # Component defaults and mixins
│       ├── orgs/                     # Organization defaults
│       └── azure/                    # Environment stacks
├── scripts/                          # Validation and utility scripts
├── docs/                            # Additional documentation
├── CLAUDE.md                        # Claude Code AI assistant guidance
├── CONTRIBUTING.md                  # Contribution guidelines
└── LICENSE                          # License information
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on:

- How to submit issues and feature requests
- Development workflow and coding standards
- Pull request process
- Code of conduct

## 📜 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🏷️ Versioning

This project uses [Semantic Versioning](https://semver.org/) with automated tagging:

- **Patch**: Bug fixes and small improvements (automatic)
- **Minor**: New features and components (add `v-minor` label to PR)
- **Major**: Breaking changes (add `v-major` label to PR)

## 🛠️ Backend Configuration

Terraform state is managed using Azure Storage:

- **Resource Group**: `atmos-rsg-core`
- **Storage Account**: `statomicore`
- **Container**: `corestate`

## 📊 Status

- **Latest Release**: [![Latest Release](https://img.shields.io/github/v/release/Damianjsp/one-platform)](https://github.com/Damianjsp/one-platform/releases)
- **Build Status**: All components validated ✅
- **Coverage**: 5 Azure components available
- **Environments**: Development environment configured

## 📚 Additional Resources

- [Atmos Documentation](https://atmos.tools/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Component Development Guide](CLAUDE.md)

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/Damianjsp/one-platform/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Damianjsp/one-platform/discussions)
- **Documentation**: Check the `docs/` directory and component READMEs

---

<div align="center">
  <sub>Built with ❤️ using <a href="https://atmos.tools/">Atmos</a> and <a href="https://www.terraform.io/">Terraform</a></sub>
</div>