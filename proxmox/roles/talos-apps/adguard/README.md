# AdGuard Home Kubernetes Deployment

A production-ready AdGuard Home deployment for Kubernetes that automatically handles both initial setup and post-setup phases without requiring manual configuration changes.

## Kubernetes Files Overview

This deployment consists of 8 Kubernetes manifest files that work together to create a complete AdGuard Home setup:

### Core Deployment Files

#### 1. `namespace.yaml` - Namespace Isolation
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: adguard
```
**Purpose**: Creates a dedicated namespace called `adguard` to isolate all AdGuard resources from other applications in the cluster.

#### 2. `adguard-deployment.yaml` - Main Application Deployment
**Purpose**: Defines the AdGuard Home pod configuration including:
- **Security Context**: Runs as root (UID 0) during initialization (required by AdGuard Home)
- **Container Ports**: Exposes ports 3000 (setup), 80 (post-setup), and 53 (DNS)
- **Health Checks**:
  - Startup probe: TCP check on port 80 with 2.5-minute timeout
  - Liveness probe: Monitors port 80 for container health
  - Readiness probe: Checks port 80 for traffic readiness
- **Resource Limits**: CPU (50m-500m), Memory (128Mi-512Mi)
- **Init Container**: Sets proper file permissions as non-root user

#### 3. `adguard-service.yaml` - Network Access
**Purpose**: Exposes AdGuard Home to the network with dual-port configuration:
```yaml
ports:
  - name: http-setup    # Port 3000 for initial setup
  - name: http-ui       # Port 80 for post-setup usage
  - name: dns-udp       # Port 53 UDP for DNS queries
  - name: dns-tcp       # Port 53 TCP for DNS queries
```
- **Type**: LoadBalancer (falls back to NodePort on bare metal)
- **Traffic Policy**: Cluster (distributes across all nodes)

### Persistent Storage Files

#### 4. `adguard-pv.yaml` - Data Persistent Volume
**Purpose**: Creates a 1GB persistent volume for AdGuard data using hostPath storage:
- **Path**: `/var/lib/adguardhome` on the cluster node
- **Reclaim Policy**: Retain (data survives pod deletion)
- **Access Mode**: ReadWriteOnce (single node access)

#### 5. `adguard-pvc.yaml` - Data Volume Claim
**Purpose**: Claims the data persistent volume for use by the deployment:
- **Storage**: 1GB
- **Binding**: Static binding to `adguard-pv`

#### 6. `adguard-config-pv.yaml` - Configuration Persistent Volume
**Purpose**: Creates a 100MB persistent volume specifically for AdGuard configuration:
- **Path**: `/var/lib/adguardhome-config` on the cluster node
- **Prevents**: Configuration loss when pods restart

#### 7. `adguard-config-pvc.yaml` - Configuration Volume Claim
**Purpose**: Claims the configuration persistent volume:
- **Storage**: 100MB
- **Binding**: Static binding to `adguard-config-pv`

### Optional Files

#### 8. `adguard-configmap.yaml` - Initial Configuration
**Purpose**: Provides optional pre-seeded configuration (currently placeholder)

### Orchestration

#### 9. `kustomization.yaml` - Unified Deployment
**Purpose**: Aggregates all resources for single-command deployment:
- **Resources**: Lists all YAML files to deploy together
- **Common Labels**: Applies consistent labels across all resources
- **Label Selectors**: Ensures proper service-to-pod matching

## Step-by-Step Deployment Guide

### Prerequisites
- Kubernetes cluster with kubectl access
- At least one worker node with `/var/lib/` write access

### Deployment Steps

#### Step 1: Deploy All Resources
```bash
# Navigate to the adguard directory
cd talos/apps/adguard

# Deploy everything with one command
kubectl apply -k .

# Expected output:
# namespace/adguard created
# configmap/adguard-config created
# service/adguard created
# persistentvolume/adguard-config-pv created
# persistentvolume/adguard-pv created
# persistentvolumeclaim/adguard-config-pvc created
# persistentvolumeclaim/adguard-pvc created
# deployment.apps/adguard created
```

#### Step 2: Wait for Pod to be Ready
```bash
# Watch pod startup (may take 1-2 minutes)
kubectl get pods -l app=adguard -w

# Expected progression:
# NAME                     READY   STATUS    RESTARTS   AGE
# adguard-xxx-yyy         0/1     Pending    0          5s
# adguard-xxx-yyy         0/1     ContainerCreating   0          10s
# adguard-xxx-yyy         1/1     Running    0          45s
```

#### Step 3: Get Access Information
```bash
# Get service details and port assignments
kubectl get svc adguard

# Example output:
# NAME      TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)
# adguard   LoadBalancer   10.108.124.172   <pending>     3000:32739/TCP,80:31359/TCP,53:31883/UDP,53:31883/TCP

# Get node IP addresses
kubectl get nodes -o wide

# Example output:
# NAME            STATUS   ROLES           INTERNAL-IP     EXTERNAL-IP
# talos-node-1    Ready    control-plane   192.168.1.104   <none>
# talos-node-2    Ready    <none>          192.168.1.245   <none>
```

#### Step 4: Access AdGuard Home

**For Fresh Installation (First Time Setup):**
1. **Open Setup URL**: `http://192.168.1.245:32739` (replace with your node IP and actual NodePort for port 3000)
2. **Complete Setup Wizard**:
   - Choose admin interface bind port: **Keep default (3000)**
   - Set admin username and password
   - Configure upstream DNS servers (e.g., 8.8.8.8, 1.1.1.1)
   - Test configuration
   - Finish setup

**For Post-Setup Usage:**
1. **Open Main URL**: `http://192.168.1.245:31359` (replace with your node IP and actual NodePort for port 80)
2. **Login**: Use the credentials you created during setup
3. **Configure DNS**: Point your devices/router to `192.168.1.245:31883` for DNS

#### Step 5: Configure DNS on Your Network
```bash
# Test DNS is working
dig @192.168.1.245 -p 31883 google.com

# Expected output should show DNS resolution working
```

**Router Configuration:**
- Set primary DNS: `192.168.1.245` (or your node IP)
- DNS Port: `31883` (or your actual NodePort for port 53)

### Understanding Port Behavior

**AdGuard Home Port Logic:**
- **Fresh Installation**: Starts on port 3000 for initial setup wizard
- **Post-Setup**: Automatically switches to port 80 for normal operation
- **Our Solution**: Service exposes both ports simultaneously, so no manual changes needed

**Port Assignments (NodePort will vary):**
- Port 3000 → NodePort 32739 (setup phase)
- Port 80 → NodePort 31359 (normal operation)
- Port 53 → NodePort 31883 (DNS service)

### Verification Commands

```bash
# Check all AdGuard resources
kubectl get all -l app=adguard

# Verify persistent storage
kubectl get pv,pvc

# Check pod logs
kubectl logs deployment/adguard

# Test web access (replace with your actual NodePorts)
curl -I http://192.168.1.245:32739  # Setup port (may not respond if already configured)
curl -I http://192.168.1.245:31359  # Main UI port

# Test DNS
dig @192.168.1.245 -p 31883 google.com
```

### Cluster Migration Process

**To migrate this setup to another cluster:**

1. **Deploy on new cluster**:
   ```bash
   kubectl apply -k talos/apps/adguard
   ```

2. **Copy configuration (optional)**:
   ```bash
   # From old cluster - backup config
   kubectl exec deployment/adguard -- tar -czf - -C /opt/adguardhome/conf . > adguard-config-backup.tar.gz

   # To new cluster - restore config (if needed)
   kubectl exec deployment/adguard -- tar -xzf - -C /opt/adguardhome/conf < adguard-config-backup.tar.gz
   ```

3. **Access and verify**: Configuration should be preserved if using shared storage

## Troubleshooting Common Issues

### Pod Won't Start
```bash
# Check pod status and events
kubectl describe pod -l app=adguard

# Check persistent volume binding
kubectl get pv,pvc
```

### Can't Access Web UI
```bash
# Verify service endpoints
kubectl get endpoints adguard

# Check if pod is ready
kubectl get pods -l app=adguard

# Verify NodePort assignments
kubectl get svc adguard
```

### DNS Not Working
```bash
# Test DNS directly
dig @192.168.1.245 -p 31883 google.com

# Check DNS pod logs
kubectl logs deployment/adguard | grep dns
```

### Configuration Lost After Restart
```bash
# Verify config volume is mounted
kubectl exec deployment/adguard -- ls -la /opt/adguardhome/conf/

# Check persistent volume
kubectl describe pvc adguard-config-pvc
```

## Cleanup

```bash
# Remove deployment (keeps persistent data)
kubectl delete -k talos/apps/adguard

# Complete cleanup (WARNING: destroys all data)
kubectl delete -k talos/apps/adguard
# Note: hostPath data on nodes requires manual cleanup if needed
```

## Security Considerations

- **Root Access**: AdGuard requires root privileges for initialization (binding to port 53)
- **Capabilities**: Only `NET_BIND_SERVICE` capability is granted
- **Network Policy**: Consider adding NetworkPolicy to restrict DNS access if needed
- **TLS**: Add cert-manager and ingress for HTTPS access in production## LoadBalancer Setup (Optional)
For external IP assignment, install MetalLB on bare metal clusters:

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
```

**MetalLB Configuration** (adjust IP range for your network):
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
```

## Troubleshooting

### Common Issues
- **Pod not ready**: Check `kubectl logs deployment/adguard` - startup probe allows up to 2.5 minutes
- **Port 3000 not responding**: Normal after setup completion - AdGuard switches to port 80
- **Port 80 not responding**: Check if initial setup is complete via port 3000 first
- **Configuration lost**: Verify persistent volumes are properly mounted and writable

### Useful Commands
```bash
# Check all resources
kubectl get all -l app=adguard

# Verify persistent storage
kubectl get pv,pvc
kubectl exec deployment/adguard -- ls -la /opt/adguardhome/

# Network debugging
kubectl get endpoints adguard
kubectl describe svc adguard

# Reset deployment (keeps data)
kubectl rollout restart deployment/adguard
```

## Cleanup
```bash
# Remove deployment (keeps persistent data)
kubectl delete -k talos/apps/adguard

# Complete cleanup including data
kubectl delete -k talos/apps/adguard
sudo rm -rf /var/lib/adguardhome /var/lib/adguardhome-config
```

---

## Summary
This deployment provides a production-ready AdGuard Home setup that requires **zero manual intervention** after initial setup. The dual-port configuration ensures seamless operation whether you're doing initial setup or daily usage, making it perfect for cluster migrations and automated deployments.
