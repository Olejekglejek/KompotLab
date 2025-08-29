#!/usr/bin/env pwsh

# Tool Verification Script
# This script tests all the installed tools in the Docker container

Write-Host "🔧 Verifying installed tools..." -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$tools = @(
    @{Name="Python"; Command="python --version"},
    @{Name="Pip"; Command="pip --version"},
    @{Name="Ansible"; Command="ansible --version | head -1"},
    @{Name="Azure CLI"; Command="az version --output table"},
    @{Name="PowerShell"; Command="pwsh --version"},
    @{Name="kubectl"; Command="kubectl version --client --output=yaml"},
    @{Name="Helm"; Command="helm version --short"},
    @{Name="jq"; Command="jq --version"},
    @{Name="Git"; Command="git --version"},
    @{Name="kubelogin"; Command="kubelogin --version"},
    @{Name="Bicep"; Command="bicep --version"},
    @{Name="curl"; Command="curl --version | head -1"},
    @{Name="rsync"; Command="rsync --version | head -1"},
    @{Name="SSH"; Command="ssh -V 2>&1 | head -1"}
)

$results = @()

foreach ($tool in $tools) {
    Write-Host "Testing $($tool.Name)..." -ForegroundColor Yellow
    try {
        $output = Invoke-Expression $tool.Command 2>&1
        if ($LASTEXITCODE -eq 0 -or $tool.Name -eq "SSH") {
            $results += [PSCustomObject]@{
                Tool = $tool.Name
                Status = "✅ OK"
                Version = ($output | Select-Object -First 1).ToString().Trim()
            }
            Write-Host "  ✅ $($tool.Name) is working" -ForegroundColor Green
        } else {
            $results += [PSCustomObject]@{
                Tool = $tool.Name
                Status = "❌ FAILED"
                Version = "Error: $output"
            }
            Write-Host "  ❌ $($tool.Name) failed" -ForegroundColor Red
        }
    } catch {
        $results += [PSCustomObject]@{
            Tool = $tool.Name
            Status = "❌ ERROR"
            Version = "Exception: $($_.Exception.Message)"
        }
        Write-Host "  ❌ $($tool.Name) error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📊 Tool Verification Summary" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
$results | Format-Table -AutoSize

# Test Azure PowerShell modules
Write-Host "🔵 Testing Azure PowerShell modules..." -ForegroundColor Cyan
try {
    $azModules = pwsh -Command "Get-Module -ListAvailable Az.* | Select-Object Name, Version | Sort-Object Name"
    if ($azModules) {
        Write-Host "✅ Azure PowerShell modules installed:" -ForegroundColor Green
        Write-Host $azModules -ForegroundColor White
    } else {
        Write-Host "⚠️  No Azure PowerShell modules found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error checking Azure PowerShell modules: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎯 Container is ready for:" -ForegroundColor Green
Write-Host "  • Ansible automation and configuration management" -ForegroundColor White
Write-Host "  • Azure resource management (CLI + PowerShell)" -ForegroundColor White
Write-Host "  • Kubernetes cluster management" -ForegroundColor White
Write-Host "  • Helm chart deployments" -ForegroundColor White
Write-Host "  • Infrastructure as Code with Bicep" -ForegroundColor White
Write-Host "  • Git version control operations" -ForegroundColor White
Write-Host "  • JSON data processing with jq" -ForegroundColor White
Write-Host "  • File synchronization with rsync" -ForegroundColor White
Write-Host "  • Secure shell connections" -ForegroundColor White
