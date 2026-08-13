#!/usr/bin/env bash
# poems-by-concept.sh <concept-local-name> [--within <file-or->]
# concept => poem item list. Direct occurrences only (the occurrence's
# word has a sense referencing this concept) -- per memo.org's "query
# concept for poem items" spec, no compound-decomposition handling here,
# same scope decision as poems-by-word.sh.
#
# <concept-local-name> is the concept: local name as it appears in
# concept-batch.ttl/concept-example.ttl (e.g. "BG-02-3060").
#
# --within <file-or-> optionally restricts the search to a prior result
# set (SPARQL Results JSON with a ?waka field) instead of the whole
# corpus -- see poems-by-word.sh's --within for the chaining example.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

CONCEPT="$1"
WITHIN=""
if [ "${2:-}" = "--within" ]; then
    WITHIN="$(within_values_clause "$3")"
fi

run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl <<EOF
PREFIX waka:    <https://example.org/waka/ontology#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX concept: <https://example.org/waka/concept/>

SELECT DISTINCT ?waka WHERE {
  $WITHIN
  ?occ waka:instantiates ?entry ; waka:ofWaka ?waka .
  ?entry ontolex:sense ?sense .
  ?sense ontolex:reference concept:$CONCEPT .
}
ORDER BY ?waka
EOF
