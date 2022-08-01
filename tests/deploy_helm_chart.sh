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
  --set fluentd.image.repository=public.ecr.aws/sumologic/kubernetes-fluentd@sha256 \
  --set fluentd.image.tag=362053ce1833aa51db31d36f97458f526d199bcd7efff53486b09e3a02a795ab \
  --set metrics-server.image.registry=public.ecr.aws \
  --set metrics-server.image.repository=sumologic/metrics-server@sha256 \
  --set metrics-server.image.tag=1f3c4554e2141e67600ffb2528d8745daf1e581330cb5f4fc75ee7c8aa2298c1 \
  --set fluent-bit.image.repository=public.ecr.aws/sumologic/fluent-bit@sha256 \
  --set fluent-bit.image.tag=faa802d22e41f8d67d487e40285fa2a7ea72f9cd49c32ddb80ea34f4d302e220 \
  --set kube-prometheus-stack.prometheusOperator.image.repository=public.ecr.aws/sumologic/prometheus-operator \
  --set kube-prometheus-stack.prometheusOperator.image.tag=v0.43.2-ubi \
  --set kube-prometheus-stack.prometheusOperator.image.sha=8e29f9b5b7ae76aa9515d1ba20180511feb0c642bc61f782d8d1ea6f62f862aa \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.repository=public.ecr.aws/sumologic/prometheus-config-reloader \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.tag=v0.43.2-ubi \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.sha=0309a748632654700e0d49f7ecd7ee61e6344f53107c9ce0c5cf1d301f943d37 \
  --set kube-prometheus-stack.kube-state-metrics.image.repository=public.ecr.aws/sumologic/kube-state-metrics@sha256 \
  --set kube-prometheus-stack.kube-state-metrics.image.tag=bb1f73b2be45fa31dfd3fbe72df1d553e5c6cdaa81709bf628764f5969ce4fc2 \
  --set kube-prometheus-stack.prometheus-node-exporter.image.repository=public.ecr.aws/sumologic/node-exporter@sha256 \
  --set kube-prometheus-stack.prometheus-node-exporter.image.tag=22694389170863ac60b6c5248310c1381cb145b6b9fa354a18ee664215c5375a \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.repository=public.ecr.aws/sumologic/prometheus \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.tag=v2.22.1-ubi \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.sha=716d5c7183affd306bee7c35c577e5da852d4dfe8da9bf37aff255cd96a0c9b3 \
  --set kube-prometheus-stack.prometheus.prometheusSpec.thanos.image=public.ecr.aws/sumologic/thanos@sha256:707e40ee919e4bc3c2edeecdc536acdf8cb67f9e5fc34eaad9d9e4c283438bb1 \
  --set telegraf-operator.image.repository=public.ecr.aws/sumologic/telegraf-operator-ubi \
  --set telegraf-operator.image.sidecarImage=public.ecr.aws/sumologic/telegraf@sha256:8d92cabdd8efbec83475a004209745cc14e877d361cae19ab80a622ebda57e24 \
  --set tailing-sidecar-operator.operator.image.repository=ghcr.io/sumologic/tailing-sidecar-operator@sha256 \
  --set tailing-sidecar-operator.operator.image.tag=1d9d902b165596e12a626f5dd2f9d512627b356c3773a04c96df24270a840724 \
  --set tailing-sidecar-operator.sidecar.image.repository=ghcr.io/sumologic/tailing-sidecar@sha256 \
  --set tailing-sidecar-operator.sidecar.image.tag=838401ab699ae1f4a581a62a6eea413bca1e2c30d60358acb16bd86be75fbca1 \
  --set tailing-sidecar-operator.kubeRbacProxy.image.repository=public.ecr.aws/sumologic/kube-rbac-proxy@sha256 \
  --set tailing-sidecar-operator.kubeRbacProxy.image.tag=f92b5704d9d1290b1dd9cc8bfcc445e3e118794e8cf9531f439994ee4d2523a6 \
  --version 2.14.1 \
  -n sumologic-system \
  --create-namespace -f "${ROOT_DIR}/tests/values.yaml"

wait_for_collection_resources "${NAMESPACE}" "${TIME}"

helm get manifest -n "${NAMESPACE}"  test-openshift > helm_chart_templates.yaml

helm delete test-openshift -n"${NAMESPACE}"
kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
