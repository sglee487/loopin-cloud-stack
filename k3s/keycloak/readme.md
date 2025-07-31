```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

```sh
helm install keycloak -n keycloak bitnami/keycloak -f values.yaml \
    --create-namespace --set auth.adminPassword='{YOUR_PASSWORD}'
```
