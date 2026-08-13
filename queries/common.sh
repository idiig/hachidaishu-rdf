#!/usr/bin/env bash
# Shared config for queries/*.sh. Requires `arq` (Apache Jena) and `jq`
# on PATH -- see README.md.
set -euo pipefail

QUERIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$(cd "$QUERIES_DIR/../data" && pwd)"
ARQ="${ARQ:-arq}"

# run_query <data-file> [<data-file> ...] -- SPARQL read from stdin,
# SPARQL Results JSON written to stdout.
run_query() {
    local data_args=()
    for f in "$@"; do
        data_args+=(--data "$DATA_DIR/$f")
    done
    "$ARQ" "${data_args[@]}" --results json --query /dev/stdin
}
