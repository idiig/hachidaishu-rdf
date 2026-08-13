#!/usr/bin/env bash
# gender-context-in-poem.sh <Male|Female> <poem-id>
# (gender, poem) => occurrence item list in that poem attributed to that
# gender. Two regimes: (1) joint M/F compositions have their own
# per-occurrence dcterms:creator (see occurrence-batch.ttl's build --
# only the ~4 shuui-1181..1184-style poems) -- match those directly; (2)
# an ordinary poem has NO per-occurrence dcterms:creator at all (by
# design, see waka-ontology.ttl), so if the poem itself has no such
# per-occurrence creators, fall back to the whole poem's own
# dcterms:creator/waka:poeticVoice gender -- if it matches, every
# occurrence in the poem counts.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

GENDER="$1"
POEM="$2"

run_query waka-batch.ttl occurrence-batch.ttl author-batch.ttl author-example.ttl <<EOF
PREFIX waka:    <https://example.org/waka/ontology#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX schema:  <https://schema.org/>
PREFIX wakaid:  <https://example.org/waka/id/>

SELECT ?pos ?entry WHERE {
  BIND(wakaid:$POEM AS ?waka)
  ?waka waka:hasOccurrence ?occ .
  ?occ waka:position ?pos ; waka:instantiates ?entry .
  {
    ?occ dcterms:creator ?p .
    ?p schema:gender schema:$GENDER .
  } UNION {
    FILTER NOT EXISTS { ?waka waka:hasOccurrence/dcterms:creator ?anyP }
    {
      ?waka dcterms:creator ?p2 .
    } UNION {
      ?waka waka:poeticVoice ?p2 .
    }
    ?p2 schema:gender schema:$GENDER .
  }
}
ORDER BY ?pos
EOF
