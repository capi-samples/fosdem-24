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
docker pull quay.io/capk/ubuntu-2004-container-disk:v1.26.0
kind load docker-image --name kind quay.io/capk/ubuntu-2004-container-disk:v1.26.0
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
clusterctl init --infrastructure kubevirt
```

## Install GitOps Agent

This is fleet in this demo but could be Flux or ArgoCD or anything else.

1. Add helm repo

```bash
helm repo add fleet https://rancher.github.io/fleet-helm-charts/
```

2. Install the Fleet charts

```bash
helm -n cattle-fleet-system install --create-namespace --wait fleet-crd fleet/fleet-crd
helm -n cattle-fleet-system install --create-namespace --wait fleet fleet/fleet
```

## Create the cluster

1. Apply the git repo

```bash
kubectl apply -f repo.yaml
```

2. Watch the **Machines** and **Clusters** in the management repo
3. Look at the VMs and instances running

```bash
kubectl get vm
kubectl get vmi
```
