#!/bin/bash

source "$(dirname "$0")/colors.sh"

## Las rutas a los YAML (1-helm-values/, 4-ingress/, etc.) son relativas a
## la raiz del repo -- nos paramos ahi sin importar desde donde se invoque
## este script.
cd "$(dirname "$0")/.." || exit 1

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
helm upgrade --install traefik traefik/traefik --version 32.1.1 --namespace $ENV --create-namespace -f "1-helm-values/0-traefik-values.yaml"
sleep 20
kubectl apply -f "3-middleware/ratelimit.yaml" -n $ENV
kubectl apply -f "4-ingress/ingressroute-http.yaml" -n $ENV
kubectl apply -f "4-ingress/ingressroute-tcp.yaml" -n $ENV
