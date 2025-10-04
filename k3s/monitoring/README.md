
### fluent-bit

```sh
helm upgrade --install fluent-bit fluent/fluent-bit -n monitoring --create-namespace -f values/fluent-bit.yaml
```

### loki

```sh
helm install loki grafana/loki -f values/loki.yaml -n monitoring
```

### prometheus

```sh
helm install prometheus prometheus-community/prometheus -n monitoring
```


### tempo

```sh
helm upgrade --install tempo grafana/tempo
```

## grafana
https://grafana.com/docs/grafana/latest/setup-grafana/installation/helm/

```sh
install my-grafana grafana/grafana --namespace monitoring
```

```sh
kubectl get secret --namespace monitoring my-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

```sh
helm upgrade --install  my-grafana grafana/grafana --namespace monitoring -f k3s/monitoring/values/grafana.yaml
```