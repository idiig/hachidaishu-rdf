#!/usr/bin/env bash
# all-concepts.sh
# No input -- lists every distinct concept actually referenced by some
# word's sense (NOT every concept concept-batch.ttl defines -- only ones
# in use by at least one lex entry, whether or not that entry has a real
# occurrence). Two output fields: ?concept (bare local name, e.g.
# "BG-02-3060", directly reusable as the <concept-local-name> argument to
# poems-by-concept.sh/concept-context-in-poem.sh/etc.) and ?label (the
# "broader-leaf" display string, same convention as
# word-context-concept-in-poem.sh's output, 2026-08-13).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

RAW="$(run_query lex-batch.ttl concept-batch.ttl concept-example.ttl <<EOF
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>

SELECT DISTINCT ?conceptUri ?leafLabel ?broaderLabel WHERE {
  ?entry ontolex:sense ?sense .
  ?sense ontolex:reference ?conceptUri .
  ?conceptUri skos:prefLabel ?leafLabel .
  OPTIONAL { ?conceptUri skos:broader ?broaderUri . ?broaderUri skos:prefLabel ?broaderLabel . }
}
EOF
)"

echo "$RAW" | jq '
{
  head: { vars: ["concept", "label"] },
  results: { bindings: (
    .results.bindings | map({
      concept: { type: "literal", value: (.conceptUri.value | sub("^https://example\\.org/waka/concept/"; "")) },
      label: { type: "literal", value: (if .broaderLabel then (.broaderLabel.value + "-" + .leafLabel.value) else .leafLabel.value end) }
    })
  ) }
}
'
