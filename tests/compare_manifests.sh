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

# busybox image has not tag set in collection
sed -i.bak 's/busybox:1.33.0/busybox/g' helm_operator_templates.yaml

DIFF="$(diff <(yq e -P helm_operator_templates.yaml) <(yq e -P helm_chart_templates.yaml) )"
check_diff "${DIFF}"
