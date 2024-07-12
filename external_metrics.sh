#!/bin/bash

source colors.sh

## Function to print messages with colors
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

### Install jq if not present
install_jq() {
  if ! command -v jq &> /dev/null; then
    print_msg $blue "Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
    print_msg $green "jq installed successfully."
  else
    print_msg $green "jq is already installed."
  fi
}

install_jq

## Interactive menu
echo -ne "
 "$yellow"Metrics Viewer
 "$blue"1)$reset video-playback metrics
 "$blue"2)$reset doug-tcp metrics
 "$blue"3)$reset doug metrics
 "$blue"0)$reset Exit
 "$green"Choose an option: "$reset

read option
echo ''

case $option in
  1)
    print_msg $blue "Fetching video-playback Metrics (pbtcpvideotest, pbtcpbase, pbvideotest, pbbase)..."
    kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/pbtcpvideotest" | jq '.items[] | select(.metricLabels.entrypoint == "pbtcpvideotest")'
    kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/pbtcpbase" | jq '.items[] | select(.metricLabels.entrypoint == "pbtcp")'
    kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/pbvideotest" | jq .
    kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/pbbase" | jq .
    ;;
  2)
    print_msg $blue "Fetching doug-tcp Metrics (dgtcp, dgtcpvideotest)..."
    kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/dgtcpbase" | jq '.items[] | select(.metricLabels.entrypoint == "dgtcp")'
    kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/dgtcpvideotest" | jq '.items[] | select(.metricLabels.entrypoint == "dgtcpvideotest")'
    ;;
  3)
    print_msg $blue "Fetching doug Metrics (dgbase, dgvideotest)......"
    kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/dgbase" | jq .
    kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/dgvideotest" | jq .

    ;;
  0)
    print_msg $green "Exiting..."
    exit 0
    ;;
  *)
    echo -e $red"Invalid option."$reset
    ;;
esac
