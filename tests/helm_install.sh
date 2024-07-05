#!/usr/bin/env bash

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

helm install test-openshift sumologic/sumologic \
  --set sumologic.accessId="dummy" \
  --set sumologic.accessKey="dummy" \
  --set sumologic.endpoint="http://receiver-mock.receiver-mock:3000/terraform/api/" \
  --set sumologic.scc.create=true \
  --set metrics-server.enabled=true \
  --set metrics-server.apiService.create=false \
  --set telegraf-operator.enabled=true \
  --set tailing-sidecar-operator.enabled=true \
  --version 4.9.0 \
  -n sumologic-system \
  --create-namespace -f "${ROOT_DIR}/tests/values.yaml" \
  --set instrumentation.instrumentationJobImage.image.repository=public.ecr.aws/sumologic/kubernetes-tools-kubectl@sha256 \
  --set instrumentation.instrumentationJobImage.image.tag=89ae5ef9c85f6a01d520c8e237e614131cdc81a09f2eade54c9b091b2993e856 \
  --set kube-prometheus-stack.kube-state-metrics.image.repository=public.ecr.aws/sumologic/kube-state-metrics@sha256 \
  --set kube-prometheus-stack.kube-state-metrics.image.tag=473614d1c0de0f9f0b5314eab40d3172f5180332a2009be590ce474b85cb898e \
  --set kube-prometheus-stack.prometheus-node-exporter.image.repository=public.ecr.aws/sumologic/node-exporter@sha256 \
  --set kube-prometheus-stack.prometheus-node-exporter.image.tag=685b59ebf0ce3c7e32f9de83359fdfc66a5143660f96b82c8ef8964c727bb2e5 \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.repository=public.ecr.aws/sumologic/prometheus@sha256 \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.sha=92c173c757018178920385bbb93d826ae5b5cab4706ac6b239e919ae6b3520b4 \
  --set kube-prometheus-stack.prometheus.prometheusSpec.image.tag=v2.39.0-ubi \
  --set kube-prometheus-stack.prometheusOperator.image.repository=public.ecr.aws/sumologic/prometheus-operator@sha256 \
  --set kube-prometheus-stack.prometheusOperator.image.sha=f98f265fd0609da354ca6cbb6ea3b56a88ebccfb2daff14896f7004aa4ffa174 \
  --set kube-prometheus-stack.prometheusOperator.image.tag=v0.59.2-ubi \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloader.image.repository=public.ecr.aws/sumologic/prometheus-config-reloader@sha256 \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.sha=03d3ca5b7c96c88ff8de363371d89ead3be6ac0b74653da1ac2231bd1b0e386d \
  --set kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.tag=v0.59.2-ubi \
  --set kube-prometheus-stack.prometheusOperator.thanosImage.repository=public.ecr.aws/sumologic/thanos@sha256 \
  --set kube-prometheus-stack.prometheusOperator.thanosImage.sha=323ff1e3500fdbf594acfca19639911b5ed8d0a527b9742c264d5f5b1ce5d4cc \
  --set kube-prometheus-stack.prometheusOperator.thanosImage.tag=v0.28.0-ubi \
  --set metadata.image.repository=public.ecr.aws/sumologic/sumologic-otel-collector@sha256 \
  --set metadata.image.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb \
  --set metrics-server.image.registry=public.ecr.aws/sumologic \
  --set metrics-server.image.repository=metrics-server@sha256 \
  --set metrics-server.image.tag=6398a46ccf68a28f647d4f05bb9a273580deb063efc501dfed0ccf1bcac44f98 \
  --set opentelemetry-operator.kubeRBACProxy.image.repository=public.ecr.aws/sumologic/kube-rbac-proxy@sha256 \
  --set opentelemetry-operator.kubeRBACProxy.image.tag=6081af347a86a9cd51232f60e9f5567bdaddf0377927a462ced91524ce80bf95 \
  --set opentelemetry-operator.manager.autoInstrumentationImage.dotnet.repository=public.ecr.aws/sumologic/autoinstrumentation-dotnet@sha256 \
  --set opentelemetry-operator.manager.autoInstrumentationImage.dotnet.tag=e99182dd7c0c8611cdc852bcc2e0866e635077b50b7e739022269cc8721f4109 \
  --set opentelemetry-operator.manager.autoInstrumentationImage.java.repository=public.ecr.aws/sumologic/autoinstrumentation-java@sha256 \
  --set opentelemetry-operator.manager.autoInstrumentationImage.java.tag=7fdb03d08173964f234f8262e872f67a42527173195b2e39cf56581c6a784f92 \
  --set opentelemetry-operator.manager.autoInstrumentationImage.nodejs.repository=public.ecr.aws/sumologic/autoinstrumentation-nodejs@sha256 \
  --set opentelemetry-operator.manager.autoInstrumentationImage.nodejs.tag=f6d2109be49cbfc725ca7f0ebbc06b74c699e55a7f18690e9959de8bcf294028 \
  --set opentelemetry-operator.manager.autoInstrumentationImage.python.repository=public.ecr.aws/sumologic/autoinstrumentation-nodejs@sha256 \
  --set opentelemetry-operator.manager.autoInstrumentationImage.python.tag=f6d2109be49cbfc725ca7f0ebbc06b74c699e55a7f18690e9959de8bcf294028 \
  --set opentelemetry-operator.manager.collectorImage.repository=public.ecr.aws/sumologic/sumologic-otel-collector@sha256 \
  --set opentelemetry-operator.manager.collectorImage.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb \
  --set opentelemetry-operator.manager.collectorImage.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb \
  --set opentelemetry-operator.manager.image.repository=public.ecr.aws/sumologic/opentelemetry-operator@sha256 \
  --set opentelemetry-operator.manager.image.tag=a714dd6995f5c3f479488c8ca281fe1a5dd92b1103c4b00b9c68f47826172267 \
  --set otelcolInstrumentation.statefulset.image.repository=public.ecr.aws/sumologic/sumologic-otel-collector@sha256 \
  --set otelcolInstrumentation.statefulset.image.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb \
  --set otelevents.image.repository=public.ecr.aws/sumologic/sumologic-otel-collector@sha256 \
  --set otelevents.image.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb \
  --set otellogs.daemonset.initContainers.changeowner.image.repository=public.ecr.aws/sumologic/busybox@sha256 \
  --set otellogs.daemonset.initContainers.changeowner.image.tag=b4546940f92abc714d70fc188c662736a3392fd168e793167533d5f72e5a91cc \
  --set otellogs.image.repository=public.ecr.aws/sumologic/sumologic-otel-collector@sha256 \
  --set otellogs.image.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb \
  --set pvcCleaner.job.image.repository=public.ecr.aws/sumologic/kubernetes-tools-kubectl@sha256 \
  --set pvcCleaner.job.image.tag=89ae5ef9c85f6a01d520c8e237e614131cdc81a09f2eade54c9b091b2993e856 \
  --set sumologic.metrics.collector.otelcol.image.repository=public.ecr.aws/sumologic/sumologic-otel-collector@sha256 \
  --set sumologic.metrics.collector.otelcol.image.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb \
  --set sumologic.metrics.remoteWriteProxy.image.repository=public.ecr.aws/sumologic/nginx-unprivileged@sha256 \
  --set sumologic.metrics.remoteWriteProxy.image.tag=9aef85eed423d0bf6bce16eb0dce3d56d18c0aa7929627ed4fe7aef7aa749c1f \
  --set sumologic.otelcolImage.repository=public.ecr.aws/sumologic/sumologic-otel-collector@sha256 \
  --set sumologic.otelcolImage.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb \
  --set sumologic.setup.job.image.repository=public.ecr.aws/sumologic/kubernetes-setup@sha256 \
  --set sumologic.setup.job.image.tag=21819dcc791144843ebed17abf7304e2cefd711995027a8737f2d9ae14418811 \
  --set sumologic.setup.job.initContainerImage.repository=public.ecr.aws/sumologic/busybox@sha256 \
  --set sumologic.setup.job.initContainerImage.tag=b4546940f92abc714d70fc188c662736a3392fd168e793167533d5f72e5a91cc \
  --set tailing-sidecar-operator.kubeRbacProxy.image.repository=public.ecr.aws/sumologic/kube-rbac-proxy@sha256 \
  --set tailing-sidecar-operator.kubeRbacProxy.image.tag=6081af347a86a9cd51232f60e9f5567bdaddf0377927a462ced91524ce80bf95 \
  --set tailing-sidecar-operator.operator.image.repository=public.ecr.aws/sumologic/tailing-sidecar-operator@sha256 \
  --set tailing-sidecar-operator.operator.image.tag=faf736cd82ceee3e97990da0346487e51ddc9fbc9a0647042f640d2012ef9f35 \
  --set tailing-sidecar-operator.sidecar.image.repository=public.ecr.aws/sumologic/tailing-sidecar@sha256 \
  --set tailing-sidecar-operator.sidecar.image.tag=48203fa961951147802711ed4769ab2d42e4adb4593a6e50c639d9cc4fb75242 \
  --set telegraf-operator.image.repository=public.ecr.aws/sumologic/telegraf-operator@sha256 \
  --set telegraf-operator.image.sidecarImage=registry.connect.redhat.com/sumologic/telegraf@sha256:ca396dad12a289aea9136da713020d31b179e9f49aae61c48332d61086d1d059 \
  --set telegraf-operator.image.tag=88c3b5d9f8e9a419131c39e6e22c5aa7cfaab5157fe4c5cc928574f5a3cfda2c \
  --set tracesGateway.deployment.image.repository=public.ecr.aws/sumologic/sumologic-otel-collector@sha256 \
  --set tracesGateway.deployment.image.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb \
  --set tracesSampler.deployment.image.repository=public.ecr.aws/sumologic/sumologic-otel-collector@sha256 \
  --set tracesSampler.deployment.image.tag=fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb
