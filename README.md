# Vox2Vocal Infra

Vox2Vocal 로컬 개발용 Kubernetes 인프라 구성을 담고 있습니다.

이 저장소의 리소스는 `k8s/` 아래 Kubernetes 매니페스트로 관리하며,
`kubectl apply -k k8s` 명령으로 Kustomize 기반 적용을 수행합니다.

## 디렉터리 구조

```text
infra/
  README.md
  AGENT.md
  k8s/
    api-gateway.yaml
    bff-server.yaml
    configmap.yaml
    ingress.yaml
    kustomization.yaml
    namespace.yaml
    nats.yaml
    postgres.yaml
    redis.yaml
    secret.yaml
    user-service.yaml
    worker.yaml
```

## Kubernetes 파일 설명

| 파일 | 설명 |
| --- | --- |
| `k8s/namespace.yaml` | 모든 로컬 Kubernetes 리소스가 사용할 `vox2vocal` 네임스페이스를 생성합니다. |
| `k8s/kustomization.yaml` | `kubectl apply -k k8s`로 적용할 매니페스트 목록입니다. 새 YAML 파일을 추가하면 이 파일에도 등록해야 합니다. |
| `k8s/configmap.yaml` | 포트, gRPC 주소, Redis 설정, `NATS_URL`처럼 비밀값이 아닌 공통 런타임 설정을 담습니다. |
| `k8s/secret.yaml` | PostgreSQL 계정, 비밀번호, `DATABASE_URL`처럼 로컬 개발용 비밀값을 담습니다. |
| `k8s/postgres.yaml` | PostgreSQL `Service`와 `StatefulSet`입니다. Service 포트는 `15432`이고 컨테이너 포트 `5432`로 라우팅합니다. |
| `k8s/redis.yaml` | Redis `Service`와 `Deployment`입니다. worker 런타임에서 사용합니다. |
| `k8s/nats.yaml` | NATS JetStream `Service`와 `StatefulSet`입니다. JetStream 저장소용 PVC를 사용하며 client 포트는 `4222`, monitoring 포트는 `8222`입니다. |
| `k8s/bff-server.yaml` | GraphQL BFF `Service`와 `Deployment`입니다. 클러스터 내부 HTTP 포트 `4000`을 제공합니다. |
| `k8s/api-gateway.yaml` | API Gateway `Service`와 `Deployment`입니다. HTTP `3001`, gRPC `50050`을 제공합니다. |
| `k8s/user-service.yaml` | 사용자 도메인 `Service`와 `Deployment`입니다. HTTP `3002`, gRPC `50051`을 제공하고 `DATABASE_URL`을 Secret에서 읽습니다. |
| `k8s/worker.yaml` | worker `Deployment`입니다. Redis 설정을 ConfigMap에서 읽습니다. |
| `k8s/ingress.yaml` | `vox2vocal.local` 요청을 BFF 서비스로 전달하는 Ingress입니다. |

## 런타임 구성 요소

| 구성 요소 | Kubernetes 종류 | 이미지 | 주요 DNS 이름 |
| --- | --- | --- | --- |
| BFF server | Deployment | `vox2vocal/bff-server:local` | `bff-server.vox2vocal.svc.cluster.local` |
| API gateway | Deployment | `vox2vocal/api-gateway:local` | `api-gateway.vox2vocal.svc.cluster.local` |
| User service | Deployment | `vox2vocal/user-service:local` | `user-service.vox2vocal.svc.cluster.local` |
| Worker | Deployment | `vox2vocal/worker:local` | Service 없음 |
| PostgreSQL | StatefulSet | `postgres:17.10-alpine` | `postgres.vox2vocal.svc.cluster.local` |
| Redis | Deployment | `redis:7.2.14-alpine3.21` | `redis.vox2vocal.svc.cluster.local` |
| NATS JetStream | StatefulSet | `nats:2.11.15-alpine3.22` | `nats.vox2vocal.svc.cluster.local` |

## 클러스터 내부 주요 주소

Kubernetes 클러스터 내부 워크로드에서는 아래 값을 사용합니다.

```text
DATABASE_URL=postgresql://vox2vocal:vox2vocal@postgres:15432/vox2vocal?schema=users
REDIS_HOST=redis
REDIS_PORT=6379
NATS_URL=nats://nats:4222
API_GATEWAY_GRPC_URL=api-gateway:50050
USER_SERVICE_GRPC_URL=user-service:50051
```

## 로컬 실행

minikube 설치:

```bash
winget install Kubernetes.minikube
```

로컬 클러스터 시작 및 Ingress 활성화:

```bash
minikube start
minikube addons enable ingress
```

minikube Docker daemon을 사용해 로컬 서비스 이미지를 빌드합니다.

PowerShell:

```powershell
minikube docker-env | Invoke-Expression
docker build -t vox2vocal/bff-server:local ../bff-server
docker build -t vox2vocal/api-gateway:local ../api-gateway
docker build -t vox2vocal/user-service:local ../user-service
docker build -t vox2vocal/worker:local ../worker
```

모든 Kubernetes 리소스 적용:

```bash
kubectl apply -k k8s
```

상태 확인:

```bash
kubectl get all -n vox2vocal
kubectl get pvc -n vox2vocal
```

## Ingress

minikube IP 확인:

```bash
minikube ip
```

로컬 hosts 파일에 아래 형식으로 등록합니다.

```text
<minikube-ip> vox2vocal.local
```

GraphQL endpoint:

```text
http://vox2vocal.local/graphql
```

## 참고

- `postgres`는 `LoadBalancer` Service로 구성되어 있고 Service 포트는 `15432`입니다. 단, minikube에서 호스트 머신 접근이 필요하면 `minikube tunnel`이 필요할 수 있습니다.
- 클러스터 내부 워크로드는 `postgres`, `redis`, `nats` 같은 Kubernetes Service DNS 이름을 사용합니다.
- 애플리케이션 설정에는 Pod DNS보다 안정적인 Service DNS를 우선 사용합니다.
