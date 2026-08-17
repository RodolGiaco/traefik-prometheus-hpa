# Custom metrics reference

[🇪🇸 Versión en español](metrics-reference.md)

This project doesn't expose its own REST API — what it exposes is a **Kubernetes metrics API** (`external.metrics.k8s.io/v1beta1`), which is what every `HorizontalPodAutoscaler` consumes. This table is the reference for the 8 metrics served by `prometheus-adapter`, defined in [`0-configmap/0-prometheus-adapter-config.yaml`](../0-configmap/0-prometheus-adapter-config.yaml).

## Metrics table

| Metric | Type | Service | Required selector | HPA reading it |
|---|---|---|---|---|
| `dgbase` | HTTP — request rate | `doug` (base) | `host=rodohpa.ddns.net` | `hpa-doug` |
| `dgvideotest` | HTTP — request rate | `doug` (client) | `host=rodohpaclient.ddns.net` | `hpa-doug-videotest` |
| `dgtcpbase` | TCP — open connections | `doug-tcp` (base) | `entrypoint=dgtcp` | `hpa-doug-tcp` |
| `dgtcpvideotest` | TCP — open connections | `doug-tcp` (client) | `entrypoint=dgtcpvideotest` | `hpa-doug-tcp-videotest` |
| `pbtcpbase` | TCP — open connections | `video-playback` (base) | `entrypoint=pbtcp` | `hpa-video-playback-tcp` |
| `pbtcpvideotest` | TCP — open connections | `video-playback` (client) | `entrypoint=pbtcpvideotest` | `hpa-video-playback-videotest-tcp` |
| `pbbase` | HTTP — request rate | `video-playback` (base) | `host=rodohpa.ddns.net` | *(available, no dedicated HPA — see note)* |
| `pbvideotest` | HTTP — request rate | `video-playback` (client) | `host=rodohpaclient.ddns.net` | *(available, no dedicated HPA)* |

> **Note on `pbbase`/`pbvideotest`:** `video-playback` is the only service that serves both HTTP and TCP traffic at once. Its active HPA scales on the TCP metric; the HTTP metrics are defined and ready to be added as an extra entry inside the same `HorizontalPodAutoscaler` object if that service ever needs to scale on that axis too (a Deployment can't be owned by more than one HPA).

## The two PromQL patterns

**HTTP traffic** (`dgbase`, `dgvideotest`, `pbbase`, `pbvideotest`) — request rate over a 2-minute window, grouped by host:

```promql
sum(rate(traefik_service_requests_total{exported_service=~".*<service>.*", host="<domain>"}[2m])) by (host)
```

**TCP traffic** (`dgtcpbase`, `dgtcpvideotest`, `pbtcpbase`, `pbtcpvideotest`) — currently open connections, no time window (it's a gauge, not a counter):

```promql
sum(traefik_open_connections{entrypoint="<entrypoint>"}) by (entrypoint)
```

## Querying them directly

```bash
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1" | jq -r '.resources[].name'

kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/beta/dgbase" | jq .
```

Or with the interactive menu: `./scripts/external_metrics.sh beta`.

## Something to keep in mind with HTTP metrics

Metrics based on HTTP traffic (`dgbase`, `dgvideotest`, `pbbase`, `pbvideotest`) only exist as a Prometheus series **after** the first real request — unlike TCP metrics (`traefik_open_connections`), which Traefik always exposes, even at zero. `prometheus-adapter` checks which series exist every `metricsRelistInterval` (1 minute in this repo, see [`1-helm-values/2-prometheus-adapter-monitoring-values.yaml`](../1-helm-values/2-prometheus-adapter-monitoring-values.yaml)), so a freshly-generated HTTP metric can take up to a minute to show up in `external.metrics.k8s.io`, and can "disappear" again if traffic stops before that cycle confirms it. To see an HPA with stable values, keep traffic flowing continuously (`./scripts/gen_traffic_doug.sh`) while watching it.
