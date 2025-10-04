# helm
https://grafana.com/docs/loki/latest/setup/install/helm/concepts/


### install
```sh
helm install loki grafana/loki -f values.yaml -n monitoring
```

### upgrade
```sh
helm upgrade loki grafana/loki --values values.yaml -n monitoring
```