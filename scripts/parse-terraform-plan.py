#!/usr/bin/env python3
"""
Terraform Plan Parser and Dashboard Generator
Parses terraform plan output and creates a beautiful summary table
"""

import sys
import re
import json
from tabulate import tabulate
from collections import defaultdict, Counter

def parse_terraform_plan(plan_output):
    """Parse terraform plan output and extract resource changes"""
    changes = []
    current_resource = None
    
    # Patterns for different operations
    patterns = {
        'create': r'^\s*\+\s+resource\s+"([^"]+)"\s+"([^"]+)"',
        'update': r'^\s*~\s+resource\s+"([^"]+)"\s+"([^"]+)"',
        'destroy': r'^\s*-\s+resource\s+"([^"]+)"\s+"([^"]+)"',
        'replace': r'^\s*-/\+\s+resource\s+"([^"]+)"\s+"([^"]+)"',
        'read': r'^\s*<=\s+data\s+"([^"]+)"\s+"([^"]+)"'
    }
    
    for line in plan_output.split('\n'):
        for action, pattern in patterns.items():
            match = re.match(pattern, line)
            if match:
                resource_type = match.group(1)
                resource_name = match.group(2)
                
                # Skip data sources for main summary
                if action == 'read':
                    continue
                    
                changes.append({
                    'action': action.upper(),
                    'resource_type': resource_type,
                    'resource_name': resource_name,
                    'full_name': f"{resource_type}.{resource_name}"
                })
                break
    
    return changes

def extract_resource_counts(plan_output):
    """Extract the summary counts from terraform plan output"""
    counts = {'add': 0, 'change': 0, 'destroy': 0}
    
    # Look for the plan summary line
    summary_pattern = r'Plan:\s+(\d+)\s+to\s+add,\s+(\d+)\s+to\s+change,\s+(\d+)\s+to\s+destroy'
    match = re.search(summary_pattern, plan_output)
    
    if match:
        counts['add'] = int(match.group(1))
        counts['change'] = int(match.group(2))
        counts['destroy'] = int(match.group(3))
    
    return counts

def generate_dashboard(component_plans):
    """Generate a beautiful dashboard from component plans"""
    
    # Overall summary
    total_counts = Counter()
    all_changes = []
    
    # Process each component
    for component, plan_output in component_plans.items():
        changes = parse_terraform_plan(plan_output)
        counts = extract_resource_counts(plan_output)
        
        all_changes.extend([{**change, 'component': component} for change in changes])
        
        for action, count in counts.items():
            if action == 'add':
                total_counts['CREATE'] += count
            elif action == 'change':
                total_counts['UPDATE'] += count
            elif action == 'destroy':
                total_counts['DESTROY'] += count
    
    # Create summary tables
    dashboard = []
    
    # Overall Summary
    dashboard.append("# 🚀 Terraform Plan Dashboard")
    dashboard.append("")
    
    if total_counts:
        summary_data = [
            ["📈 CREATE", total_counts.get('CREATE', 0), "🟢"],
            ["🔄 UPDATE", total_counts.get('UPDATE', 0), "🟡"],
            ["🗑️  DESTROY", total_counts.get('DESTROY', 0), "🔴"],
            ["📊 TOTAL", sum(total_counts.values()), "ℹ️"]
        ]
        
        dashboard.append("## 📊 Overall Summary")
        dashboard.append("```")
        dashboard.append(tabulate(summary_data, headers=["Action", "Count", "Status"], 
                                tablefmt="grid", colalign=("left", "center", "center")))
        dashboard.append("```")
        dashboard.append("")
    
    # Component-wise breakdown
    if len(component_plans) > 1:
        dashboard.append("## 🧩 Component Breakdown")
        dashboard.append("")
        
        component_data = []
        for component, plan_output in component_plans.items():
            counts = extract_resource_counts(plan_output)
            component_data.append([
                component,
                counts.get('add', 0),
                counts.get('change', 0),
                counts.get('destroy', 0),
                sum(counts.values())
            ])
        
        if component_data:
            dashboard.append("```")
            dashboard.append(tabulate(component_data, 
                                    headers=["Component", "Create", "Update", "Destroy", "Total"],
                                    tablefmt="grid", colalign=("left", "center", "center", "center", "center")))
            dashboard.append("```")
            dashboard.append("")
    
    # Detailed resource changes
    if all_changes:
        dashboard.append("## 📝 Detailed Changes")
        dashboard.append("")
        
        # Group by action
        by_action = defaultdict(list)
        for change in all_changes:
            by_action[change['action']].append(change)
        
        action_icons = {
            'CREATE': '🟢',
            'UPDATE': '🟡', 
            'DESTROY': '🔴',
            'REPLACE': '🔄'
        }
        
        for action in ['CREATE', 'UPDATE', 'REPLACE', 'DESTROY']:
            if action in by_action:
                changes = by_action[action]
                dashboard.append(f"### {action_icons.get(action, '📋')} {action} ({len(changes)} resources)")
                dashboard.append("")
                
                change_data = []
                for change in changes:
                    change_data.append([
                        change['component'],
                        change['resource_type'],
                        change['resource_name']
                    ])
                
                dashboard.append("```")
                dashboard.append(tabulate(change_data,
                                        headers=["Component", "Resource Type", "Resource Name"],
                                        tablefmt="grid", colalign=("left", "left", "left")))
                dashboard.append("```")
                dashboard.append("")
    
    # Add warnings if destroying resources
    if total_counts.get('DESTROY', 0) > 0:
        dashboard.append("## ⚠️ DESTRUCTION WARNING")
        dashboard.append("")
        dashboard.append("🔥 **This plan will DESTROY resources!**")
        dashboard.append("")
        dashboard.append("Please review the destruction carefully before applying.")
        dashboard.append("Destroyed resources cannot be recovered.")
        dashboard.append("")
    
    return "\n".join(dashboard)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 parse-terraform-plan.py <component_name> [plan_file]")
        sys.exit(1)
    
    component_name = sys.argv[1]
    
    # Read from file or stdin
    if len(sys.argv) > 2:
        with open(sys.argv[2], 'r') as f:
            plan_output = f.read()
    else:
        plan_output = sys.stdin.read()
    
    # For single component, create a dict
    component_plans = {component_name: plan_output}
    
    # Generate and print dashboard
    dashboard = generate_dashboard(component_plans)
    print(dashboard)

# Make functions available when imported or executed
if __name__ == "__main__":
    main()
else:
    # When imported, make functions available in global scope
    globals().update({
        'parse_terraform_plan': parse_terraform_plan,
        'extract_resource_counts': extract_resource_counts,
        'generate_dashboard': generate_dashboard
    })