#!/usr/bin/env bash
# Test for ../poems-by-anthology.sh: anthology => full poem-id
# population for it (kokin/gosen/shuui/goshuui, matched by the wakaid:
# local-name prefix). This is the population query recursive narrowing
# chains typically start from -- see --within on the other
# poems-by-*.sh scripts (poems-by-word.sh etc.) for how to chain
# further conditions on top of this.
#
# 1111 poems total in Kokinshu, wakaid:kokin-1 included, wakaid:gosen-1
# excluded (verified via ad hoc arq COUNT query on waka-batch.ttl).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/poems-by-anthology.sh" "kokin")"

assert_true "kokin-1 is among the results" "$JSON" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/kokin-1")'
assert_true "gosen-1 is NOT among the results" "$JSON" \
    '([.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/gosen-1")) | not'
assert_count "exactly 1111 poems in kokin" "$JSON" \
    '.results.bindings | length' "1111"

finish
