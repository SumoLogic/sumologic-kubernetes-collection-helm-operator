#!/usr/bin/env bash

# The test will protect against forgetting about checking introduced changes in kustomize templates.
# Content of bundle.yaml should be updated along with changes in templates for kustomize.

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

# shellcheck disable=SC1090
source "${ROOT_DIR}/tests/functions.sh"

make generate-bundle
DIFF="$(diff -B generated_bundle.yaml bundle.yaml)"
check_diff "${DIFF}"
