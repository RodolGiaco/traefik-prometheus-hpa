#!/bin/bash

source colors.sh

## Función para imprimir mensajes con colores
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

## Dar permisos de ejecución a todos los scripts necesarios
chmod +x delete_all.sh
chmod +x install_or_upgrade_traefik.sh
chmod +x install_or_upgrade_prometheus.sh
chmod +x install_hpa_apps.sh
chmod +x external_metrics.sh

### Instalar jq si no está presente
install_jq() {
  if ! command -v jq &> /dev/null; then
    print_msg $BLUE "Instalando jq..."
    sudo apt-get update
    sudo apt-get install -y jq
    print_msg $GREEN "jq instalado correctamente."
  else
    print_msg $GREEN "jq ya está instalado."
  fi
}


## Menú interactivo
 echo -ne "
 "$yellow"Traefik with hpa using custom metrics
 "$blue"1)$reset install traefik/prometheus/hpa
 "$blue"2)$reset upgrade traefik
 "$blue"3)$reset upgrade prometheus
 "$blue"4)$reset see metrics
 "$blue"5)$reset delete and uninstall all
 "$blue"6)$reset apply hpa for apps video
 "$blue"0)$reset Exit
 "$green"Choose an option: "$reset

 read option
 echo ''

case $option in
  1) ./install_or_upgrade_traefik.sh
     ./install_or_upgrade_prometheus.sh
     ./install_hpa_apps.sh
	  ;;
	2) ./install_or_upgrade_traefik.sh
  	;;
  3) ./install_or_upgrade_prometheus.sh
	  ;;
  4) ./external_metrics.sh
	  ;;
  5) ./delete_all.sh
	  ;;
	6) ./install_hpa_apps.sh
  	;;
  0) exit 0;;
  *) echo -e $red"Invalid option."$reset;;
esac