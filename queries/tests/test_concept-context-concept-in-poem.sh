#!/usr/bin/env bash
# Test for ../concept-context-concept-in-poem.sh: (concept, poem_id) =>
# occurrence item CONCEPT list, same resolution as
# concept-context-in-poem.sh but each resulting word mapped through
# ontolex:sense -> ontolex:reference to its own concept(s).
#
# gosen-1033 + concept:BG-02-3060 (see concept-context-in-poem.sh's
# test): position 1 (たつたがは) is excluded from the "word" match set
# (concept:BG-02-3060 itself), but its OWN concept (CH-29-5250, verified
# by hand earlier) must appear in the output, mapped from position 1.
#
# Output format (2026-08-13, per user): "broader-leaf" label string, not
# the raw concept: URI (see word-context-concept-in-poem.sh's test for
# the full explanation). concept:CH-29-5250 -> "川・湖-川・湖" (own label
# and immediate broader's label coincide, verified by hand). The excluded
# concept:BG-02-3060 -> "思考・認識・知解-思考・認識・知解" (different
# string, so checking it never appears is still a meaningful check).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/concept-context-concept-in-poem.sh" "BG-02-3060" "gosen-1033")"

assert_true "川・湖-川・湖 (CH-29-5250) appears for position 1 (たつたがは)" "$JSON" \
    '[.results.bindings[] | select(.pos.value == "1" and .concept.value == "川・湖-川・湖")] | length == 1'
assert_true "思考・認識・知解-思考・認識・知解 (the query concept itself) never appears in the output" "$JSON" \
    '[.results.bindings[] | select(.concept.value == "思考・認識・知解-思考・認識・知解")] | length == 0'

finish
