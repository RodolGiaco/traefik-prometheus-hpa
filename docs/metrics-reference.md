# Referencia de métricas personalizadas

[🇬🇧 English version](metrics-reference.en.md)

Este proyecto no expone una API REST propia — lo que expone es una **API de métricas de Kubernetes** (`external.metrics.k8s.io/v1beta1`), que es lo que consume cada `HorizontalPodAutoscaler`. Esta tabla es la referencia de las 8 métricas que sirve `prometheus-adapter`, definidas en [`0-configmap/0-prometheus-adapter-config.yaml`](../0-configmap/0-prometheus-adapter-config.yaml).

## Tabla de métricas

| Métrica | Tipo | Servicio | Selector requerido | HPA que la lee |
|---|---|---|---|---|
| `dgbase` | HTTP — tasa de requests | `doug` (base) | `host=rodohpa.ddns.net` | `hpa-doug` |
| `dgvideotest` | HTTP — tasa de requests | `doug` (cliente) | `host=rodohpaclient.ddns.net` | `hpa-doug-videotest` |
| `dgtcpbase` | TCP — conexiones abiertas | `doug-tcp` (base) | `entrypoint=dgtcp` | `hpa-doug-tcp` |
| `dgtcpvideotest` | TCP — conexiones abiertas | `doug-tcp` (cliente) | `entrypoint=dgtcpvideotest` | `hpa-doug-tcp-videotest` |
| `pbtcpbase` | TCP — conexiones abiertas | `video-playback` (base) | `entrypoint=pbtcp` | `hpa-video-playback-tcp` |
| `pbtcpvideotest` | TCP — conexiones abiertas | `video-playback` (cliente) | `entrypoint=pbtcpvideotest` | `hpa-video-playback-videotest-tcp` |
| `pbbase` | HTTP — tasa de requests | `video-playback` (base) | `host=rodohpa.ddns.net` | *(disponible, sin HPA propio — ver nota)* |
| `pbvideotest` | HTTP — tasa de requests | `video-playback` (cliente) | `host=rodohpaclient.ddns.net` | *(disponible, sin HPA propio)* |

> **Nota sobre `pbbase`/`pbvideotest`:** `video-playback` es el único servicio que expone tráfico HTTP y TCP a la vez. Su HPA activo escala por la métrica TCP; las métricas HTTP quedan definidas y listas para usarse como una entrada adicional dentro del mismo objeto `HorizontalPodAutoscaler` si se necesita escalar también por ese eje (un Deployment no puede tener más de un HPA como dueño).

## Los dos patrones de PromQL

**Tráfico HTTP** (`dgbase`, `dgvideotest`, `pbbase`, `pbvideotest`) — tasa de requests sobre una ventana de 2 minutos, agrupada por host:

```promql
sum(rate(traefik_service_requests_total{exported_service=~".*<servicio>.*", host="<dominio>"}[2m])) by (host)
```

**Tráfico TCP** (`dgtcpbase`, `dgtcpvideotest`, `pbtcpbase`, `pbtcpvideotest`) — conexiones abiertas en el momento, sin ventana de tiempo (es un gauge, no un contador):

```promql
sum(traefik_open_connections{entrypoint="<entrypoint>"}) by (entrypoint)
```

## Consultarlas directamente

```bash
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1" | jq -r '.resources[].name'

kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/dgbase" | jq .
```

O con el menú interactivo: `./scripts/external_metrics.sh beta`.

## Algo a tener en cuenta con las métricas HTTP

Las métricas basadas en tráfico HTTP (`dgbase`, `dgvideotest`, `pbbase`, `pbvideotest`) solo existen como serie de Prometheus **después** de la primera request real — a diferencia de las métricas TCP (`traefik_open_connections`), que Traefik expone siempre, incluso en cero. `prometheus-adapter` revisa qué series existen cada `metricsRelistInterval` (1 minuto en este repo, ver [`1-helm-values/2-prometheus-adapter-monitoring-values.yaml`](../1-helm-values/2-prometheus-adapter-monitoring-values.yaml)), así que una métrica HTTP recién generada puede tardar hasta un minuto en aparecer en `external.metrics.k8s.io`, y puede "desaparecer" de nuevo si el tráfico se corta antes de que ese ciclo la confirme. Para ver un HPA con valores estables, conviene mantener tráfico continuo (`./scripts/gen_traffic_doug.sh`) mientras se lo observa.
