#!/bin/bash
# Genera trafico continuo para 6 metricas custom (2 HTTP + 4 TCP):
#   dgbase, dgvideotest                              (HTTP, doug, rate cada 1s)
#   dgtcpbase, pbtcpbase, dgtcpvideotest, pbtcpvideotest (TCP, 2 conexiones
#   persistentes por entrypoint -- no crecen, solo se mantienen abiertas)
# video-playback se prueba solo por TCP: su HPA activo (hpa-video-playback-tcp)
# escala por conexiones, no por requests -- ver 5-hpa/0-video-playback.yaml.
# Ctrl+C corta todo (HTTP y las conexiones TCP).

set -u

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
WEBPORT=$(kubectl get svc traefik -n beta -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}')
DGTCP_PORT=$(kubectl get svc traefik -n beta -o jsonpath='{.spec.ports[?(@.name=="dgtcp")].nodePort}')
DGTCPVT_PORT=$(kubectl get svc traefik -n beta -o jsonpath='{.spec.ports[?(@.name=="dgtcpvideotest")].nodePort}')
PBTCP_PORT=$(kubectl get svc traefik -n beta -o jsonpath='{.spec.ports[?(@.name=="pbtcp")].nodePort}')
PBTCPVT_PORT=$(kubectl get svc traefik -n beta -o jsonpath='{.spec.ports[?(@.name=="pbtcpvideotest")].nodePort}')

HOST_BASE="rodohpa.ddns.net"
HOST_VIDEOTEST="rodohpaclient.ddns.net"

echo "NODE_IP=$NODE_IP  WEBPORT=$WEBPORT"
echo "TCP ports -> dgtcp=$DGTCP_PORT dgtcpvideotest=$DGTCPVT_PORT pbtcp=$PBTCP_PORT pbtcpvideotest=$PBTCPVT_PORT"
echo

# --- Conexiones TCP persistentes (2 por entrypoint, no crecen) ---
NC_PIDS=()
open_tcp() {
  local port=$1
  local n=$2
  local label=$3
  for i in $(seq 1 "$n"); do
    ( exec 3<>"/dev/tcp/${NODE_IP}/${port}"; sleep 3600 ) &
    NC_PIDS+=($!)
  done
  echo "  $n conexion(es) TCP abiertas -> $label (puerto $port)"
}
echo "Abriendo conexiones TCP persistentes..."
open_tcp "$DGTCP_PORT" 2 "dgtcpbase"
open_tcp "$DGTCPVT_PORT" 2 "dgtcpvideotest"
open_tcp "$PBTCP_PORT" 2 "pbtcpbase"
open_tcp "$PBTCPVT_PORT" 2 "pbtcpvideotest"
echo

cleanup() {
  echo
  echo "Cerrando conexiones TCP..."
  kill "${NC_PIDS[@]}" 2>/dev/null
  exit 0
}
trap cleanup INT TERM

echo "Mandando HTTP cada 1s (doug, base y videotest -- playback solo por TCP). Ctrl+C para cortar todo."
echo

while true; do
  ts=$(date '+%H:%M:%S')
  c_doug=$(curl -s -o /dev/null -w '%{http_code}' -H "Host: ${HOST_BASE}" "http://${NODE_IP}:${WEBPORT}/api")
  c_dougvt=$(curl -s -o /dev/null -w '%{http_code}' -H "Host: ${HOST_VIDEOTEST}" "http://${NODE_IP}:${WEBPORT}/api")
  echo "[$ts] doug=$c_doug doug-videotest=$c_dougvt"
  sleep 1
done
