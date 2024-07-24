#!/bin/bash

source colors.sh

## Function to print messages with colors
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

## Function to install or upgrade Prometheus
print_msg $blue "Installing/Upgrading Prometheus..."
kubectl create namespace monitoring 2>/dev/null || print_msg $yellow "Namespace monitoring already exists"
kubectl apply -f "0-configmap/0-prometheus-adapter-config.yaml"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install prometheus-operator prometheus-community/kube-prometheus-stack -n monitoring -f "1-helm-values/1-prometheus-operator-monitoring-values.yaml"
print_msg $green "Prometheus-operator applied successfully."
sleep 20

kubectl apply -f "2-apiservice/0-apiservice-external.metrics.yaml"
helm upgrade --install prometheus prometheus-community/prometheus -n monitoring
print_msg $green "Prometheus applied successfully."

helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter --namespace monitoring -f "1-helm-values/2-prometheus-adapter-monitoring-values.yaml"
print_msg $green "Prometheus implementation completed."


