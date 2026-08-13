#!/usr/bin/env bash
# Test for ../gender-context-in-poem.sh: (gender, poem_id) => occurrence
# item list in that poem attributed to that gender.
#
# Two regimes, both verified by hand earlier in conversation:
# - shuui-1181 (joint M/F composition, per-occurrence dcterms:creator
#   set): Male must return exactly positions 1-8 (8 rows, 藤原忠君's
#   half), Female exactly positions 9-17 (9 rows, 良岑義方女's half).
# - gosen-1 (ordinary single-author poem, creator 藤原敏行/Male, NO
#   per-occurrence dcterms:creator asserted at all -- by design, see
#   waka-ontology.ttl's dcterms:creator reuse note): Male must return
#   ALL 15 occurrences (the whole poem counts as Male), Female must
#   return 0 (nothing to attribute to Female here).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON_M_1181="$("$QUERIES_DIR/gender-context-in-poem.sh" "Male" "shuui-1181")"
JSON_F_1181="$("$QUERIES_DIR/gender-context-in-poem.sh" "Female" "shuui-1181")"
assert_count "shuui-1181 Male: 8 occurrences" "$JSON_M_1181" '.results.bindings | length' 8
assert_count "shuui-1181 Female: 9 occurrences" "$JSON_F_1181" '.results.bindings | length' 9
assert_true "shuui-1181 Male results are all position <= 8" "$JSON_M_1181" \
    '[.results.bindings[].pos.value | tonumber] | all(. <= 8)'
assert_true "shuui-1181 Female results are all position >= 9" "$JSON_F_1181" \
    '[.results.bindings[].pos.value | tonumber] | all(. >= 9)'

JSON_M_G1="$("$QUERIES_DIR/gender-context-in-poem.sh" "Male" "gosen-1")"
JSON_F_G1="$("$QUERIES_DIR/gender-context-in-poem.sh" "Female" "gosen-1")"
assert_count "gosen-1 Male: all 15 occurrences (ordinary single-author poem)" "$JSON_M_G1" '.results.bindings | length' 15
assert_count "gosen-1 Female: 0 occurrences" "$JSON_F_G1" '.results.bindings | length' 0

finish
