#!/bin/bash

# Checkov Security Scanner for Terraform
# This script runs Checkov security scans on Terraform configurations

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SECURITY_DIR="${PROJECT_ROOT}/security"
CHECKOV_REPORT_DIR="${SECURITY_DIR}/reports"
CHECKOV_CONFIG_FILE="${SECURITY_DIR}/checkov.yaml"
CHECKOV_BASELINE_FILE="${SECURITY_DIR}/checkov.baseline"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] [COMPONENT] [STACK]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help          Show this help message"
    echo "  -a, --all           Scan all components"
    echo "  -p, --plan          Scan Terraform plan files"
    echo "  -f, --format FORMAT Output format (cli, json, sarif, junit, csv) [default: cli]"
    echo "  -o, --output FILE   Output file path (auto-generated if not specified)"
    echo "  -c, --config FILE   Checkov configuration file"
    echo "  --baseline FILE     Baseline file to ignore existing issues"
    echo "  --skip-check CHECKS Comma-separated list of checks to skip"
    echo "  --framework FRAMEWORK Scan specific framework (terraform, arm, bicep)"
    echo "  --no-fail           Don't fail on security issues (warning only)"
    echo "  --soft-fail         Exit with code 0 even if issues found"
    echo "  --html              Generate HTML report (default for non-CLI formats)"
    echo "  --create-baseline   Create baseline file for existing issues"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 azure-keyvault core-eus-dev"
    echo "  $0 --all"
    echo "  $0 --plan azure-storage-account core-eus-dev"
    echo "  $0 --format json azure-keyvault core-eus-dev"
    echo "  $0 --html --all"
    echo "  $0 --create-baseline"
    echo ""
}

# Function to log messages
log() {
    local level="$1"
    shift
    case "$level" in
        "INFO")  echo -e "${BLUE}[INFO]${NC} $*" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $*" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $*" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $*" ;;
    esac
}

# Function to get current date in DDMMYYYY-HHMM format
get_date_stamp() {
    date +"%d%m%Y-%H%M"
}

# Function to create output directory
create_output_dir() {
    if [[ ! -d "$CHECKOV_REPORT_DIR" ]]; then
        log "INFO" "Creating Checkov report directory: $CHECKOV_REPORT_DIR"
        mkdir -p "$CHECKOV_REPORT_DIR"
    fi
}

# Function to check if Checkov is installed
check_checkov() {
    if ! command -v checkov &> /dev/null; then
        log "ERROR" "Checkov is not installed. Please install it with: pip install checkov"
        exit 1
    fi
    log "INFO" "Checkov version: $(checkov --version)"
}

# Function to generate HTML report from JSON
generate_html_report() {
    local json_file="$1"
    local html_file="$2"
    local component="${3:-all}"
    local stack="${4:-all}"
    
    log "INFO" "Generating HTML report: $html_file"
    
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Checkov Security Report - $component</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            font-weight: 300;
        }
        .header p {
            margin: 10px 0 0 0;
            font-size: 1.1em;
            opacity: 0.9;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.3s ease;
        }
        .summary-card:hover {
            transform: translateY(-5px);
        }
        .summary-card h3 {
            margin: 0 0 10px 0;
            font-size: 1.2em;
            color: #555;
        }
        .summary-card .number {
            font-size: 2.5em;
            font-weight: bold;
            margin: 10px 0;
        }
        .critical { color: #e74c3c; }
        .high { color: #e67e22; }
        .medium { color: #f39c12; }
        .low { color: #27ae60; }
        .info { color: #3498db; }
        .passed { color: #27ae60; }
        
        .content {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .section {
            margin-bottom: 30px;
        }
        .section h2 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .finding {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            padding: 20px;
            margin-bottom: 15px;
            border-left: 4px solid #3498db;
        }
        .finding.critical { border-left-color: #e74c3c; }
        .finding.high { border-left-color: #e67e22; }
        .finding.medium { border-left-color: #f39c12; }
        .finding.low { border-left-color: #27ae60; }
        .finding.info { border-left-color: #3498db; }
        
        .finding-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        .finding-title {
            font-size: 1.2em;
            font-weight: 600;
            color: #2c3e50;
        }
        .severity-badge {
            padding: 5px 15px;
            border-radius: 20px;
            color: white;
            font-size: 0.9em;
            font-weight: 500;
            text-transform: uppercase;
        }
        .severity-badge.critical { background-color: #e74c3c; }
        .severity-badge.high { background-color: #e67e22; }
        .severity-badge.medium { background-color: #f39c12; }
        .severity-badge.low { background-color: #27ae60; }
        .severity-badge.info { background-color: #3498db; }
        
        .finding-details {
            margin-top: 15px;
        }
        .finding-details p {
            margin: 5px 0;
            color: #666;
        }
        .finding-details code {
            background: #f1f2f6;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }
        .no-issues {
            text-align: center;
            padding: 40px;
            color: #27ae60;
            font-size: 1.3em;
        }
        .no-issues i {
            font-size: 3em;
            margin-bottom: 15px;
            display: block;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding: 20px;
            color: #666;
            font-size: 0.9em;
        }
        .tabs {
            display: flex;
            background: #f8f9fa;
            border-radius: 10px;
            margin-bottom: 20px;
            overflow: hidden;
        }
        .tab {
            flex: 1;
            padding: 15px;
            text-align: center;
            cursor: pointer;
            background: #f8f9fa;
            border: none;
            font-size: 1em;
            transition: background-color 0.3s ease;
        }
        .tab.active {
            background: #3498db;
            color: white;
        }
        .tab:hover {
            background: #3498db;
            color: white;
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
        }
        @media (max-width: 768px) {
            .summary {
                grid-template-columns: 1fr;
            }
            .finding-header {
                flex-direction: column;
                align-items: flex-start;
            }
            .severity-badge {
                margin-top: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔒 Security Report</h1>
        <p>Checkov Security Scan Results</p>
        <p><strong>Component:</strong> $component | <strong>Stack:</strong> $stack | <strong>Generated:</strong> $(date)</p>
    </div>
EOF

    # Parse JSON and generate summary
    if [[ -f "$json_file" ]]; then
        python3 << EOF >> "$html_file"
import json
import sys

try:
    with open('$json_file', 'r') as f:
        data = json.load(f)
    
    # Extract summary data
    summary = data.get('summary', {})
    passed = summary.get('passed', 0)
    failed = summary.get('failed', 0)
    skipped = summary.get('skipped', 0)
    
    # Count by severity
    results = data.get('results', {})
    failed_checks = results.get('failed_checks', [])
    
    severity_counts = {'CRITICAL': 0, 'HIGH': 0, 'MEDIUM': 0, 'LOW': 0, 'INFO': 0}
    for check in failed_checks:
        severity = check.get('severity', 'INFO').upper()
        if severity in severity_counts:
            severity_counts[severity] += 1
    
    print(f'''
    <div class="summary">
        <div class="summary-card">
            <h3>Total Checks</h3>
            <div class="number">{passed + failed + skipped}</div>
            <p>Infrastructure checks performed</p>
        </div>
        <div class="summary-card">
            <h3>Passed</h3>
            <div class="number passed">{passed}</div>
            <p>Security checks passed</p>
        </div>
        <div class="summary-card">
            <h3>Failed</h3>
            <div class="number critical">{failed}</div>
            <p>Security issues found</p>
        </div>
        <div class="summary-card">
            <h3>Skipped</h3>
            <div class="number">{skipped}</div>
            <p>Checks skipped</p>
        </div>
    </div>
    
    <div class="summary">
        <div class="summary-card">
            <h3>Critical</h3>
            <div class="number critical">{severity_counts['CRITICAL']}</div>
            <p>Must fix immediately</p>
        </div>
        <div class="summary-card">
            <h3>High</h3>
            <div class="number high">{severity_counts['HIGH']}</div>
            <p>Fix soon</p>
        </div>
        <div class="summary-card">
            <h3>Medium</h3>
            <div class="number medium">{severity_counts['MEDIUM']}</div>
            <p>Fix when possible</p>
        </div>
        <div class="summary-card">
            <h3>Low</h3>
            <div class="number low">{severity_counts['LOW']}</div>
            <p>Consider fixing</p>
        </div>
    </div>
    
    <div class="content">
        <div class="tabs">
            <button class="tab active" onclick="showTab('failed')">Failed Checks ({failed})</button>
            <button class="tab" onclick="showTab('passed')">Passed Checks ({passed})</button>
            <button class="tab" onclick="showTab('skipped')">Skipped Checks ({skipped})</button>
        </div>
        
        <div id="failed" class="tab-content active">
            <div class="section">
                <h2>🚨 Failed Security Checks</h2>
    ''')
    
    if failed_checks:
        for i, check in enumerate(failed_checks):
            severity = check.get('severity', 'INFO').lower()
            check_id = check.get('check_id', 'Unknown')
            check_name = check.get('check_name', 'Unknown Check')
            resource = check.get('resource', 'Unknown Resource')
            file_path = check.get('file_path', 'Unknown File')
            description = check.get('description', 'No description available')
            
            print(f'''
                <div class="finding {severity}">
                    <div class="finding-header">
                        <div class="finding-title">{check_name}</div>
                        <div class="severity-badge {severity}">{severity.upper()}</div>
                    </div>
                    <div class="finding-details">
                        <p><strong>Check ID:</strong> <code>{check_id}</code></p>
                        <p><strong>Resource:</strong> <code>{resource}</code></p>
                        <p><strong>File:</strong> <code>{file_path}</code></p>
                        <p><strong>Description:</strong> {description}</p>
                    </div>
                </div>
            ''')
    else:
        print('''
            <div class="no-issues">
                <i>✅</i>
                <p>No security issues found! All checks passed.</p>
            </div>
        ''')
    
    print('''
            </div>
        </div>
        
        <div id="passed" class="tab-content">
            <div class="section">
                <h2>✅ Passed Security Checks</h2>
    ''')
    
    passed_checks = results.get('passed_checks', [])
    if passed_checks:
        for check in passed_checks[:20]:  # Show first 20 passed checks
            check_id = check.get('check_id', 'Unknown')
            check_name = check.get('check_name', 'Unknown Check')
            resource = check.get('resource', 'Unknown Resource')
            
            print(f'''
                <div class="finding">
                    <div class="finding-header">
                        <div class="finding-title">{check_name}</div>
                        <div class="severity-badge passed">PASSED</div>
                    </div>
                    <div class="finding-details">
                        <p><strong>Check ID:</strong> <code>{check_id}</code></p>
                        <p><strong>Resource:</strong> <code>{resource}</code></p>
                    </div>
                </div>
            ''')
        
        if len(passed_checks) > 20:
            print(f'<p><em>... and {len(passed_checks) - 20} more passed checks</em></p>')
    else:
        print('<p>No passed checks to display.</p>')
    
    print('''
            </div>
        </div>
        
        <div id="skipped" class="tab-content">
            <div class="section">
                <h2>⏭️ Skipped Security Checks</h2>
    ''')
    
    skipped_checks = results.get('skipped_checks', [])
    if skipped_checks:
        for check in skipped_checks:
            check_id = check.get('check_id', 'Unknown')
            check_name = check.get('check_name', 'Unknown Check')
            suppress_comment = check.get('suppress_comment', 'No reason provided')
            
            print(f'''
                <div class="finding">
                    <div class="finding-header">
                        <div class="finding-title">{check_name}</div>
                        <div class="severity-badge info">SKIPPED</div>
                    </div>
                    <div class="finding-details">
                        <p><strong>Check ID:</strong> <code>{check_id}</code></p>
                        <p><strong>Reason:</strong> {suppress_comment}</p>
                    </div>
                </div>
            ''')
    else:
        print('<p>No skipped checks to display.</p>')
    
    print('''
            </div>
        </div>
    </div>
    ''')

except Exception as e:
    print(f'<div class="content"><p>Error parsing JSON report: {e}</p></div>')
EOF
    else
        cat >> "$html_file" << EOF
    <div class="content">
        <div class="no-issues">
            <i>❌</i>
            <p>Could not generate report. JSON file not found.</p>
        </div>
    </div>
EOF
    fi

    cat >> "$html_file" << EOF
    
    <div class="footer">
        <p>Generated by Checkov Security Scanner | One Platform Infrastructure</p>
        <p>Report generated on $(date)</p>
    </div>
    
    <script>
        function showTab(tabName) {
            // Hide all tab contents
            var tabContents = document.querySelectorAll('.tab-content');
            tabContents.forEach(function(content) {
                content.classList.remove('active');
            });
            
            // Remove active class from all tabs
            var tabs = document.querySelectorAll('.tab');
            tabs.forEach(function(tab) {
                tab.classList.remove('active');
            });
            
            // Show selected tab content
            document.getElementById(tabName).classList.add('active');
            
            // Add active class to clicked tab
            event.target.classList.add('active');
        }
    </script>
</body>
</html>
EOF

    log "SUCCESS" "HTML report generated: $html_file"
}

# Function to generate report filename
generate_report_filename() {
    local component="$1"
    local stack="$2"
    local format="$3"
    local date_stamp=$(get_date_stamp)
    local base_name="checkov-${component}-${stack}-${date_stamp}"
    
    case "$format" in
        "json") echo "${base_name}.json" ;;
        "html") echo "${base_name}.html" ;;
        "sarif") echo "${base_name}.sarif" ;;
        "junit") echo "${base_name}.xml" ;;
        "csv") echo "${base_name}.csv" ;;
        *) echo "${base_name}.txt" ;;
    esac
}

# Function to scan single component
scan_component() {
    local component="$1"
    local stack="$2"
    local scan_type="${3:-code}"
    
    log "INFO" "Scanning component: $component in stack: $stack"
    
    local component_dir="$PROJECT_ROOT/atmos/components/terraform/modules/$component"
    local plan_file="$PROJECT_ROOT/atmos/stacks/$stack-$component.tfplan"
    
    if [[ ! -d "$component_dir" ]]; then
        log "ERROR" "Component directory not found: $component_dir"
        return 1
    fi
    
    # Generate output filename if not specified
    local output_file="${OUTPUT_FILE:-}"
    if [[ -z "$output_file" ]]; then
        local format="${OUTPUT_FORMAT:-html}"
        output_file="$CHECKOV_REPORT_DIR/$(generate_report_filename "$component" "$stack" "$format")"
    fi
    
    # Always generate JSON for HTML conversion
    local json_file=""
    if [[ "${OUTPUT_FORMAT:-html}" == "html" ]]; then
        json_file="$CHECKOV_REPORT_DIR/$(generate_report_filename "$component" "$stack" "json")"
    fi
    
    local checkov_args=(
        "--framework" "terraform"
        "--quiet"
    )
    
    # Add config file if exists
    if [[ -f "$CHECKOV_CONFIG_FILE" ]]; then
        checkov_args+=("--config-file" "$CHECKOV_CONFIG_FILE")
    fi
    
    # Add baseline if specified or exists
    local baseline_file="${BASELINE_FILE:-$CHECKOV_BASELINE_FILE}"
    if [[ -f "$baseline_file" ]]; then
        checkov_args+=("--baseline" "$baseline_file")
    fi
    
    # Add skip checks if specified
    if [[ -n "${SKIP_CHECKS:-}" ]]; then
        checkov_args+=("--skip-check" "$SKIP_CHECKS")
    fi
    
    # Add soft fail if specified
    if [[ "${SOFT_FAIL:-false}" == "true" ]]; then
        checkov_args+=("--soft-fail")
    fi
    
    # Set output format and file
    if [[ "${OUTPUT_FORMAT:-html}" == "html" ]]; then
        # Generate JSON first for HTML conversion
        checkov_args+=("--output" "json" "--output-file" "$json_file")
    else
        checkov_args+=("--output" "${OUTPUT_FORMAT:-cli}")
        if [[ -n "$output_file" ]]; then
            checkov_args+=("--output-file" "$output_file")
        fi
    fi
    
    # Scan based on type
    if [[ "$scan_type" == "plan" ]] && [[ -f "$plan_file" ]]; then
        log "INFO" "Scanning Terraform plan file: $plan_file"
        checkov_args+=("--file" "$plan_file")
    else
        log "INFO" "Scanning Terraform code in: $component_dir"
        checkov_args+=("--directory" "$component_dir")
    fi
    
    # Run Checkov
    local exit_code=0
    if [[ "${NO_FAIL:-false}" == "true" ]]; then
        checkov "${checkov_args[@]}" || exit_code=$?
        if [[ $exit_code -ne 0 ]]; then
            log "WARN" "Security issues found in $component (exit code: $exit_code)"
        else
            log "SUCCESS" "No security issues found in $component"
        fi
    else
        if checkov "${checkov_args[@]}"; then
            log "SUCCESS" "No security issues found in $component"
        else
            log "ERROR" "Security issues found in $component"
            exit_code=1
        fi
    fi
    
    # Generate HTML report if requested
    if [[ "${OUTPUT_FORMAT:-html}" == "html" && -f "$json_file" ]]; then
        generate_html_report "$json_file" "$output_file" "$component" "$stack"
        # Clean up temporary JSON file
        rm -f "$json_file"
    fi
    
    if [[ -n "$output_file" && -f "$output_file" ]]; then
        log "INFO" "Report saved to: $output_file"
    fi
    
    return $exit_code
}

# Function to scan all components
scan_all_components() {
    log "INFO" "Scanning all components"
    
    local components_dir="$PROJECT_ROOT/atmos/components/terraform/modules"
    local failed_components=()
    local total_components=0
    
    if [[ ! -d "$components_dir" ]]; then
        log "ERROR" "Components directory not found: $components_dir"
        return 1
    fi
    
    # Generate output filename if not specified
    local output_file="${OUTPUT_FILE:-}"
    if [[ -z "$output_file" ]]; then
        local format="${OUTPUT_FORMAT:-html}"
        output_file="$CHECKOV_REPORT_DIR/$(generate_report_filename "all" "all" "$format")"
    fi
    
    # Always generate JSON for HTML conversion
    local json_file=""
    if [[ "${OUTPUT_FORMAT:-html}" == "html" ]]; then
        json_file="$CHECKOV_REPORT_DIR/$(generate_report_filename "all" "all" "json")"
    fi
    
    local checkov_args=(
        "--framework" "terraform"
        "--quiet"
        "--directory" "$components_dir"
    )
    
    # Add config file if exists
    if [[ -f "$CHECKOV_CONFIG_FILE" ]]; then
        checkov_args+=("--config-file" "$CHECKOV_CONFIG_FILE")
    fi
    
    # Add baseline if specified or exists
    local baseline_file="${BASELINE_FILE:-$CHECKOV_BASELINE_FILE}"
    if [[ -f "$baseline_file" ]]; then
        checkov_args+=("--baseline" "$baseline_file")
    fi
    
    # Add skip checks if specified
    if [[ -n "${SKIP_CHECKS:-}" ]]; then
        checkov_args+=("--skip-check" "$SKIP_CHECKS")
    fi
    
    # Add soft fail if specified
    if [[ "${SOFT_FAIL:-false}" == "true" ]]; then
        checkov_args+=("--soft-fail")
    fi
    
    # Set output format and file
    if [[ "${OUTPUT_FORMAT:-html}" == "html" ]]; then
        # Generate JSON first for HTML conversion
        checkov_args+=("--output" "json" "--output-file" "$json_file")
    else
        checkov_args+=("--output" "${OUTPUT_FORMAT:-cli}")
        if [[ -n "$output_file" ]]; then
            checkov_args+=("--output-file" "$output_file")
        fi
    fi
    
    # Run Checkov
    local exit_code=0
    if [[ "${NO_FAIL:-false}" == "true" ]]; then
        checkov "${checkov_args[@]}" || exit_code=$?
        if [[ $exit_code -ne 0 ]]; then
            log "WARN" "Security issues found in components (exit code: $exit_code)"
        else
            log "SUCCESS" "No security issues found in components"
        fi
    else
        if checkov "${checkov_args[@]}"; then
            log "SUCCESS" "No security issues found in components"
        else
            log "ERROR" "Security issues found in components"
            exit_code=1
        fi
    fi
    
    # Generate HTML report if requested
    if [[ "${OUTPUT_FORMAT:-html}" == "html" && -f "$json_file" ]]; then
        generate_html_report "$json_file" "$output_file" "all" "all"
        # Clean up temporary JSON file
        rm -f "$json_file"
    fi
    
    if [[ -n "$output_file" && -f "$output_file" ]]; then
        log "INFO" "Report saved to: $output_file"
    fi
    
    return $exit_code
}

# Function to create baseline file
create_baseline() {
    log "INFO" "Creating baseline file for existing issues"
    
    local components_dir="$PROJECT_ROOT/atmos/components/terraform/modules"
    
    local checkov_args=(
        "--framework" "terraform"
        "--directory" "$components_dir"
        "--create-baseline"
    )
    
    # Add config file if exists
    if [[ -f "$CHECKOV_CONFIG_FILE" ]]; then
        checkov_args+=("--config-file" "$CHECKOV_CONFIG_FILE")
    fi
    
    # Run Checkov to create baseline
    if checkov "${checkov_args[@]}"; then
        log "SUCCESS" "Baseline file created successfully"
        if [[ -f ".checkov.baseline" ]]; then
            mv ".checkov.baseline" "$CHECKOV_BASELINE_FILE"
            log "INFO" "Baseline moved to: $CHECKOV_BASELINE_FILE"
        fi
    else
        log "ERROR" "Failed to create baseline file"
        return 1
    fi
}

# Function to create default Checkov configuration
create_default_config() {
    if [[ ! -f "$CHECKOV_CONFIG_FILE" ]]; then
        log "INFO" "Creating default Checkov configuration"
        cat > "$CHECKOV_CONFIG_FILE" << 'EOF'
# Checkov Configuration for One Platform
# https://www.checkov.io/2.Basics/CLI%20Command%20Reference.html

# Framework settings
framework: [terraform]

# Output settings
output: [cli]
quiet: true

# Skip checks for known issues or exceptions
skip-check:
  # Azure-specific checks that may not apply to our architecture
  - CKV_AZURE_1   # Ensure that RDP access is restricted from the internet
  - CKV_AZURE_2   # Ensure that SSH access is restricted from the internet
  - CKV_AZURE_35  # Ensure default network access rule for Storage Accounts is set to deny
  - CKV_AZURE_36  # Ensure 'Trusted Microsoft Services' is enabled for Storage Account access
  
  # Terraform-specific checks that conflict with our patterns
  - CKV_TF_1      # Ensure Terraform module sources use a commit hash
  
# Severity levels to include
severity: [CRITICAL, HIGH, MEDIUM, LOW]

# Compact output format
compact: true

# Download external modules
download-external-modules: false

# Evaluate variables
evaluate-variables: true

# Include suppressed resources in output
include-all-checkov-policies: true

# Repo root for better path resolution
repo-root-for-plan-enrichment: .

# Azure-specific settings
secrets:
  - entropy_threshold: 4.5

# Hard fail on security issues (can be overridden with --soft-fail)
hard-fail-on: [CRITICAL, HIGH]

# Key Azure security checks to enforce
check:
  - CKV_AZURE_3   # Ensure that 'Secure transfer required' is set on Storage Accounts
  - CKV_AZURE_4   # Ensure the storage account public access is disabled
  - CKV_AZURE_8   # Ensure that 'Public access level' is set to Private for blob containers
  - CKV_AZURE_13  # Ensure App Service Authentication is set on Azure App Service
  - CKV_AZURE_14  # Ensure web app redirects all HTTP traffic to HTTPS
  - CKV_AZURE_15  # Ensure web app is using the latest version of TLS encryption
  - CKV_AZURE_33  # Ensure Storage logging is enabled for Queue service
  - CKV_AZURE_34  # Ensure Storage logging is enabled for Table service
  - CKV_AZURE_40  # Ensure Azure Key Vault is recoverable
  - CKV_AZURE_41  # Ensure that the expiration date is set on all keys
  - CKV_AZURE_42  # Ensure that the expiration date is set on all secrets
  - CKV_AZURE_43  # Ensure Storage Accounts adhere to the naming rules
  - CKV_AZURE_44  # Ensure Storage Account is using the latest version of TLS encryption
EOF
        log "SUCCESS" "Created Checkov configuration at $CHECKOV_CONFIG_FILE"
    fi
}

# Main function
main() {
    local component=""
    local stack=""
    local scan_all=false
    local scan_plan=false
    local create_baseline_flag=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -a|--all)
                scan_all=true
                shift
                ;;
            -p|--plan)
                scan_plan=true
                shift
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -c|--config)
                CHECKOV_CONFIG_FILE="$2"
                shift 2
                ;;
            --baseline)
                BASELINE_FILE="$2"
                shift 2
                ;;
            --skip-check)
                SKIP_CHECKS="$2"
                shift 2
                ;;
            --framework)
                FRAMEWORK="$2"
                shift 2
                ;;
            --no-fail)
                NO_FAIL=true
                shift
                ;;
            --soft-fail)
                SOFT_FAIL=true
                shift
                ;;
            --html)
                OUTPUT_FORMAT="html"
                shift
                ;;
            --create-baseline)
                create_baseline_flag=true
                shift
                ;;
            -*)
                log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$component" ]]; then
                    component="$1"
                elif [[ -z "$stack" ]]; then
                    stack="$1"
                else
                    log "ERROR" "Too many arguments"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check prerequisites
    check_checkov
    create_output_dir
    create_default_config
    
    # Handle baseline creation
    if [[ "$create_baseline_flag" == "true" ]]; then
        create_baseline
        exit $?
    fi
    
    # Determine scan type and execute
    if [[ "$scan_all" == "true" ]]; then
        scan_all_components
    elif [[ -n "$component" ]]; then
        if [[ -z "$stack" ]]; then
            stack="core-eus-dev"  # Default stack
        fi
        local scan_type="code"
        if [[ "$scan_plan" == "true" ]]; then
            scan_type="plan"
        fi
        scan_component "$component" "$stack" "$scan_type"
    else
        log "ERROR" "No component specified. Use --all to scan all components or specify a component name."
        usage
        exit 1
    fi
}

# Execute main function
main "$@"