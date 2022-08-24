#!/usr/bin/env bash

function wait_for_resource() {
  local namespace="${1}"
  local time="${2}"
  local resource="${3}"

  for i in $(seq 0 "${time}")
  do
    if ! kubectl get -n "${namespace}" "${resource}" ; then
      echo "Waiting for ${resource} in ${i} iteration"
      kubectl get pods -n "${namespace}"
      sleep 1
    else
      echo "Found ${resource}"
      break
    fi
  done
}

function wait_for_collection_resources() {
  local namespace="${1}"
  local time="${2}"

  wait_for_resource "${namespace}" "${time}" daemonset.apps/test-openshift-falco
  wait_for_resource "${namespace}" "${time}" daemonset.apps/test-openshift-fluent-bit
  wait_for_resource "${namespace}" "${time}" daemonset.apps/test-openshift-prometheus-node-exporter 

  wait_for_resource "${namespace}" "${time}" deployment.apps/test-openshift-kube-promet-operator
  wait_for_resource "${namespace}" "${time}" deployment.apps/test-openshift-kube-state-metrics  
  wait_for_resource "${namespace}" "${time}" deployment.apps/test-openshift-metrics-server
  wait_for_resource "${namespace}" "${time}" deployment.apps/test-openshift-tailing-sidecar-operator
  wait_for_resource "${namespace}" "${time}" deployment.apps/test-openshift-telegraf-operator

  wait_for_resource "${namespace}" "${time}" statefulset.apps/prometheus-test-openshift-kube-promet-prometheus 
  wait_for_resource "${namespace}" "${time}" statefulset.apps/test-openshift-sumologic-fluentd-events
  wait_for_resource "${namespace}" "${time}" statefulset.apps/test-openshift-sumologic-fluentd-logs
  wait_for_resource "${namespace}" "${time}" statefulset.apps/test-openshift-sumologic-fluentd-metrics
}

function wait_for_ns_termination() {
  local namespace="${1}"
  local time="${2}"

  for i in $(seq 0 "${time}")
  do
    if kubectl get ns "${namespace}" ; then
      echo "Waiting for \"${namespace}\" termination in ${i} iteration"
      sleep 1
    else
      echo "${namespace} terminated"
      break
    fi
  done
}

function check_diff(){
    diff="${1}"
    if [[ ${diff} == "" ]]; then
        echo "Test passed"
    else
        echo "${diff}"
        echo "Test failed"
        exit 1
    fi
}

function check_yq_version() {
  readonly yq_version="$(yq --version | grep -oE '[^[:space:]]+$')"
  readonly yq_major_version="${yq_version:0:1}"
  readonly yq_min_version=4
  if [[ "${yq_major_version}" < "${yq_min_version}" ]]; then
    echo "Please install yq in version ${yq_min_version}.0 or higher"
    exit 1
  fi
}
