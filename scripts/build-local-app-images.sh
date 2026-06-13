#!/usr/bin/env sh
set -eu

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
NAMESPACE="${NAMESPACE:-vox2vocal}"
TAG="${TAG:-local-$(date +%Y%m%d%H%M%S)}"

build_and_load() {
  service="$1"
  context="$2"

  image="vox2vocal/${service}:${TAG}"
  docker build --network=host -t "${image}" "${ROOT_DIR}/${context}"
  minikube image load "${image}"
  kubectl set image "deployment/${service}" -n "${NAMESPACE}" "${service}=${image}"
}

build_and_load "api-gateway" "vox2vocal-api-gateway"
build_and_load "bff-server" "vox2vocal-bff-server"
build_and_load "user-service" "vox2vocal-user-service"
build_and_load "worker" "vox2vocal-worker"

kubectl rollout status deployment -n "${NAMESPACE}" api-gateway --timeout=180s
kubectl rollout status deployment -n "${NAMESPACE}" bff-server --timeout=180s
kubectl rollout status deployment -n "${NAMESPACE}" user-service --timeout=180s
kubectl rollout status deployment -n "${NAMESPACE}" worker --timeout=180s
