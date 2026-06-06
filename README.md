# Vox2Vocal Infra

Vox2Vocal 로컬 개발 환경을 위한 Kubernetes 인프라 구성입니다.

이 저장소의 Kubernetes 리소스는 `k8s/` 아래 Kustomize manifest로 관리하며, 적용 명령은 다음과 같습니다.

```bash
kubectl apply -k k8s
```

Namespace는 `vox2vocal`을 사용합니다.

## Directory

```text
infra/
  README.md
  AGENT.md
  LOGGING_MVP_ROADMAP.md
  sql/
    audit-schema.sql
  k8s/
    api-gateway.yaml
    bff-server.yaml
    configmap.yaml
    engine-audio-ingest.yaml
    grafana.yaml
    ingress.yaml
    kustomization.yaml
    loki.yaml
    namespace.yaml
    nats.yaml
    postgres.yaml
    promtail.yaml
    redis.yaml
    secret.yaml
    user-service.yaml
    worker.yaml
```

## Kubernetes Files

| File | Description |
| --- | --- |
| `k8s/namespace.yaml` | `vox2vocal` namespace를 생성합니다. |
| `k8s/kustomization.yaml` | `kubectl apply -k k8s`로 적용할 manifest 목록입니다. 새 YAML을 추가하면 반드시 여기에 등록합니다. |
| `k8s/configmap.yaml` | 포트, 내부 DNS, NATS subject, logging, OpenTelemetry 확장용 공통 설정입니다. |
| `k8s/secret.yaml` | PostgreSQL 계정, `DATABASE_URL`, `AUDIT_DATABASE_URL` 등 로컬 개발용 secret입니다. |
| `k8s/postgres.yaml` | PostgreSQL `StatefulSet`과 `LoadBalancer` Service입니다. Service port는 `15432`, container port는 `5432`입니다. |
| `k8s/redis.yaml` | Redis `Deployment`와 Service입니다. |
| `k8s/nats.yaml` | NATS JetStream `StatefulSet`, Service, PVC입니다. Client port는 `4222`, monitoring port는 `8222`입니다. |
| `k8s/engine-audio-ingest.yaml` | Audio ingest engine 개발용 `Deployment`, Service, PVC입니다. Logging env, resource limit, 기본 securityContext를 포함합니다. |
| `k8s/loki.yaml` | 로컬 개발용 Loki 단일 replica `StatefulSet`, Service, PVC입니다. HTTP port는 `3100`입니다. |
| `k8s/grafana.yaml` | Grafana `Deployment`, Service, Loki datasource ConfigMap, `grafana.vox2vocal.local` Ingress입니다. |
| `k8s/promtail.yaml` | `/var/log/containers/*_vox2vocal_*.log`를 수집해 Loki로 전송하는 Promtail `DaemonSet`, ServiceAccount, RBAC, ConfigMap입니다. |
| `k8s/bff-server.yaml` | GraphQL BFF `Deployment`와 Service입니다. |
| `k8s/api-gateway.yaml` | API Gateway `Deployment`와 Service입니다. HTTP `3001`, gRPC `50050`을 제공합니다. |
| `k8s/user-service.yaml` | User service `Deployment`와 Service입니다. HTTP `3002`, gRPC `50051`을 제공합니다. |
| `k8s/worker.yaml` | Worker `Deployment`입니다. Redis 설정을 ConfigMap에서 읽습니다. |
| `k8s/ingress.yaml` | `vox2vocal.local` 요청을 BFF Service로 전달합니다. |

## Runtime Components

| Component | Kind | Image | Internal Address |
| --- | --- | --- | --- |
| BFF server | Deployment | `vox2vocal/bff-server:local` | `bff-server.vox2vocal.svc.cluster.local` |
| API gateway | Deployment | `vox2vocal/api-gateway:local` | `api-gateway.vox2vocal.svc.cluster.local` |
| User service | Deployment | `vox2vocal/user-service:local` | `user-service.vox2vocal.svc.cluster.local` |
| Worker | Deployment | `vox2vocal/worker:local` | 없음 |
| Audio ingest engine | Deployment | `vox2vocal/engine-audio-ingest:local` | `engine-audio-ingest.vox2vocal.svc.cluster.local` |
| Loki | StatefulSet | `grafana/loki:3.2.1` | `loki.vox2vocal.svc.cluster.local` |
| Grafana | Deployment | `grafana/grafana:11.3.0` | `grafana.vox2vocal.svc.cluster.local` |
| Promtail | DaemonSet | `grafana/promtail:3.2.1` | node-local collector |
| PostgreSQL | StatefulSet | `postgres:17.10-alpine` | `postgres.vox2vocal.svc.cluster.local` |
| Redis | Deployment | `redis:7.2.14-alpine3.21` | `redis.vox2vocal.svc.cluster.local` |
| NATS JetStream | StatefulSet | `nats:2.11.15-alpine3.22` | `nats.vox2vocal.svc.cluster.local` |

## Internal Configuration

Cluster 내부 workload는 다음 값을 사용합니다.

```text
DATABASE_URL=postgresql://vox2vocal:vox2vocal@postgres:15432/vox2vocal?schema=users
AUDIT_DATABASE_URL=postgresql://vox2vocal:vox2vocal@postgres:15432/vox2vocal?schema=audit
REDIS_HOST=redis
REDIS_PORT=6379
NATS_URL=nats://nats:4222
NATS_AUDIO_STREAM=VOX2VOCAL_AUDIO
NATS_AUDIO_INGEST_REQUEST_SUBJECT=audio.ingest.requested
NATS_AUDIO_INGEST_COMPLETED_SUBJECT=audio.ingest.completed
NATS_AUDIO_INGEST_FAILED_SUBJECT=audio.ingest.failed
ENGINE_AUDIO_INGEST_PORT=8080
LOG_FORMAT=json
LOG_LEVEL=INFO
LOG_SCHEMA_VERSION=1.0
TRACE_PROPAGATION_ENABLED=true
LOKI_URL=http://loki:3100
GRAFANA_URL=http://grafana:3000
API_GATEWAY_GRPC_URL=api-gateway:50050
USER_SERVICE_GRPC_URL=user-service:50051
```

## Local Run

Minikube 설치:

```bash
winget install Kubernetes.minikube
```

Cluster 시작과 Ingress 활성화:

```bash
minikube start
minikube addons enable ingress
```

Minikube Docker daemon에 로컬 이미지를 빌드합니다.

PowerShell:

```powershell
minikube docker-env | Invoke-Expression
docker build -t vox2vocal/bff-server:local ../bff-server
docker build -t vox2vocal/api-gateway:local ../api-gateway
docker build -t vox2vocal/user-service:local ../user-service
docker build -t vox2vocal/worker:local ../worker
docker build -t vox2vocal/engine-audio-ingest:local ../engine-audio-ingest
```

Kubernetes 리소스 적용:

```bash
kubectl apply -k k8s
```

상태 확인:

```bash
kubectl get all -n vox2vocal
kubectl get pvc -n vox2vocal
kubectl logs -n vox2vocal deploy/engine-audio-ingest
kubectl logs -n vox2vocal ds/promtail
```

## Access

PostgreSQL은 `LoadBalancer` Service로 구성되어 있고 Service port는 `15432`입니다.

```text
postgresql://vox2vocal:vox2vocal@localhost:15432/vox2vocal?schema=users
```

Minikube 환경에서 `localhost:15432` 접근이 되지 않으면 `minikube tunnel`이 필요할 수 있습니다.

Ingress 사용 시 hosts 파일에 다음 형식으로 등록합니다.

```text
<minikube-ip> vox2vocal.local grafana.vox2vocal.local
```

GraphQL endpoint:

```text
http://vox2vocal.local/graphql
```

Grafana endpoint:

```text
http://grafana.vox2vocal.local
```

또는 port-forward:

```bash
kubectl port-forward -n vox2vocal svc/grafana 3000:3000
```

Grafana 접속 후 `Connections > Data sources > Loki`에서 datasource URL이 `http://loki:3100`인지 확인합니다.

Explore query:

```text
{namespace="vox2vocal"}
{service="engine-audio-ingest"}
{log_domain="security"}
```

## Logging Policy

| Domain | MVP Storage | Note |
| --- | --- | --- |
| `operational` | Loki | 엔진 상태, dependency, health 로그입니다. |
| `pipeline` | Loki | Job/trace 흐름 로그입니다. `trace_id`, `job_id`, `audio_asset_id`는 label이 아니라 log body에 유지합니다. |
| `quality` | Loki | Audio/model 품질 경고 로그입니다. |
| `model` | Loki | 모델 버전, 설정 재현성 관련 로그입니다. |
| `security` | Loki security stream | `log_domain=security` label로 분리하고 이후 OpenSearch 또는 SIEM으로 확장합니다. |
| `audit` | PostgreSQL append-only audit store | Loki 단독 저장 금지입니다. `audit.audit_events`, `audit.audit_daily_digests` 기준으로 준비합니다. |

Promtail label은 다음으로 제한합니다.

```text
namespace
pod
container
service
level
log_domain
```

다음 high-cardinality 값은 Loki label로 만들지 않습니다.

```text
trace_id
job_id
audio_asset_id
user_id
```

운영 로그는 `LOCAL_STORAGE_ROOT`, audio asset directory, canonical WAV directory, manifest directory에 저장하지 않습니다.

## Audit

Audit schema 초안은 `sql/audit-schema.sql`에 있습니다.

MVP에서는 기존 PostgreSQL을 사용하되 `schema=audit`로 논리 분리합니다. 애플리케이션 계정은 장기적으로 audit table에 insert-only 권한을 갖는 것이 이상적입니다.

권한, 동의, 관리자 행위 판단과 관련된 audit write 실패는 fail-closed가 기본입니다. 장기 증적은 이후 object storage 또는 WORM archive로 확장합니다.

## Engine Image Contract

`engine-audio-ingest` 이미지는 애플리케이션 저장소에서 다음 기반으로 빌드되어야 합니다.

```text
python:3.12-slim
FFmpeg/ffprobe
libsndfile1
FastAPI/Uvicorn
nats-py
librosa
soundfile
numpy
boto3
```

Infra manifest는 개발용 실행 환경과 연결 정보를 제공하며, 엔진 애플리케이션 구현과 Dockerfile 품질은 engine 담당 저장소에서 관리합니다.
