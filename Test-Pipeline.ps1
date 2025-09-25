# Azure DevOps Terraform Pipeline Test Scripts (PowerShell)
# This script contains automated tests for validating the pipeline configuration

param(
    [switch]$Verbose
)

# Test result tracking
$script:TestsPassed = 0
$script:TestsFailed = 0
$script:TotalTests = 0

# Function to print test results
function Write-TestResult {
    param(
        [string]$TestName,
        [string]$Result,
        [string]$Message
    )
    
    $script:TotalTests++
    
    if ($Result -eq "PASS") {
        Write-Host "✅ PASS: $TestName - $Message" -ForegroundColor Green
        $script:TestsPassed++
    } else {
        Write-Host "❌ FAIL: $TestName - $Message" -ForegroundColor Red
        $script:TestsFailed++
    }
}

# Function to print test header
function Write-TestHeader {
    param([string]$HeaderText)
    
    Write-Host ""
    Write-Host "🧪 $HeaderText" -ForegroundColor Yellow
    Write-Host "================================================"
}

# Test 1: YAML Syntax Validation
function Test-YamlSyntax {
    Write-TestHeader "YAML Syntax Validation"
    
    # Test azure-pipelines.yml
    try {
        $null = Get-Content "azure-pipelines.yml" | ConvertFrom-Yaml -ErrorAction Stop
        Write-TestResult "azure-pipelines.yml syntax" "PASS" "Valid YAML syntax"
    } catch {
        Write-TestResult "azure-pipelines.yml syntax" "FAIL" "Invalid YAML syntax: $($_.Exception.Message)"
    }
    
    # Test template-terraform-stages.yml
    try {
        $content = Get-Content "template-terraform-stages.yml" -Raw
        if ($content -match "^\s*#.*parameters.*yaml.*template" -and $content -match "stages:" -and $content -match "jobs:") {
            Write-TestResult "template-terraform-stages.yml syntax" "PASS" "Valid YAML structure"
        } else {
            Write-TestResult "template-terraform-stages.yml syntax" "FAIL" "Invalid YAML structure"
        }
    } catch {
        Write-TestResult "template-terraform-stages.yml syntax" "FAIL" "Error reading file: $($_.Exception.Message)"
    }
    
    # Test template-create-terraform-backend.yml
    try {
        $content = Get-Content "template-create-terraform-backend.yml" -Raw
        if ($content -match "parameters:" -and $content -match "stages:" -and $content -match "steps:") {
            Write-TestResult "template-create-terraform-backend.yml syntax" "PASS" "Valid YAML structure"
        } else {
            Write-TestResult "template-create-terraform-backend.yml syntax" "FAIL" "Invalid YAML structure"
        }
    } catch {
        Write-TestResult "template-create-terraform-backend.yml syntax" "FAIL" "Error reading file: $($_.Exception.Message)"
    }
}

# Test 2: Terraform Configuration Validation
function Test-TerraformConfig {
    Write-TestHeader "Terraform Configuration Validation"
    
    # Check if terraform directory exists
    if (Test-Path "terraform" -PathType Container) {
        Write-TestResult "terraform directory" "PASS" "Directory exists"
        
        # Validate terraform syntax if terraform is available
        if (Get-Command terraform -ErrorAction SilentlyContinue) {
            Push-Location terraform
            try {
                $result = & terraform validate 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-TestResult "terraform validate" "PASS" "Configuration is valid"
                } else {
                    Write-TestResult "terraform validate" "FAIL" "Configuration has errors: $result"
                }
            } catch {
                Write-TestResult "terraform validate" "FAIL" "Error running terraform validate: $($_.Exception.Message)"
            }
            Pop-Location
        } else {
            Write-TestResult "terraform validate" "FAIL" "Terraform not installed or not in PATH"
        }
    } else {
        Write-TestResult "terraform directory" "FAIL" "Directory missing"
    }
    
    # Check required files
    $requiredFiles = @("terraform/main.tf", "terraform/variables.tf", "terraform/backend.tf")
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-TestResult "$file existence" "PASS" "File exists"
        } else {
            Write-TestResult "$file existence" "FAIL" "File missing"
        }
    }
}

# Test 3: Provider Configuration Validation
function Test-ProviderConfig {
    Write-TestHeader "Provider Configuration Validation"
    
    if (Test-Path "terraform/main.tf") {
        $content = Get-Content "terraform/main.tf" -Raw
        
        # Check AzureRM provider configuration
        if ($content -match "use_oidc\s*=\s*true") {
            Write-TestResult "Provider OIDC config" "PASS" "OIDC authentication enabled"
        } else {
            Write-TestResult "Provider OIDC config" "FAIL" "OIDC authentication not configured"
        }
        
        if ($content -match "use_cli\s*=\s*false") {
            Write-TestResult "Provider CLI config" "PASS" "CLI authentication disabled"
        } else {
            Write-TestResult "Provider CLI config" "FAIL" "CLI authentication not disabled"
        }
        
        if ($content -match "use_msi\s*=\s*false") {
            Write-TestResult "Provider MSI config" "PASS" "MSI authentication disabled"
        } else {
            Write-TestResult "Provider MSI config" "FAIL" "MSI authentication not disabled"
        }
    } else {
        Write-TestResult "Provider config file" "FAIL" "terraform/main.tf not found"
    }
}

# Test 4: Backend Configuration Validation
function Test-BackendConfig {
    Write-TestHeader "Backend Configuration Validation"
    
    if (Test-Path "terraform/backend.tf") {
        $backendContent = Get-Content "terraform/backend.tf" -Raw
        
        # Check backend OIDC configuration
        if ($backendContent -match "use_oidc\s*=\s*true") {
            Write-TestResult "Backend OIDC config" "PASS" "Backend OIDC enabled"
        } else {
            Write-TestResult "Backend OIDC config" "FAIL" "Backend OIDC not configured"
        }
    } else {
        Write-TestResult "Backend config file" "FAIL" "terraform/backend.tf not found"
    }
    
    # Check terraform init command includes OIDC
    if (Test-Path "template-terraform-stages.yml") {
        $templateContent = Get-Content "template-terraform-stages.yml" -Raw
        if ($templateContent -match 'backend-config="use_oidc=true"') {
            Write-TestResult "Init OIDC config" "PASS" "Init command includes OIDC"
        } else {
            Write-TestResult "Init OIDC config" "FAIL" "Init command missing OIDC config"
        }
    }
}

# Test 5: Parameter Validation
function Test-Parameters {
    Write-TestHeader "Parameter Validation"
    
    if (Test-Path "template-terraform-stages.yml") {
        $content = Get-Content "template-terraform-stages.yml" -Raw
        
        # Check required parameters in template
        $requiredParams = @(
            "environment",
            "environmentDisplayName",
            "backendServiceArm",
            "backendAzureRmResourceGroupName",
            "backendAzureRmStorageAccountName",
            "backendAzureRmContainerName",
            "backendAzureRmKey",
            "workingDirectory"
        )
        
        foreach ($param in $requiredParams) {
            if ($content -match "$param\s*:") {
                Write-TestResult "Parameter $param" "PASS" "Parameter defined"
            } else {
                Write-TestResult "Parameter $param" "FAIL" "Parameter missing"
            }
        }
    } else {
        Write-TestResult "Template file" "FAIL" "template-terraform-stages.yml not found"
    }
}

# Test 6: Authentication Configuration
function Test-AuthConfig {
    Write-TestHeader "Authentication Configuration"
    
    if (Test-Path "template-terraform-stages.yml") {
        $content = Get-Content "template-terraform-stages.yml" -Raw
        
        # Check for OIDC authentication logic
        if ($content -match "Using Workload Identity Federation \(OIDC\) authentication") {
            Write-TestResult "OIDC auth logic" "PASS" "OIDC authentication logic present"
        } else {
            Write-TestResult "OIDC auth logic" "FAIL" "OIDC authentication logic missing"
        }
        
        # Check for environment variable exports
        if ($content -match "export ARM_USE_OIDC=true") {
            Write-TestResult "ARM_USE_OIDC export" "PASS" "ARM_USE_OIDC properly exported"
        } else {
            Write-TestResult "ARM_USE_OIDC export" "FAIL" "ARM_USE_OIDC export missing"
        }
        
        # Check for debug output
        if ($content -match "Available Service Principal Variables") {
            Write-TestResult "Debug output" "PASS" "Authentication debug output present"
        } else {
            Write-TestResult "Debug output" "FAIL" "Authentication debug output missing"
        }
    }
}

# Test 7: Terraform Version Configuration
function Test-TerraformVersion {
    Write-TestHeader "Terraform Version Configuration"
    
    if (Test-Path "template-terraform-stages.yml") {
        $content = Get-Content "template-terraform-stages.yml" -Raw
        
        # Check for specific Terraform version installation
        if ($content -match 'TERRAFORM_VERSION="1\.5\.7"') {
            Write-TestResult "Terraform version" "PASS" "Terraform v1.5.7 specified"
        } else {
            Write-TestResult "Terraform version" "FAIL" "Terraform version not specified or incorrect"
        }
        
        # Check for version verification
        if ($content -match "terraform version") {
            Write-TestResult "Version verification" "PASS" "Version verification present"
        } else {
            Write-TestResult "Version verification" "FAIL" "Version verification missing"
        }
    }
}

# Test 8: Error Handling
function Test-ErrorHandling {
    Write-TestHeader "Error Handling"
    
    if (Test-Path "template-terraform-stages.yml") {
        $content = Get-Content "template-terraform-stages.yml" -Raw
        
        # Check for error handling in PowerShell script
        if ($content -match "catch \{") {
            Write-TestResult "PowerShell error handling" "PASS" "Error handling present"
        } else {
            Write-TestResult "PowerShell error handling" "FAIL" "Error handling missing"
        }
        
        # Check for exit codes
        if ($content -match "exit 1") {
            Write-TestResult "Error exit codes" "PASS" "Proper exit codes used"
        } else {
            Write-TestResult "Error exit codes" "FAIL" "Error exit codes missing"
        }
    }
}

# Test 9: Security Best Practices
function Test-Security {
    Write-TestHeader "Security Best Practices"
    
    # Check all relevant files for hardcoded secrets
    $files = @("template-terraform-stages.yml", "terraform/main.tf", "terraform/variables.tf", "terraform/backend.tf")
    $secretsFound = $false
    
    foreach ($file in $files) {
        if (Test-Path $file) {
            $content = Get-Content $file -Raw
            if ($content -match "(client_secret|password|key)\s*[=:]\s*['\`"][^$]") {
                $secretsFound = $true
                break
            }
        }
    }
    
    if (-not $secretsFound) {
        Write-TestResult "No hardcoded secrets" "PASS" "No hardcoded secrets found"
    } else {
        Write-TestResult "No hardcoded secrets" "FAIL" "Potential hardcoded secrets found"
    }
    
    # Check for secret masking
    if (Test-Path "template-terraform-stages.yml") {
        $content = Get-Content "template-terraform-stages.yml" -Raw
        if ($content -match "REDACTED") {
            Write-TestResult "Secret masking" "PASS" "Secret masking implemented"
        } else {
            Write-TestResult "Secret masking" "FAIL" "Secret masking missing"
        }
    }
}

# Test 10: Multi-environment Support
function Test-MultiEnv {
    Write-TestHeader "Multi-environment Support"
    
    # Check for environment variable usage in Terraform
    if (Test-Path "terraform/main.tf") {
        $content = Get-Content "terraform/main.tf" -Raw
        if ($content -match '\$\{.*environment.*\}') {
            Write-TestResult "Environment variables" "PASS" "Environment variables used in Terraform"
        } else {
            Write-TestResult "Environment variables" "FAIL" "Environment variables not used"
        }
    }
    
    # Check for environment-specific state files
    if (Test-Path "template-terraform-stages.yml") {
        $content = Get-Content "template-terraform-stages.yml" -Raw
        if ($content -match 'parameters\.backendAzureRmKey') {
            Write-TestResult "Environment state files" "PASS" "Environment-specific state files configured"
        } else {
            Write-TestResult "Environment state files" "FAIL" "Environment-specific state files not configured"
        }
    }
}

# Main execution
function Main {
    Write-Host "🚀 Azure DevOps Terraform Pipeline Test Suite" -ForegroundColor Yellow
    Write-Host "=============================================="
    Write-Host "Testing pipeline configuration and best practices..."
    Write-Host ""
    
    # Check if running from correct directory
    if (-not (Test-Path "azure-pipelines.yml")) {
        Write-Host "❌ Error: Please run this script from the repository root directory" -ForegroundColor Red
        exit 1
    }
    
    # Run all tests
    Test-YamlSyntax
    Test-TerraformConfig
    Test-ProviderConfig
    Test-BackendConfig
    Test-Parameters
    Test-AuthConfig
    Test-TerraformVersion
    Test-ErrorHandling
    Test-Security
    Test-MultiEnv
    
    # Print summary
    Write-Host ""
    Write-Host "=============================================="
    Write-Host "📊 Test Summary" -ForegroundColor Yellow
    Write-Host "=============================================="
    Write-Host "Total Tests: $script:TotalTests"
    Write-Host "Passed: $script:TestsPassed" -ForegroundColor Green
    Write-Host "Failed: $script:TestsFailed" -ForegroundColor Red
    
    if ($script:TestsFailed -eq 0) {
        Write-Host ""
        Write-Host "🎉 All tests passed! Pipeline configuration looks good." -ForegroundColor Green
        exit 0
    } else {
        Write-Host ""
        Write-Host "⚠️  Some tests failed. Please review the configuration." -ForegroundColor Red
        exit 1
    }
}

# Helper function for YAML parsing (basic implementation)
function ConvertFrom-Yaml {
    param([Parameter(ValueFromPipeline)]$InputObject)
    # Basic YAML validation - just check for basic structure
    # This is a simplified implementation
    if ($InputObject -match "^\s*#.*" -or $InputObject -match "^\s*\w+\s*:" -or $InputObject -match "^\s*-\s") {
        return $true
    } else {
        throw "Invalid YAML structure"
    }
}

# Run main function
Main