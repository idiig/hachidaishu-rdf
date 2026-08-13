#!/usr/bin/env bash
# concept-context-concept-in-poem.sh <concept-local-name> <poem-id>
# (concept, poem) => occurrence item CONCEPT list within that poem. Same
# resolution as concept-context-in-poem.sh (see that script's header),
# each resulting word additionally mapped through
# ontolex:sense -> ontolex:reference to its own concept(s). DISTINCT
# collapses multiple senses of one word sharing the same concept.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

CONCEPT="$1"
POEM="$2"

GROUPS_JSON="$(run_query lex-batch.ttl <<EOF
PREFIX waka:    <https://example.org/waka/ontology#>
PREFIX decomp:  <http://www.w3.org/ns/lemon/decomp#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX concept: <https://example.org/waka/concept/>

SELECT ?compound ?group WHERE {
  ?compound waka:parallelDecomp ?group .
  ?group decomp:constituent ?matchComp .
  ?matchComp decomp:correspondsTo ?matchWord .
  ?matchWord ontolex:sense ?s .
  ?s ontolex:reference concept:$CONCEPT .
  {
    SELECT ?group (COUNT(?c) AS ?n) WHERE {
      ?group decomp:constituent ?c .
    }
    GROUP BY ?group
  }
}
ORDER BY ?compound ?n ?group
EOF
)"

WINNING_GROUPS="$(echo "$GROUPS_JSON" | jq -r '
  [.results.bindings[] | {compound: .compound.value, group: .group.value}]
  | group_by(.compound) | map(.[0].group) | .[]
')"

GROUP_VALUES_LIST="$(echo "$WINNING_GROUPS" | sed '/^$/d' | sed 's|^|<|; s|$|>|' | tr '\n' ' ')"

WORD_ROWS="$(run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl concept-batch.ttl concept-example.ttl <<EOF
PREFIX waka:    <https://example.org/waka/ontology#>
PREFIX decomp:  <http://www.w3.org/ns/lemon/decomp#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX concept: <https://example.org/waka/concept/>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX wakaid:  <https://example.org/waka/id/>

SELECT DISTINCT ?pos ?concept WHERE {
  BIND(wakaid:$POEM AS ?waka)
  {
    ?matchedEntry ontolex:sense ?s0 .
    ?s0 ontolex:reference concept:$CONCEPT .
    ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka .
  } UNION {
    ?matchedEntry decomp:subterm ?subterm .
    ?subterm ontolex:sense ?s1 .
    ?s1 ontolex:reference concept:$CONCEPT .
    ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka .
  } UNION {
    VALUES ?winGroup { $GROUP_VALUES_LIST }
    ?matchedEntry waka:parallelDecomp ?winGroup .
    ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka .
  }
  ?waka waka:hasOccurrence ?otherOcc .
  ?otherOcc waka:position ?pos ; waka:instantiates ?otherEntry .
  FILTER NOT EXISTS { ?otherEntry ontolex:sense ?sx . ?sx ontolex:reference concept:$CONCEPT . }
  ?otherEntry ontolex:sense ?sense .
  ?sense ontolex:reference ?conceptUri .
  ?conceptUri skos:prefLabel ?leafLabel .
  OPTIONAL { ?conceptUri skos:broader ?broaderUri . ?broaderUri skos:prefLabel ?broaderLabel . }
  BIND(IF(BOUND(?broaderLabel), CONCAT(?broaderLabel, "-", ?leafLabel), ?leafLabel) AS ?concept)
}
EOF
)"

SUBTERM_SIBLING_ROWS="$(run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl concept-batch.ttl concept-example.ttl <<EOF
PREFIX waka:    <https://example.org/waka/ontology#>
PREFIX decomp:  <http://www.w3.org/ns/lemon/decomp#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX concept: <https://example.org/waka/concept/>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX wakaid:  <https://example.org/waka/id/>

SELECT DISTINCT ?pos ?concept WHERE {
  BIND(wakaid:$POEM AS ?waka)
  ?matchedEntry decomp:subterm ?subterm .
  ?subterm ontolex:sense ?s1 .
  ?s1 ontolex:reference concept:$CONCEPT .
  ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka ; waka:position ?pos .
  ?matchedEntry decomp:subterm ?otherEntry .
  FILTER NOT EXISTS { ?otherEntry ontolex:sense ?sy . ?sy ontolex:reference concept:$CONCEPT . }
  ?otherEntry ontolex:sense ?sense .
  ?sense ontolex:reference ?conceptUri .
  ?conceptUri skos:prefLabel ?leafLabel .
  OPTIONAL { ?conceptUri skos:broader ?broaderUri . ?broaderUri skos:prefLabel ?broaderLabel . }
  BIND(IF(BOUND(?broaderLabel), CONCAT(?broaderLabel, "-", ?leafLabel), ?leafLabel) AS ?concept)
}
EOF
)"

PARALLEL_SIBLING_ROWS="$(run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl concept-batch.ttl concept-example.ttl <<EOF
PREFIX waka:    <https://example.org/waka/ontology#>
PREFIX decomp:  <http://www.w3.org/ns/lemon/decomp#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX concept: <https://example.org/waka/concept/>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX wakaid:  <https://example.org/waka/id/>

SELECT DISTINCT ?pos ?concept WHERE {
  BIND(wakaid:$POEM AS ?waka)
  VALUES ?winGroup { $GROUP_VALUES_LIST }
  ?matchedEntry waka:parallelDecomp ?winGroup .
  ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka ; waka:position ?pos .
  ?winGroup decomp:constituent ?sibComp .
  ?sibComp decomp:correspondsTo ?otherEntry .
  FILTER NOT EXISTS { ?otherEntry ontolex:sense ?sz . ?sz ontolex:reference concept:$CONCEPT . }
  ?otherEntry ontolex:sense ?sense .
  ?sense ontolex:reference ?conceptUri .
  ?conceptUri skos:prefLabel ?leafLabel .
  OPTIONAL { ?conceptUri skos:broader ?broaderUri . ?broaderUri skos:prefLabel ?broaderLabel . }
  BIND(IF(BOUND(?broaderLabel), CONCAT(?broaderLabel, "-", ?leafLabel), ?leafLabel) AS ?concept)
}
EOF
)"

jq -n --argjson word "$WORD_ROWS" --argjson sub "$SUBTERM_SIBLING_ROWS" --argjson par "$PARALLEL_SIBLING_ROWS" '
{
  head: { vars: ["pos", "concept", "kind"] },
  results: { bindings: (
    ($word.results.bindings | map(. + {kind: {type: "literal", value: "word"}})) +
    ($sub.results.bindings | map(. + {kind: {type: "literal", value: "compound-sibling"}})) +
    ($par.results.bindings | map(. + {kind: {type: "literal", value: "compound-sibling"}}))
  ) }
}
'
