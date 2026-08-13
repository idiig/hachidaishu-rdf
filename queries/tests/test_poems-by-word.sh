#!/usr/bin/env bash
# Test for ../poems-by-word.sh: word => poem item list.
# Ground truth verified by hand in conversation (2026-08-13):
# kokin-1's position 1 occurrence directly instantiates lex:とし【年】
# (`occ:kokin-1-1 ... waka:instantiates lex:とし【年】`), so poems-by-word
# for とし【年】 must include wakaid:kokin-1 among its results, and the
# result must be non-empty overall (とし【年】 is a common word, expect
# more than just that one poem).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/poems-by-word.sh" "とし【年】")"

assert_true "kokin-1 is among the results" "$JSON" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/kokin-1")'

COUNT="$(echo "$JSON" | jq '.results.bindings | length')"
if [ "$COUNT" -gt 1 ]; then
    echo "  ok   - more than one poem found ($COUNT total, とし【年】 is common)"
else
    echo "  FAIL - expected more than one poem, got $COUNT"
    FAILED=1
fi

# --within chains this query on top of a prior result set (here,
# poems-by-anthology.sh's own output) instead of searching the whole
# corpus -- 41 of the 195 corpus-wide とし【年】 poems are in Kokinshu
# (verified via ad hoc arq COUNT query restricted to the kokin- prefix).
JSON_WITHIN="$("$QUERIES_DIR/poems-by-word.sh" "とし【年】" --within <("$QUERIES_DIR/poems-by-anthology.sh" "kokin"))"
assert_count "とし【年】 --within kokin: 41 poems (narrowed from 195 corpus-wide)" "$JSON_WITHIN" \
    '.results.bindings | length' "41"

finish
