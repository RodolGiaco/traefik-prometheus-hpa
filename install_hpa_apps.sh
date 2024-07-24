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

print_msg $blue "apply all hpa for apps video in environment $ENV"
kubectl apply -f "5-hpa/0-video-playback.yaml" -n $ENV
kubectl apply -f "5-hpa/1-doug.yaml" -n $ENV
kubectl apply -f "5-hpa/2-doug-tcp.yaml" -n $ENV
# Uncomment for local simulation
kubectl apply -f "6-app/video-playback" -n $ENV
kubectl apply -f "6-app/doug" -n $ENV
kubectl apply -f "6-app/doug-tcp" -n $ENV
print_msg $green "hpa apply complete for apps video in environment $ENV."
sleep 5
watch -n 1 -t kubectl get hpa -n $ENV
