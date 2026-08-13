#!/usr/bin/env bash
# Test for ../poems-by-concept.sh: concept => poem item list. Direct
# match only (no compound-decomposition handling) -- per memo.org's
# "query concept for poem items" spec, same scope decision as
# poems-by-word.sh.
#
# concept:BG-02-3060 (思ふ/おもふ's concept) is referenced by 18
# different lex entries (verified by hand: おもふ/こふ/しる/みる/...),
# and shuui-1181 contains おもふ at position 1 -- must be in the results.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/poems-by-concept.sh" "BG-02-3060")"

assert_true "shuui-1181 is among the results" "$JSON" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/shuui-1181")'

COUNT="$(echo "$JSON" | jq '.results.bindings | length')"
if [ "$COUNT" -gt 10 ]; then
    echo "  ok   - many poems found ($COUNT total, concept has 18 different words mapped to it)"
else
    echo "  FAIL - expected > 10 poems, got $COUNT"
    FAILED=1
fi

# --within chains this query on top of a prior result set (here,
# poems-by-anthology.sh's own output) instead of searching the whole
# corpus -- 526 kokin poems reference BG-02-3060 (verified via ad hoc
# arq COUNT query restricted to the kokin- prefix).
JSON_WITHIN="$("$QUERIES_DIR/poems-by-concept.sh" "BG-02-3060" --within <("$QUERIES_DIR/poems-by-anthology.sh" "kokin"))"
assert_count "BG-02-3060 --within kokin: 526 poems" "$JSON_WITHIN" \
    '.results.bindings | length' "526"

finish
