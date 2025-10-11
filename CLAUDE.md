# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a k3s-based Kubernetes infrastructure repository for the Loopin application stack. It manages deployment configurations using Kustomize overlays and Helm charts for various microservices and infrastructure components.

## Architecture

### Structure

- **k3s/**: Main Kubernetes configuration directory
  - **loopin-production/**: Loopin application services (kustomize-based)
    - **base/**: Base Kubernetes manifests for services
      - gateway-service
      - media-catalog-service
      - playback-service
      - youtube-fetcher-service
      - web-client
    - **overlays/prod/**: Production-specific configurations and patches
  - **argocd/**: ArgoCD GitOps deployment configuration
  - **auth/**: Keycloak authentication service (Helm)
  - **monitoring/**: Observability stack (Prometheus, Grafana, Loki, Tempo, Fluent-bit)
  - **cert-manager/**: TLS certificate management via Let's Encrypt
  - **fluent-bit/**: Log forwarding configuration
  - **default/**: Default namespace resources
  - **trafik-config.yaml**: Traefik ingress controller configuration

### Kustomize Structure

Services use a base + overlay pattern:
- Base configurations in `k3s/loopin-production/base/<service>/`
- Production overlays in `k3s/loopin-production/overlays/prod/<service>/`
- Each overlay contains:
  - `kustomization.yaml`: Image tags, patches, configMap generators
  - `deployment-patch.yaml`: Environment-specific deployment modifications
  - `application-prod.yml`: Production application config
  - Secret YAML files (gitignored)

### Key Infrastructure Components

- **Ingress**: Traefik with TLS termination (wildcard and service-specific certs)
- **Authentication**: Keycloak in `auth` namespace
- **GitOps**: ArgoCD accessible at argocd.loopin.bid
- **Monitoring**: Prometheus + Grafana + Loki + Tempo stack in `monitoring` namespace
- **Logging**: Fluent-bit forwarding to Loki
- **Certificate Management**: cert-manager with Let's Encrypt ACME (ClusterIssuer: `letsencrypt-prod`)

### Domain Structure

Production domains use loopin.bid:
- api.loopin.bid → gateway-service
- web.loopin.bid → web-client
- echo.loopin.bid → echo-server (test service)
- argocd.loopin.bid → ArgoCD UI

## Common Commands

### Monitoring Stack

Deploy Fluent-bit:
```sh
helm upgrade --install fluent-bit fluent/fluent-bit -n monitoring --create-namespace -f k3s/monitoring/values/fluent-bit.yaml
```

Deploy Loki:
```sh
helm install loki grafana/loki -f k3s/monitoring/values/loki.yaml -n monitoring
```

Deploy Prometheus:
```sh
helm install prometheus prometheus-community/prometheus -n monitoring
```

Deploy Tempo:
```sh
helm upgrade --install tempo grafana/tempo
```

Deploy Grafana:
```sh
helm upgrade --install my-grafana grafana/grafana --namespace monitoring -f k3s/monitoring/values/grafana.yaml
```

Retrieve Grafana admin password:
```sh
kubectl get secret --namespace monitoring my-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### Authentication (Keycloak)

Deploy or upgrade Keycloak:
```sh
helm upgrade --install keycloak -n auth bitnami/keycloak -f k3s/auth/values.yaml --set auth.adminPassword='{YOUR_PASSWORD}'
```

### Application Deployment

Apply Kustomize configurations:
```sh
kubectl apply -k k3s/loopin-production/overlays/prod/
```

Apply specific service:
```sh
kubectl apply -k k3s/loopin-production/overlays/prod/gateway-service/
```

### Certificate Management

Apply ClusterIssuer for Let's Encrypt:
```sh
kubectl apply -f k3s/cert-manager/cluster-issuer.yaml
```

Apply Keycloak certificate:
```sh
kubectl apply -f k3s/cert-manager/keycloak-cert.yaml
```

### Traefik Configuration

Apply Traefik proxy configuration (fixes mixed-content issues with Keycloak):
```sh
kubectl apply -f k3s/trafik-config.yaml
```

## Important Notes

### Secrets Management

Secrets are gitignored and stored in `.secrets/` directory. Key secret files:
- `k3s/loopin-production/overlays/prod/youtube-fetcher-service/youtube-api-key-secret.yaml`
- `k3s/loopin-production/overlays/prod/gateway-service/gateway-keycloak-client-secret.yaml`
- `k3s/auth/realm-export.json`

Always create these manually and never commit them.

### Image Updates

To update a service image, modify the `newTag` field in the service's overlay `kustomization.yaml`:
```yaml
images:
  - name: ghcr.io/sglee487/loopin-server/gateway-service
    newTag: <new-commit-sha>
```

### Namespaces

- `loopin-production`: Application services
- `auth`: Keycloak authentication
- `monitoring`: Observability stack
- `argocd`: GitOps deployment
- `kube-system`: Traefik ingress controller
