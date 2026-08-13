#!/usr/bin/env bash
# Test for ../all-words.sh: no input, lists every distinct word (lex:
# local name, not full URI -- directly reusable as the <word-local-name>
# argument to poems-by-word.sh/word-context-in-poem.sh/etc.) that has at
# least one real occurrence in the corpus.
#
# とし【年】 (kokin-1 position 1) and たつたがは【立田川・立田河・竜田川・
# 竜田河・龍田川】 (gosen-1033 position 1) must both appear (verified real
# occurrences, used throughout this session's other tests). Expect well
# over 1000 distinct words (3109+ confirmed earlier in conversation).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/all-words.sh")"

assert_true "とし【年】 is in the list" "$JSON" \
    '[.results.bindings[].word.value] | any(. == "とし【年】")'
assert_true "たつたがは【立田川・立田河・竜田川・竜田河・龍田川】 is in the list" "$JSON" \
    '[.results.bindings[].word.value] | any(. == "たつたがは【立田川・立田河・竜田川・竜田河・龍田川】")'

COUNT="$(echo "$JSON" | jq '.results.bindings | length')"
if [ "$COUNT" -gt 1000 ]; then
    echo "  ok   - well over 1000 distinct words ($COUNT total)"
else
    echo "  FAIL - expected > 1000 words, got $COUNT"
    FAILED=1
fi

finish
