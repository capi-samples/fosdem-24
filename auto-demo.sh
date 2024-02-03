#!/usr/bin/env bash

# Include the magic
. demo-magic.sh

TYPE_SPEED=40
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"

# Clear the screen before starting
clear

pe "echo 'Create the management cluster'"

pe "kind create cluster --config=kind-config.yaml"

while IFS= read -r line; do
    docker pull "$line"
    kind load docker-image "$line"
done <"images.txt"
pe "clear"

. auto-demo-existing-kind.sh
