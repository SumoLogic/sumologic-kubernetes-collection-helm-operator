#!/usr/bin/env bash

set -e

echo "Checking the bash scripts with shellcheck..."
find . -path "*/tests/*" ! -path "*/helm-charts/*" -name '*.sh' -type 'f' -print |
    while read -r file; do
        # Run tests in their own context
        echo "Checking ${file} with shellcheck"
        shellcheck --enable all "${file}"
    done