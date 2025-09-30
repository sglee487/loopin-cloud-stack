### helm

https://artifacthub.io/packages/helm/bitnami/keycloak

### upgrade or install

```sh
helm install keycloak -n auth bitnami/keycloak -f values.yaml \
     --set auth.adminPassword='{YOUR_PASSWORD}'
```
