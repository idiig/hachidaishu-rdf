#!/usr/bin/env bash
# word-context-concept-in-poem.sh <word-local-name> <poem-id>
# (word, poem) => occurrence item CONCEPT list within that poem. Same
# occurrence/compound-sibling resolution as word-context-in-poem.sh (see
# that script's header for why this is three separate self-contained
# queries merged by jq, not one query with nested UNION arms -- a real
# bug found via TDD, 2026-08-13), but each resulting word is additionally
# joined through ontolex:sense -> ontolex:reference to its concept(s).
#
# A word can have more than one sense (and so more than one concept) --
# occurrence deliberately doesn't disambiguate which sense a given
# position means (see design-notes.md's "occurrence 不携带 pos/wlsp"),
# so this can legitimately return more than one ?concept for the same
# ?pos. DISTINCT collapses a single entry's multiple senses that happen
# to share the exact same concept (common for kanji-spelling variants of
# one word, e.g. 立田河/立田川/竜田川/竜田河/龍田川 all -> concept:CH-29-5250)
# down to one row.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

WORD="$1"
POEM="$2"

GROUPS_JSON="$(run_query lex-batch.ttl <<EOF
PREFIX waka: <https://example.org/waka/ontology#>
PREFIX lex:  <https://example.org/waka/lexicon/>
PREFIX decomp: <http://www.w3.org/ns/lemon/decomp#>

SELECT ?compound ?group WHERE {
  ?compound waka:parallelDecomp ?group .
  ?group decomp:constituent ?matchComp .
  ?matchComp decomp:correspondsTo lex:$WORD .
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
PREFIX lex:     <https://example.org/waka/lexicon/>
PREFIX decomp:  <http://www.w3.org/ns/lemon/decomp#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX wakaid:  <https://example.org/waka/id/>

SELECT DISTINCT ?pos ?concept WHERE {
  BIND(wakaid:$POEM AS ?waka)
  {
    ?matchOcc waka:instantiates lex:$WORD ; waka:ofWaka ?waka .
  } UNION {
    ?matchedEntry decomp:subterm lex:$WORD .
    ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka .
  } UNION {
    VALUES ?winGroup { $GROUP_VALUES_LIST }
    ?matchedEntry waka:parallelDecomp ?winGroup .
    ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka .
  }
  ?waka waka:hasOccurrence ?otherOcc .
  ?otherOcc waka:position ?pos ; waka:instantiates ?otherEntry .
  FILTER(?otherEntry != lex:$WORD)
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
PREFIX lex:     <https://example.org/waka/lexicon/>
PREFIX decomp:  <http://www.w3.org/ns/lemon/decomp#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX wakaid:  <https://example.org/waka/id/>

SELECT DISTINCT ?pos ?concept WHERE {
  BIND(wakaid:$POEM AS ?waka)
  ?matchedEntry decomp:subterm lex:$WORD .
  ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka ; waka:position ?pos .
  ?matchedEntry decomp:subterm ?otherEntry .
  FILTER(?otherEntry != lex:$WORD)
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
PREFIX lex:     <https://example.org/waka/lexicon/>
PREFIX decomp:  <http://www.w3.org/ns/lemon/decomp#>
PREFIX ontolex: <http://www.w3.org/ns/lemon/ontolex#>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX wakaid:  <https://example.org/waka/id/>

SELECT DISTINCT ?pos ?concept WHERE {
  BIND(wakaid:$POEM AS ?waka)
  VALUES ?winGroup { $GROUP_VALUES_LIST }
  ?matchedEntry waka:parallelDecomp ?winGroup .
  ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka ; waka:position ?pos .
  ?winGroup decomp:constituent ?sibComp .
  ?sibComp decomp:correspondsTo ?otherEntry .
  FILTER(?otherEntry != lex:$WORD)
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
