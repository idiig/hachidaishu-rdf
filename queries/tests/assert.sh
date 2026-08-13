#!/usr/bin/env bash
# Minimal assertion helpers for scripts/queries/tests/test_*.sh. Each
# test_*.sh sources this, runs the query script under test, and calls
# these against the resulting SPARQL Results JSON (via jq).
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUERIES_DIR="$(cd "$TESTS_DIR/.." && pwd)"

FAILED=0

# assert_json_contains <json> <jq-filter-producing-bool>
assert_true() {
    local desc="$1" json="$2" filter="$3"
    if [ "$(echo "$json" | jq -r "$filter")" = "true" ]; then
        echo "  ok   - $desc"
    else
        echo "  FAIL - $desc"
        echo "         filter: $filter"
        FAILED=1
    fi
}

assert_count() {
    local desc="$1" json="$2" filter="$3" expected="$4"
    local actual
    actual="$(echo "$json" | jq "$filter")"
    if [ "$actual" = "$expected" ]; then
        echo "  ok   - $desc (count=$actual)"
    else
        echo "  FAIL - $desc (expected $expected, got $actual)"
        echo "         filter: $filter"
        FAILED=1
    fi
}

finish() {
    if [ "$FAILED" = "1" ]; then
        echo "FAILED"
        exit 1
    else
        echo "PASSED"
    fi
}
