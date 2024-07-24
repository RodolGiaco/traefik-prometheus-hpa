#!/bin/bash

source colors.sh

## Función para imprimir mensajes con colores
print_msg() {
  local color=$1
  local msg=$2
  echo -e "${color}${msg}${reset}"
}

## Función para seleccionar el ambiente
select_environment() {
while true; do
   echo -ne "
   "$yellow"Select environment:
   "$blue"1)$reset beta
   "$blue"2)$reset candidate
   "$blue"3)$reset prod
   "$blue"0)$reset Exit
   "$green"Choose an option: "$reset

   read option
   echo ''

 case $option in
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
  1) select_environment
     ./install_or_upgrade_traefik.sh $ENV
     ./install_or_upgrade_prometheus.sh
     ./install_hpa_apps.sh $ENV
	  ;;
	2) select_environment
     ./install_or_upgrade_traefik.sh $ENV
  	;;
  3) ./install_or_upgrade_prometheus.sh
	  ;;
  4) select_environment
     ./external_metrics.sh $ENV
	  ;;
  5) select_environment
     ./delete_all.sh $ENV
	  ;;
	6) select_environment
     ./install_hpa_apps.sh $ENV
  	;;
  0) exit 0;;
  *) echo -e $red"Invalid option."$reset;;
esac
