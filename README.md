# One Platform

[![Latest Release](https://img.shields.io/badge/release-v1.2.0-blue)](https://github.com/oneplatform-ecosystem/infrastructure-platform/releases/tag/v1.2.0)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)
[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.9.0-blue)](https://www.terraform.io/)
[![Azure Provider](https://img.shields.io/badge/azurerm-4.23.0-blue)](https://registry.terraform.io/providers/hashicorp/azurerm/)
[![Atmos](https://img.shields.io/badge/atmos-1.182.0-green)](https://atmos.tools/)
[![Semantic Versioning](https://img.shields.io/badge/semver-enabled-brightgreen)](https://semver.org/)

One Platform is a comprehensive infrastructure-as-code solution designed to manage Azure deployments across multiple environments with consistency, reliability, and best practices using Atmos orchestration.

## 🚀 Overview

This repository provides a centralized platform for managing infrastructure deployments, leveraging [Atmos](https://atmos.tools/) as an orchestration layer to manage Terraform components and stacks across environments. It provides a scalable and maintainable approach to infrastructure management using component-based architecture.

## 🚀 Quick Start

⚠️ **Important**: Before deploying, you must configure your Azure credentials and update placeholder values.

**📋 Prerequisites and Setup**: Follow the [SETUP.md](SETUP.md) guide for complete installation and configuration instructions including:
- Azure CLI, Terraform >= 1.9.0, Atmos CLI installation
- Azure Service Principal creation
- Backend storage account configuration
- Environment variable setup

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
| `azure-rsg` | Azure Resource Groups | None |
| `azure-vnet` | Azure Virtual Networks | Resource Groups |
| `azure-subnet` | Azure Subnets | Resource Groups, VNets |
| `azure-nsg` | Azure Network Security Groups | Resource Groups, Subnets |
| `azure-private-endpoint` | Azure Private Endpoints | Resource Groups, Subnets |
| `azure-storage-account` | Azure Storage Accounts (V2, Data Lake Gen2) | Resource Groups |
| `azure-keyvault` | Azure Key Vault (keys, secrets, certificates) | Resource Groups |
| `azure-app-service-plan` | Azure App Service Plans for hosting applications | Resource Groups |
| `azure-function-app` | Azure Function Apps for serverless computing | Resource Groups, App Service Plans, Storage Accounts |

## 🏗️ Architecture

### Stack Structure
```
atmos/
├── components/terraform/modules/     # Reusable Terraform modules
│   ├── azure-rsg/                    # Resource group management  
│   ├── azure-vnet/                   # Virtual network configuration
│   ├── azure-subnet/                 # Subnet management with private endpoint support
│   ├── azure-nsg/                    # Network security groups
│   ├── azure-private-endpoint/       # Private endpoint connectivity
│   ├── azure-storage-account/        # Storage accounts (V2, ADLS Gen2)
│   ├── azure-keyvault/               # Key Vault for secrets management
│   ├── azure-app-service-plan/       # App Service Plans for hosting
│   └── azure-function-app/           # Function Apps for serverless computing
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

## 🚀 Basic Usage

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/oneplatform-ecosystem/infrastructure-platform.git
   cd infrastructure-platform
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

# Deploy Key Vault components
atmos terraform apply azure-keyvault-dev -s core-eus-dev
atmos terraform apply azure-keyvault-secure -s core-eus-dev

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

## 🔒 Security Features

### Key Vault Implementation
The platform includes comprehensive Azure Key Vault integration with two deployment patterns:

#### Development Key Vault (`azure-keyvault-dev`)
- **Public Access**: Enabled for development convenience
- **Use Cases**: Development secrets, connection strings, API endpoints
- **Access Policies**: Service principal with full permissions
- **Example Secrets**: Database connections, API base URLs

#### Secure Key Vault (`azure-keyvault-secure`) 
- **Private Access Only**: Network access through private endpoint
- **Enhanced Security**: Public network access disabled
- **Network ACLs**: Deny all public traffic by default
- **Use Cases**: Production secrets, JWT signing keys, encryption keys
- **Purge Protection**: Enabled for data safety

### Private Endpoint Connectivity
- **VNet Integration**: Secure access from `10.0.1.0/24` subnet
- **DNS Resolution**: Automatic private DNS integration
- **Service Endpoints**: Support for vault, blob, dfs, file, table services
- **Network Policies**: Subnet configured for private endpoint traffic

## 📁 Project Structure

```
one-platform/
├── atmos/
│   ├── atmos.yaml                    # Atmos configuration
│   ├── components/terraform/modules/ # Terraform modules
│   │   ├── azure-resource-group/
│   │   ├── azure-vnet/
│   │   ├── azure-subnet/
│   │   ├── azure-nsg/
│   │   ├── azure-private-endpoint/
│   │   ├── azure-storage-account/
│   │   └── azure-keyvault/
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

- **Resource Group**: `${ATMOS_BACKEND_RESOURCE_GROUP}` (configured in organization defaults)
- **Storage Account**: `${ATMOS_BACKEND_STORAGE_ACCOUNT}` (configured in organization defaults)
- **Container**: `${ATMOS_BACKEND_CONTAINER}` (configured in organization defaults)

## 📊 Status

- **Latest Release**: [![Latest Release](https://img.shields.io/badge/release-v1.2.0-blue)](https://github.com/oneplatform-ecosystem/infrastructure-platform/releases/tag/v1.2.0)
- **Build Status**: All components validated ✅
- **Coverage**: 9 Azure components available
- **Environments**: Development environment fully deployed
- **Infrastructure**: Core networking, storage, and security services operational

## 📚 Additional Resources

- [Atmos Documentation](https://atmos.tools/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Component Development Guide](CLAUDE.md)

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/oneplatform-ecosystem/infrastructure-platform/issues)
- **Discussions**: [GitHub Discussions](https://github.com/oneplatform-ecosystem/infrastructure-platform/discussions)
- **Documentation**: Check the `docs/` directory and component READMEs

---

<div align="center">
  <sub>Built with ❤️ using <a href="https://atmos.tools/">Atmos</a> and <a href="https://www.terraform.io/">Terraform</a></sub>
</div>