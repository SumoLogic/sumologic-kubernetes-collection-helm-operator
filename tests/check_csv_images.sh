#!/usr/bin/env bash
# Validates that digest-pinned images added or changed in the CSV are published
# in the Red Hat Ecosystem Catalog (public API, no credentials required).

set -euo pipefail

CSV_FILE="${1:-bundle/manifests/operator.clusterserviceversion.yaml}"
CATALOG_API="https://catalog.redhat.com/api/containers/v1/images"

if [[ ! -f "${CSV_FILE}" ]]; then
    echo "ERROR: CSV file not found: ${CSV_FILE}"
    exit 1
fi

# Priority: BASE_REF env > GITHUB_BASE_REF (CI) > tracking branch > HEAD~1
if [[ -n "${BASE_REF:-}" ]]; then
    : # use as-is
elif [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    BASE_REF="origin/${GITHUB_BASE_REF}"
else
    BASE_REF=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "HEAD~1")
fi

echo "=== Detection ==="
echo "CSV file : ${CSV_FILE}"
echo "Base ref : ${BASE_REF}"
echo ""


# grep exits 1 on no match; || true prevents set -e from aborting.
mapfile -t IMAGES < <(git diff "${BASE_REF}" -- "${CSV_FILE}" \
    | grep '^+[^+]' \
    | grep -oE 'registry\.[a-zA-Z0-9._-]+\.[a-zA-Z]+/[a-zA-Z0-9._/-]+@sha256:[A-Fa-f0-9]{64}' \
    | sort -u || true)

if [[ ${#IMAGES[@]} -eq 0 ]]; then
    echo "Result  : No digest-pinned image changes detected — check skipped."
    exit 0
fi

DETECTED=0
for IMAGE in "${IMAGES[@]}"; do
    DETECTED=$((DETECTED + 1))
    echo "  [+] ${IMAGE}"
done
echo "Result  : ${DETECTED} changed image(s) detected — proceeding to check."

echo "=== Check ==="

FAILED=0
CHECKED=0

for IMAGE in "${IMAGES[@]}"; do
    CHECKED=$((CHECKED + 1))
    DIGEST="sha256:${IMAGE##*@sha256:}"
    printf "Checking %-85s ... " "${IMAGE}"

    TOTAL=$(curl --retry 3 --retry-delay 3 --connect-timeout 10 --max-time 30 -sf "${CATALOG_API}?filter=image_id==${DIGEST}&page_size=1" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('total', 0))" || echo "curl_error")

    if [[ "${TOTAL}" == "curl_error" ]]; then
        echo "API ERROR"
        FAILED=$((FAILED + 1))
    elif [[ "${TOTAL}" -gt 0 ]]; then
        echo "OK"
    else
        echo "NOT FOUND IN CATALOG"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "Result  : Checked ${CHECKED} image(s), ${FAILED} not found in catalog."

if [[ "${FAILED}" -ne 0 ]]; then
    echo ""
    echo "ERROR: ${FAILED} image(s) are not published in the Red Hat Ecosystem Catalog."
    echo "Ensure all images are certified and published before merging."
    exit 1
fi
