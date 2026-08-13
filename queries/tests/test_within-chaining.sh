#!/usr/bin/env bash
# Recursive-narrowing regression test: --within must compose to
# arbitrary depth, not just one level on top of a raw poems-by-*.sh
# call. Each poems-by-*.sh script's stdout is valid --within input to
# any other (including itself), so a chain like "anthology -> topic ->
# gender" must equal the same three conditions evaluated together in one
# independent SPARQL query.
#
# kokin poems, topic 春 (broader-inclusive), Female: 10 poems (verified
# via ad hoc arq COUNT query combining all three conditions directly).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/poems-by-anthology.sh" kokin \
    | "$QUERIES_DIR/poems-by-topic.sh" 春 --within - \
    | "$QUERIES_DIR/poems-by-gender.sh" Female --within -)"

assert_count "kokin + topic 春 + gender Female, 3-level chain: 10 poems" "$JSON" \
    '.results.bindings | length' "10"

finish
