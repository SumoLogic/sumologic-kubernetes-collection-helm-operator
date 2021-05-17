#!/usr/bin/env bash

date

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

# shellcheck disable=SC1090
source "${ROOT_DIR}/tests/functions.sh"

readonly DEPLOYMENT_TYPE="${DEPLOYMENT_TYPE:=default}"
readonly IMG="${IMG:=ghcr.io/kkujawa-sumo/sumologic-kubernetes-collection-helm-operator:gffd1a78700}"
readonly NAMESPACE="sumologic-system"
readonly TIME=900

if [[ ${DEPLOYMENT_TYPE} == "default" ]]; then
    make deploy IMG="${IMG}"
else
    make deploy-using-public-images IMG="${IMG}"
fi

wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/sumologic-helm-operator
kubectl wait --for=condition=ready --timeout 300s pod -l control-plane=sumologic-kubernetes-collection-helm-operator -n sumologic-system

kubectl apply -f tests/test_openshift.yaml -n sumologic-system

wait_for_collection_resources "${NAMESPACE}" "${TIME}"

helm get manifest -n "${NAMESPACE}" test-openshift > helm_operator_templates.yaml

kubectl delete -f tests/test_openshift.yaml -n sumologic-system
make undeploy

kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
