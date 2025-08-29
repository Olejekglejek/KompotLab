Write-Host @'
Usage: ./ansible-run.ps1 [OPTIONS] COMMAND

Execute Ansible commands in an isolated Docker container with automatic cleanup.

ARGUMENTS:
    COMMAND                The Ansible command to execute in quotes

OPTIONS:
    -ContainerPrefix      Custom prefix for container names (default: ansible-run)
    -Help                 Show this help message

EXAMPLES:
    ./ansible-run.ps1 "ansible-playbook -i ./proxmox/inventory/inventory.yml ./proxmox/playbooks/talos-adguard.yml"
    ./ansible-run.ps1 "ansible-playbook --check -i ./proxmox/inventory/inventory.yml ./proxmox/playbooks/talos-jellyfin.yml"

NOTES:
    - Docker must be running and accessible
    - Container names include timestamp and random ID to prevent conflicts
    - Current directory is mounted as /workspace in the container
    - All dependencies from requirements.txt are installed
    - Real-time output streaming is enabled
'@
