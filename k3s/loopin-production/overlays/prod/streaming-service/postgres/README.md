### helm

https://artifacthub.io/packages/helm/bitnami/postgresql

### install or upgrade

```sh
helm upgrade --install streaming-service-postgresql bitnami/postgresql -f values.yaml -n loopin-production --set auth.postgresPassword=YOUR_PASSWORD
```
