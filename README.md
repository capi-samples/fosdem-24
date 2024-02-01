# Kubevirt Instructions

## Pre-reqs

- Linux
- Qemu/KVM
- Kind
- Helm v3

## Setup CAPI Management Cluster

1. Create management cluster using kind

```bash
kind create cluster --config=kind-config.yaml

```

2. (optional) Load VM images into management cluster

```bash
# Ensure login to GHCR before running this part
while IFS= read -r line; do
    docker pull "$line"
    kind load docker-image "$line"
done < "images.txt"
```

3. Install calico

```bash
kubectl create -f  https://raw.githubusercontent.com/projectcalico/calico/v3.24.4/manifests/calico.yaml
```

4. Install metallb

```bash
kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml"
kubectl wait pods -n metallb-system -l app=metallb,component=controller --for=condition=Ready --timeout=10m
kubectl wait pods -n metallb-system -l app=metallb,component=speaker --for=condition=Ready --timeout=2m
```

5. Create ip pool

```bash
GW_IP=$(docker network inspect -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}' kind)
NET_IP=$(echo ${GW_IP} | sed -E 's|^([0-9]+\.[0-9]+)\..*$|\1|g')
cat <<EOF | sed -E "s|172.19|${NET_IP}|g" | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: capi-ip-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.19.255.200-172.19.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
EOF
```

6. Install kubevirt

```bash
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/v1.1.1/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/v1.1.1/kubevirt-cr.yaml"
kubectl wait -n kubevirt kv kubevirt --for=condition=Available --timeout=10m
```

7. Install CAPI & providers

```bash
clusterctl init  --core cluster-api:v1.6.1 --bootstrap kubeadm:v1.6.1 --control-plane kubeadm:v1.6.1 --infrastructure kubevirt:v0.1.8
```

## Install GitOps Agent

This is fleet in this demo but could be Flux or ArgoCD or anything else.

1. Add helm repo

```bash
helm repo add fleet https://rancher.github.io/fleet-helm-charts/
```

2. Install the Fleet charts

```bash
helm -n cattle-fleet-system install --create-namespace --wait fleet-crd fleet/fleet-crd --version 0.9.0
helm -n cattle-fleet-system install --create-namespace --wait fleet fleet/fleet --version 0.9.0
```

## Create the cluster

1. Apply the git repo

```bash
kubectl apply -f gitrepo.yaml
```

2. Watch the **Machines** and **Clusters** in the management repo
3. Look at the VMs and instances running

```bash
kubectl get vm
kubectl get vmi
```

## (optional) Show the boot logs

1. Install virtctl from [releases](https://github.com/kubevirt/kubevirt/releases).
2. Get the name of the VM (i.e. `kubectl get vm`)
3. Run the following:

```bash
virtctl vnc <vm_name>
```

## (optional) Scale the cluster

1. Watch the VMs or Machines
2. Edit the machine deployment in GitHub:
3. Change replicas to **2** and save
4. Watch the new VM be provisioned

