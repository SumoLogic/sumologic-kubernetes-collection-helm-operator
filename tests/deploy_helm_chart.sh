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
  --set fluentd.logs.containers.multiline.enabled=false \
  --set metrics-server.enabled=true \
  --set metrics-server.apiService.create=false \
  --set otelagent.enabled=true \
  --set telegraf-operator.enabled=true \
  --set falco.enabled=true \
  --set tailing-sidecar-operator.enabled=true \
  --set opentelemetry-operator.enabled=true \
  --set fluentd.image.repository=public.ecr.aws/sumologic/kubernetes-fluentd@sha256 \
  --set fluentd.image.tag=dca1e3854b2e7fd2540c53c8092e3105c6a4bdcce426035a2cd5fed28a8690bf \
  --set metrics-server.image.registry=public.ecr.aws \
  --set metrics-server.image.repository=sumologic/metrics-server@sha256 \
  --set metrics-server.image.tag=c4a41f333bf942fa21c08d0c5b1b6b649f878341886ba59593b73d808ad9d3b0 \
  --set fluent-bit.image.repository=public.ecr.aws/sumologic/fluent-bit@sha256 \
  --set fluent-bit.image.tag=5f676040c66bd3d5c6309366beeb4c7ca91e0a70df3995ef19cea1adfec9b5ce \
  --set kube-prometheus-stack.prometheusOperator.image.repository=public.ecr.aws/sumologic/prometheus-operator \
  --set kube-prometheus-stack.prometheusOperator.image.tag=v0.44.0 \
  --set kube-prometheus-stack.prometheusOperator.image.sha=27384cfcd3bf32bee7584332b82188a7da5780dfc33f33ea8aa3afd2c10ca948 \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.repository=public.ecr.aws/sumologic/prometheus-config-reloader \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.tag=v0.44.0 \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.sha=7fc45d6c4cfa93363751277d3b761d30b1857be70d2c83568cabc36b19f47914 \
  --set kube-prometheus-stack.kube-state-metrics.image.repository=public.ecr.aws/sumologic/kube-state-metrics@sha256 \
  --set kube-prometheus-stack.kube-state-metrics.image.tag=18fb3800783b26db6a131ab846a28186dc0e9c12401e72a12ad99bf11d33186a \
  --set kube-prometheus-stack.prometheus-node-exporter.image.repository=public.ecr.aws/sumologic/node-exporter@sha256 \
  --set kube-prometheus-stack.prometheus-node-exporter.image.tag=685b59ebf0ce3c7e32f9de83359fdfc66a5143660f96b82c8ef8964c727bb2e5 \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.repository=public.ecr.aws/sumologic/prometheus \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.tag=v2.22.1 \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.sha=47004a8f74aab2353e8d0ac5725e4206a53305e7766a19b1cbb1dd770c2e8e36 \
  --set kube-prometheus-stack.prometheus.prometheusSpec.thanos.image=public.ecr.aws/sumologic/thanos@sha256:3f5b6df4e423475f912cb2e48e55e89235c68b473b53e202b246e024307ea965 \
  --set telegraf-operator.image.repository=public.ecr.aws/sumologic/telegraf-operator-ubi \
  --set telegraf-operator.image.sidecarImage=public.ecr.aws/sumologic/telegraf@sha256:f9883d1e9e0baf0d326a7c2c5503e011b36bf0bff22d6470c2f6d2b39fdd11fb \
  --set tailing-sidecar-operator.operator.image.repository=ghcr.io/sumologic/tailing-sidecar-operator@sha256 \
  --set tailing-sidecar-operator.operator.image.tag=5829d4e03c0a473d27fba56774a6a0f19aed84e2ae1e501d706bd50b60241b6c \
  --set tailing-sidecar-operator.sidecar.image.repository=ghcr.io/sumologic/tailing-sidecar@sha256 \
  --set tailing-sidecar-operator.sidecar.image.tag=aff9aef3bbe41ffe1fc8e4b280533405a6065d48f7e3ff617458cd0a8e3b4ab5 \
  --set tailing-sidecar-operator.kubeRbacProxy.image.repository=public.ecr.aws/sumologic/kube-rbac-proxy@sha256 \
  --set tailing-sidecar-operator.kubeRbacProxy.image.tag=d47164d94803408071d68227798eadd3692d6705a6bcd55ccb31b025fc36d1d8 \
  --set opentelemetry-operator.manager.image.repository=ghcr.io/open-telemetry/opentelemetry-operator/opentelemetry-operator@sha256 \
  --set opentelemetry-operator.manager.image.tag=148960f590a96fb000b2ff2accb33d131e52649006ef24a0c572664b8d2c9644 \
  --set opentelemetry-operator.kubeRBACProxy.image.repository=public.ecr.aws/sumologic/kube-rbac-proxy@sha256 \
  --set opentelemetry-operator.kubeRBACProxy.image.tag=d47164d94803408071d68227798eadd3692d6705a6bcd55ccb31b025fc36d1d8 \
  --version 2.14.1 \
  -n sumologic-system \
  --create-namespace -f "${ROOT_DIR}/tests/values.yaml"

wait_for_collection_resources "${NAMESPACE}" "${TIME}"

helm get manifest -n "${NAMESPACE}"  test-openshift > helm_chart_templates.yaml

helm delete test-openshift -n"${NAMESPACE}"
kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
