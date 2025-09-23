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
- **Service connection configured in Azure DevOps** (see setup instructions below)

## Service Connection Setup
**CRITICAL**: The pipeline requires an **Azure Resource Manager** service connection, not a GitHub connection.

### Step 1: Check Existing Service Connections
1. Go to **Azure DevOps Project Settings** → **Service connections**
2. Look for connections with type **Azure Resource Manager**
3. If you find one, note its exact name

### Step 2: Create Azure Service Connection (if needed)
If you don't have an Azure Resource Manager connection:
1. Click **New service connection** → **Azure Resource Manager**
2. Choose **Service principal (automatic)** (recommended)
3. Select your Azure subscription and resource group
4. **Name it clearly** (e.g., `Azure-Production`, `MyAzureSubscription`)
5. Click **Save**

### Step 3: Update Pipeline
**Update the `backendServiceArm` variable in `azure-pipelines.yml`:**
```yaml
variables:
  backendServiceArm: 'YOUR_AZURE_SERVICE_CONNECTION_NAME'  # Not GitHub connection!
```

**⚠️ Common Mistake:** Using GitHub service connection instead of Azure service connection

## Quick Start
1. **Create Azure service connection** (see above)
2. **Update the variables** in `azure-pipelines.yml`:
   - `backendServiceArm`: Your Azure service connection name
   - `backendAzureRmStorageAccountName`: Must be globally unique
   - Other variables as needed for your environment
3. Commit and push to trigger the pipeline

## Built-in Tasks Used
This pipeline uses only built-in Azure DevOps tasks:
- `AzureCLI@2` - For Terraform operations and Azure backend setup
- `PowerShell@2` - For Terraform installation and change detection

**Note**: No marketplace extensions required! All Terraform operations use the built-in AzureCLI task.

## Configuration
**Critical Variables to Update in `azure-pipelines.yml`:**
- `backendServiceArm`: **YOUR AZURE SERVICE CONNECTION NAME** (must match exactly)
- `backendAzureRmResourceGroupName`: Resource group for Terraform state storage
- `backendAzureRmStorageAccountName`: Storage account name (**must be globally unique**)
- `location`: Azure region for resources

**Example:**
```yaml
variables:
  backendServiceArm: 'MyAzureConnection'  # ← Your service connection name
  backendAzureRmResourceGroupName: 'my-terraform-state-rg'
  backendAzureRmStorageAccountName: 'myuniquestorageacct123'  # ← Must be globally unique
  backendAzureRmContainerName: 'tfstate'
  location: 'eastus'
```

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
