#!/usr/bin/env pwsh

# Quick wrapper script for common Ansible playbook executions
# Usage: ./ansible-quick.ps1 [playbook-name] [additional-args]

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$PlaybookName,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$AdditionalArgs = "",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$List
)

# Define available playbooks relative to project root
$scriptsDir = $PSScriptRoot
$projectRoot = Split-Path $scriptsDir -Parent
$playbooks = @{
    "adguard"     = "proxmox/playbooks/talos-adguard.yml"
    "jellyfin"    = "proxmox/playbooks/talos-jellyfin.yml"
    "filebrowser" = "proxmox/playbooks/talos-filebrowser.yml"
    "talos"       = "proxmox/playbooks/talos-infra.yml"
    "proxmox"     = "proxmox/playbooks/proxmox-infra.yml"
    "usb-direct"  = "proxmox/playbooks/usb-passthrough-direct.yml"
    "usb-ssh"     = "proxmox/playbooks/usb-passthrough-ssh.yml"
    "usb-talos"   = "proxmox/playbooks/usb-passthrough-talos.yml"
}

$inventoryPath = "proxmox/inventory/inventory.yml"

if ($List) {
    Write-Host "Available playbooks:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    foreach ($key in $playbooks.Keys | Sort-Object) {
        Write-Host "  $key" -ForegroundColor Yellow -NoNewline
        Write-Host " -> $($playbooks[$key])" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Usage examples:" -ForegroundColor Cyan
    Write-Host "  ./ansible-quick.ps1 adguard" -ForegroundColor White
    Write-Host "  ./ansible-quick.ps1 jellyfin --check" -ForegroundColor White
    Write-Host "  ./ansible-quick.ps1 infra -DryRun" -ForegroundColor White
    exit 0
}

if (-not $PlaybookName) {
    Write-Error "❌ PlaybookName is required"
    Write-Host "Available playbooks: $($playbooks.Keys -join ', ')" -ForegroundColor Yellow
    Write-Host "Use -List to see all available playbooks with their paths" -ForegroundColor Cyan
    exit 1
}

if (-not $playbooks.ContainsKey($PlaybookName)) {
    Write-Error "❌ Unknown playbook: $PlaybookName"
    Write-Host "Available playbooks: $($playbooks.Keys -join ', ')" -ForegroundColor Yellow
    Write-Host "Use -List to see all available playbooks with their paths" -ForegroundColor Cyan
    exit 1
}

$playbookPath = $playbooks[$PlaybookName]

# Build the ansible command
$command = "ansible-playbook -i $inventoryPath $playbookPath"

if ($DryRun) {
    $command += " --check"
}

if ($AdditionalArgs) {
    $command += " $AdditionalArgs"
}

Write-Host "🎭 Running playbook: $PlaybookName" -ForegroundColor Cyan
Write-Host "📋 Command: $command" -ForegroundColor Yellow

# Prepare arguments for the main script
$scriptArgs = @($command)

# Call the main ansible-run.ps1 script
& "./ansible-run.ps1" @scriptArgs
