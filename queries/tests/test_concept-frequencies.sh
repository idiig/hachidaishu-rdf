#!/usr/bin/env bash
# Test for ../concept-frequencies.sh: anthology => every concept
# referenced by some word used in it, with its occurrence count (same
# "broader-leaf" label convention as all-concepts.sh). Sister to
# word-frequencies.sh, for candidate-targets/hapax filtering when the
# target unit is "concept" rather than "word".
#
# concept:BG-02-3060 (思考・認識・知解-思考・認識・知解) occurs exactly 712
# times in Kokinshu (verified via ad hoc arq COUNT query, filtered on the
# wakaid:kokin- prefix).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/concept-frequencies.sh" "kokin")"

assert_true "BG-02-3060 / 思考・認識・知解-思考・認識・知解 has count 712 in kokin" "$JSON" \
    '[.results.bindings[] | select(.concept.value == "BG-02-3060" and .label.value == "思考・認識・知解-思考・認識・知解" and .count.value == "712")] | length == 1'

finish
