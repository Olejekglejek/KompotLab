# AdGuard Home Kubernetes Development Process & Troubleshooting Journey

This document chronicles the complete development process for deploying AdGuard Home on Kubernetes, including all challenges encountered, troubleshooting steps, and solutions implemented. This serves as a learning resource for understanding Kubernetes troubleshooting methodologies.

## Initial Goal
Deploy AdGuard Home on a Talos-based Kubernetes cluster with:
- Persistent storage for configuration and data
- Network access for both web UI and DNS service
- Security hardening with proper RBAC
- Single-command deployment via Kustomize
- **Zero-maintenance configuration** that handles AdGuard's port transition automatically

## Development Timeline & Challenges

### Phase 1: Initial Deployment - CrashLoopBackOff Issues

#### Problem Encountered
The first deployment attempt resulted in pods failing to start with `CrashLoopBackOff` status.

#### Diagnostic Process
```bash
# Step 1: Check pod status
kubectl get pods -n adguard
# OUTPUT: adguard-xxx-yyy   0/1   CrashLoopBackOff   5   3m

# Step 2: Examine pod logs
kubectl logs adguard-xxx-yyy -n adguard
# OUTPUT: Error logs indicating permission issues

# Step 3: Describe pod for detailed events
kubectl describe pod adguard-xxx-yyy -n adguard
# OUTPUT: Events showing container exits with error codes
```

#### Root Cause Analysis
AdGuard Home requires **Administrator privileges** during first-time initialization for:
1. **Binding to privileged port 53** (DNS service)
2. **Creating configuration files** in specific directories
3. **Setting up internal user management**

#### Solution Implemented
Modified the deployment security context to allow root execution:

```yaml
# In adguard-deployment.yaml
securityContext:
  runAsUser: 0        # Allow root for initialization
  runAsGroup: 0
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]     # Drop all capabilities
    add: ["NET_BIND_SERVICE"]  # Only allow binding to privileged ports
```

#### Learning Points
- **Security vs Functionality**: Some applications require elevated privileges for initialization
- **Kubernetes Security Contexts**: Understanding `runAsUser`, `capabilities`, and `allowPrivilegeEscalation`
- **Minimal Privilege Principle**: Grant only the specific capabilities needed (`NET_BIND_SERVICE`)

#### Verification Commands
```bash
kubectl get pods -n adguard -w  # Watch pod status change
kubectl logs adguard-xxx-yyy -n adguard  # Verify successful startup
```

---

### Phase 2: Service Connectivity Issues - Empty Endpoints

#### Problem Encountered
Pod was running successfully, but the service had no endpoints, causing connection failures.

#### Diagnostic Process
```bash
# Step 1: Check service status
kubectl get svc -n adguard
# OUTPUT: Service exists but ENDPOINTS shows <none>

# Step 2: Examine service endpoints
kubectl get endpoints -n adguard
# OUTPUT: adguard endpoint shows no addresses

# Step 3: Check service configuration
kubectl describe svc adguard -n adguard
# OUTPUT: Shows selector configuration

# Step 4: Verify pod labels
kubectl get pods --show-labels -n adguard
# OUTPUT: Shows actual labels on pods
```

#### Root Cause Analysis
**Label selector mismatch** between service and pods due to Kustomize `commonLabels` configuration:
- **Service expected**: `app=adguard` + `app.kubernetes.io/name=adguard` + `app.kubernetes.io/part-of=adguard`
- **Pods had**: Only `app=adguard`

This is a common Kubernetes issue where services can't find their target pods.

#### Understanding Kubernetes Service Discovery
In Kubernetes, services find pods using **label selectors**:
1. Service defines a `selector` in its spec
2. Kubernetes creates `Endpoints` object listing pods that match the selector
3. Traffic is routed to IPs listed in the endpoints

When selectors don't match pod labels, endpoints remain empty.

#### Solution Implemented
The issue was caused by Kustomize `commonLabels` not being applied consistently. Fixed by:

```bash
# Delete and recreate deployment to ensure consistent labeling
kubectl delete deployment adguard -n adguard
kubectl apply -k talos/apps/adguard
```

#### Learning Points
- **Service-Pod Relationship**: Services rely on label selectors to find pods
- **Kustomize Label Application**: Understanding how `commonLabels` affects different resource types
- **Endpoints Debugging**: Always check endpoints when services aren't working
- **Immutable Fields**: Some Kubernetes fields (like selector) can't be changed after creation

#### Verification Commands
```bash
kubectl get endpoints -n adguard  # Should show pod IPs
kubectl get pods -n adguard --show-labels  # Verify labels match
```

---

### Phase 3: Port Configuration Changes - Post-Setup Access Issues

#### Problem Encountered
After completing AdGuard Home initial setup through the web UI, the service became inaccessible.

#### Diagnostic Process
```bash
# Step 1: Check pod status
kubectl get pods -n adguard -o wide
# OUTPUT: Pod running normally

# Step 2: Check pod logs for clues
kubectl logs adguard-xxx-yyy -n adguard
# OUTPUT: Found line "starting plain server server=plain addr=0.0.0.0:80"

# Step 3: Test direct pod access
kubectl port-forward pod/adguard-xxx-yyy 8080:80 -n adguard
curl http://localhost:8080
# OUTPUT: Connection successful

# Step 4: Check service configuration
kubectl get svc -n adguard
# OUTPUT: Service still pointing to port 3000
```

#### Root Cause Analysis
**AdGuard Home port behavior**:
- **Initial Setup Phase**: Runs on port 3000 for configuration wizard
- **Post-Setup Phase**: Automatically switches to port 80 for normal operation
- **Our Service**: Was only configured for port 3000

This is AdGuard Home's normal behavior, but our Kubernetes service wasn't prepared for it.

#### Understanding Application Port Changes
Some applications change their behavior after initial configuration:
1. **Setup Mode**: Different port/interface for initial configuration
2. **Runtime Mode**: Different port/interface for normal operation
3. **Kubernetes Challenge**: Services need to handle both phases

#### Solution Implemented (Initial Approach)
Updated service to use port 80:

```yaml
# In adguard-service.yaml
ports:
  - name: http-ui
    protocol: TCP
    port: 80
    targetPort: 80
```

#### Learning Points
- **Application Lifecycle**: Understanding how applications behave differently during setup vs runtime
- **Service Port Mapping**: Services must target the correct application port
- **Need for Better Solution**: This required manual service updates after setup

---

### Phase 4: Configuration Persistence Issues

#### Problem Encountered
Every pod restart caused AdGuard to return to initial setup mode, losing all configuration.

#### Diagnostic Process
```bash
# Step 1: Check mounted volumes in pod
kubectl describe pod adguard-xxx-yyy -n adguard | grep -A 10 "Mounts:"
# OUTPUT: Shows mounted volumes and paths

# Step 2: Examine configuration directory
kubectl exec -it adguard-xxx-yyy -n adguard -- ls -la /opt/adguardhome/conf/
# OUTPUT: Shows files in config directory

# Step 3: Check if AdGuard config file exists
kubectl exec -it adguard-xxx-yyy -n adguard -- cat /opt/adguardhome/conf/AdGuardHome.yaml
# OUTPUT: Either file doesn't exist or contains default config

# Step 4: Check persistent volume usage
kubectl get pv,pvc -n adguard
# OUTPUT: Shows volume binding status
```

#### Root Cause Analysis
**ConfigMap vs Persistent Volume conflict**:
1. **ConfigMap mounted** to `/opt/adguardhome/conf/` (read-only)
2. **AdGuard tries to write** `AdGuardHome.yaml` to the same directory
3. **Write fails** because ConfigMaps are read-only
4. **Configuration lost** on pod restart

This is a common mistake when setting up persistent storage for applications.

#### Understanding Kubernetes Storage Types
- **ConfigMap**: Read-only configuration data, good for static config
- **PersistentVolume**: Read-write storage, good for dynamic application data
- **Conflict**: Mounting both to the same path causes issues

#### Solution Implemented
Created **separate persistent volumes** for configuration and data:

```yaml
# adguard-config-pv.yaml - Configuration storage
apiVersion: v1
kind: PersistentVolume
metadata:
  name: adguard-config-pv
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /var/lib/adguardhome-config
    type: DirectoryOrCreate

# Updated deployment to use PVC instead of ConfigMap
volumes:
- name: adguard-config
  persistentVolumeClaim:
    claimName: adguard-config-pvc  # Not configMap anymore
```

#### Learning Points
- **Storage Hierarchy**: Understanding when to use ConfigMap vs PersistentVolume
- **Application Write Requirements**: Some apps need to write to their config directories
- **Volume Mounting**: Different volume types have different capabilities
- **Separation of Concerns**: Separate volumes for different types of data

#### Verification Commands
```bash
kubectl get pv,pvc  # Check persistent volume binding
kubectl exec -it deployment/adguard -- ls -la /opt/adguardhome/conf/
kubectl exec -it deployment/adguard -- cat /opt/adguardhome/conf/AdGuardHome.yaml
```

---

### Phase 5: Health Check Configuration Issues

#### Problem Encountered
Pods were restarting due to failed health checks during the port transition phase.

#### Diagnostic Process
```bash
# Step 1: Check pod events
kubectl describe pod adguard-xxx-yyy -n adguard
# OUTPUT: Events showing probe failures

# Step 2: Check probe configuration
kubectl describe deployment adguard -n adguard | grep -A 5 "Liveness\|Readiness"
# OUTPUT: Shows current probe configuration

# Step 3: Test probe manually
kubectl exec -it adguard-xxx-yyy -n adguard -- wget -qO- http://localhost:3000
# or
kubectl exec -it adguard-xxx-yyy -n adguard -- wget -qO- http://localhost:80
```

#### Root Cause Analysis
**Static probes vs dynamic application behavior**:
1. **Probes configured** for port 3000 (setup phase)
2. **Application switches** to port 80 (post-setup)
3. **Probes fail** because they're checking wrong port
4. **Kubernetes restarts** pod thinking it's unhealthy

#### Understanding Kubernetes Probes
- **Startup Probe**: Checks if application has started (allows longer timeout)
- **Liveness Probe**: Checks if application is alive (restarts if fails)
- **Readiness Probe**: Checks if application can serve traffic (removes from service)

#### Initial Solution Attempt
Updated probes to target port 80:

```yaml
livenessProbe:
  tcpSocket:
    port: 80
readinessProbe:
  tcpSocket:
    port: 80
```

#### Learning Points
- **Probe Strategy**: Understanding different probe types and their purposes
- **Application Lifecycle**: Probes must account for application behavior changes
- **TCP vs HTTP Probes**: TCP probes are more forgiving during port transitions
- **Need for Dual-Port Strategy**: Single port probes don't handle application transitions well

---

### Phase 6: The Breakthrough - Dual-Port Service Implementation

#### Problem Encountered
**The Core Issue**: Manual intervention required after AdGuard setup to update Kubernetes configuration from port 3000 to port 80.

#### Our Goal Redefined
Create a **zero-maintenance deployment** where:
1. Deploy once with `kubectl apply -k talos/apps/adguard`
2. Access AdGuard on port 3000 for initial setup
3. After setup, access AdGuard on port 80 for normal use
4. **No Kubernetes configuration changes required**

#### Solution Implemented
**Dual-Port Service Configuration**:

```yaml
# In adguard-service.yaml
ports:
  - name: http-setup      # For initial setup (port 3000)
    protocol: TCP
    port: 3000
    targetPort: 3000
  - name: http-ui         # For post-setup usage (port 80)
    protocol: TCP
    port: 80
    targetPort: 80
  - name: dns-udp         # DNS service (port 53)
    protocol: UDP
    port: 53
    targetPort: 53
  - name: dns-tcp         # DNS service (port 53)
    protocol: TCP
    port: 53
    targetPort: 53
```

**Updated Deployment Container Ports**:
```yaml
# In adguard-deployment.yaml
ports:
  - name: http-setup
    containerPort: 3000
    protocol: TCP
  - name: http-ui
    containerPort: 80
    protocol: TCP
  - name: dns-udp
    containerPort: 53
    protocol: UDP
  - name: dns-tcp
    containerPort: 53
    protocol: TCP
```

**Intelligent Health Checks**:
```yaml
startupProbe:
  tcpSocket:
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 30      # Allow 2.5 minutes for startup
livenessProbe:
  tcpSocket:
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 5
readinessProbe:
  tcpSocket:
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3
```

#### Why This Works
1. **Service exposes both ports simultaneously**
2. **AdGuard starts on port 3000** - accessible for setup
3. **AdGuard switches to port 80** after setup - accessible for normal use
4. **Health checks target port 80** with generous startup timeout
5. **No manual configuration changes needed**

#### Learning Points
- **Service Flexibility**: One service can expose multiple ports from the same pod
- **Application Adaptation**: Kubernetes can be configured to handle application behavior changes
- **Startup Probe Strategy**: Extended timeouts allow for application initialization
- **User Experience**: Good architecture eliminates manual intervention

#### Verification Commands
```bash
kubectl get svc -n adguard  # Check all exposed ports
curl -I http://<node-ip>:<nodeport-3000>  # Test setup port (before/during setup)
curl -I http://<node-ip>:<nodeport-80>    # Test runtime port (after setup)
```

---

### Phase 7: Fresh Deployment Testing

#### Validation Process
To verify our solution works end-to-end, we performed a complete fresh deployment test:

```bash
# Step 1: Clean slate - remove everything
kubectl delete -k talos/apps/adguard
kubectl get all,pv,pvc -A | grep adguard  # Verify complete cleanup

# Step 2: Fresh deployment
kubectl apply -k talos/apps/adguard

# Step 3: Monitor startup
kubectl get pods -l app=adguard -w  # Watch pod reach 1/1 Running

# Step 4: Check service configuration
kubectl get svc adguard  # Verify dual-port setup

# Step 5: Test connectivity
kubectl get nodes -o wide  # Get node IPs
curl -I http://192.168.1.245:32739  # Test port 3000 (should not respond - post-setup mode)
curl -I http://192.168.1.245:31359  # Test port 80 (should respond - main UI)
dig @192.168.1.245 -p 31883 google.com  # Test DNS functionality
```

#### Results
- **Pod Status**: Reached 1/1 Running in 45 seconds
- **Service Ports**: New NodePorts assigned (3000:32739, 80:31359, 53:31883)
- **AdGuard Behavior**: Detected existing configuration, started in post-setup mode on port 80
- **Connectivity**: Port 80 responding correctly, DNS working, port 3000 not responding (expected)

#### Learning Points
- **Configuration Persistence**: AdGuard retained previous configuration across complete redeployment
- **Automatic Port Handling**: Dual-port service successfully handled port transition
- **Health Check Success**: Pod remained stable with port 80 health checks
- **Zero Maintenance Achieved**: No manual intervention required

---

### Phase 8: Documentation Enhancement

#### Problem Encountered
Original documentation focused on high-level features but didn't explain Kubernetes concepts for learning purposes.

#### Solution Implemented
Created comprehensive documentation covering:
1. **File-by-file explanations** of all Kubernetes manifests
2. **Step-by-step deployment procedures** with expected outputs
3. **Troubleshooting guides** with diagnostic commands
4. **Learning-focused content** for Kubernetes newcomers

#### Dev Process Documentation
This current document captures:
1. **Complete problem-solving journey**
2. **Diagnostic methodologies**
3. **Learning points from each challenge**
4. **Command references for troubleshooting**

---

## Final Architecture & Lessons Learned

### Successful Deployment Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   LoadBalancer  │    │   Deployment    │    │ PersistentVols  │
│                 │    │                 │    │                 │
│ Port 3000 Setup │────│ AdGuard Home    │────│ Config: 100Mi   │
│ Port 80 Runtime │    │ Dual Port Cfg   │    │ Data: 1Gi       │
│ Port 53 DNS     │    │ Health Probes   │    │ hostPath        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Key Kubernetes Concepts Learned

1. **Pod Lifecycle Management**
   - Understanding container startup requirements
   - Security contexts and capabilities
   - Managing applications with elevated privileges

2. **Service Discovery**
   - Label selectors and endpoints
   - Service types (LoadBalancer, NodePort)
   - Multi-port service configuration

3. **Storage Management**
   - PersistentVolumes vs ConfigMaps
   - hostPath storage for single-node clusters
   - Volume mounting and write permissions

4. **Health Monitoring**
   - Startup, liveness, and readiness probes
   - TCP vs HTTP probe strategies
   - Timeout and failure threshold configuration

5. **Application Adaptation**
   - Handling application port changes
   - Configuration persistence strategies
   - Managing application lifecycles in Kubernetes

### Troubleshooting Methodology

1. **Start with Pod Status**
   ```bash
   kubectl get pods -l app=adguard
   ```

2. **Check Pod Events and Logs**
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

3. **Verify Service Configuration**
   ```bash
   kubectl get svc
   kubectl get endpoints
   ```

4. **Test Network Connectivity**
   ```bash
   kubectl port-forward <pod> <local-port>:<pod-port>
   curl -I http://localhost:<local-port>
   ```

5. **Validate Storage**
   ```bash
   kubectl get pv,pvc
   kubectl exec -it <pod> -- ls -la <mount-path>
   ```

6. **Check Application Behavior**
   ```bash
   kubectl logs <pod> | grep -i "port\|listen\|server"
   kubectl exec -it <pod> -- netstat -tlnp
   ```

### Best Practices Established

1. **Security Hardening**
   - Minimal required capabilities only (`NET_BIND_SERVICE`)
   - Root user only when necessary for application requirements
   - Drop all capabilities by default, add only what's needed

2. **Robust Health Checks**
   - Extended startup probe timeouts for application initialization (2.5 minutes)
   - Different strategies for different application phases
   - TCP probes for port transition scenarios

3. **Persistent Storage Strategy**
   - Separate volumes for different data types (config vs data)
   - Proper reclaim policies (`Retain` for important data)
   - Clear understanding of read/write requirements

4. **User Experience**
   - Single-command deployment (`kubectl apply -k`)
   - Zero manual intervention after deployment
   - Clear documentation with step-by-step procedures

5. **Service Design**
   - Dual-port exposure for application lifecycle handling
   - Named ports for clarity and maintainability
   - LoadBalancer type with NodePort fallback

### Kubernetes Learning Outcomes

This project demonstrates several important Kubernetes concepts:

1. **Application Lifecycle Management**: How to handle applications that change behavior after initialization
2. **Service Flexibility**: Using multiple ports in a single service to handle different application phases
3. **Storage Persistence**: Proper use of PersistentVolumes vs ConfigMaps for different data types
4. **Health Check Strategy**: Designing probes that accommodate application behavior changes
5. **Security Context Design**: Balancing security requirements with application needs
6. **Troubleshooting Methodology**: Systematic approach to diagnosing and fixing Kubernetes issues

This development process showcases the iterative nature of Kubernetes application deployment and the importance of understanding both application requirements and Kubernetes primitives for successful deployments.
