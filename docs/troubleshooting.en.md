# Troubleshooting and non-obvious behavior

[🇪🇸 Versión en español](troubleshooting.md)

Notes on Traefik, Prometheus and `prometheus-adapter` behaviors that aren't obvious at first glance, but determine whether this stack works or stays stuck at `<unknown>`.

## One Deployment, one HPA

Kubernetes doesn't allow two `HorizontalPodAutoscaler` objects to share the same `scaleTargetRef`. If a Deployment needs to scale on more than one metric (for example, HTTP traffic and TCP connections at once, like `video-playback` does), those metrics have to live as multiple entries inside the `metrics:` list of **a single** HPA — never as two separate HPAs pointing at the same `scaleTargetRef`. If you try, the second HPA ends up with `ScalingActive: False` and an `AmbiguousSelector` event, and neither one ever computes replicas.

## Traefik's `app.kubernetes.io/instance` label includes the namespace

The official Traefik chart, when `instanceLabelOverride` is left unset, generates that label as `<release-name>-<namespace>`, not just `<release-name>`. Since the release is always named `traefik` (see [`scripts/install_or_upgrade_traefik.sh`](../scripts/install_or_upgrade_traefik.sh)), the actual value ends up being `traefik-beta`, `traefik-candidate`, etc. Any `ServiceMonitor` that needs to select Traefik's pods by that label has to use the full value (with the namespace), not just the release name.

## The `Host` header includes the port when it's non-standard

When an HTTP client (curl, a browser) hits a server on a port other than 80/443, the `Host` header it sends includes the port per spec (`example.com:31555`, not `example.com`). This matters because this repo's `prometheus-adapter` rules filter on `host="<exact domain>"` — an exact filter with no port won't match if the client hits a `nodePort` (which always happens on a local `kind` cluster, since there's no real LoadBalancer on port 80). Against a real LoadBalancer on the standard port (like on GKE) this doesn't happen, because no client includes the port in the header there.

## A freshly-created HTTP metric can take a while to show up (and "flicker")

See the full detail in [`metrics-reference.en.md`](metrics-reference.en.md#something-to-keep-in-mind-with-http-metrics) — in short: metrics based on `traefik_service_requests_total` only exist as a series after the first real request, and `prometheus-adapter` only checks for newly-existing series every `metricsRelistInterval` (1 minute). With intermittent traffic, it's normal to see a metric appear and then go back to `404` a few minutes later.

## The Traefik chart version is pinned on purpose

The [Traefik `values.yaml`](../1-helm-values/0-traefik-values.yaml) uses fields (`globalArguments`, root-level `certResolvers`, `logs`, `podSecurityPolicy`, `hub.ratelimit`, `rbac.secretResourceNames`, `ports.websecure.middlewares`/`tls`) that newer chart versions (from `41.x` onward) no longer accept — the chart schema changed. That's why the install script pins `--version 32.1.1` instead of pulling the latest version from the Helm repo.

## An empty `kubectl get --raw` for a metric isn't the same as an error

`kubectl get --raw ".../namespaces/beta/dgbase"` can return:
- **404 `NotFound`**: `prometheus-adapter` hasn't discovered that metric yet (see the timing note above).
- **`{"items":[]}`**: the metric exists but the label selector doesn't match any current series.
- **An item with `"value":"0"`**: the metric exists, matches, and the actual value is zero (for example, `rate()` decayed to zero because there's no recent traffic).

These are three distinct states with distinct causes — worth telling them apart when debugging instead of assuming "it didn't work."
