#!/bin/bash
# Traefik RTMP EntryPoint 설정 스크립트
# K3s 환경에서 HelmChartConfig가 제대로 적용되지 않을 때 사용

set -e

echo "================================"
echo "Traefik RTMP EntryPoint Setup"
echo "================================"
echo ""

# 1. HelmChartConfig 적용 (이미 존재하면 unchanged)
echo "[1/4] Applying HelmChartConfig..."
kubectl apply -f k3s/trafik-config.yaml

# 2. Traefik Deployment에 RTMP entrypoint argument 추가
echo "[2/4] Patching Traefik deployment - adding RTMP entrypoint argument..."
kubectl patch deployment traefik -n kube-system --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--entryPoints.rtmp.address=:1935/tcp"
  }
]' 2>/dev/null || echo "  (Already exists or patched)"

# 3. Traefik Deployment에 RTMP container port 추가
echo "[3/4] Patching Traefik deployment - adding RTMP container port..."
kubectl patch deployment traefik -n kube-system --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/ports/-",
    "value": {
      "name": "rtmp",
      "containerPort": 1935,
      "protocol": "TCP"
    }
  }
]' 2>/dev/null || echo "  (Already exists or patched)"

# 4. Traefik Pod가 재시작될 때까지 대기
echo "[4/4] Waiting for Traefik pod to restart..."
sleep 5
kubectl rollout status deployment traefik -n kube-system --timeout=60s

echo ""
echo "✅ Traefik RTMP configuration completed!"
echo ""
echo "Verification:"
echo "  kubectl get svc traefik -n kube-system | grep rtmp"
echo "  kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=20"
echo ""

# 5. 결과 확인
echo "Current Traefik service status:"
kubectl get svc traefik -n kube-system -o jsonpath='{.spec.ports[?(@.name=="rtmp")]}' | jq '.'

echo ""
echo "RTMP Endpoint:"
EXTERNAL_IP=$(kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[1].ip}')
echo "  rtmp://${EXTERNAL_IP}:1935/live/<stream-key>"
