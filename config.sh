#!/bin/bash
# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

## Función para imprimir mensajes con colores
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${NC}"
}
### Descomentar para limpieza completa del cluster
#print_msg $RED "Eliminando todos los recursos en el cluster..."
#helm ls --all --all-namespaces -q | xargs -I {} helm uninstall {} --namespace monitoring
#helm ls --all --all-namespaces -q | xargs -I {} helm uninstall {} --namespace beta
#kubectl delete middleware --all -n beta
#kubectl delete ingressroute --all -n beta
#kubectl delete ingressclass --all -n beta
#print_msg $GREEN "Eliminación completada"

##Instalar Traefik
print_msg $BLUE "Instalando Traefik..."
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm install traefik traefik/traefik --namespace beta --create-namespace -f 1-helm-values/0-traefik-beta-values.yaml
sleep 20
kubectl apply -f 3-middleware/
kubectl apply -f 4-ingress/

##Instalar Prometheus
print_msg $BLUE "Instalando Prometheus..."
kubectl create namespace monitoring
kubectl apply -f 0-configmap/0-prometheus-adapter-cofig.yaml
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus-operator prometheus-community/kube-prometheus-stack -n monitoring -f 1-helm-values/1-prometheus-operator-monitoring-values.yaml
print_msg $GREEN "Prometheus-operator aplicado correctamente."
sleep 30
kubectl apply -f 2-apiservice/0-apiservice-external.metrics.yaml
helm install prometheus prometheus-community/prometheus -n monitoring
print_msg $GREEN "Prometheus aplicado correctamente."

helm install prometheus-adapter prometheus-community/prometheus-adapter --namespace monitoring -f  1-helm-values/2-prometheus-adapter-monitoring-values.yaml
print_msg $GREEN "Implementación de Prometheus completada."
print_msg $GREEN "Todas las aplicaciones han sido aplicadas correctamente."

#kubectl apply -f 5-hpa/

