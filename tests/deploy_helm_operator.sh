#!/usr/bin/env bash

date

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

# shellcheck disable=SC1090
source "${ROOT_DIR}/tests/functions.sh"

readonly DEPLOYMENT_TYPE="${DEPLOYMENT_TYPE:=default}"
readonly IMG="${IMG:=registry.connect.redhat.com/sumologic/sumologic-kubernetes-collection-helm-operator:4.9.0-0}"
readonly NAMESPACE="sumologic-system"
readonly TIME=300

# Change container registry in bundle.yaml to public.ecr.aws and ghcr.io to not login to registry.connect.redhat.com
./tests/replace_components_images.sh

# Change image in bundle.yaml to image
sed -i.bak "s#registry.connect.redhat.com/sumologic/sumologic-kubernetes-collection-helm-operator:4.9.0-0#${IMG}#g" bundle.yaml

kubectl apply -f bundle.yaml

wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/sumologic-helm-operator
kubectl wait --for=condition=ready --timeout 300s pod -l control-plane=sumologic-kubernetes-collection-helm-operator -n sumologic-system

kubectl apply -f tests/test_openshift.yaml -n sumologic-system

kubectl get SumologicCollection --all-namespaces

wait_for_collection_resources "${NAMESPACE}" "${TIME}"

kubectl describe pods -n sumologic-system
helm get manifest -n "${NAMESPACE}" test-openshift > helm_operator_templates.yaml

kubectl delete -f tests/test_openshift.yaml -n sumologic-system
make undeploy

kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
