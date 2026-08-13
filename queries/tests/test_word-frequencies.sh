#!/usr/bin/env bash
# Test for ../word-frequencies.sh: anthology => every word used in it,
# with its occurrence count. Supports the KLD pipeline's
# candidate-targets/hapax-legomena filtering (see module-design-prototype.el).
#
# lex:とし【年】 occurs exactly 43 times in Kokinshu (verified via ad hoc
# arq COUNT query, filtered on the wakaid:kokin- prefix).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/word-frequencies.sh" "kokin")"

assert_true "とし【年】 has count 43 in kokin" "$JSON" \
    '[.results.bindings[] | select(.word.value == "とし【年】" and .count.value == "43")] | length == 1'

finish
