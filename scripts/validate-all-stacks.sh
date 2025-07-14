#!/bin/bash

# Atmos All Stacks Validation Script
# Usage: ./validate-all-stacks.sh [stack-pattern]
# Example: ./validate-all-stacks.sh (validates all stacks)
# Example: ./validate-all-stacks.sh dev (validates only dev stacks)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Change to the project root directory (assuming script is in scripts/)
cd "$(dirname "$0")/.."

STACK_PATTERN=${1:-""}

print_status $BLUE "🚀 Starting comprehensive Atmos stack validation"

# Change to atmos directory for Atmos commands (where atmos.yaml is located)
cd atmos

# Global validation first
print_status $CYAN "🔍 Running global stack configuration validation..."
if atmos validate stacks; then
    print_status $GREEN "✅ Global stack configuration is valid"
else
    print_status $RED "❌ Global stack configuration validation failed"
    exit 1
fi

# Get list of all stacks
print_status $CYAN "📋 Discovering available stacks..."
STACKS=$(atmos list stacks --format=json | jq -r '.[] | select(.stack != null) | .stack' | sort | uniq)

if [ -z "$STACKS" ]; then
    print_status $RED "❌ No stacks found"
    exit 1
fi

# Filter stacks if pattern provided
if [ -n "$STACK_PATTERN" ]; then
    FILTERED_STACKS=$(echo "$STACKS" | grep "$STACK_PATTERN" || true)
    if [ -z "$FILTERED_STACKS" ]; then
        print_status $RED "❌ No stacks match pattern: $STACK_PATTERN"
        exit 1
    fi
    STACKS=$FILTERED_STACKS
    print_status $YELLOW "🔎 Filtering stacks with pattern: $STACK_PATTERN"
fi

print_status $BLUE "📦 Found stacks to validate:"
echo "$STACKS" | while read -r stack; do
    print_status $WHITE "  - $stack"
done

# Initialize counters
TOTAL_VALIDATIONS=0
SUCCESSFUL_VALIDATIONS=0
FAILED_VALIDATIONS=0

# Create results summary
RESULTS_FILE="/tmp/atmos-validation-results-$(date +%Y%m%d-%H%M%S).txt"
echo "Atmos Stack Validation Results - $(date)" > "$RESULTS_FILE"
echo "=======================================" >> "$RESULTS_FILE"

# Validate each stack
echo "$STACKS" | while read -r stack; do
    if [ -z "$stack" ]; then
        continue
    fi
    
    print_status $CYAN "🔧 Validating stack: $stack"
    
    # Get components for this stack
    COMPONENTS=$(atmos list components --stack="$stack" --format=json 2>/dev/null | jq -r '.[] | select(.component_type == "terraform") | .component' | sort | uniq || echo "")
    
    if [ -z "$COMPONENTS" ]; then
        print_status $YELLOW "⚠️  No Terraform components found for stack: $stack"
        echo "SKIP: $stack (no components)" >> "$RESULTS_FILE"
        continue
    fi
    
    print_status $BLUE "  Components found: $(echo "$COMPONENTS" | tr '\n' ' ')"
    
    STACK_FAILED=false
    
    # Validate each component in the stack
    echo "$COMPONENTS" | while read -r component; do
        if [ -z "$component" ]; then
            continue
        fi
        
        print_status $YELLOW "    🔍 Validating $component in $stack..."
        
        # Run terraform plan
        if atmos terraform plan "$component" -s "$stack" > "/tmp/atmos-plan-$component-$stack.log" 2>&1; then
            print_status $GREEN "    ✅ $component validation successful"
            echo "PASS: $stack/$component" >> "$RESULTS_FILE"
        else
            print_status $RED "    ❌ $component validation failed"
            echo "FAIL: $stack/$component" >> "$RESULTS_FILE"
            echo "      Error log: /tmp/atmos-plan-$component-$stack.log" >> "$RESULTS_FILE"
            STACK_FAILED=true
        fi
    done
    
    if [ "$STACK_FAILED" = true ]; then
        print_status $RED "❌ Stack $stack validation completed with errors"
    else
        print_status $GREEN "✅ Stack $stack validation completed successfully"
    fi
    
    echo "" >> "$RESULTS_FILE"
done

# Print summary
print_status $BLUE "📊 Validation Summary"
print_status $CYAN "Results saved to: $RESULTS_FILE"

# Display results summary
if [ -f "$RESULTS_FILE" ]; then
    TOTAL_TESTS=$(grep -c "PASS:\|FAIL:" "$RESULTS_FILE" || echo "0")
    PASSED_TESTS=$(grep -c "PASS:" "$RESULTS_FILE" || echo "0")
    FAILED_TESTS=$(grep -c "FAIL:" "$RESULTS_FILE" || echo "0")
    
    print_status $BLUE "Total validations: $TOTAL_TESTS"
    print_status $GREEN "Successful: $PASSED_TESTS"
    
    if [ "$FAILED_TESTS" -gt 0 ]; then
        print_status $RED "Failed: $FAILED_TESTS"
        print_status $RED "❌ Some validations failed. Check the results file for details."
        exit 1
    else
        print_status $GREEN "🎉 All validations passed successfully!"
    fi
fi