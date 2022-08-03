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
  --set fluentd.image.tag=a07ea5c9025a4ed4c964165fae961fef902645fc3eb741761ac5068b1684acce \
  --set metrics-server.image.registry=docker.io \
  --set metrics-server.image.repository=bitnami/metrics-server@sha256 \
  --set metrics-server.image.tag=579ed5377d14841c6b1641cfaf9c0802420a066529b8a71e5f91609d3f28fd05 \
  --set fluent-bit.image.repository=public.ecr.aws/sumologic/fluent-bit@sha256 \
  --set fluent-bit.image.tag=2861b8821e685873b1e806376bf50beb4326ed577a9882661ed7b849927d91cc \
  --set kube-prometheus-stack.prometheusOperator.image.repository=quay.io/prometheus-operator/prometheus-operator \
  --set kube-prometheus-stack.prometheusOperator.image.tag=v0.44.0 \
  --set kube-prometheus-stack.prometheusOperator.image.sha=983627001c89bc6d7d881939c0c314c72ee26256004e8890c9e31efc498d7649 \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.repository=quay.io/prometheus-operator/prometheus-config-reloader \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.tag=v0.44.0 \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.sha=6659cb3d97b5f846b5e1651ca1ab95189509f899713c727143f1bc50cc6e57cf \
  --set kube-prometheus-stack.kube-state-metrics.image.repository=k8s.gcr.io/kube-state-metrics/kube-state-metrics@sha256 \
  --set kube-prometheus-stack.kube-state-metrics.image.tag=47d3a12d9da6699a9d95df8aaff235305229ef08203fae3fc1f1d47b2a409f89 \
  --set kube-prometheus-stack.prometheus-node-exporter.image.repository=quay.io/prometheus/node-exporter@sha256 \
  --set kube-prometheus-stack.prometheus-node-exporter.image.tag=f2269e73124dd0f60a7d19a2ce1264d33d08a985aed0ee6b0b89d0be470592cd \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.repository=quay.io/prometheus/prometheus\
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.tag=v2.22.1 \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.sha=b899dbd1b9017b9a379f76ce5b40eead01a62762c4f2057eacef945c3c22d210 \
  --set kube-prometheus-stack.prometheus.prometheusSpec.thanos.image=quay.io/thanos/thanos@sha256:43bfca02f322e4c719f4a373dd4618685fa806ce6d8094e1e2ff4a6ba4260cc2 \
  --set telegraf-operator.image.repository=quay.io/influxdb/telegraf-operator \
  --set telegraf-operator.image.sidecarImage=public.ecr.aws/sumologic/telegraf@sha256:ab779faeb3a2bd480c3f235738091eb8880c4086c60774f50d1e950dd22d994a \
  --set tailing-sidecar-operator.operator.image.repository=ghcr.io/sumologic/tailing-sidecar-operator@sha256 \
  --set tailing-sidecar-operator.operator.image.tag=51438fd64b91ed2f4dcafec60aaa8b5f3098b1aa035b39d5931cd7987a0bdc4f \
  --set tailing-sidecar-operator.sidecar.image.repository=ghcr.io/sumologic/tailing-sidecar@sha256 \
  --set tailing-sidecar-operator.sidecar.image.tag=4cd7efc6baf434805aab33a9ded476f4fd6195f7a8ed38be99179d1a99a9d3c0 \
  --set tailing-sidecar-operator.kubeRbacProxy.image.repository=gcr.io/kubebuilder/kube-rbac-proxy@sha256 \
  --set tailing-sidecar-operator.kubeRbacProxy.image.tag=e10d1d982dd653db74ca87a1d1ad017bc5ef1aeb651bdea089debf16485b080b \
  --version 2.14.1 \
  -n sumologic-system \
  --create-namespace -f "${ROOT_DIR}/tests/values.yaml"

wait_for_collection_resources "${NAMESPACE}" "${TIME}"

helm get manifest -n "${NAMESPACE}"  test-openshift > helm_chart_templates.yaml

helm delete test-openshift -n"${NAMESPACE}"
kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
