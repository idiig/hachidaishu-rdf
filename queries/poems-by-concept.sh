#!/usr/bin/env bash
# poems-by-concept.sh <concept-local-name>
# concept => poem item list. Direct occurrences only (the occurrence's
# word has a sense referencing this concept) -- per memo.org's "query
# concept for poem items" spec, no compound-decomposition handling here,
# same scope decision as poems-by-word.sh.
#
# <concept-local-name> is the concept: local name as it appears in
# concept-batch.ttl/concept-example.ttl (e.g. "BG-02-3060").
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

CONCEPT="$1"

run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl <<EOF
PREFIX waka:    <https://example.org/waka/ontology#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX concept: <https://example.org/waka/concept/>

SELECT DISTINCT ?waka WHERE {
  ?occ waka:instantiates ?entry ; waka:ofWaka ?waka .
  ?entry ontolex:sense ?sense .
  ?sense ontolex:reference concept:$CONCEPT .
}
ORDER BY ?waka
EOF
