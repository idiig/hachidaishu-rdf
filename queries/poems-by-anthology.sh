#!/usr/bin/env bash
# poems-by-anthology.sh <anthology> [--within <file-or->]
# anthology => full poem-id population for it. <anthology> is one of
# kokin/gosen/shuui/goshuui, matched against the wakaid: local-name
# prefix (e.g. "kokin-1"). This is the population query recursive
# narrowing chains typically start from -- see --within on the other
# poems-by-*.sh scripts for how to chain further conditions on top of
# this (or on top of each other, in any order).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ANTHOLOGY="$1"
WITHIN=""
if [ "${2:-}" = "--within" ]; then
    WITHIN="$(within_values_clause "$3")"
fi

run_query waka-batch.ttl <<EOF
PREFIX waka: <https://example.org/waka/ontology#>

SELECT DISTINCT ?waka WHERE {
  $WITHIN
  ?waka a waka:Waka .
  FILTER(STRSTARTS(STR(?waka), "https://example.org/waka/id/$ANTHOLOGY-"))
}
ORDER BY ?waka
EOF
