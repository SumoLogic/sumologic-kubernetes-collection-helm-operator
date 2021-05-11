#!/usr/bin/env bash

date

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

# shellcheck disable=SC1090
source "${ROOT_DIR}/tests/functions.sh"

readonly IMG="${IMG:=public.ecr.aws/sumologic/sumologic-kubernetes-collection-helm-operator:0.0.4}"
readonly NAMESPACE="sumologic-system"
readonly TIME=900

make deploy IMG="${IMG}"
wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/sumologic-controller-manager
kubectl wait --for=condition=ready --timeout 300s pod -l control-plane=controller-manager -n sumologic-system

kubectl apply -f tests/test_openshift.yaml -n sumologic-system

wait_for_resource "${NAMESPACE}" "${TIME}" daemonset.apps/test-openshift-falco
wait_for_resource "${NAMESPACE}" "${TIME}" daemonset.apps/test-openshift-fluent-bit
wait_for_resource "${NAMESPACE}" "${TIME}" daemonset.apps/test-openshift-prometheus-node-exporter 

wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/test-openshift-kube-promet-operator
wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/test-openshift-kube-state-metrics  
wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/test-openshift-metrics-server
wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/test-openshift-tailing-sidecar-operator
wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/test-openshift-telegraf-operator

wait_for_resource "${NAMESPACE}" "${TIME}" statefulset.apps/prometheus-test-openshift-kube-promet-prometheus 
wait_for_resource "${NAMESPACE}" "${TIME}" statefulset.apps/test-openshift-sumologic-fluentd-events
wait_for_resource "${NAMESPACE}" "${TIME}" statefulset.apps/test-openshift-sumologic-fluentd-logs
wait_for_resource "${NAMESPACE}" "${TIME}" statefulset.apps/test-openshift-sumologic-fluentd-metrics

helm get manifest -n "${NAMESPACE}" test-openshift > helm_operator_templates.yaml

kubectl delete -f tests/test_openshift.yaml -n sumologic-system
make undeploy
kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
