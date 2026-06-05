# Infra Agent Guide

이 가이드는 `infra` 저장소 안의 변경 작업에 적용합니다.

## 인프라 추가 또는 변경 시

Kubernetes 리소스를 추가, 삭제, 이름 변경하거나 런타임 계약을 바꾸는 경우
관련 문서를 같은 작업 단위에서 함께 갱신합니다.

필수 확인 항목:

1. 매니페스트 파일을 추가하거나 제거하면 `k8s/kustomization.yaml`을 갱신합니다.
2. `README.md`의 파일 목록, 구성 요소 표, DNS 이름, 포트, 런타임 URL을 최신 상태로 유지합니다.
3. 비밀값이 아닌 런타임 설정을 추가하거나 이름 변경하면 `k8s/configmap.yaml`을 갱신합니다.
4. 비밀값 런타임 설정을 추가하거나 이름 변경하면 `k8s/secret.yaml`을 갱신합니다.
5. 로컬 실행 명령, 포트, tunnel, 호스트 접근 방식이 바뀌면 `../docs/infra/local-run-guide.md` 등 관련 문서도 함께 갱신합니다.
6. 리소스 이름, label, selector, Service DNS 이름은 기존 매니페스트 규칙과 일관되게 유지합니다.

## 검증

인프라 변경을 커밋하기 전에 최소한 Kustomize 렌더링을 확인합니다.

```bash
kubectl kustomize k8s
```

로컬 클러스터가 준비되어 있다면 영향을 받은 리소스를 적용하고 상태를 확인합니다.

```bash
kubectl apply -k k8s
kubectl get all -n vox2vocal
kubectl get pvc -n vox2vocal
```

서비스 의존성은 가능하면 클러스터 내부에서 직접 확인합니다.

```bash
kubectl exec -n vox2vocal deploy/bff-server -- nslookup nats
kubectl exec -n vox2vocal deploy/bff-server -- nslookup postgres
```

## 커밋 규칙

- 인프라 작업 단위별로 커밋을 분리합니다.
- 리소스 변경 설명에 필요한 문서 갱신은 같은 커밋에 포함합니다.
- 관련 없는 문서 정리는 별도 커밋으로 분리합니다.
- 커밋 메시지에는 영향을 받은 구성 요소를 드러냅니다. 예: `Add NATS JetStream to Kubernetes infra`
