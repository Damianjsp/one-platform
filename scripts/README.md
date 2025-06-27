# Atmos Validation Scripts

This directory contains scripts to validate Atmos stacks and components.

## Scripts

### `validate-component.sh`
Validates a single component in a specific stack.

**Usage:**
```bash
./scripts/validate-component.sh <component> <stack>
```

**Examples:**
```bash
# Validate azure-subnet component in core-eus-dev stack
./scripts/validate-component.sh azure-subnet core-eus-dev

# Validate azure-vnet component in core-eus-dev stack
./scripts/validate-component.sh azure-vnet core-eus-dev
```

**What it does:**
1. Validates stack configuration
2. Generates Terraform varfile
3. Runs `terraform plan`
4. Reports success/failure with colored output

### `validate-all-stacks.sh`
Validates all components across all stacks or filtered stacks.

**Usage:**
```bash
./scripts/validate-all-stacks.sh [stack-pattern]
```

**Examples:**
```bash
# Validate all stacks
./scripts/validate-all-stacks.sh

# Validate only dev stacks
./scripts/validate-all-stacks.sh dev

# Validate stacks containing "eus"
./scripts/validate-all-stacks.sh eus
```

**What it does:**
1. Runs global stack configuration validation
2. Discovers all available stacks (optionally filtered)
3. For each stack, finds all Terraform components
4. Validates each component with `terraform plan`
5. Generates a detailed results summary
6. Saves results to timestamped file in `/tmp/`

## Features

- **Colored output** for easy reading
- **Error handling** with proper exit codes
- **Progress tracking** with status indicators
- **Detailed logging** of failures
- **Summary reports** for batch validations

## Prerequisites

- Atmos CLI installed and configured
- Terraform installed
- Azure CLI authenticated (for Azure resources)
- `jq` installed for JSON processing

## Integration

These scripts can be integrated into:
- CI/CD pipelines
- Pre-commit hooks
- Development workflows
- Infrastructure validation processes