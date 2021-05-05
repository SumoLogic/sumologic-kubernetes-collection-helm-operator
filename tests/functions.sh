#!/usr/bin/env bash

function wait_for_resource() {
  local namespace="${1}"
  local time="${2}"
  local resource="${3}"

  for i in $(seq 0 "${time}")
  do
    if ! kubectl get -n "${namespace}" "${resource}" ; then
      echo "Waiting for ${resource} in ${i} iteration"
      sleep 1
    else
      echo "Found ${resource}"
      break
    fi
  done
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
