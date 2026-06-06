# Logging MVP Roadmap

이 문서는 Vox2Vocal `engine-*` 계열 로그 운영 MVP의 인프라 구성 범위, 단계별 작업, 현재 완료 상태를 추적합니다.

## Goal

`engine-*` 서비스의 JSON stdout/stderr 로그를 Kubernetes container log로 수집하고 Promtail을 통해 Loki에 저장한 뒤 Grafana에서 조회합니다.

Audit 데이터는 Loki에만 저장하지 않습니다. PostgreSQL append-only audit store를 기본 저장소로 두고, 장기 증적은 이후 object storage 또는 WORM archive로 확장합니다.

## Storage Flow

```text
operational / pipeline / quality / model
  engine-* stdout/stderr
  -> Kubernetes container log
  -> Promtail
  -> Loki
  -> Grafana

security
  engine-* stdout/stderr with log_domain=security
  -> Kubernetes container log
  -> Promtail
  -> Loki security stream
  -> future OpenSearch or SIEM

audit
  audit_writer
  -> PostgreSQL append-only audit.audit_events
  -> audit.audit_daily_digests
  -> future object storage or WORM archive
```

## Phase 1: Local Logging MVP

- [x] Loki single replica와 PVC 구성
- [x] Grafana와 Loki datasource provisioning 구성
- [x] Promtail DaemonSet, ServiceAccount, RBAC 구성
- [x] Promtail이 `/var/log/containers/*_vox2vocal_*.log`를 수집하도록 구성
- [x] JSON log에서 `level`, `log_domain` 파싱 구성
- [x] Loki label을 `namespace`, `pod`, `container`, `service`, `level`, `log_domain`으로 제한
- [x] `trace_id`, `job_id`, `audio_asset_id`, `user_id`를 Loki label에서 제외
- [x] `engine-audio-ingest` logging env, resources, securityContext 보완
- [x] `AUDIT_DATABASE_URL` 추가
- [x] PostgreSQL audit table SQL 초안 추가
- [x] `k8s/kustomization.yaml`에 신규 manifest 등록
- [x] README에 운영 확인 명령, 저장 정책, 접근 방식 반영

## Phase 2: Operational Hardening

- [ ] Grafana dashboard provisioning 추가
- [ ] Loki query 예시와 runbook 상세화
- [ ] `log_domain=security` 기반 alert rule 추가
- [ ] engine별 error rate, FFmpeg timeout, NATS dependency failure query 정의
- [ ] audit write failure P1 alert 기준 정의
- [ ] Promtail 유지 또는 Alloy/Fluent Bit 전환 기준 평가

## Phase 3: Retention And Security Expansion

- [ ] Security 로그 OpenSearch 또는 SIEM 연동
- [ ] Audit daily digest 생성 Job 또는 application migration 확정
- [ ] Audit archive object storage export 설계
- [ ] WORM/object lock 적용 기준 문서화
- [ ] Cold log archive bucket 구조 확정
- [ ] Incident evidence package export 절차 정의

## Current Status

완료:

- Loki, Grafana, Promtail Kubernetes manifest 작성
- Loki `Service` 이름 `loki`, port `3100` 구성
- Grafana `Service` 이름 `grafana`, port `3000` 구성
- Grafana Loki datasource 자동 등록
- Promtail collector가 `vox2vocal` namespace의 container log를 Loki로 전송
- `engine-audio-ingest`에 logging env와 resource/security 설정 추가
- Audit PostgreSQL 논리 분리 준비
- `sql/audit-schema.sql` 추가
- README와 roadmap 문서 갱신

2026-06-06 로컬 클러스터 검증 결과:

- `kubectl kustomize k8s` 성공
- `kubectl apply -k k8s` 성공
- `statefulset/loki` Ready
- `deployment/grafana` Ready
- `daemonset/promtail` Ready
- Loki label API에서 `namespace`, `pod`, `container`, `service` label 확인
- Loki query range에서 `{namespace="vox2vocal"}` 로그 stream 조회 확인
- Grafana API에서 Loki datasource `http://loki:3100` 확인

남은 작업:

- `vox2vocal/engine-audio-ingest:local` 이미지를 Minikube Docker daemon에 빌드한 뒤 engine pod 정상화
- `{service="engine-audio-ingest"}` 로그 유입 확인
- `log_domain=security` 실제 샘플 로그 유입 확인
- Grafana UI에서 datasource `Save & test` 확인
- Audit SQL 적용 방식을 확정: application migration 또는 수동 DBA SQL
- Dashboard, alert, rule provisioning 추가

## Validation Commands

```bash
kubectl kustomize k8s
kubectl apply -k k8s --dry-run=client
kubectl apply -k k8s
kubectl get all -n vox2vocal
kubectl get pvc -n vox2vocal
kubectl logs -n vox2vocal ds/promtail
kubectl port-forward -n vox2vocal svc/grafana 3000:3000
```

Grafana Explore query:

```text
{namespace="vox2vocal"}
{service="engine-audio-ingest"}
{log_domain="security"}
```
