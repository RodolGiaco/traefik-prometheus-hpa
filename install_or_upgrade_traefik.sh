#!/bin/bash

source colors.sh

## Function to print messages with colors
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

## Function to install or upgrade Traefik
print_msg $blue "Installing/Upgrading Traefik..."
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm upgrade --install traefik traefik/traefik --namespace beta --create-namespace -f "1-helm-values/0-traefik-beta-values.yaml"
sleep 20
kubectl apply -f "3-middleware/ratelimit.yaml"
kubectl apply -f "4-ingress/ingressroute-http.yaml"
kubectl apply -f "4-ingress/ingressroute-tcp.yaml"
