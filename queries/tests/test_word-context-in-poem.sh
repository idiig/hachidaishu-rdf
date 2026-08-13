#!/usr/bin/env bash
# Test for ../word-context-in-poem.sh: (word, poem_id) => occurrence item
# list within that poem, "compound-sibling" rows for words that only
# appear as part of a compound's own occurrence.
#
# Case A (flat decomp:subterm): gosen-1033 contains
# たつたがは【立田川・立田河・竜田川・竜田河・龍田川】 at position 1, whose
# decomp:subterm is {たつた【立田・竜田・龍田】, かは【川・河】} (verified by
# hand earlier in conversation). Querying with word=たつた【立田・竜田・龍田】
# must surface かは【川・河】 as a compound-sibling, plus 18 ordinary word
# rows (positions 1,3..18, since position 1 itself -- the matched compound
# -- is excluded like any other "otherEntry != target" match, but note
# the target itself isn't たつたがは, it's たつた, so position 1's own
# entry (たつたがは) SHOULD appear as an ordinary word row -- it doesn't
# equal the query word).
#
# Case B (waka:parallelDecomp, size-based tie-break, NO tie needed here):
# gosen-161 position 3 contains やそうぢびと【八十氏人】, which has 4
# candidate decompositions; やそ【八十】 is a component in decomp-1 (2
# components: やそ+うぢびと) and decomp-3 (3 components: やそ+うぢ+ひと) --
# decomp-1 has fewer, so it wins and the ONLY compound-sibling must be
# うぢびと【氏人】 (not うぢ/ひと from decomp-3, not や/そ/うぢびと from
# decomp-2, which doesn't even contain やそ as a whole component).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

echo "case A: flat decomp:subterm (たつた / gosen-1033)"
JSON_A="$("$QUERIES_DIR/word-context-in-poem.sh" "たつた【立田・竜田・龍田】" "gosen-1033")"

assert_true "かは【川・河】 appears as compound-sibling at pos=1 (the compound's own position)" "$JSON_A" \
    '[.results.bindings[] | select(.otherEntry.value == "https://example.org/waka/lexicon/かは【川・河】" and .kind.value == "compound-sibling" and .pos.value == "1")] | length == 1'

assert_true "たつたがは (the compound itself, position 1) appears as an ordinary word" "$JSON_A" \
    '[.results.bindings[] | select(.otherEntry.value == "https://example.org/waka/lexicon/たつたがは【立田川・立田河・竜田川・竜田河・龍田川】" and .kind.value == "word" and .pos.value == "1")] | length == 1'

assert_count "18 ordinary word rows total" "$JSON_A" \
    '[.results.bindings[] | select(.kind.value == "word")] | length' 18

echo "case B: waka:parallelDecomp size tie-break (やそ / gosen-161)"
JSON_B="$("$QUERIES_DIR/word-context-in-poem.sh" "やそ【八十】" "gosen-161")"

assert_true "うぢびと【氏人】 appears as compound-sibling at pos=3 (smaller group wins)" "$JSON_B" \
    '[.results.bindings[] | select(.otherEntry.value == "https://example.org/waka/lexicon/うぢびと【氏人】" and .kind.value == "compound-sibling" and .pos.value == "3")] | length == 1'

assert_true "うぢ【宇治】 does NOT appear (loses to the smaller group)" "$JSON_B" \
    '[.results.bindings[] | select(.otherEntry.value == "https://example.org/waka/lexicon/うぢ【宇治】")] | length == 0'

assert_true "ひと【人】 does NOT appear (loses to the smaller group)" "$JSON_B" \
    '[.results.bindings[] | select(.otherEntry.value == "https://example.org/waka/lexicon/ひと【人】")] | length == 0'

finish
