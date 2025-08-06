## grafana
https://grafana.com/docs/grafana/latest/setup-grafana/installation/helm/

```sh
helm install my-grafana grafana/grafana --namespace monitoring
```

```sh
kubectl get secret --namespace monitoring my-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

```sh
helm upgrade --install my-grafana grafana/grafana -f values.yaml --namespace monitoring
```