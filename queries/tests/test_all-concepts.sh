#!/usr/bin/env bash
# Test for ../all-concepts.sh: no input, lists every distinct concept
# actually referenced by some word's sense (not every concept
# concept-batch.ttl defines -- only ones in use), as (?concept local
# name, reusable as the <concept-local-name> argument to
# poems-by-concept.sh/etc.; ?label, the "broader-leaf" display string
# from the 2026-08-13 output-format change).
#
# concept:CH-29-5250 ("川・湖-川・湖") and concept:BG-02-3060
# ("思考・認識・知解-思考・認識・知解") both verified real, in-use concepts
# earlier in conversation -- must both appear with correct local name +
# label pairing.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/all-concepts.sh")"

assert_true "CH-29-5250 / 川・湖-川・湖 pair is in the list" "$JSON" \
    '[.results.bindings[] | select(.concept.value == "CH-29-5250" and .label.value == "川・湖-川・湖")] | length == 1'
assert_true "BG-02-3060 / 思考・認識・知解-思考・認識・知解 pair is in the list" "$JSON" \
    '[.results.bindings[] | select(.concept.value == "BG-02-3060" and .label.value == "思考・認識・知解-思考・認識・知解")] | length == 1'

finish
