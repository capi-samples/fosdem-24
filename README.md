# Proxmox Instructions

NOTE: There are 2 providers for Proxmox. This demo uses <https://github.com/ionos-cloud/cluster-api-provider-proxmox>.

## Pre-reqs

- Linux
- Access to proxmox server
  - Template VM Available
- Kind
- Helm v3

## Setup CAPI Management Cluster

1. Create environment file with envars. See [sample](./sample-env)

2. Create management cluster using kind

```bash
kind create cluster

```

2. (optional) Load VM images into management cluster

```bash
# Ensure login to GHCR before running this part
while IFS= read -r line; do
    docker pull "$line"
    kind load docker-image "$line"
done < "images.txt"
```

3. Install CAPI & providers

```bash
clusterctl init --core cluster-api:v1.6.1 --bootstrap kubeadm:v1.6.1 --control-plane kubeadm:v1.6.1 --infrastructure proxmox:v0.2.0
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
kubectl wait pods -n cattle-fleet-system -l app=fleet-controller --for=condition=Ready --timeout=2m
```

## Create the cluster

1. Apply the git repo

```bash
kubectl apply -f gitrepo.yaml
```

2. Watch the **Machines** and **Clusters** in the management repo
3. Look at the VMs and instances running

```bash
kubectl get machines
kubectl get proxmoxmachines
```

> NOTE: the cluster was generated originally using **clusterctl**: `clusterctl generate cluster test1 --infrastructure proxmox --kubernetes-version v1.27.8 --control-plane-machine-count 1 --worker-machine-count 1 > cluster.yaml`

## (optional) Scale the cluster

1. Watch the Machines
2. Edit the machine deployment in GitHub.
3. Change replicas to **2** and save
4. Watch the new Machine / VM be provisioned
