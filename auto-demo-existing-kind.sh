#!/usr/bin/env bash

# Include the magic
. demo-magic.sh

TYPE_SPEED=30
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"

# Clear the screen before starting
clear

pe "echo 'Start k9s in another terminal'"
wait

pe "kubectl create -f  https://raw.githubusercontent.com/projectcalico/calico/v3.24.4/manifests/calico.yaml"
pe "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml"
pei "kubectl wait pods -n metallb-system -l app=metallb,component=controller --for=condition=Ready --timeout=10m"
pei "kubectl wait pods -n metallb-system -l app=metallb,component=speaker --for=condition=Ready --timeout=2m"

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

pe "echo 'show ip pools'"
pe "kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.1.1/kubevirt-operator.yaml"
pe "kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.1.1/kubevirt-cr.yaml"
pe "kubectl wait -n kubevirt kv kubevirt --for=condition=Available --timeout=10m"
pe "clusterctl init  --core cluster-api:v1.6.1 --bootstrap kubeadm:v1.6.1 --control-plane kubeadm:v1.6.1 --infrastructure kubevirt:v0.1.8"

pe "clear"
pe "echo 'Install GitOps Agent - fleet'"

pe "helm repo add fleet https://rancher.github.io/fleet-helm-charts/"
pe "helm -n cattle-fleet-system install --create-namespace --wait fleet-crd fleet/fleet-crd --version 0.9.0"
pe "helm -n cattle-fleet-system install --create-namespace --wait fleet fleet/fleet --version 0.9.0"

pe "clear"
pe "echo 'Create a cluster'"
pe "echo 'Show cluster definition in Git'"
pe "kubectl apply -f gitrepo.yaml"
