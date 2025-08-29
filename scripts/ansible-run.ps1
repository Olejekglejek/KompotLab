#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [string]$ContainerPrefix = 'ansible-run',

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

if ($Help) {
    . "$PSScriptRoot/ansible-help.ps1"
    exit 0
}

# Check if Docker is running
try {
    $null = docker version
    Write-Host '✅ Docker is running' -ForegroundColor Green
}
catch {
    throw '❌ Docker is not running or not accessible. Please start Docker and try again.'
}

# Main execution
try {
    Write-Host '🐳 Running Ansible in Docker' -ForegroundColor Cyan
    Write-Host '============================' -ForegroundColor Cyan

    # Generate unique container name
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $randomId = Get-Random -Minimum 100000 -Maximum 999999
    $containerName = "${ContainerPrefix}-${timestamp}-${randomId}"
    Write-Host "🏷️  Container name: $containerName" -ForegroundColor Yellow


    # Get scripts directory and project root
    $scriptsDir = $PSScriptRoot
    $projectRoot = Split-Path $scriptsDir -Parent
    Write-Host "📁 Scripts directory: $scriptsDir" -ForegroundColor Cyan
    Write-Host "📁 Project root: $projectRoot" -ForegroundColor Cyan

    Write-Host '📋 Using Dockerfile from project root...' -ForegroundColor Cyan
    $dockerfilePath = Join-Path $projectRoot 'Dockerfile'


    try {
        # Build the Docker image
        $imageName = "${ContainerPrefix}:latest"
        Write-Host '🔨 Building Docker image...' -ForegroundColor Cyan

        $buildResult = docker build -t $imageName -f $dockerfilePath $projectRoot 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error '❌ Failed to build Docker image'
            Write-Host $buildResult -ForegroundColor Red
            exit 1
        }

        Write-Host '✅ Docker image built successfully' -ForegroundColor Green

        # Prepare docker run command
        $dockerArgs = @(
            'run'
            '--rm'  # Auto-remove container when it exits
            '-it'   # Interactive terminal
            '--name', $containerName
            '-v', "${projectRoot}:/workspace"
            '-w', '/workspace'
            $imageName
            'sh', '-c', $Command
        )

        Write-Host '🧹 Container will be automatically cleaned up after execution' -ForegroundColor Yellow


        Write-Host "🚀 Executing command: $Command" -ForegroundColor Cyan
        Write-Host '⏱️  Starting execution...' -ForegroundColor Cyan
        Write-Host '----------------------------------------' -ForegroundColor Gray

        # Execute the command in Docker container
        $startTime = Get-Date
        & docker @dockerArgs
        $exitCode = $LASTEXITCODE
        $endTime = Get-Date
        $duration = $endTime - $startTime

        Write-Host '----------------------------------------' -ForegroundColor Gray

        if ($exitCode -eq 0) {
            Write-Host '✅ Command executed successfully' -ForegroundColor Green
        }
        else {
            Write-Host "❌ Command failed with exit code: $exitCode" -ForegroundColor Red
        }

        Write-Host "⏱️  Execution time: $($duration.ToString('mm\:ss\.fff'))" -ForegroundColor Cyan

        exit $exitCode

    }
    finally {
        # Cleanup container if something went wrong
        try {
            $containerExists = docker ps -a --format 'table {{.Names}}' | Select-String $containerName
            if ($containerExists) {
                Write-Host '🧹 Cleaning up container...' -ForegroundColor Cyan
                docker rm -f $containerName 2>$null
            }
        }
        catch {
            Write-Error "❌ Failed to clean up container: $($_.Exception.Message)"
        }
    }

}
catch {
    Write-Error "❌ An unexpected error occurred: $($_.Exception.Message)"
    exit 1
}
