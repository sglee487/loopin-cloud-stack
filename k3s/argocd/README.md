## argocd insecure 활성화 방법

다음 명령어로 설치했을 때 (file)
```sh
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```


```sh
kubectl -n argocd patch cm argocd-cmd-params-cm \
  --type merge -p '{"data":{"server.insecure":"true"}}'
```

```sh
kubectl -n argocd rollout restart deploy argocd-server
```
