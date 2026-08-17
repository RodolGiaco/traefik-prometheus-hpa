# Troubleshooting y cosas no evidentes

[🇬🇧 English version](troubleshooting.en.md)

Notas sobre comportamientos de Traefik, Prometheus y `prometheus-adapter` que no son obvios a simple vista, pero que determinan si este stack funciona o se queda en `<unknown>`.

## Un Deployment, un solo HPA

Kubernetes no permite que dos objetos `HorizontalPodAutoscaler` compartan el mismo `scaleTargetRef`. Si un Deployment necesita escalar por más de una métrica (por ejemplo, tráfico HTTP y conexiones TCP a la vez, como es el caso de `video-playback`), esas métricas tienen que convivir como múltiples entradas dentro de la lista `metrics:` de **un mismo** HPA — nunca como dos HPA distintos apuntando al mismo `scaleTargetRef`. Si se intenta, el segundo HPA queda con `ScalingActive: False` y el evento `AmbiguousSelector`, y ninguno de los dos llega a calcular réplicas.

## El label `app.kubernetes.io/instance` de Traefik incluye el namespace

El chart oficial de Traefik, cuando `instanceLabelOverride` no está seteado, genera esa label como `<nombre-del-release>-<namespace>`, no solo `<nombre-del-release>`. Como el release siempre se llama `traefik` (ver [`scripts/install_or_upgrade_traefik.sh`](../scripts/install_or_upgrade_traefik.sh)), el valor real termina siendo `traefik-beta`, `traefik-candidate`, etc. Cualquier `ServiceMonitor` que necesite seleccionar los pods de Traefik por esa label tiene que usar el valor completo (con el namespace), no solo el nombre del release.

## El header `Host` incluye el puerto cuando no es el estándar

Cuando un cliente HTTP (curl, un browser) le pega a un servidor en un puerto que no es 80/443, el header `Host` que manda por spec incluye el puerto (`ejemplo.com:31555`, no `ejemplo.com`). Esto importa porque las reglas de `prometheus-adapter` en este repo filtran por `host="<dominio exacto>"` — un filtro exacto sin puerto no matchea si el cliente le pega a un `nodePort` (como pasa siempre en un cluster local con `kind`, que no tiene un LoadBalancer real en el puerto 80). Contra un LoadBalancer real en el puerto estándar (como en GKE) esto no pasa, porque ahí ningún cliente incluye el puerto en el header.

## Una métrica HTTP recién nacida puede tardar en aparecer (y "parpadear")

Ver el detalle completo en [`metrics-reference.md`](metrics-reference.md#algo-a-tener-en-cuenta-con-las-métricas-http) — en resumen: las métricas basadas en `traefik_service_requests_total` solo existen como serie después de la primera request real, y `prometheus-adapter` solo revisa qué series nuevas existen cada `metricsRelistInterval` (1 minuto). Con tráfico intermitente, es normal ver una métrica aparecer y volver a dar `404` unos minutos después.

## La versión del chart de Traefik está fijada a propósito

El [`values.yaml` de Traefik](../1-helm-values/0-traefik-values.yaml) usa campos (`globalArguments`, `certResolvers` a nivel raíz, `logs`, `podSecurityPolicy`, `hub.ratelimit`, `rbac.secretResourceNames`, `ports.websecure.middlewares`/`tls`) que las versiones más nuevas del chart (a partir de la `41.x`) ya no aceptan — el schema del chart cambió. Por eso el script de instalación fija `--version 32.1.1` en vez de traer la última versión del repo de Helm.

## `kubectl get --raw` de una métrica vacía no es lo mismo que un error

`kubectl get --raw ".../namespaces/beta/dgbase"` puede devolver:
- **404 `NotFound`**: `prometheus-adapter` todavía no descubrió esa métrica (ver el punto de arriba sobre timing).
- **`{"items":[]}`**: la métrica existe pero el selector de labels no matchea ninguna serie actual.
- **Un item con `"value":"0"`**: la métrica existe, matchea, y el valor real es cero (por ejemplo, `rate()` cayó a cero porque no hay tráfico reciente).

Son tres estados distintos con causas distintas — vale la pena diferenciarlos al debuggear en vez de asumir que "no anduvo".
