#!/usr/bin/env bash

date

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

# shellcheck disable=SC1090
source "${ROOT_DIR}/tests/functions.sh"

check_yq_version

# Remove lines which should be different from templates
sed -i.bak '/checksum\/config:/d' helm_operator_templates.yaml
sed -i.bak '/checksum\/config:/d' helm_chart_templates.yaml
sed -i.bak '/caBundle:/d' helm_operator_templates.yaml
sed -i.bak '/caBundle:/d' helm_chart_templates.yaml

# Remove line with tag in Prometheus Spec
sed -i.bak '/tag: v2.22.1/d' helm_operator_templates.yaml
# Remove tag from image in Prometheus Spec
sed -i.bak 's#quay.io/prometheus/prometheus:v2.22.1#quay.io/prometheus/prometheus#g' helm_chart_templates.yaml

# Change image for telegraf operator to version with tag
sed -i.bak 's#quay.io/influxdb/telegraf-operator@sha256:20af9e3715f24002a23d3759b451ede47061fb27761e244f69bbe742f7a502d0#quay.io/influxdb/telegraf-operator@sha256:20af9e3715f24002a23d3759b451ede47061fb27761e244f69bbe742f7a502d0:v1.3.5#g' helm_operator_templates.yaml

# busybox image has not tag set in collection
sed -i.bak 's/busybox:1.33.0/busybox/g' helm_operator_templates.yaml

DIFF="$(diff <(yq e -P helm_operator_templates.yaml) <(yq e -P helm_chart_templates.yaml) )"
check_diff "${DIFF}"
