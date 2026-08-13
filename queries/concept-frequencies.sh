#!/usr/bin/env bash
# concept-frequencies.sh <anthology>
# anthology => every concept referenced (via some word's sense) by an
# occurrence in it, with its occurrence count. Same "broader-leaf" label
# convention as all-concepts.sh. Sister script to word-frequencies.sh,
# for the KLD pipeline's candidate-targets step when the target unit is
# "concept" rather than "word" -- also scoped to a whole anthology, not
# any condition-restricted subset of it.
#
# <anthology> is one of kokin/gosen/shuui/goshuui, matched against the
# wakaid: local-name prefix (e.g. "kokin-1").
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ANTHOLOGY="$1"

RAW="$(run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl concept-batch.ttl concept-example.ttl <<EOF
PREFIX waka:    <https://example.org/waka/ontology#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>

SELECT ?conceptUri ?leafLabel ?broaderLabel (COUNT(?occ) AS ?n) WHERE {
  ?occ waka:instantiates ?entry ; waka:ofWaka ?waka .
  ?entry ontolex:sense ?sense .
  ?sense ontolex:reference ?conceptUri .
  ?conceptUri skos:prefLabel ?leafLabel .
  OPTIONAL { ?conceptUri skos:broader ?broaderUri . ?broaderUri skos:prefLabel ?broaderLabel . }
  FILTER(STRSTARTS(STR(?waka), "https://example.org/waka/id/$ANTHOLOGY-"))
}
GROUP BY ?conceptUri ?leafLabel ?broaderLabel
ORDER BY DESC(?n) ?conceptUri
EOF
)"

echo "$RAW" | jq '
{
  head: { vars: ["concept", "label", "count"] },
  results: { bindings: (
    .results.bindings | map({
      concept: { type: "literal", value: (.conceptUri.value | sub("^https://example\\.org/waka/concept/"; "")) },
      label: { type: "literal", value: (if .broaderLabel then (.broaderLabel.value + "-" + .leafLabel.value) else .leafLabel.value end) },
      count: { type: "literal", value: .n.value, datatype: "http://www.w3.org/2001/XMLSchema#integer" }
    })
  ) }
}
'
