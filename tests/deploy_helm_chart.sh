#!/usr/bin/env bash

date

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

# shellcheck disable=SC1090
source "${ROOT_DIR}/tests/functions.sh"

readonly NAMESPACE="sumologic-system"
readonly TIME=300

helm repo add sumologic https://sumologic.github.io/sumologic-kubernetes-collection
helm repo update

./tests/helm_install.sh

wait_for_collection_resources "${NAMESPACE}" "${TIME}"

helm get manifest -n "${NAMESPACE}"  test-openshift > helm_chart_templates.yaml

helm delete test-openshift -n"${NAMESPACE}"
kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
