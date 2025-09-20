$CONTROL_PLANE_IP = '192.168.1.200'

talosctl gen config talos-proxmox-cluster https://$($CONTROL_PLANE_IP):6443 --output-dir /Users/Oleg.Negruta/Documents/Repos/Oleg/KompotLab/.env/talos-config/_out --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.10.3 --force

talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file /Users/Oleg.Negruta/Documents/Repos/Oleg/KompotLab/.env/talos-config/_out/controlplane.yaml

$WORKER_IP = '192.168.1.201'
talosctl apply-config --insecure --nodes $($WORKER_IP) --file /Users/Oleg.Negruta/Documents/Repos/Oleg/KompotLab/.env/talos-config/_out/worker.yaml

$env:TALOSCONFIG="/Users/Oleg.Negruta/Documents/Repos/Oleg/KompotLab/.env/talos-config/_out/talosconfig"
talosctl config endpoint $CONTROL_PLANE_IP
talosctl config node $CONTROL_PLANE_IP

talosctl containers
talosctl containers -k
talosctl logs <container> or talosctl logs -k <container>.

talosctl bootstrap
talosctl kubeconfig /Users/Oleg.Negruta/Documents/Repos/Oleg/KompotLab/.env/talos-config/_out/kubeconfig



$CONTROL_PLANE_IP = "192.168.1.192"
talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file /Users/Oleg.Negruta/Documents/Repos/Oleg/KompotLab/.env/talos-config/controlplane.yaml

$WORKER_IP = "192.168.1.122"
talosctl apply-config --insecure --nodes $WORKER_IP --file /Users/Oleg.Negruta/Documents/Repos/Oleg/KompotLab/.env/talos-config/worker.yaml
