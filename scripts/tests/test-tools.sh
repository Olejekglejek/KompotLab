#!/bin/bash
# Tool verification script for the containerized environment

echo "🛠️  Tool Verification Report"
echo "============================"
echo ""

check_tool() {
    local tool=$1
    local expected_output=$2
    echo -n "Testing $tool..."
    if command -v "$tool" &> /dev/null; then
        if [ -n "$expected_output" ]; then
            if $tool $expected_output &> /dev/null; then
                echo " ✅ Working"
            else
                echo " ⚠️  Found but error on test command"
            fi
        else
            echo " ✅ Found"
        fi
    else
        echo " ❌ Not found"
    fi
}

check_version() {
    local tool=$1
    local version_flag=$2
    echo -n "Testing $tool..."
    if command -v "$tool" &> /dev/null; then
        version_output=$($tool $version_flag 2>/dev/null | head -1 || echo "Version check failed")
        echo " ✅ $version_output"
    else
        echo " ❌ Not found"
    fi
}

echo "Core Tools:"
check_version "python" "--version"
check_version "pip" "--version"
check_version "git" "--version"

echo ""
echo "Ansible & Configuration Management:"
check_version "ansible" "--version"
check_version "ansible-playbook" "--version"
check_tool "ansible-galaxy" "--version"
check_tool "ansible-lint" "--version"

echo ""
echo "Azure Tools:"
check_version "az" "--version"
check_tool "kubelogin" "--version"
check_tool "bicep" "--version"

echo ""
echo "Kubernetes Tools:"
check_version "kubectl" "version --client"
check_version "helm" "version --client"

echo ""
echo "Development Tools:"
check_tool "jq" "--version"
check_tool "curl" "--version"
check_tool "ssh" "-V"

echo ""
echo "PowerShell Test:"
if command -v "pwsh" &> /dev/null; then
    echo "PowerShell: ✅ Found - $(pwsh --version 2>/dev/null || echo 'Version check failed')"
    pwsh_test=$(pwsh -c "Get-Host" 2>/dev/null || echo "PowerShell execution failed")
    if [[ $pwsh_test == *"PowerShell execution failed"* ]]; then
        echo "PowerShell Execution: ⚠️  PowerShell found but may not work properly on this architecture"
    else
        echo "PowerShell Execution: ✅ Working"
    fi
else
    echo "PowerShell: ❌ Not found"
fi

echo ""
echo "🎯 Summary: Most tools should be available for Ansible operations!"
