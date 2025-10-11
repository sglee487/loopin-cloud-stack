# RTMP 스트리밍 설정 가이드

이 문서는 K3s + Traefik 환경에서 RTMP 스트리밍을 설정하는 방법을 설명합니다.

## 문제 상황

K3s의 HelmChartConfig를 사용하여 Traefik에 RTMP entrypoint를 추가했지만, 실제 deployment에 반영되지 않는 문제가 발생했습니다.

### 증상
```bash
# Traefik 로그에서 확인되는 에러
[ERR] EntryPoint doesn't exist entryPointName=rtmp
[ERR] No valid entryPoint for this router

# Service의 RTMP endpoint가 비어있음
kubectl describe svc traefik -n kube-system
# Port: rtmp 1935/TCP
# Endpoints: (empty)
```

## 해결 방법

### 방법 1: 자동 스크립트 실행 (권장)

```bash
cd /home/opc/workspace/snservice-cloud-stack
chmod +x k3s/traefik-rtmp-setup.sh
./k3s/traefik-rtmp-setup.sh
```

### 방법 2: 수동 설정

#### 1. HelmChartConfig 적용
```bash
kubectl apply -f k3s/trafik-config.yaml
```

#### 2. Traefik Deployment에 RTMP entrypoint argument 추가
```bash
kubectl patch deployment traefik -n kube-system --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--entryPoints.rtmp.address=:1935/tcp"
  }
]'
```

#### 3. Traefik Deployment에 RTMP container port 추가
```bash
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
]'
```

#### 4. Traefik 재시작 확인
```bash
kubectl rollout status deployment traefik -n kube-system
```

## 검증

### 1. Traefik Arguments 확인
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik -o yaml | grep -A 30 "args:" | grep rtmp
```

예상 출력:
```
- --entryPoints.rtmp.address=:1935/tcp
```

### 2. Service Endpoints 확인
```bash
kubectl describe svc traefik -n kube-system | grep -A 5 "rtmp"
```

예상 출력:
```
Port:      rtmp  1935/TCP
TargetPort: rtmp/TCP
NodePort:  rtmp  30194/TCP
Endpoints: 10.42.0.160:1935
```

### 3. IngressRouteTCP 확인
```bash
kubectl get ingressroutetcp -n loopin-production
```

### 4. Traefik 로그 확인 (에러 없어야 함)
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=50 | grep -i rtmp
```

RTMP 관련 에러가 없어야 합니다.

## 사용 방법

### External IP 확인
```bash
kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[1].ip}'
# 출력: 168.138.205.163
```

### RTMP 스트리밍 URL

#### IP 직접 사용
```
rtmp://168.138.205.163:1935/live/<stream-key>
```

#### 도메인 사용 (DNS 설정 후)
```
rtmp://ingest.loopin.bid:1935/live/<stream-key>
```

### OBS Studio 설정
- **Server**: `rtmp://168.138.205.163:1935/live`
- **Stream Key**: `your-stream-key`

### FFmpeg 테스트
```bash
# 파일 스트리밍
ffmpeg -re -i input.mp4 -c copy -f flv rtmp://168.138.205.163:1935/live/test

# 웹캠 스트리밍 (Linux)
ffmpeg -f v4l2 -i /dev/video0 -c:v libx264 -preset veryfast -b:v 1500k \
  -f flv rtmp://168.138.205.163:1935/live/test
```

## 로그 모니터링

### SRS 서버 로그 (RTMP 연결 확인)
```bash
kubectl logs -n loopin-production -l app=srs-server --tail=50 -f
```

연결 성공 시:
```
[INFO] RTMP client connected
[INFO] publish stream: live/your-stream-key
```

### Traefik Access 로그
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik --tail=50 -f
```

## 네트워크 설정

### 오라클 클라우드 방화벽
1. **Security List**에서 Ingress Rule 추가:
   - Source: `0.0.0.0/0`
   - Protocol: `TCP`
   - Destination Port: `1935`

2. **Network Security Groups** 확인 (사용 중인 경우)

### DNS 설정 (선택사항)
```
A Record:
  Name: ingest.loopin.bid
  Value: 168.138.205.163
  TTL: 300
```

## 트러블슈팅

### 연결이 안 될 때

1. **Traefik Service 확인**
```bash
kubectl get svc traefik -n kube-system -o wide
```

2. **SRS Service 확인**
```bash
kubectl get svc srs-service -n loopin-production
kubectl get endpoints srs-service -n loopin-production
```

3. **IngressRouteTCP 확인**
```bash
kubectl describe ingressroutetcp srs-rtmp -n loopin-production
```

4. **포트 테스트**
```bash
# 로컬에서
nc -zv 168.138.205.163 1935

# 또는
telnet 168.138.205.163 1935
```

5. **SRS Pod 로그 확인**
```bash
kubectl logs -n loopin-production -l app=srs-server --tail=100
```

## 관련 파일

- `k3s/trafik-config.yaml` - Traefik HelmChartConfig (RTMP entrypoint 정의)
- `k3s/loopin-production/overlays/prod/ingress-tcp.yaml` - RTMP IngressRouteTCP
- `k3s/loopin-production/base/srs-server/` - SRS 서버 설정
- `k3s/traefik-rtmp-setup.sh` - 자동 설정 스크립트

## 참고사항

- RTMP는 TCP 기반 프로토콜이므로 HTTP Ingress가 아닌 IngressRouteTCP를 사용해야 합니다
- HostSNI 기반 라우팅이 불가능하므로 `HostSNI('*')`를 사용합니다
- 1935 포트로 들어오는 모든 TCP 트래픽이 SRS 서버로 라우팅됩니다
- 도메인은 DNS 해석용이며, 실제 Kubernetes 라우팅은 포트 기반입니다
