#!/bin/bash

source colors.sh

## Function to print messages with colors
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

## Check for environment parameter
if [ -z "$1" ]; then
  print_msg $red "No environment specified. Usage: $0 <environment>"
  exit 1
fi
ENV=$1

## Function to install or upgrade Traefik
print_msg $blue "Installing/Upgrading Traefik in environment $ENV..."
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm upgrade --install traefik traefik/traefik --namespace $ENV --create-namespace -f "1-helm-values/0-traefik-values.yaml"
sleep 20
kubectl apply -f "3-middleware/ratelimit.yaml" -n $ENV
kubectl apply -f "4-ingress/ingressroute-http.yaml" -n $ENV
kubectl apply -f "4-ingress/ingressroute-tcp.yaml" -n $ENV
