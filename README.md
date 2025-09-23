# AzureDevOpsPipelines-Templates

## Overview
This repository contains Azure DevOps pipeline templates for Terraform infrastructure deployment with multi-environment support (Dev → Test → Production).

## Pipeline Structure
The pipeline consists of:
1. **Backend Creation**: Creates Azure Storage for Terraform state
2. **Dev Environment**: Deploys to development environment
3. **Test Environment**: Deploys to test environment (depends on Dev)
4. **Production Environment**: Deploys to production (depends on Dev + Test)

## Prerequisites
- Azure DevOps organization
- Azure subscription with appropriate permissions
- Service connection configured in Azure DevOps (`AZURE_5_SUBSCRIPTION`)

## Quick Start
1. Update the variables in `azure-pipelines.yml` to match your environment
2. Ensure your Azure service connection name matches `backendServiceArm` variable
3. Commit and push to trigger the pipeline

## Built-in Tasks Used
This pipeline uses only built-in Azure DevOps tasks:
- `AzureCLI@2` - For Terraform operations and Azure backend setup
- `PowerShell@2` - For Terraform installation and change detection

**Note**: No marketplace extensions required! All Terraform operations use the built-in AzureCLI task.

## Configuration
Update these variables in `azure-pipelines.yml`:
- `backendServiceArm`: Your Azure service connection name
- `backendAzureRmResourceGroupName`: Resource group for Terraform state storage
- `backendAzureRmStorageAccountName`: Storage account name (must be globally unique)
- `location`: Azure region for resources

```yaml
# sample-azure-pipelines.yml
trigger:
- main

pool:
  vmImage: ubuntu-latest

jobs:
- job: SampleJob
  displayName: Sample Job with Template Steps
  
  steps:
  - template: sample-template-step.yml
  - template: sample-template-step.yml
  - template: sample-template-step.yml
```

Video with explanation on YouTube is available here: https://youtu.be/US_e31hZiWk
