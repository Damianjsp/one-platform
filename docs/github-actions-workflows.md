# GitHub Actions Workflows Guide

This document explains the two-workflow approach for managing Atmos infrastructure operations in GitHub Actions.

## Overview

The platform uses two complementary workflows to handle different infrastructure deployment scenarios:

1. **`atmos-stack-operations.yml`** - For dependency-aware planning and deployment of affected components
2. **`atmos-operations.yml`** - For individual component operations

## Workflow 1: Stack Operations (Recommended)

**File**: `.github/workflows/atmos-stack-operations.yml`

### Purpose
- Handles dependency-aware planning and deployment
- Uses CloudPosse official GitHub Actions
- Automatically determines affected components
- Manages component dependencies correctly
- Filters out abstract components automatically

### Key Features
- **Affected Component Detection**: Uses `cloudposse/github-action-atmos-affected-stacks` to determine which components need updates
- **Parallel Processing**: Plans/applies components in parallel with proper dependency handling
- **Official Actions**: Uses `cloudposse/github-action-atmos-terraform-plan` and `cloudposse/github-action-atmos-terraform-apply`
- **Matrix Strategy**: Executes operations across multiple components simultaneously
- **Abstract Component Filtering**: Automatically skips abstract components

### When to Use
- **Recommended for most operations**
- When you need to deploy multiple related components
- When terraform output references need to be resolved
- For dependency-aware planning
- When you want to leverage Atmos' built-in dependency management

### Usage Example
```yaml
# Workflow Dispatch Parameters
Action: plan
Stack: core-eus-dev
Include Dependents: false
```

### Workflow Steps
1. **Affected Detection**: Determines which components are affected by changes
2. **Matrix Planning**: Plans all affected components in parallel
3. **Manual Approval**: Requires approval for apply/destroy operations
4. **Parallel Execution**: Executes operations across affected components

### Benefits
- ✅ Leverages Atmos' built-in dependency resolution
- ✅ Uses official CloudPosse actions (maintained and supported)
- ✅ Handles terraform output references correctly
- ✅ Automatic abstract component filtering
- ✅ Parallel processing for faster execution
- ✅ Proper error handling and reporting

## Workflow 2: Individual Component Operations

**File**: `.github/workflows/atmos-operations.yml`

### Purpose
- Handles single component operations
- Simplified workflow for specific component management
- Direct component targeting without dependency resolution

### Key Features
- **Single Component Focus**: Operates on one component at a time
- **Manual Component Selection**: Requires explicit component name input
- **Abstract Component Validation**: Prevents operations on abstract components
- **Simplified Logic**: Streamlined for single-component operations

### When to Use
- When you need to operate on a single, specific component
- For debugging or testing individual components
- When you want direct control over component operations
- For emergency fixes to specific components

### Usage Example
```yaml
# Workflow Dispatch Parameters
Action: plan
Component: azure-storage-account-general
Stack: core-eus-dev
```

### Limitations
- ⚠️ May fail if terraform output references are not resolved
- ⚠️ No dependency resolution
- ⚠️ Single component at a time
- ⚠️ Requires manual component name specification

### Benefits
- ✅ Simple and direct
- ✅ Fast execution for single components
- ✅ Good for debugging and testing
- ✅ Minimal complexity

## Component Types

### Abstract Components
Components marked with `metadata.type: abstract` in catalog defaults:
- `azure-app-service-plan`
- `azure-function-app`
- `azure-keyvault`
- `azure-storage-account`
- `azure-private-endpoint`

These components **cannot be deployed directly** and serve as templates for concrete instances.

### Concrete Components
Actual deployable component instances:
- `azure-app-service-plan-web`
- `azure-function-app-api`
- `azure-keyvault-dev`
- `azure-storage-account-general`
- `azure-private-endpoint-storage-blob`

## Recommendations

### For Most Operations
**Use `atmos-stack-operations.yml`** because:
- It handles dependencies correctly
- It uses official CloudPosse actions
- It provides better error handling
- It's designed for production use

### For Individual Component Operations
**Use `atmos-operations.yml`** when:
- You need to operate on a single component
- You're debugging or testing
- You need emergency fixes
- Dependencies are already resolved

### For New Stacks
**Use `atmos-stack-operations.yml`** because:
- It will plan components in proper dependency order
- It handles terraform output references correctly
- It's less likely to fail due to missing dependencies

## Troubleshooting

### Common Issues

#### "Cannot plan abstract component"
**Problem**: Trying to operate on an abstract component
**Solution**: Use the concrete component instance name instead

#### "Terraform output reference not resolved"
**Problem**: Component depends on outputs from other components that haven't been deployed
**Solution**: Use `atmos-stack-operations.yml` for dependency-aware planning

#### "Component not found in stack"
**Problem**: Component name doesn't exist in the specified stack
**Solution**: Check `atmos list components -s STACK_NAME` for available components

## Migration Guide

### From Old Workflow to New Approach

1. **For Affected Planning**: Use `atmos-stack-operations.yml` instead of `affected` in the old workflow
2. **For All Components**: Use `atmos-stack-operations.yml` with appropriate stack configuration
3. **For Single Components**: Use `atmos-operations.yml` with concrete component names

### Example Migration

**Old Approach**:
```yaml
Action: plan
Component: affected
Stack: core-eus-dev
```

**New Approach**:
```yaml
# Use atmos-stack-operations.yml
Action: plan
Stack: core-eus-dev
Include Dependents: false
```

## Best Practices

1. **Prefer Stack Operations**: Use `atmos-stack-operations.yml` for most operations
2. **Use Concrete Components**: Always specify concrete component instances, not abstract components
3. **Test in Development**: Test component changes in development stacks first
4. **Monitor Dependencies**: Be aware of component dependencies when planning operations
5. **Review Plans**: Always review terraform plans before applying changes
6. **Use Manual Approval**: Keep manual approval enabled for apply/destroy operations

## Future Enhancements

- Integration with Atlantis for PR-based deployments
- Enhanced error reporting and notifications
- Automatic rollback capabilities
- Integration with monitoring and alerting systems