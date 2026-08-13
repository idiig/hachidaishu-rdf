#!/usr/bin/env bash
# word-frequencies.sh <anthology>
# anthology => every word used in it (lex: local name, same convention
# as all-words.sh) with its occurrence count. <anthology> is one of
# kokin/gosen/shuui/goshuui, matched against the wakaid: local-name
# prefix (e.g. "kokin-1"), same anthology labels build_occurrences.py
# uses.
#
# For the KLD pipeline's candidate-targets step (see
# module-design-prototype.el): word-frequencies is scoped to a whole
# anthology, not to any condition-restricted subset of it.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ANTHOLOGY="$1"

RAW="$(run_query waka-batch.ttl occurrence-batch.ttl <<EOF
PREFIX waka: <https://example.org/waka/ontology#>

SELECT ?entry (COUNT(?occ) AS ?n) WHERE {
  ?occ waka:instantiates ?entry ; waka:ofWaka ?waka .
  FILTER(STRSTARTS(STR(?waka), "https://example.org/waka/id/$ANTHOLOGY-"))
}
GROUP BY ?entry
ORDER BY DESC(?n) ?entry
EOF
)"

echo "$RAW" | jq '
{
  head: { vars: ["word", "count"] },
  results: { bindings: (
    .results.bindings | map({
      word: { type: "literal", value: (.entry.value | sub("^https://example\\.org/waka/lexicon/"; "")) },
      count: { type: "literal", value: .n.value, datatype: "http://www.w3.org/2001/XMLSchema#integer" }
    })
  ) }
}
'
