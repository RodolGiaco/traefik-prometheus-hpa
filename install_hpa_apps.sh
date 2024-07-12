#!/bin/bash

source colors.sh

## Function to print messages with colors
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

print_msg $blue "apply all hpa for apps video"
kubectl apply -f "5-hpa/0-video-playback.yaml"
kubectl apply -f "5-hpa/1-doug.yaml"
kubectl apply -f "5-hpa/2-doug-tcp.yaml"
# Uncomment for local simulation
#kubectl apply -f "6-app/video-playback"
#kubectl apply -f "6-app/doug"
#kubectl apply -f "6-app/doug-tcp"
print_msg $green "hpa apply complete for apps video."
sleep 5
watch -n 1 -t kubectl get hpa -n beta
