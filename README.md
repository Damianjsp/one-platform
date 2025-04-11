# One Platform

One Platform is a comprehensive infrastructure as code solution designed to manage deployments across multiple environments and cloud providers with consistency, reliability, and best practices.

## Overview

This repository provides a centralized platform for managing infrastructure deployments, leveraging Atmos as an orchestration layer to manage Terraform components and stacks across environments. It provides a scalable and maintainable approach to infrastructure management using component-based architecture.

## Key Features

- **Multi-Environment Support**: Deploy to development, staging, and production environments with consistent configurations
- **Azure Support**: Deploying resources to Azure Public Cloud with proper resource naming and tagging
- **Standardized Naming and Tagging**: Consistent resource naming using the `null-label` pattern
- **Component-Based Architecture**: Reusable Terraform modules organized by functionality
- **DRY Configuration**: Reduce duplication using Atmos stacks and component inheritance

## Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (>= 1.9.0)
- [Atmos CLI](https://atmos.tools/quick-start/)
- Azure CLI with active subscription

### Setup

1. Clone this repository

   ```bash
   git clone https://github.com/yourusername/one-platform.git
   cd one-platform

