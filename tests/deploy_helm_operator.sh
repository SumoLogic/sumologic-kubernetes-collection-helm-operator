#!/usr/bin/env bash

date

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

# shellcheck disable=SC1090
source "${ROOT_DIR}/tests/functions.sh"

readonly DEPLOYMENT_TYPE="${DEPLOYMENT_TYPE:=default}"
readonly IMG="${IMG:=public.ecr.aws/sumologic/sumologic-kubernetes-collection-helm-operator:2.14.1-0-rc.0}"
readonly NAMESPACE="sumologic-system"
readonly TIME=900

# Change container registry in bundle.yaml to public.ecr.aws and ghcr.io to not login to registry.connect.redhat.com
# sed -i.bak "s#registry.connect.redhat.com/sumologic/kubernetes-setup#public.ecr.aws/sumologic/kubernetes-setup#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/node-exporter#public.ecr.aws/sumologic/node-exporter#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/kube-state-metrics#public.ecr.aws/sumologic/kube-state-metrics#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/prometheus-operator#public.ecr.aws/sumologic/prometheus-operator#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/prometheus-config-reloader#public.ecr.aws/sumologic/prometheus-config-reloader#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/prometheus#public.ecr.aws/sumologic/prometheus#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/thanos#public.ecr.aws/sumologic/thanos#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/metrics-server#public.ecr.aws/sumologic/metrics-server#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/metrics-server#public.ecr.aws/sumologic/metrics-server#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/kube-rbac-proxy#public.ecr.aws/sumologic/kube-rbac-proxy#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/tailing-sidecar-operator#ghcr.io/sumologic/tailing-sidecar-operator#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/tailing-sidecar#ghcr.io/sumologic/tailing-sidecar#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/telegraf-operator#public.ecr.aws/sumologic/telegraf-operator-ubi#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/telegraf#public.ecr.aws/sumologic/telegraf#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/kubernetes-fluentd#public.ecr.aws/sumologic/kubernetes-fluentd#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/fluent-bit#public.ecr.aws/sumologic/fluent-bit#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/sumo-ubi-minimal@#public.ecr.aws/sumologic/sumo-ubi-minimal#g" bundle.yaml
# sed -i.bak "s#registry.connect.redhat.com/sumologic/opentelemetry-collector@#public.ecr.aws/sumologic/opentelemetry-collector#g" bundle.yaml

# Change image in bundle.yaml to imag
sed -i.bak "s#public.ecr.aws/sumologic/sumologic-kubernetes-collection-helm-operator:2.14.1-0-rc.0#${IMG}#g" bundle.yaml

kubectl apply -f bundle.yaml

wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/sumologic-helm-operator
kubectl wait --for=condition=ready --timeout 300s pod -l control-plane=sumologic-kubernetes-collection-helm-operator -n sumologic-system

kubectl apply -f tests/test_openshift.yaml -n sumologic-system

wait_for_collection_resources "${NAMESPACE}" "${TIME}"

helm get manifest -n "${NAMESPACE}" test-openshift > helm_operator_templates.yaml

kubectl delete -f tests/test_openshift.yaml -n sumologic-system
make undeploy

kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
