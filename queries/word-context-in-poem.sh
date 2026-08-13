#!/usr/bin/env bash
# word-context-in-poem.sh <word-local-name> <poem-id>
# (word, poem) => occurrence item list within that poem. Two kinds of
# result row (?kind): "word" = an ordinary independently-occurring word
# at its own position; "compound-sibling" = another component of the
# SAME compound occurrence that brought the query word into this poem
# (only when the query word itself has no independent occurrence here,
# only appears embedded in a compound) -- these share the compound's own
# ?pos, since they have no independent position of their own.
#
# waka:parallelDecomp tie-break (fewest decomp:constituent, then first
# group by sort order, per memo.org): SPARQL has no clean "top-1 per
# group" operator, so it's resolved in bash/jq from a query that returns
# ALL candidate groups pre-sorted; jq just takes the first row per
# compound. See design-notes.md's "SPARQL 查询脚本" section.
#
# Three SEPARATE self-contained queries, merged by jq, NOT one query with
# nested UNION arms sharing bindings from an outer scope -- found via TDD
# (2026-08-13) that this Jena/arq version silently drops bindings
# (BIND(?outerVar AS ?x) -> unbound ?x, and FILTER(?outerVar = "...") ->
# excludes everything) when a nested `{ }` group references a variable
# bound only in a PRECEDING sibling part of the same WHERE clause, under
# some join orderings. Each query below is fully flat (no such nesting),
# which sidesteps the bug entirely and also makes each query's match
# provenance unambiguous by construction (a compound-sibling query only
# runs the pattern for its own match type, so it can never leak siblings
# from an unrelated match, e.g. a word that directly occurs here AND
# separately has its own decomp:subterm data aggregated at the lexicon
# level from a different, unrelated occurrence elsewhere in the corpus --
# see design-notes.md's "occurrence 不携带 pos/wlsp").
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

WORD_ROWS="$(run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl <<EOF
PREFIX waka:   <https://example.org/waka/ontology#>
PREFIX lex:    <https://example.org/waka/lexicon/>
PREFIX decomp: <http://www.w3.org/ns/lemon/decomp#>
PREFIX wakaid: <https://example.org/waka/id/>

SELECT ?pos ?otherEntry WHERE {
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
}
EOF
)"

SUBTERM_SIBLING_ROWS="$(run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl <<EOF
PREFIX waka:   <https://example.org/waka/ontology#>
PREFIX lex:    <https://example.org/waka/lexicon/>
PREFIX decomp: <http://www.w3.org/ns/lemon/decomp#>
PREFIX wakaid: <https://example.org/waka/id/>

SELECT ?pos ?otherEntry WHERE {
  BIND(wakaid:$POEM AS ?waka)
  ?matchedEntry decomp:subterm lex:$WORD .
  ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka ; waka:position ?pos .
  ?matchedEntry decomp:subterm ?otherEntry .
  FILTER(?otherEntry != lex:$WORD)
}
EOF
)"

PARALLEL_SIBLING_ROWS="$(run_query waka-batch.ttl occurrence-batch.ttl lex-batch.ttl <<EOF
PREFIX waka:   <https://example.org/waka/ontology#>
PREFIX lex:    <https://example.org/waka/lexicon/>
PREFIX decomp: <http://www.w3.org/ns/lemon/decomp#>
PREFIX wakaid: <https://example.org/waka/id/>

SELECT ?pos ?otherEntry WHERE {
  BIND(wakaid:$POEM AS ?waka)
  VALUES ?winGroup { $GROUP_VALUES_LIST }
  ?matchedEntry waka:parallelDecomp ?winGroup .
  ?matchOcc waka:instantiates ?matchedEntry ; waka:ofWaka ?waka ; waka:position ?pos .
  ?winGroup decomp:constituent ?sibComp .
  ?sibComp decomp:correspondsTo ?otherEntry .
  FILTER(?otherEntry != lex:$WORD)
}
EOF
)"

jq -n --argjson word "$WORD_ROWS" --argjson sub "$SUBTERM_SIBLING_ROWS" --argjson par "$PARALLEL_SIBLING_ROWS" '
{
  head: { vars: ["pos", "otherEntry", "kind"] },
  results: { bindings: (
    ($word.results.bindings | map(. + {kind: {type: "literal", value: "word"}})) +
    ($sub.results.bindings | map(. + {kind: {type: "literal", value: "compound-sibling"}})) +
    ($par.results.bindings | map(. + {kind: {type: "literal", value: "compound-sibling"}}))
  ) }
}
'
