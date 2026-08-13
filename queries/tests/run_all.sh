#!/usr/bin/env bash
# Run every test_*.sh in this directory, report a summary.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

PASS=0
FAIL=0
for t in test_*.sh; do
    echo "=== $t ==="
    if bash "$t"; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
    echo
done

echo "==================="
echo "passed: $PASS, failed: $FAIL"
[ "$FAIL" -eq 0 ]
