# Contributing to One Platform

First off, thank you for considering contributing to One Platform! It's people like you that make One Platform such a great tool.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Pull Request Process](#pull-request-process)
- [Component Development](#component-development)
- [Testing](#testing)
- [Documentation](#documentation)

## 🤝 Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Expected Behavior

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.9.0
- [Atmos CLI](https://atmos.tools/quick-start/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [jq](https://stedolan.github.io/jq/)
- Git configured with your name and email

### Development Setup

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/one-platform.git
   cd one-platform
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/Damianjsp/one-platform.git
   ```

3. **Authenticate with Azure**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

4. **Validate setup**
   ```bash
   cd atmos
   atmos validate stacks
   ```

## 🛠️ How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title** describing the issue
- **Detailed description** of the problem
- **Steps to reproduce** the behavior
- **Expected vs actual behavior**
- **Environment details** (OS, Terraform version, etc.)
- **Relevant logs** or error messages

**Use this template:**
```markdown
## Bug Description
A clear description of what the bug is.

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. Run command '...'
4. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- OS: [e.g., macOS 12.0]
- Terraform: [e.g., 1.9.0]
- Atmos: [e.g., 1.45.0]
- Azure Provider: [e.g., 4.23.0]

## Additional Context
Any other context about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Include:

- **Clear title** describing the enhancement
- **Detailed description** of the proposed feature
- **Use cases** explaining why this would be useful
- **Possible implementation** if you have ideas

### Contributing Code

#### Types of Contributions

- **New Azure components** (Storage, Key Vault, SQL, etc.)
- **Bug fixes** in existing components
- **Documentation improvements**
- **Testing enhancements**
- **Tooling and automation**

## 🔄 Development Workflow

### Branch Naming Convention

- `feature/component-name` - New components
- `feature/description` - New features
- `fix/issue-description` - Bug fixes
- `docs/topic` - Documentation updates
- `chore/task` - Maintenance tasks

### Workflow Steps

1. **Create a branch**
   ```bash
   git checkout -b feature/azure-storage-account
   ```

2. **Make your changes**
   - Follow coding standards
   - Add tests
   - Update documentation

3. **Test your changes**
   ```bash
   # Validate stacks
   atmos validate stacks
   
   # Test specific component
   ./scripts/validate-component.sh azure-storage-account core-eus-dev
   
   # Test all stacks
   ./scripts/validate-all-stacks.sh
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add Azure Storage Account component"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/azure-storage-account
   ```

## 📝 Coding Standards

### Terraform Standards

- **File Structure**: Follow the established pattern
  ```
  azure-component/
  ├── main.tf
  ├── variables.tf
  ├── outputs.tf
  ├── providers.tf
  ├── backend.tf.json
  ├── providers_override.tf.json
  └── README.md
  ```

- **Naming**: Use clear, descriptive names
- **Comments**: Add comments for complex logic
- **Variables**: Include descriptions and types
- **Outputs**: Provide comprehensive outputs

### Required Patterns

1. **Use cloudposse/label module**
   ```hcl
   module "label" {
     source  = "cloudposse/label/null"
     version = "0.25.0"
     # ... configuration
   }
   ```

2. **Conditional resource creation**
   ```hcl
   resource "azurerm_resource" "this" {
     count = var.enabled ? 1 : 0
     # ... configuration
   }
   ```

3. **Consistent variable structure**
   ```hcl
   variable "enabled" {
     description = "Set to false to prevent the module from creating any resources"
     type        = bool
     default     = true
   }
   ```

### Atmos Standards

- **Catalog Structure**: Follow the established pattern
  ```
  stacks/catalog/component-name/
  ├── defaults.yaml
  └── mixins/
      ├── dev.yaml
      └── prod.yaml
  ```

- **Component References**: Use Atmos interpolation
  ```yaml
  resource_group_name: "${var.environment}${var.stage}${components.terraform.azure-resource-group.vars.name}${var.namespace}"
  ```

## 🔍 Pull Request Process

### Before Submitting

- [ ] Tests pass (`./scripts/validate-all-stacks.sh`)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated (if applicable)
- [ ] Component README.md created/updated
- [ ] Examples provided

### PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Component Details (if applicable)
- **Component Name**: azure-storage-account
- **Dependencies**: azure-resource-group
- **Azure Services**: Storage Account

## Testing
- [ ] Stack validation passes
- [ ] Component validation passes
- [ ] Manual testing completed

## Documentation
- [ ] Component README.md updated
- [ ] Usage examples provided
- [ ] CLAUDE.md updated (if needed)

## Checklist
- [ ] Code follows project standards
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
```

### Review Process

1. **Automated checks** must pass
2. **At least one review** from maintainers
3. **All conversations resolved**
4. **Tests passing**

### Versioning Labels

Add appropriate labels to your PR for semantic versioning:

- No label = **patch** version (bug fixes, small improvements)
- `v-minor` = **minor** version (new features, new components)
- `v-major` = **major** version (breaking changes)

## 🧩 Component Development

### New Component Checklist

- [ ] **Terraform module** created following patterns
- [ ] **Variables** include all label module variables
- [ ] **Outputs** provide comprehensive information
- [ ] **Catalog defaults** created
- [ ] **Environment mixins** created (dev/prod)
- [ ] **Stack integration** added
- [ ] **README.md** with usage examples
- [ ] **Validation** tests pass

### Component Guidelines

1. **Single Responsibility**: Each component should have a clear, single purpose
2. **Reusability**: Design for multiple environments and use cases
3. **Dependencies**: Clearly define and document dependencies
4. **Configuration**: Support environment-specific configurations
5. **Naming**: Follow naming conventions consistently

## 🧪 Testing

### Validation Requirements

All contributions must pass:

```bash
# Stack configuration validation
atmos validate stacks

# Individual component validation
./scripts/validate-component.sh <component> <stack>

# All stacks validation
./scripts/validate-all-stacks.sh
```

### Testing Best Practices

- Test in isolated environment
- Verify component interdependencies
- Test multiple instances when applicable
- Validate naming conventions
- Check resource tagging

## 📚 Documentation

### Required Documentation

1. **Component README.md**
   - Description and purpose
   - Usage examples
   - Input variables table
   - Output values table
   - Requirements and dependencies

2. **Stack Examples**
   - Include commented examples in stack files
   - Show different configuration scenarios

3. **Update CLAUDE.md**
   - Add new component to current components list
   - Document any new patterns or conventions

### Documentation Standards

- Use clear, concise language
- Provide practical examples
- Include code snippets
- Link to relevant Azure documentation
- Use tables for structured information

## 🏷️ Semantic Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes to existing components
- **MINOR**: New components or non-breaking features
- **PATCH**: Bug fixes and small improvements

Versioning is automated based on PR labels:
- No label = patch
- `v-minor` label = minor
- `v-major` label = major

## 🆘 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Documentation**: Check existing docs and component READMEs
- **Code Review**: Ask for feedback on your approach before submitting large changes

## 🙏 Recognition

Contributors are recognized in:
- GitHub contributors list
- Release notes
- Component documentation (for significant contributions)

Thank you for contributing to One Platform! 🚀