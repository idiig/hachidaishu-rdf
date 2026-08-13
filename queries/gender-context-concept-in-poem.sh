#!/usr/bin/env bash
# gender-context-concept-in-poem.sh <Male|Female> <poem-id>
# (gender, poem) => occurrence item CONCEPT list, same resolution as
# gender-context-in-poem.sh (see that script's header) but each entry
# mapped through ontolex:sense -> ontolex:reference to its concept(s).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

GENDER="$1"
POEM="$2"

run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl author-batch.ttl author-example.ttl concept-batch.ttl concept-example.ttl <<EOF
PREFIX waka:    <https://example.org/waka/ontology#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX schema:  <https://schema.org/>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX wakaid:  <https://example.org/waka/id/>

SELECT DISTINCT ?pos ?concept WHERE {
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
  ?entry ontolex:sense ?sense .
  ?sense ontolex:reference ?conceptUri .
  ?conceptUri skos:prefLabel ?leafLabel .
  OPTIONAL { ?conceptUri skos:broader ?broaderUri . ?broaderUri skos:prefLabel ?broaderLabel . }
  BIND(IF(BOUND(?broaderLabel), CONCAT(?broaderLabel, "-", ?leafLabel), ?leafLabel) AS ?concept)
}
ORDER BY ?pos ?concept
EOF
