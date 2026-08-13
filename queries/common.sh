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

# within_values_clause <file-or-dash> -- reads SPARQL Results JSON (the
# same shape run_query produces -- e.g. a prior poems-by-*.sh's own
# stdout) from FILE (or stdin if FILE is "-"), and echoes a SPARQL
# VALUES clause restricting ?waka to exactly those poems. Lets
# poems-by-*.sh scripts be chained via --within: each one's output
# becomes the next one's --within input, narrowing further at each
# step, e.g.:
#   poems-by-anthology.sh kokin | poems-by-topic.sh 春 --within -
within_values_clause() {
    local file="$1" uris
    if [ "$file" = "-" ]; then
        uris="$(jq -r '.results.bindings[].waka.value' | sed 's/.*/<&>/' | tr '\n' ' ')"
    else
        uris="$(jq -r '.results.bindings[].waka.value' "$file" | sed 's/.*/<&>/' | tr '\n' ' ')"
    fi
    echo "VALUES ?waka { $uris }"
}
