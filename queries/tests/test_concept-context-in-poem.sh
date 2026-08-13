#!/usr/bin/env bash
# Test for ../concept-context-in-poem.sh: (concept, poem_id) =>
# occurrence item (word) list within that poem, direct + compound cases
# like word-context-in-poem.sh but keyed by concept -- "self" exclusion
# generalizes from "not the same word" (word version) to "not a word
# that itself references the same concept" (verified by hand: none of
# gosen-1033's other 16 words reference concept:BG-02-3060).
#
# gosen-1033 has 18 positions; position 18 (おもふ) is the only one whose
# word references concept:BG-02-3060 (verified by hand). Expect exactly
# 17 result rows (positions 1-17, kind="word"), position 18 itself
# excluded, and no compound-sibling rows (おもふ isn't part of any
# compound occurrence in this poem).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/concept-context-in-poem.sh" "BG-02-3060" "gosen-1033")"

assert_count "17 result rows" "$JSON" '.results.bindings | length' 17
assert_true "position 18 (the matched word itself) is excluded" "$JSON" \
    '[.results.bindings[] | select(.pos.value == "18")] | length == 0'
assert_true "all rows have kind=word" "$JSON" \
    '[.results.bindings[].kind.value] | all(. == "word")'

finish
