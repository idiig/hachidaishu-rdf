#!/usr/bin/env bash
# Test for ../gender-context-concept-in-poem.sh: (gender, poem_id) =>
# occurrence item CONCEPT list, same resolution as
# gender-context-in-poem.sh but mapped through ontolex:sense ->
# ontolex:reference.
#
# shuui-1181 position 1 (Male half) is おもふ【思ふ】, whose sense
# references concept:BG-02-3060 (verified by hand) -- must appear in the
# Male query, must NOT appear in the Female query (that word is only at
# a Male-half position).
#
# Output format (2026-08-13, per user): "broader-leaf" label string, not
# the raw concept: URI (see word-context-concept-in-poem.sh's test for
# the full explanation). concept:BG-02-3060's own label is
# "思考・認識・知解", its immediate broader (concept:BG-02-306) is ALSO
# "思考・認識・知解" (verified by hand, a real data coincidence) ->
# "思考・認識・知解-思考・認識・知解".
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON_M="$("$QUERIES_DIR/gender-context-concept-in-poem.sh" "Male" "shuui-1181")"
JSON_F="$("$QUERIES_DIR/gender-context-concept-in-poem.sh" "Female" "shuui-1181")"

assert_true "思考・認識・知解-思考・認識・知解 (おもふ, pos 1) in Male results" "$JSON_M" \
    '[.results.bindings[] | select(.pos.value == "1" and .concept.value == "思考・認識・知解-思考・認識・知解")] | length == 1'
assert_true "思考・認識・知解-思考・認識・知解 NOT in Female results" "$JSON_F" \
    '[.results.bindings[] | select(.concept.value == "思考・認識・知解-思考・認識・知解")] | length == 0'

finish
