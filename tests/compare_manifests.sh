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
sed -i.bak 's#public.ecr.aws/sumologic/prometheus:v2.22.1#public.ecr.aws/sumologic/prometheus#g' helm_chart_templates.yaml

# Change image for telegraf operator to version with tag
sed -i.bak 's#public.ecr.aws/sumologic/telegraf-operator@sha256:ff958222be01c0c3966474463e43bbd5bcf348790dd34bb761718cb1cea2d793#public.ecr.aws/sumologic/telegraf-operator-ubi:v1.3.11#g' helm_operator_templates.yaml

# busybox image has not tag set in collection
sed -i.bak 's/busybox:1.33.0/busybox/g' helm_operator_templates.yaml

# Remove lines with certificates genareted for opentelemetry operator
sed -i.bak '/tls.crt:/d' helm_operator_templates.yaml
sed -i.bak '/tls.crt:/d' helm_chart_templates.yaml
sed -i.bak '/tls.key:/d' helm_operator_templates.yaml
sed -i.bak '/tls.key:/d' helm_chart_templates.yaml


wc -l helm_operator_templates.yaml
wc -l helm_chart_templates.yaml

DIFF="$(diff <(yq -P 'sort_keys(..)' -o=props helm_operator_templates.yaml) <(yq -P 'sort_keys(..)' -o=props helm_chart_templates.yaml))"
check_diff "${DIFF}"
