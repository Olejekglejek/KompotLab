## User

I want to install jellyfin on my homelab aks cluster. How do I do it? I found that there is a helm chart helm repo add jellyfin https://jellyfin.github.io/jellyfin-helm


## Agent

Absolutely! Here’s a step-by-step guide to installing Jellyfin on your AKS (Azure Kubernetes Service) cluster using the official Helm chart.

---

## **Step 1: Prerequisites**

- **Helm installed** on your local machine (`brew install helm` on Mac, or [see docs](https://helm.sh/docs/intro/install/))
- **kubectl installed** and configured to access your AKS cluster
- Your AKS cluster is up and running

---

## **Step 2: Add the Jellyfin Helm Repository**

```shell
helm repo add jellyfin https://jellyfin.github.io/jellyfin-helm
helm repo update
```

---

## **Step 3: Create a Namespace (Optional but recommended)**

```shell
kubectl create namespace jellyfin
```

---

## **Step 4: Install Jellyfin Using Helm**

```shell
helm install jellyfin jellyfin/jellyfin --namespace jellyfin
```

- This will install Jellyfin with default settings.
- You can customize the installation by passing values with `--set` or using a custom `values.yaml` file.

---

## **Step 5: Check the Deployment**

```shell
kubectl get pods -n jellyfin
kubectl get svc -n jellyfin
```

- Look for the `jellyfin` pod to be running.
- The service will expose Jellyfin—by default, it’s a ClusterIP. You may want to change this to a LoadBalancer or NodePort for external access.

---

## **Step 6: (Optional) Expose Jellyfin Externally**

If you want to access Jellyfin from outside your cluster, you can edit the service:

```shell
kubectl edit svc jellyfin -n jellyfin
```
- Change `type: ClusterIP` to `type: LoadBalancer` (for AKS, this will provision an Azure Load Balancer).

Or, use Helm to set it during install:
```shell
helm install jellyfin jellyfin/jellyfin --namespace jellyfin --set service.type=LoadBalancer
```

---

## **Step 7: Access Jellyfin**

- Get the external IP:
  ```shell
  kubectl get svc -n jellyfin
  ```
- Visit the external IP in your browser.

---

## **Step 8: Customize Configuration (Optional)**

- You can pass custom values using a `values.yaml` file:
  ```shell
  helm show values jellyfin/jellyfin > jellyfin-values.yaml
  # Edit jellyfin-values.yaml as needed
  helm install jellyfin jellyfin/jellyfin --namespace jellyfin -f jellyfin-values.yaml
  ```

---

**Let me know if you want help with persistent storage, ingress, or customizing your Jellyfin deployment!**

## User

Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  3m59s  default-scheduler  0/2 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.


## Agent

This warning means your Jellyfin pod can't be scheduled because its PersistentVolumeClaim (PVC) is **unbound**—in other words, Kubernetes can't find a PersistentVolume (PV) that matches the claim.

## What’s Happening?

- The Helm chart for Jellyfin requests persistent storage (for media, config, etc.) via a PVC.
- Your cluster doesn’t have a matching PV, or a StorageClass that can dynamically provision one.

## How to Fix

### 1. **Check the PVC Status**

```shell
kubectl get pvc -n jellyfin
```
Look for PVCs in `Pending` state.

### 2. **Check StorageClasses**

```shell
kubectl get storageclass
```
AKS usually provides a default StorageClass (like `default`, `managed-csi`, etc.).

### 3. **Edit Your Helm Install to Use a Valid StorageClass**

If your cluster has a default StorageClass, you can tell Helm to use it:

```shell
helm upgrade --install jellyfin jellyfin/jellyfin \
  --namespace jellyfin \
  --set persistence.storageClass=managed-csi
```
Replace `managed-csi` with your actual StorageClass name.

### 4. **If No StorageClass Exists**

You may need to create one, or enable the default AKS storage class.
For AKS, the default is usually available unless you’ve customized your cluster.

### 5. **Verify PV/PVC Binding**

After updating, check again:
```shell
kubectl get pvc -n jellyfin
kubectl get pv
```
PVC should move from `Pending` to `Bound`.

---

## **Summary Table**

| Step                | Command/Action                                  |
|---------------------|------------------------------------------------|
| Check PVC status    | `kubectl get pvc -n jellyfin`                  |
| Check StorageClass  | `kubectl get storageclass`                     |
| Use StorageClass    | `helm install ... --set persistence.storageClass=<name>` |
| Check PV status     | `kubectl get pv`                               |

---

**Let me know if you want help with a specific StorageClass, or want to see your PVC manifest for troubleshooting!**
