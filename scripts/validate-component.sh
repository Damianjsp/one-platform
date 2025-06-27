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