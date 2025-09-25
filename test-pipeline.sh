#!/bin/bash

# Azure DevOps Terraform Pipeline Test Scripts
# This script contains automated tests for validating the pipeline configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to print test results
print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name - $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name - $message"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to print test header
print_test_header() {
    echo -e "\n${YELLOW}🧪 $1${NC}"
    echo "================================================"
}

# Test 1: YAML Syntax Validation
test_yaml_syntax() {
    print_test_header "YAML Syntax Validation"
    
    # Test azure-pipelines.yml
    if python -c "import yaml; yaml.safe_load(open('azure-pipelines.yml'))" 2>/dev/null; then
        print_test_result "azure-pipelines.yml syntax" "PASS" "Valid YAML syntax"
    else
        print_test_result "azure-pipelines.yml syntax" "FAIL" "Invalid YAML syntax"
    fi
    
    # Test template-terraform-stages.yml
    if python -c "import yaml; yaml.safe_load(open('template-terraform-stages.yml'))" 2>/dev/null; then
        print_test_result "template-terraform-stages.yml syntax" "PASS" "Valid YAML syntax"
    else
        print_test_result "template-terraform-stages.yml syntax" "FAIL" "Invalid YAML syntax"
    fi
    
    # Test template-create-terraform-backend.yml
    if python -c "import yaml; yaml.safe_load(open('template-create-terraform-backend.yml'))" 2>/dev/null; then
        print_test_result "template-create-terraform-backend.yml syntax" "PASS" "Valid YAML syntax"
    else
        print_test_result "template-create-terraform-backend.yml syntax" "FAIL" "Invalid YAML syntax"
    fi
}

# Test 2: Terraform Configuration Validation
test_terraform_config() {
    print_test_header "Terraform Configuration Validation"
    
    # Check if terraform directory exists
    if [ -d "terraform" ]; then
        print_test_result "terraform directory" "PASS" "Directory exists"
        
        # Validate terraform syntax (requires terraform to be installed)
        if command -v terraform &> /dev/null; then
            cd terraform
            if terraform validate &>/dev/null; then
                print_test_result "terraform validate" "PASS" "Configuration is valid"
            else
                print_test_result "terraform validate" "FAIL" "Configuration has errors"
            fi
            cd ..
        else
            print_test_result "terraform validate" "FAIL" "Terraform not installed"
        fi
    else
        print_test_result "terraform directory" "FAIL" "Directory missing"
    fi
    
    # Check required files
    for file in "terraform/main.tf" "terraform/variables.tf" "terraform/backend.tf"; do
        if [ -f "$file" ]; then
            print_test_result "$file existence" "PASS" "File exists"
        else
            print_test_result "$file existence" "FAIL" "File missing"
        fi
    done
}

# Test 3: Provider Configuration Validation
test_provider_config() {
    print_test_header "Provider Configuration Validation"
    
    # Check AzureRM provider configuration
    if grep -q "use_oidc = true" terraform/main.tf; then
        print_test_result "Provider OIDC config" "PASS" "OIDC authentication enabled"
    else
        print_test_result "Provider OIDC config" "FAIL" "OIDC authentication not configured"
    fi
    
    if grep -q "use_cli = false" terraform/main.tf; then
        print_test_result "Provider CLI config" "PASS" "CLI authentication disabled"
    else
        print_test_result "Provider CLI config" "FAIL" "CLI authentication not disabled"
    fi
    
    if grep -q "use_msi = false" terraform/main.tf; then
        print_test_result "Provider MSI config" "PASS" "MSI authentication disabled"
    else
        print_test_result "Provider MSI config" "FAIL" "MSI authentication not disabled"
    fi
}

# Test 4: Backend Configuration Validation
test_backend_config() {
    print_test_header "Backend Configuration Validation"
    
    # Check backend OIDC configuration
    if grep -q "use_oidc = true" terraform/backend.tf; then
        print_test_result "Backend OIDC config" "PASS" "Backend OIDC enabled"
    else
        print_test_result "Backend OIDC config" "FAIL" "Backend OIDC not configured"
    fi
    
    # Check terraform init command includes OIDC
    if grep -q 'backend-config="use_oidc=true"' template-terraform-stages.yml; then
        print_test_result "Init OIDC config" "PASS" "Init command includes OIDC"
    else
        print_test_result "Init OIDC config" "FAIL" "Init command missing OIDC config"
    fi
}

# Test 5: Parameter Validation
test_parameters() {
    print_test_header "Parameter Validation"
    
    # Check required parameters in template
    local required_params=(
        "environment"
        "environmentDisplayName"
        "backendServiceArm"
        "backendAzureRmResourceGroupName"
        "backendAzureRmStorageAccountName"
        "backendAzureRmContainerName"
        "backendAzureRmKey"
        "workingDirectory"
    )
    
    for param in "${required_params[@]}"; do
        if grep -q "$param:" template-terraform-stages.yml; then
            print_test_result "Parameter $param" "PASS" "Parameter defined"
        else
            print_test_result "Parameter $param" "FAIL" "Parameter missing"
        fi
    done
}

# Test 6: Authentication Configuration
test_auth_config() {
    print_test_header "Authentication Configuration"
    
    # Check for OIDC authentication logic
    if grep -q "Using Workload Identity Federation (OIDC) authentication" template-terraform-stages.yml; then
        print_test_result "OIDC auth logic" "PASS" "OIDC authentication logic present"
    else
        print_test_result "OIDC auth logic" "FAIL" "OIDC authentication logic missing"
    fi
    
    # Check for environment variable exports
    if grep -q "export ARM_USE_OIDC=true" template-terraform-stages.yml; then
        print_test_result "ARM_USE_OIDC export" "PASS" "ARM_USE_OIDC properly exported"
    else
        print_test_result "ARM_USE_OIDC export" "FAIL" "ARM_USE_OIDC export missing"
    fi
    
    # Check for debug output
    if grep -q "Available Service Principal Variables" template-terraform-stages.yml; then
        print_test_result "Debug output" "PASS" "Authentication debug output present"
    else
        print_test_result "Debug output" "FAIL" "Authentication debug output missing"
    fi
}

# Test 7: Terraform Version Configuration
test_terraform_version() {
    print_test_header "Terraform Version Configuration"
    
    # Check for specific Terraform version installation
    if grep -q "TERRAFORM_VERSION=\"1.5.7\"" template-terraform-stages.yml; then
        print_test_result "Terraform version" "PASS" "Terraform v1.5.7 specified"
    else
        print_test_result "Terraform version" "FAIL" "Terraform version not specified or incorrect"
    fi
    
    # Check for version verification
    if grep -q "terraform version" template-terraform-stages.yml; then
        print_test_result "Version verification" "PASS" "Version verification present"
    else
        print_test_result "Version verification" "FAIL" "Version verification missing"
    fi
}

# Test 8: Error Handling
test_error_handling() {
    print_test_header "Error Handling"
    
    # Check for error handling in PowerShell script
    if grep -q "catch {" template-terraform-stages.yml; then
        print_test_result "PowerShell error handling" "PASS" "Error handling present"
    else
        print_test_result "PowerShell error handling" "FAIL" "Error handling missing"
    fi
    
    # Check for exit codes
    if grep -q "exit 1" template-terraform-stages.yml; then
        print_test_result "Error exit codes" "PASS" "Proper exit codes used"
    else
        print_test_result "Error exit codes" "FAIL" "Error exit codes missing"
    fi
}

# Test 9: Security Best Practices
test_security() {
    print_test_header "Security Best Practices"
    
    # Check that secrets are not hardcoded
    if ! grep -E "(client_secret|password|key).*=.*['\"][^$]" template-terraform-stages.yml terraform/*.tf; then
        print_test_result "No hardcoded secrets" "PASS" "No hardcoded secrets found"
    else
        print_test_result "No hardcoded secrets" "FAIL" "Potential hardcoded secrets found"
    fi
    
    # Check for secret masking
    if grep -q "REDACTED" template-terraform-stages.yml; then
        print_test_result "Secret masking" "PASS" "Secret masking implemented"
    else
        print_test_result "Secret masking" "FAIL" "Secret masking missing"
    fi
}

# Test 10: Multi-environment Support
test_multi_env() {
    print_test_header "Multi-environment Support"
    
    # Check for environment variable usage
    if grep -q '${environment}' terraform/main.tf; then
        print_test_result "Environment variables" "PASS" "Environment variables used in Terraform"
    else
        print_test_result "Environment variables" "FAIL" "Environment variables not used"
    fi
    
    # Check for environment-specific state files
    if grep -q 'parameters.backendAzureRmKey' template-terraform-stages.yml; then
        print_test_result "Environment state files" "PASS" "Environment-specific state files configured"
    else
        print_test_result "Environment state files" "FAIL" "Environment-specific state files not configured"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}🚀 Azure DevOps Terraform Pipeline Test Suite${NC}"
    echo "=============================================="
    echo "Testing pipeline configuration and best practices..."
    echo ""
    
    # Run all tests
    test_yaml_syntax
    test_terraform_config
    test_provider_config
    test_backend_config
    test_parameters
    test_auth_config
    test_terraform_version
    test_error_handling
    test_security
    test_multi_env
    
    # Print summary
    echo ""
    echo "=============================================="
    echo -e "${YELLOW}📊 Test Summary${NC}"
    echo "=============================================="
    echo -e "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All tests passed! Pipeline configuration looks good.${NC}"
        exit 0
    else
        echo -e "\n${RED}⚠️  Some tests failed. Please review the configuration.${NC}"
        exit 1
    fi
}

# Check if running from correct directory
if [ ! -f "azure-pipelines.yml" ]; then
    echo -e "${RED}❌ Error: Please run this script from the repository root directory${NC}"
    exit 1
fi

# Run main function
main "$@"