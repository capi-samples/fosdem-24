#!/usr/bin/env bash

# Include the magic
. demo-magic.sh

TYPE_SPEED=40
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"

# Clear the screen before starting
clear

pe "echo 'Start k9s in another terminal'"
pe "echo 'Ensure clusterctl config changes have been made'"
wait

pe "clusterctl init --core cluster-api:v1.6.1 --bootstrap kubeadm:v1.6.1 --control-plane kubeadm:v1.6.1 --infrastructure proxmox:v0.2.0 --ipam incluster"

pe "clear"
pe "echo 'Install GitOps Agent - fleet'"

pe "helm repo add fleet https://rancher.github.io/fleet-helm-charts/"
pe "helm -n cattle-fleet-system install --create-namespace --wait fleet-crd fleet/fleet-crd --version 0.9.0"
pe "helm -n cattle-fleet-system install --create-namespace --wait fleet fleet/fleet --version 0.9.0"

pe "clear"
pe "echo 'Create a cluster'"
pe "echo 'Show cluster definition in Git'"
pe "kubectl apply -f gitrepo.yaml"
pe "echo 'Show Proxmox'"
