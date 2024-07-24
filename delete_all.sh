#!/bin/bash

source colors.sh

## Function to print messages with colors
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

## Function to select environment
select_environment() {
  while true; do
    echo "Select environment:"
    echo "1) beta"
    echo "2) candidate"
    echo "3) prod"
    read -p "Enter your choice [1-3]: " choice

    case $choice in
      1)
        ENV="beta"
        break
        ;;
      2)
        ENV="candidate"
        break
        ;;
      3)
        ENV="prod"
        break
        ;;
      *)
        echo "Invalid choice. Please enter a valid option."
        ;;
    esac
  done
}

## Check for environment parameter
if [ -z "$1" ]; then
  select_environment
else
  ENV=$1
fi

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
    kubectl delete -f "$file" -n $ENV 2>/dev/null && print_msg $green "Resource in $file deleted in environment $ENV" || print_msg $yellow "Resource in $file not found or already deleted in environment $ENV"
  else
    print_msg $yellow "File $file not found"
  fi
}

## Deletion confirmation
echo -ne "
${red}======== WARNING!!! ========
This action will remove all installations related to HPA with custom metrics using Prometheus and Traefik.
Proceeding will uninstall all related components and configurations.+
${white}Do you wish to continue? (Y/N) ${reset}"
read option
if [[ ${option^^} == "Y" ]]; then
  echo -e ${green}"Continuing..."${reset}
else
  echo -e ${yellow}"Aborting..."${reset}
  exit 1
fi

## Delete all resources
print_msg $red "Deleting specific resources in the cluster in environment $ENV..."
helm_uninstall traefik $ENV
helm_uninstall prometheus monitoring
helm_uninstall prometheus-operator monitoring
helm_uninstall prometheus-adapter monitoring

kubectl_delete_file "0-configmap/0-prometheus-adapter-config.yaml"
kubectl_delete_file "3-middleware/ratelimit.yaml"
kubectl_delete_file "4-ingress/ingressroute-http.yaml"
kubectl_delete_file "4-ingress/ingressroute-tcp.yaml"
kubectl_delete_file "5-hpa/0-video-playback.yaml"
kubectl_delete_file "5-hpa/1-doug.yaml"
kubectl_delete_file "5-hpa/2-doug-tcp.yaml"

print_msg $green "Deletion completed in environment $ENV"
