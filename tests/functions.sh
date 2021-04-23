#!/usr/bin/env bash

function wait_for_resource() {
  local namespace="$1"
  local time="$2"
  local resource="$3"
  
  local substring="AGE"

  for i in $(seq 0 $time)
  do
    get="$(kubectl get -n $namespace $resource)"
    if [[ ! $get =~ $substring ]]; then
      echo "Waiting for $resource in $i iteration"
      sleep 1
    else
      echo "Found $resource"
      break
    fi
  done
}

function wait_for_ns_termination() {
  local namespace="$1"
  local time="$2"
  
  local substring="AGE"

  for i in $(seq 0 $time)
  do
    get="$(kubectl get ns $namespace)"
    if [[ $get =~ $substring ]]; then
      echo "Waiting for $namespace termination in $i iteration"
      sleep 1
    else
      echo "$namespace terminated"
      break
    fi
  done
}

function check_diff(){
    diff="$1"
    if [[ $diff == "" ]]; then
        echo "Test passed"
    else
        echo $diff
        echo "Test failed"
        exit 1
    fi
}
