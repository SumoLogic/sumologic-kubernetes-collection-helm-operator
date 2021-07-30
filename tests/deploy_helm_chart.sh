#!/usr/bin/env bash

date

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

# shellcheck disable=SC1090
source "${ROOT_DIR}/tests/functions.sh"

readonly NAMESPACE="sumologic-system"
readonly TIME=900

helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
helm repo update

helm install test-openshift sumologic/sumologic \
  --set sumologic.accessId="dummy" \
  --set sumologic.accessKey="dummy" \
  --set sumologic.endpoint="http://receiver-mock.receiver-mock:3000/terraform/api/" \
  --set sumologic.scc.create=true \
  --set fluent-bit.securityContext.privileged=true \
  --set kube-prometheus-stack.prometheus-node-exporter.service.port=9200 \
  --set kube-prometheus-stack.prometheus-node-exporter.service.targetPort=9200 \
  --set fluentd.buffer.queueChunkLimitSize=256 \
  --set fluentd.buffer.totalLimitSize="256m" \
  --set fluentd.logs.containers.multiline.enabled=false \
  --set metrics-server.enabled=true \
  --set metrics-server.apiService.create=false \
  --set otelagent.enabled=true \
  --set telegraf-operator.enabled=true \
  --set falco.enabled=true \
  --set tailing-sidecar-operator.enabled=true \
  --version 2.1.4 \
  -n sumologic-system \
  --create-namespace -f "${ROOT_DIR}/tests/values.yaml"

wait_for_collection_resources "${NAMESPACE}" "${TIME}"

helm get manifest -n "${NAMESPACE}"  test-openshift > helm_chart_templates.yaml

helm delete test-openshift -n"${NAMESPACE}"
kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
