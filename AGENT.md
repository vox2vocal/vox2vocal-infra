# Infra Agent Guide

이 가이드는 `infra` 저장소의 Kubernetes, 로컬 개발 인프라, 운영 관측 구성 변경에 적용합니다.

## Scope

`infra` 변경은 다음 범위를 포함합니다.

- Kubernetes manifest 추가, 삭제, 이름 변경
- Service, port, DNS, selector, label 변경
- ConfigMap 또는 Secret key 추가, 삭제, 이름 변경
- PostgreSQL, Redis, NATS, Loki, Grafana, Promtail 등 런타임 구성 변경
- 로컬 실행 방식, tunnel, ingress, port-forward, 접근 URL 변경
- 인프라 운영 정책 또는 로그 저장 정책 문서 변경

## Required Documentation Updates

인프라를 변경할 때는 관련 문서를 같은 작업 단위에서 갱신합니다.

1. 새 manifest를 추가하거나 제거하면 `k8s/kustomization.yaml`을 갱신합니다.
2. 런타임 구성 요소, DNS, port, 접근 URL이 바뀌면 `README.md`를 갱신합니다.
3. 비밀값이 아닌 공통 설정이 바뀌면 `k8s/configmap.yaml`과 `README.md`를 함께 확인합니다.
4. 비밀값 또는 connection string이 바뀌면 `k8s/secret.yaml`과 `README.md`를 함께 확인합니다.
5. 로그 인프라, 저장 정책, audit 정책이 바뀌면 `LOGGING_MVP_ROADMAP.md`를 갱신합니다.
6. 로컬 실행 명령, tunnel, ingress 접근 방식이 바뀌면 관련 실행 문서도 함께 갱신합니다.
7. Service DNS, label, selector는 기존 manifest 규칙과 일관되게 유지합니다.

## Logging Rules

- Operational, pipeline, quality, 일반 model 로그는 Loki에 저장합니다.
- Security 로그는 MVP에서 `log_domain=security` Loki stream으로 분리하고, 이후 OpenSearch 또는 SIEM으로 확장합니다.
- Audit 데이터는 Loki에만 저장하지 않습니다.
- Audit 데이터는 PostgreSQL append-only audit store에 저장하고, 이후 object storage 또는 WORM archive로 확장할 수 있게 문서화합니다.
- Loki label은 `namespace`, `pod`, `container`, `service`, `level`, `log_domain` 수준으로 제한합니다.
- `trace_id`, `job_id`, `audio_asset_id`, `user_id`는 high-cardinality 값이므로 Loki label로 만들지 않습니다.
- 운영 로그는 `LOCAL_STORAGE_ROOT`, audio asset directory, canonical WAV directory, manifest directory에 저장하지 않습니다.

## Validation

인프라 변경 후 최소한 Kustomize 렌더링을 확인합니다.

```bash
kubectl kustomize k8s
```

로컬 클러스터가 준비되어 있으면 적용과 상태 확인까지 수행합니다.

```bash
kubectl apply -k k8s
kubectl get all -n vox2vocal
kubectl get pvc -n vox2vocal
```

로그 인프라를 변경한 경우 다음도 확인합니다.

```bash
kubectl logs -n vox2vocal ds/promtail
kubectl port-forward -n vox2vocal svc/grafana 3000:3000
```

Grafana에서는 Loki datasource가 `http://loki:3100`으로 등록되어 있는지 확인합니다.

## Commit Convention

커밋 요청이 있으면 `infra` repo 안에서만 커밋하고 푸시합니다. 커밋 메시지는 Conventional Commits 형식을 사용합니다.

```text
type(scope): 한글 제목
```

주요 type:

```text
feat: 기능 또는 인프라 구성 추가
fix: 버그 수정
docs: 문서 변경
chore: 설정, 의존성, 환경 구성 변경
refactor: 동작 변경 없는 구조 개선
test: 테스트 추가 또는 수정
ci: CI/CD 설정 변경
```

권장 scope:

```text
infra
k8s
logging
nats
postgres
docs
```

예시:

```text
feat(logging): 로그 운영 MVP 인프라 추가

- Loki, Grafana, Promtail manifest 추가
- engine-audio-ingest logging env와 resource limit 구성
- audit PostgreSQL schema 초안 문서화
```

작업 단위가 다르면 같은 repo 안에서도 커밋을 분리합니다. 관련 없는 문서 정리나 리팩터링은 인프라 변경 커밋에 섞지 않습니다.
