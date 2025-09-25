# Functional Test Cases for Azure DevOps Terraform Pipeline

## Test Suite Overview
This document outlines functional test cases for the Azure DevOps pipeline that deploys infrastructure using Terraform with OIDC authentication.

## Test Environment Setup
- **Repository**: AzureDevOpsPipelines150-Template
- **Branch**: main
- **Azure Subscription**: ebb8126f-b2a1-4a95-929a-bb83a078307e
- **Service Connection**: AzureServiceConnection (OIDC)
- **Storage Account**: aihub010144112441
- **Resource Group**: demo-chat

---

## Test Case 1: Pipeline Configuration Validation

### TC01.1 - YAML Syntax Validation
**Objective**: Verify all YAML files have correct syntax and structure
**Prerequisites**: Repository checked out
**Test Steps**:
1. Navigate to repository root
2. Validate `azure-pipelines.yml` syntax
3. Validate `template-terraform-stages.yml` syntax
4. Validate `template-create-terraform-backend.yml` syntax
5. Check for proper parameter definitions and references

**Expected Results**:
- All YAML files pass syntax validation
- No duplicate parameters or missing references
- Proper indentation (2 spaces) throughout

**Test Data**:
```yaml
# Check these key sections exist:
- parameters section with all required variables
- stages section with proper dependency chain
- steps with correct task references
```

### TC01.2 - Template Parameter Validation
**Objective**: Verify all template parameters are properly defined and used
**Test Steps**:
1. Review parameter definitions in templates
2. Verify parameter types and default values
3. Check parameter usage in stages
4. Validate parameter passing between templates

**Expected Results**:
- All parameters have appropriate types and defaults
- No undefined parameter references
- Parameter values propagate correctly between templates

---

## Test Case 2: Authentication and Service Connection

### TC02.1 - Service Connection Configuration
**Objective**: Verify AzureServiceConnection service connection is properly configured
**Prerequisites**: Service connection exists in Azure DevOps
**Test Steps**:
1. Navigate to Project Settings → Service connections
2. Verify "AzureServiceConnection" connection exists
3. Check authentication method is set to "Workload Identity Federation"
4. Validate subscription and tenant information

**Expected Results**:
- Service connection named "AzureServiceConnection" exists
- Uses Workload Identity Federation (OIDC)
- Subscription ID: ebb8126f-b2a1-4a95-929a-bb83a078307e
- Tenant ID: 24880b1f-f12b-4328-b12b-f5b27d0a5815

### TC02.2 - OIDC Authentication Test
**Objective**: Verify OIDC authentication works in pipeline
**Test Steps**:
1. Trigger pipeline execution
2. Monitor "terraform init" step output
3. Check authentication debug output
4. Verify ARM environment variables are set correctly

**Expected Results**:
```bash
# Expected debug output:
servicePrincipalId: [SET]
servicePrincipalKey: NOT_SET
tenantId: 24880b1f-f12b-4328-b12b-f5b27d0a5815
idToken: SET (length: 1474)
Using Workload Identity Federation (OIDC) authentication
ARM_USE_OIDC: true
ARM_OIDC_TOKEN: SET
```

---

## Test Case 3: Terraform Installation and Version

### TC03.1 - Terraform Installation
**Objective**: Verify Terraform v1.5.7 is correctly installed
**Test Steps**:
1. Execute "Install Terraform v1.5.7" step
2. Check if existing version is detected
3. Verify download and installation process
4. Validate final version output

**Expected Results**:
- Terraform v1.5.7 installed successfully
- Version command returns "Terraform v1.5.7"
- Installation completes without errors

**Test Script**:
```bash
# Verify installation
terraform version
# Expected output: Terraform v1.5.7
```

### TC03.2 - Terraform Provider Configuration
**Objective**: Verify AzureRM provider is correctly configured
**Test Steps**:
1. Review `terraform/main.tf` provider configuration
2. Check provider version constraints in `terraform/versions.tf`
3. Verify OIDC authentication settings

**Expected Results**:
```hcl
# Provider should have:
provider "azurerm" {
  features {}
  use_cli  = false
  use_msi  = false
  use_oidc = true
}

# Version constraint:
azurerm = {
  source  = "hashicorp/azurerm"
  version = "~> 3.0"
}
```

---

## Test Case 4: Backend Storage Configuration

### TC04.1 - Backend Storage Creation
**Objective**: Verify Terraform backend storage is created with proper permissions
**Test Steps**:
1. Execute "Create Storage Container for tfstate" step
2. Verify resource group creation/existence
3. Check storage account creation/configuration
4. Validate container creation
5. Verify service principal permissions

**Expected Results**:
- Resource group `rg-terraform-state` exists
- Storage account `tfstate20250923db` exists with Standard_LRS
- Container `tfstate` exists
- Service principal has required roles:
  - Storage Account Contributor
  - Storage Blob Data Contributor

### TC04.2 - Backend OIDC Authentication
**Objective**: Verify backend uses OIDC authentication
**Test Steps**:
1. Check `terraform/backend.tf` configuration
2. Verify terraform init command includes OIDC parameters
3. Monitor backend authentication during init

**Expected Results**:
```hcl
# Backend configuration:
backend "azurerm" {
  use_oidc = true
}

# Init command includes:
terraform init -backend-config="use_oidc=true"
```

---

## Test Case 5: Terraform Workflow Execution

### TC05.1 - Terraform Init
**Objective**: Verify terraform init succeeds with backend configuration
**Test Steps**:
1. Execute terraform init step
2. Monitor authentication process
3. Verify backend state storage connection
4. Check for any permission errors

**Expected Results**:
- Init completes successfully
- Backend state configured with Azure storage
- No authentication or permission errors
- State file location confirmed

### TC05.2 - Terraform Validate
**Objective**: Verify terraform configuration is valid
**Test Steps**:
1. Execute terraform validate step
2. Check validation output
3. Verify no syntax or configuration errors

**Expected Results**:
- Validation passes successfully
- No configuration errors reported
- "Success! The configuration is valid." message displayed

### TC05.3 - Terraform Plan
**Objective**: Verify terraform plan generates valid execution plan
**Test Steps**:
1. Execute terraform plan step
2. Review plan output
3. Check resource changes detection
4. Verify plan file creation

**Expected Results**:
- Plan executes successfully
- Plan file created with environment-specific name
- Resource changes properly detected and displayed
- No authentication errors during planning

### TC05.4 - Plan Change Detection
**Objective**: Verify PowerShell script correctly detects plan changes
**Test Steps**:
1. Execute "detect any terraform change in the plan" step
2. Verify JSON parsing of plan file
3. Check variable setting logic
4. Validate different change scenarios (create/update/delete/no-change)

**Expected Results**:
- PowerShell script executes without errors
- JSON parsing successful
- Variable `anyTfChanges` set correctly:
  - `true` if changes detected
  - `false` if no changes
- Proper action detection (create/update/delete)

### TC05.5 - Terraform Apply (Conditional)
**Objective**: Verify terraform apply runs only when changes are detected
**Test Steps**:
1. Test scenario with changes: verify apply executes
2. Test scenario without changes: verify apply is skipped
3. Monitor apply process and output
4. Verify resource deployment

**Expected Results**:
- Apply step runs only when `anyTfChanges == true`
- Apply step skipped when `anyTfChanges == false`
- Resources deployed successfully when apply runs
- State file updated in backend storage

---

## Test Case 6: Multi-Environment Testing

### TC06.1 - Development Environment
**Objective**: Verify pipeline works for dev environment
**Test Steps**:
1. Configure pipeline for dev environment
2. Execute complete pipeline
3. Verify resource naming includes 'dev'
4. Check state file separation

**Expected Results**:
- Resources created with 'dev' suffix
- State file: `dev.tfstate`
- Proper environment variable usage

### TC06.2 - Test Environment
**Objective**: Verify pipeline works for test environment
**Test Steps**:
1. Configure pipeline for test environment
2. Execute complete pipeline
3. Verify resource naming includes 'test'
4. Check state file separation

**Expected Results**:
- Resources created with 'test' suffix
- State file: `test.tfstate`
- No interference with dev environment

### TC06.3 - Production Environment
**Objective**: Verify pipeline works for production environment
**Test Steps**:
1. Configure pipeline for prod environment
2. Execute complete pipeline
3. Verify resource naming includes 'prod'
4. Check state file separation

**Expected Results**:
- Resources created with 'prod' suffix
- State file: `prod.tfstate`
- No interference with other environments

---

## Test Case 7: Error Handling and Recovery

### TC07.1 - Authentication Failure Handling
**Objective**: Verify proper error handling for authentication failures
**Test Steps**:
1. Temporarily misconfigure service connection
2. Execute pipeline
3. Verify error messages are clear
4. Check pipeline fails gracefully

**Expected Results**:
- Clear error messages about authentication failure
- Pipeline fails with appropriate exit codes
- No partial resource deployment

### TC07.2 - Storage Permission Error Handling
**Objective**: Verify handling of storage permission issues
**Test Steps**:
1. Remove storage permissions temporarily
2. Execute pipeline
3. Verify error handling
4. Restore permissions and retry

**Expected Results**:
- Clear error messages about permission issues
- Suggested remediation steps displayed
- Pipeline recovers after permission fix

### TC07.3 - Terraform Configuration Error Handling
**Objective**: Verify handling of terraform configuration errors
**Test Steps**:
1. Introduce syntax error in terraform files
2. Execute pipeline
3. Verify error detection and reporting
4. Fix error and verify recovery

**Expected Results**:
- Terraform validation catches configuration errors
- Clear error messages with file/line information
- Pipeline fails at appropriate step

---

## Test Case 8: Security and Compliance

### TC08.1 - Secret Management
**Objective**: Verify secrets are not exposed in logs
**Test Steps**:
1. Execute pipeline with verbose logging
2. Review all log outputs
3. Check for exposed secrets or tokens
4. Verify secret masking

**Expected Results**:
- No client secrets exposed in logs
- ARM_CLIENT_SECRET shows as [REDACTED] or masked
- OIDC tokens not displayed in plain text
- Service principal IDs may be visible (non-secret)

### TC08.2 - Least Privilege Access
**Objective**: Verify service principal has minimal required permissions
**Test Steps**:
1. Review service principal role assignments
2. Verify permissions are limited to required scope
3. Test with additional unnecessary permissions removed

**Expected Results**:
- Service principal has only required roles:
  - Storage Account Contributor (on storage account)
  - Storage Blob Data Contributor (on storage account)
  - Contributor (on target resource groups)
- No subscription-level permissions unless necessary

---

## Test Case 9: Performance and Reliability

### TC09.1 - Pipeline Execution Time
**Objective**: Verify pipeline completes within reasonable time
**Test Steps**:
1. Execute complete pipeline
2. Measure execution time for each stage
3. Identify bottlenecks
4. Compare with baseline performance

**Expected Results**:
- Complete pipeline execution < 10 minutes
- Terraform installation < 2 minutes
- Backend creation < 3 minutes
- Terraform operations < 5 minutes

### TC09.2 - Pipeline Reliability
**Objective**: Verify pipeline success rate and retryability
**Test Steps**:
1. Execute pipeline multiple times
2. Record success/failure rates
3. Test retry behavior on transient failures
4. Verify idempotent operations

**Expected Results**:
- Success rate > 95% under normal conditions
- Transient failures automatically retried
- Operations are idempotent (safe to re-run)

---

## Test Case 10: Integration Testing

### TC10.1 - End-to-End Workflow
**Objective**: Verify complete pipeline workflow from trigger to deployment
**Test Steps**:
1. Trigger pipeline from GitHub commit
2. Monitor all stages execution
3. Verify resource deployment
4. Check state file storage
5. Validate environment deployment

**Expected Results**:
- Pipeline triggers automatically on main branch changes
- All stages execute in correct order
- Resources deployed to Azure successfully
- State stored in backend correctly
- Environment accessible and functional

### TC10.2 - Rollback Testing
**Objective**: Verify ability to rollback changes
**Test Steps**:
1. Deploy initial infrastructure
2. Make changes and deploy again
3. Test rollback to previous state
4. Verify infrastructure consistency

**Expected Results**:
- Previous terraform state can be restored
- Infrastructure reverts to previous configuration
- No resource inconsistencies

---

## Test Data Requirements

### Sample Variables for Testing
```yaml
# Test parameters
environment: "test"
environmentDisplayName: "Test Environment"
backendServiceArm: "AzureServiceConnection"
backendAzureRmResourceGroupName: "demo-chat"
backendAzureRmStorageAccountName: "aihub010144112441"
backendAzureRmContainerName: "tfstate"
backendAzureRmKey: "test.tfstate"
workingDirectory: "terraform"
location: "westeurope"
```

### Test Resource Naming Convention
```
# Expected resource names
Resource Group: rg-{environment}-example
Storage Account: tfstate20250923db
Container: tfstate
State File: {environment}.tfstate
```

---

## Test Execution Checklist

### Pre-Test Setup
- [ ] Azure DevOps project configured
- [ ] Service connection "AzureServiceConnection" exists
- [ ] Repository cloned and accessible
- [ ] Test subscription available
- [ ] Required permissions granted

### Test Execution
- [ ] All YAML syntax validated
- [ ] Authentication tests passed
- [ ] Terraform installation verified
- [ ] Backend configuration tested
- [ ] Multi-environment testing completed
- [ ] Error handling validated
- [ ] Security compliance verified
- [ ] Performance benchmarks met
- [ ] End-to-end integration tested

### Post-Test Cleanup
- [ ] Test resources cleaned up
- [ ] State files archived/removed
- [ ] Temporary permissions revoked
- [ ] Test logs archived

---

## Success Criteria

### Overall Pipeline Success
✅ All stages complete successfully  
✅ Terraform operations execute without errors  
✅ OIDC authentication works reliably  
✅ Resources deployed to correct environment  
✅ State management functions properly  
✅ Security requirements met  
✅ Performance targets achieved  

### Quality Gates
- **Code Quality**: All YAML files pass linting
- **Security**: No secrets exposed in logs
- **Reliability**: >95% success rate
- **Performance**: <10 minute execution time
- **Compliance**: Proper permission management