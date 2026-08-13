#!/usr/bin/env bash
# Test for ../word-context-concept-in-poem.sh: (word, poem_id) =>
# occurrence item CONCEPT list within that poem (same occurrence
# resolution as word-context-in-poem.sh, but each entry mapped through
# ontolex:sense -> ontolex:reference to its concept(s)).
#
# Reuses gosen-1033/たつた case: position 1's word (たつたがは, a
# compound proper noun) has 5 kanji-spelling senses that all reference
# the SAME concept:CH-29-5250 (verified by hand) -- must appear exactly
# once (DISTINCT), not 5 times. The compound-sibling かは【川・河】 has 2
# senses (川/河) that both reference concept:BG-01-5250 -- also once.
#
# Output format (2026-08-13, per user): not the raw concept: URI --
# "broader-leaf" label string, where "broader" is the concept's own
# immediate skos:broader (NOT the top pos-level ancestor, which is
# excluded), and "leaf" is the concept's own skos:prefLabel. Verified by
# hand: concept:CH-29-5250's own label is "川・湖", its immediate broader
# (concept:CH-29-525) is ALSO "川・湖" (a real data coincidence, that
# branch has no finer subdivision beyond this level) -> "川・湖-川・湖".
# Same for concept:BG-01-5250 -> "川・湖-川・湖".
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/word-context-concept-in-poem.sh" "たつた【立田・竜田・龍田】" "gosen-1033")"

assert_count "川・湖-川・湖 (CH-29-5250) appears exactly once for position 1 (たつたがは, deduped across its 5 senses)" "$JSON" \
    '[.results.bindings[] | select(.kind.value == "word" and .pos.value == "1" and .concept.value == "川・湖-川・湖")] | length' 1

assert_count "川・湖-川・湖 (BG-01-5250) appears exactly once for the compound-sibling かは at pos=1 (deduped across its 2 senses)" "$JSON" \
    '[.results.bindings[] | select(.kind.value == "compound-sibling" and .pos.value == "1" and .concept.value == "川・湖-川・湖")] | length' 1

finish
