# Test Execution Guide

## Overview
This guide explains how to run the functional tests for your Azure DevOps Terraform pipeline.

## Test Files Created

### 1. **FUNCTIONAL_TEST_CASES.md**
Comprehensive documentation of all test cases including:
- Test objectives and prerequisites
- Step-by-step test procedures
- Expected results and validation criteria
- Success criteria and quality gates

### 2. **test-pipeline.sh** (Linux/macOS)
Automated test script for validating pipeline configuration:
```bash
# Make executable and run
chmod +x test-pipeline.sh
./test-pipeline.sh
```

### 3. **Test-Pipeline.ps1** (Windows/PowerShell)
PowerShell version of the automated test script:
```powershell
# Run in PowerShell
.\Test-Pipeline.ps1
```

### 4. **pipeline-integration-tests.yml**
Azure DevOps pipeline template for running integration tests within your pipeline.

## How to Run Tests

### Local Configuration Tests

#### On Linux/macOS:
```bash
# Navigate to repository root
cd /path/to/AzureDevOpsPipelines150-Template

# Run configuration tests
chmod +x test-pipeline.sh
./test-pipeline.sh
```

#### On Windows:
```powershell
# Navigate to repository root
cd C:\path\to\AzureDevOpsPipelines150-Template

# Run configuration tests
.\Test-Pipeline.ps1
```

### Azure DevOps Integration Tests

#### Option 1: Add to Existing Pipeline
Add this stage to your `azure-pipelines.yml`:
```yaml
# Add to your existing azure-pipelines.yml
stages:
- template: pipeline-integration-tests.yml
  parameters:
    environment: 'test'
    testResourceGroup: 'rg-test-validation'
    runCleanup: true

# Your existing stages...
- template: template-create-terraform-backend.yml
  # ... rest of your pipeline
```

#### Option 2: Separate Test Pipeline
Create a separate pipeline file `azure-pipelines-test.yml`:
```yaml
# azure-pipelines-test.yml
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - template-terraform-stages.yml
    - template-create-terraform-backend.yml
    - terraform/*

pool:
  vmImage: ubuntu-latest

stages:
- template: pipeline-integration-tests.yml
  parameters:
    environment: 'test'
    testResourceGroup: 'rg-test-validation'
    runCleanup: true
```

## Test Categories

### 1. **Configuration Tests** (Local)
- YAML syntax validation
- Terraform configuration validation
- Parameter validation
- Security best practices check

**Run Command:**
```bash
./test-pipeline.sh
```

### 2. **Authentication Tests** (Azure DevOps)
- Service connection validation
- OIDC authentication testing
- Permission verification

**Trigger:** Include in Azure DevOps pipeline

### 3. **Integration Tests** (Azure DevOps)
- End-to-end workflow testing
- Resource creation/destruction
- Multi-environment testing

**Trigger:** Include in Azure DevOps pipeline

### 4. **Performance Tests** (Azure DevOps)
- Pipeline execution time
- Resource provisioning speed
- Terraform operation benchmarks

**Trigger:** Include in Azure DevOps pipeline

## Test Results Interpretation

### Local Test Script Results

#### ✅ All Tests Pass
```
🎉 All tests passed! Pipeline configuration looks good.
Total Tests: 30
Passed: 30
Failed: 0
```
**Action:** Your pipeline is ready for deployment.

#### ❌ Some Tests Fail
```
⚠️ Some tests failed. Please review the configuration.
Total Tests: 30
Passed: 25
Failed: 5
```
**Action:** Review failed tests and fix configuration issues.

### Common Test Failures and Solutions

#### 1. **YAML Syntax Errors**
```
❌ FAIL: azure-pipelines.yml syntax - Invalid YAML syntax
```
**Solution:** Check YAML indentation and structure.

#### 2. **Missing Parameters**
```
❌ FAIL: Parameter backendServiceArm - Parameter missing
```
**Solution:** Add missing parameters to template files.

#### 3. **Terraform Configuration Issues**
```
❌ FAIL: terraform validate - Configuration has errors
```
**Solution:** Fix Terraform syntax and provider configuration.

#### 4. **Authentication Configuration Missing**
```
❌ FAIL: OIDC auth logic - OIDC authentication logic missing
```
**Solution:** Ensure OIDC authentication is properly configured.

#### 5. **Security Issues**
```
❌ FAIL: No hardcoded secrets - Potential hardcoded secrets found
```
**Solution:** Remove any hardcoded secrets and use variables.

## Continuous Testing Strategy

### Pre-commit Testing
```bash
# Add to pre-commit hook
#!/bin/bash
echo "Running pipeline configuration tests..."
./test-pipeline.sh
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

### Pull Request Validation
Set up branch policies to require:
1. Successful build from test pipeline
2. All configuration tests passing
3. Code review approval

### Regular Validation
Schedule weekly runs of integration tests to catch:
- Azure service changes
- Permission drift
- Configuration degradation

## Test Maintenance

### Adding New Tests

#### To Local Test Script:
```bash
# Add new test function
test_new_feature() {
    print_test_header "New Feature Testing"
    
    # Test logic here
    if [[ condition ]]; then
        print_test_result "New test" "PASS" "Test passed"
    else
        print_test_result "New test" "FAIL" "Test failed"
    fi
}

# Add to main function
main() {
    # ... existing tests
    test_new_feature
    # ... rest of main
}
```

#### To Integration Tests:
```yaml
# Add new job to pipeline-integration-tests.yml
- job: NewFeatureTest
  displayName: 'New Feature Test'
  pool:
    vmImage: ubuntu-latest
  
  steps:
  - task: AzureCLI@2
    displayName: 'Test New Feature'
    inputs:
      azureSubscription: 'AzureServiceConnection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        echo "Testing new feature..."
        # Test logic here
```

### Updating Test Data
When you change:
- Storage account names
- Resource group names  
- Service connection names
- Terraform versions

Update the corresponding values in:
- `FUNCTIONAL_TEST_CASES.md`
- `test-pipeline.sh`
- `Test-Pipeline.ps1`
- `pipeline-integration-tests.yml`

## Troubleshooting Test Issues

### Test Script Won't Run
```bash
# Check permissions
ls -la test-pipeline.sh
# Make executable if needed
chmod +x test-pipeline.sh
```

### PowerShell Execution Policy
```powershell
# Check execution policy
Get-ExecutionPolicy
# Set if needed (run as administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Azure DevOps Test Failures
1. Check service connection permissions
2. Verify subscription access
3. Review pipeline logs for detailed errors
4. Ensure test resource groups don't conflict

### Missing Dependencies
```bash
# Install required tools
# Python (for YAML validation)
pip install pyyaml

# Terraform (for configuration validation)
# Follow installation guide for your OS
```

## Best Practices

### Test Environment Management
- Use separate subscriptions/resource groups for testing
- Clean up test resources after each run
- Use naming conventions to identify test resources

### Test Data Management
- Keep test configurations in version control
- Use environment variables for sensitive data
- Document any manual setup required

### Test Reliability
- Make tests idempotent (safe to re-run)
- Add appropriate timeouts and retries
- Include cleanup steps in case of failures

### Security Considerations
- Never commit real credentials to test files
- Use least-privilege access for test service principals
- Regularly rotate test credentials
- Monitor test resource usage and costs

## Integration with CI/CD

### GitHub Actions Integration
```yaml
# .github/workflows/test-pipeline.yml
name: Pipeline Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Run Pipeline Tests
      run: |
        chmod +x test-pipeline.sh
        ./test-pipeline.sh
```

### Azure DevOps Build Validation
```yaml
# Build validation pipeline
trigger:
  branches:
    include:
    - main
    - feature/*

stages:
- stage: Validate
  jobs:
  - job: ConfigTests
    steps:
    - bash: |
        chmod +x test-pipeline.sh
        ./test-pipeline.sh
      displayName: 'Run Configuration Tests'
```

This comprehensive testing framework ensures your Azure DevOps Terraform pipeline is robust, secure, and reliable! 🎯