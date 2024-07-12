#!/bin/bash

source colors.sh

## Function to print messages with colors
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

## Function to uninstall Helm resources
helm_uninstall() {
  local release=$1
  local namespace=$2
  if helm ls --namespace "$namespace" | grep -q "$release"; then
    helm uninstall "$release" --namespace "$namespace"
    print_msg $green "$release uninstalled in namespace $namespace"
  else
    print_msg $yellow "$release not found in namespace $namespace"
  fi
}

## Function to delete Kubernetes resources
kubectl_delete_file() {
  local file=$1
  if [[ -f "$file" ]]; then
    kubectl delete -f "$file" 2>/dev/null && print_msg $green "Resource in $file deleted" || print_msg $yellow "Resource in $file not found or already deleted"
  else
    print_msg $yellow "File $file not found"
  fi
}

## Deletion confirmation
echo -ne "
${red}======== WARNING!!! ========
This action will destroy the running cluster.
${white}Do you wish to continue? (Y/N) ${reset}"
read option
if [[ ${option^^} == "Y" ]]; then
  echo -e ${green}"Continuing..."${reset}
else
  echo -e ${yellow}"Aborting..."${reset}
  exit 1
fi

## Delete all resources
print_msg $red "Deleting specific resources in the cluster..."
helm_uninstall traefik beta
helm_uninstall prometheus monitoring
helm_uninstall prometheus-operator monitoring
helm_uninstall prometheus-adapter monitoring

kubectl_delete_file "0-configmap/0-prometheus-adapter-cofig.yaml"
kubectl_delete_file "3-middleware/ratelimit.yaml"
kubectl_delete_file "4-ingress/ingressroute-http.yaml"
kubectl_delete_file "4-ingress/ingressroute-tcp.yaml"
kubectl_delete_file "5-hpa/0-video-playback.yaml"
kubectl_delete_file "5-hpa/1-doug.yaml"
kubectl_delete_file "5-hpa/2-doug-tcp.yaml"

print_msg $green "Deletion completed"
