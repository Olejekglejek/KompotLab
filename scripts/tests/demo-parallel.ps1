#!/usr/bin/env pwsh

# Demo script to show parallel execution capabilities
# This script runs multiple Ansible commands simultaneously to demonstrate
# that container names don't clash and cleanup works properly

Write-Host "🚀 Ansible Docker Runner - Parallel Execution Demo" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This demo will run 3 commands in parallel:" -ForegroundColor Yellow
Write-Host "1. ansible --version (quick command)" -ForegroundColor White
Write-Host "2. ansible-config dump (medium command)" -ForegroundColor White
Write-Host "3. sleep 3 && ansible --version (delayed command)" -ForegroundColor White
Write-Host ""

Write-Host "Each command will run in its own Docker container with unique names." -ForegroundColor Cyan
Write-Host "All containers will be automatically cleaned up after execution." -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Press Enter to start demo (or Ctrl+C to cancel)"

# Start all three commands in parallel
Write-Host "🏁 Starting parallel execution..." -ForegroundColor Green
Write-Host ""

# Command 1: Quick version check
Start-Job -Name "AnsibleVersion" -ScriptBlock {
    Set-Location $using:PWD
    ./ansible-run.ps1 "ansible --version"
}

# Command 2: Config dump
Start-Job -Name "AnsibleConfig" -ScriptBlock {
    Set-Location $using:PWD
    ./ansible-run.ps1 "ansible-config dump --only-changed"
}

# Command 3: Delayed version check
Start-Job -Name "DelayedVersion" -ScriptBlock {
    Set-Location $using:PWD
    ./ansible-run.ps1 "sleep 3 && echo '⏰ Delayed command executing...' && ansible --version"
}

# Wait for all jobs to complete and show results
Write-Host "⏳ Waiting for all commands to complete..." -ForegroundColor Yellow
Write-Host ""

$jobs = Get-Job
foreach ($job in $jobs) {
    Write-Host "📋 Results from $($job.Name):" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Gray
    $job | Wait-Job | Receive-Job
    Write-Host ""
    Write-Host "Status: $($job.State)" -ForegroundColor $(if ($job.State -eq "Completed") { "Green" } else { "Red" })
    Write-Host ""
    Write-Host "================================" -ForegroundColor Gray
    Write-Host ""
}

# Clean up jobs
Get-Job | Remove-Job

Write-Host "✅ Demo completed!" -ForegroundColor Green
Write-Host "All containers were automatically cleaned up." -ForegroundColor Cyan
Write-Host ""
Write-Host "You can verify by running: docker ps -a" -ForegroundColor Yellow
