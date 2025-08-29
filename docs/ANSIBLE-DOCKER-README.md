# Ansible Docker Runner

This project provides PowerShell scripts to run Ansible commands in Docker containers, eliminating the need to manage Python virtual environments locally.

## Features

- ✅ **Isolated execution**: Each command runs in a fresh Docker container
- ✅ **Automatic cleanup**: Containers are removed after execution
- ✅ **Parallel execution**: Multiple commands can run simultaneously with unique container names
- ✅ **Real-time output**: Stream command output directly to your terminal
- ✅ **Error handling**: Proper cleanup even when commands fail
- ✅ **Quick shortcuts**: Predefined commands for common playbooks

## Scripts

### 1. `ansible-run.ps1` - Main Script

The main script that creates and runs Ansible commands in Docker containers.

```powershell
# Basic usage
./ansible-run.ps1 "ansible-playbook -i ./proxmox/inventory/inventory.yml ./proxmox/playbooks/talos-adguard.yml"

# Check mode (dry run)
./ansible-run.ps1 "ansible-playbook --check -i ./proxmox/inventory/inventory.yml ./proxmox/playbooks/talos-jellyfin.yml"

# Get help
./ansible-run.ps1 -Help
```

### 2. `ansible-quick.ps1` - Quick Wrapper

A convenient wrapper for common playbook executions.

```powershell
# List available playbooks
./ansible-quick.ps1 -List

# Run a playbook
./ansible-quick.ps1 adguard
./ansible-quick.ps1 jellyfin
./ansible-quick.ps1 infra

# Dry run
./ansible-quick.ps1 adguard -DryRun

# Additional ansible arguments
./ansible-quick.ps1 jellyfin "--extra-vars 'debug=true'"
```

## Available Quick Playbooks

| Name | Playbook Path |
|------|---------------|
| `adguard` | `./proxmox/playbooks/talos-adguard.yml` |
| `jellyfin` | `./proxmox/playbooks/talos-jellyfin.yml` |
| `filebrowser` | `./proxmox/playbooks/talos-filebrowser.yml` |
| `infra` | `./proxmox/playbooks/talos-infra.yml` |
| `usb-direct` | `./proxmox/playbooks/usb-passthrough-direct.yml` |
| `usb-ssh` | `./proxmox/playbooks/usb-passthrough-ssh.yml` |
| `usb-talos` | `./proxmox/playbooks/usb-passthrough-talos.yml` |

## Prerequisites

1. **Docker**: Make sure Docker is installed and running
2. **PowerShell**: The scripts are designed for PowerShell (pwsh)
3. **Requirements**: The `requirements.txt` file should be in the project root

## How It Works

1. **Dockerfile Detection**: First checks if a `Dockerfile` exists in the project root
   - If exists: Uses the existing Dockerfile (optimized for Ansible operations)
   - If missing: Creates a temporary Dockerfile with basic Ansible setup
2. **Container Creation**: Builds a Docker image with Python 3.11 and all dependencies from `requirements.txt`
3. **Volume Mounting**: Mounts your current directory as `/workspace` in the container
4. **Command Execution**: Runs your Ansible command with real-time output streaming
5. **Cleanup**: Automatically removes the container and temporary files (if created)

## Parallel Execution

You can run multiple commands in parallel without conflicts:

```powershell
# Terminal 1
./ansible-quick.ps1 adguard

# Terminal 2 (simultaneously)
./ansible-quick.ps1 jellyfin
```

Each execution gets a unique container name with timestamp and random ID:
- `ansible-run-20250820-143022-847291`
- `ansible-run-20250820-143025-192847`

## Troubleshooting

### Docker Issues
```powershell
# Check if Docker is running
docker version

# If Docker is not running, start it
# On macOS: Start Docker Desktop
# On Linux: sudo systemctl start docker
```

### Permission Issues
```powershell
# Make scripts executable (if needed)
chmod +x ansible-run.ps1
chmod +x ansible-quick.ps1
```

### Container Cleanup
```powershell
# List running containers
docker ps

# Remove stuck containers manually
docker rm -f container-name

# Remove all stopped containers
docker container prune
```

## Examples

### Run AdGuard Deployment
```powershell
./ansible-quick.ps1 adguard
```

### Check Jellyfin Playbook Without Changes
```powershell
./ansible-quick.ps1 jellyfin -DryRun
```

### Run Custom Ansible Command
```powershell
./ansible-run.ps1 "ansible all -i ./proxmox/inventory/inventory.yml -m ping"
```

### Azure Integration Examples

```powershell
# Azure login and resource management
./ansible-run.ps1 "az login && az account list"

# Kubernetes cluster management
./ansible-run.ps1 "az aks get-credentials --resource-group myRG --name myCluster"

# Bicep template deployment
./ansible-run.ps1 "bicep build template.bicep"

# Azure PowerShell operations
./ansible-run.ps1 "pwsh -c 'Connect-AzAccount; Get-AzResourceGroup'"
```

### Kubernetes Examples

```powershell
# Check cluster connectivity
./ansible-run.ps1 "kubectl cluster-info"

# Deploy with Helm
./ansible-run.ps1 "helm install my-app ./my-chart"

# Process JSON with jq
./ansible-run.ps1 "kubectl get pods -o json | jq '.items[].metadata.name'"
```



## Configuration

The Docker container includes:
- **Base**: Alpine Linux 3.19 (lightweight and secure)
- **Python 3**: With pip and all packages from `requirements.txt`
- **Ansible Tools**: ansible, ansible-lint, yamllint, flake8
- **Azure Tools**:
  - Azure CLI (az)
  - Azure PowerShell modules (Az.*)
  - kubelogin (Azure Kubernetes authentication)
  - Bicep (Azure Infrastructure as Code)
- **Kubernetes Tools**:
  - kubectl (Kubernetes CLI)
  - Helm (Kubernetes package manager)
- **Development Tools**:
  - PowerShell Core 7.4+ (pwsh)
  - Git (version control)
  - jq (JSON processor)
  - curl, wget (HTTP clients)
  - rsync (file synchronization)
  - SSH client and sshpass

Environment variables set in container:
- `ANSIBLE_HOST_KEY_CHECKING=False`
- `ANSIBLE_STDOUT_CALLBACK=yaml`
- `ANSIBLE_CALLBACKS_ENABLED=timer`
- `PYTHONUNBUFFERED=1`
- `ANSIBLE_FORCE_COLOR=1`

### Tool Verification

Run the tool verification script to check all installed tools:
```powershell
./ansible-run.ps1 "pwsh ./test-tools.ps1"
```

### Docker Build Optimization

A `.dockerignore` file is included to speed up builds by excluding:
- Version control files (.git, .github)
- Python cache files (__pycache__, *.pyc)
- Virtual environments (virtualBerry/)
- IDE files (.vscode, .idea)
- Documentation files (*.md, README*)
- Temporary and log files
