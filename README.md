# Vox2Vocal Infra

minikube 기반 로컬 Kubernetes 실행 구성을 담고 있습니다.

## 구성 요소

- `bff-server`: 외부 공개 GraphQL BFF
- `api-gateway`: 내부 gRPC API Gateway
- `user-service`: 사용자 도메인 gRPC 서비스
- `worker`: Redis/BullMQ worker
- `postgres`: PostgreSQL
- `redis`: Redis

## minikube 실행 순서

```bash
minikube start
minikube addons enable ingress
```

minikube Docker daemon을 사용해 로컬 이미지를 빌드합니다.

PowerShell:

```powershell
minikube docker-env | Invoke-Expression
docker build -t vox2vocal/bff-server:local ../bff-server
docker build -t vox2vocal/api-gateway:local ../api-gateway
docker build -t vox2vocal/user-service:local ../user-service
docker build -t vox2vocal/worker:local ../worker
```

리소스 적용:

```bash
kubectl apply -k k8s
```

Ingress 확인:

```bash
minikube ip
```

로컬 hosts 파일에 다음 형식으로 등록합니다.

```txt
<minikube-ip> vox2vocal.local
```

GraphQL endpoint:

```txt
http://vox2vocal.local/graphql
```
