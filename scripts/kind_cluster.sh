#!/bin/bash
# Crea o elimina el cluster local de kind usado para probar todo el stack
# sin depender de un cluster GKE real.
source "$(dirname "$0")/colors.sh"

CLUSTER_NAME="rodo"

print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

if [ -z "$1" ]; then
  print_msg $red "Uso: $0 <up|down>"
  exit 1
fi

case $1 in
  up)
    if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
      print_msg $yellow "El cluster kind '$CLUSTER_NAME' ya existe, no se recrea."
    else
      print_msg $blue "Creando cluster kind '$CLUSTER_NAME'..."
      kind create cluster --name "$CLUSTER_NAME"
      print_msg $green "Cluster '$CLUSTER_NAME' listo. Contexto: kind-$CLUSTER_NAME"
    fi
    ;;
  down)
    print_msg $red "Eliminando cluster kind '$CLUSTER_NAME'..."
    kind delete cluster --name "$CLUSTER_NAME"
    ;;
  *)
    print_msg $red "Opcion invalida. Uso: $0 <up|down>"
    exit 1
    ;;
esac
