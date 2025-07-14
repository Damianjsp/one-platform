#!/bin/bash

# Atmos Component Validation Script
# Usage: ./validate-component.sh <component> <stack>
# Example: ./validate-component.sh azure-subnet core-eus-dev

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    print_status $RED "Usage: $0 <component> <stack>"
    print_status $YELLOW "Example: $0 azure-subnet core-eus-dev"
    exit 1
fi

COMPONENT=$1
STACK=$2

print_status $BLUE "🔍 Validating component: $COMPONENT in stack: $STACK"

# Change to the project root directory (assuming script is in scripts/)
cd "$(dirname "$0")/.."

# Check Terraform formatting for the specific component
print_status $YELLOW "🎨 Checking Terraform formatting for component: $COMPONENT..."
COMPONENT_DIR="atmos/components/terraform/modules/$COMPONENT"
if [ -d "$COMPONENT_DIR" ]; then
    cd "$COMPONENT_DIR"
    if terraform fmt -check=true -diff=true; then
        print_status $GREEN "✅ Terraform files are properly formatted"
    else
        print_status $RED "❌ Terraform files are not properly formatted"
        print_status $YELLOW "Run 'terraform fmt' in $COMPONENT_DIR to fix formatting"
        exit 1
    fi
    cd - > /dev/null
else
    print_status $RED "❌ Component directory not found: $COMPONENT_DIR"
    exit 1
fi

# Validate Terraform syntax for the component
print_status $YELLOW "✅ Validating Terraform syntax for component: $COMPONENT..."
cd "$COMPONENT_DIR"
terraform init -backend=false > /dev/null 2>&1
if terraform validate; then
    print_status $GREEN "✅ Terraform syntax is valid"
    cd - > /dev/null
else
    print_status $RED "❌ Terraform validation failed"
    exit 1
fi

# Change to atmos directory for Atmos commands (where atmos.yaml is located)
cd atmos

# Check if component is abstract
print_status $YELLOW "🔍 Checking if component is abstract..."
COMPONENT_INFO=$(atmos describe component $COMPONENT -s $STACK --format=json 2>/dev/null || echo "{}")
COMPONENT_TYPE=$(echo "$COMPONENT_INFO" | jq -r '.metadata.type // "concrete"')

if [ "$COMPONENT_TYPE" = "abstract" ]; then
    print_status $YELLOW "⏭️  Component $COMPONENT is marked as abstract - skipping validation"
    print_status $GREEN "✅ Abstract component validation completed (skipped)"
    exit 0
fi

# Validate stack configuration
print_status $YELLOW "📋 Validating stack configuration..."
if atmos validate stacks; then
    print_status $GREEN "✅ Stack configuration is valid"
else
    print_status $RED "❌ Stack configuration validation failed"
    exit 1
fi

# Generate terraform configuration
print_status $YELLOW "🔧 Generating Terraform configuration..."
if atmos terraform generate varfile $COMPONENT -s $STACK > /dev/null 2>&1; then
    print_status $GREEN "✅ Terraform varfile generated successfully"
else
    print_status $RED "❌ Failed to generate Terraform varfile"
    exit 1
fi

# Run terraform plan
print_status $YELLOW "📦 Running Terraform plan..."
if atmos terraform plan $COMPONENT -s $STACK; then
    print_status $GREEN "✅ Terraform plan completed successfully"
else
    print_status $RED "❌ Terraform plan failed"
    exit 1
fi

print_status $GREEN "🎉 Component $COMPONENT validation completed successfully for stack $STACK"