#!/usr/bin/env bash
# Test for ../poems-by-gender.sh: gender => poem item list. Must include
# both direct dcterms:creator gender matches AND waka:poeticVoice
# gender-switch matches, and naturally includes joint M/F compositions
# for BOTH genders (since dcterms:creator is multi-valued on the Waka).
#
# gosen-662: dcterms:creator person:anonymous-male-unknown-status (Male)
# but waka:poeticVoice person:anonymous-female-unknown-status (Female) --
# verified by hand. Must appear for BOTH Male (direct creator) and
# Female (poeticVoice) queries.
# shuui-1181: dcterms:creator person:良岑義方女 (Female) + 藤原忠君 (Male),
# a joint kami-no-ku/shimo-no-ku composition -- must appear for BOTH.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON_M="$("$QUERIES_DIR/poems-by-gender.sh" "Male")"
JSON_F="$("$QUERIES_DIR/poems-by-gender.sh" "Female")"

assert_true "gosen-662 in Male results (direct creator)" "$JSON_M" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/gosen-662")'
assert_true "gosen-662 in Female results (poeticVoice switch)" "$JSON_F" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/gosen-662")'
assert_true "shuui-1181 in Male results (joint composition)" "$JSON_M" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/shuui-1181")'
assert_true "shuui-1181 in Female results (joint composition)" "$JSON_F" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/shuui-1181")'

# --within chains this query on top of a prior result set (here,
# poems-by-anthology.sh's own output) instead of searching the whole
# corpus -- 84 kokin poems are attributable to Female (verified via ad
# hoc arq COUNT query restricted to the kokin- prefix).
JSON_F_WITHIN="$("$QUERIES_DIR/poems-by-gender.sh" "Female" --within <("$QUERIES_DIR/poems-by-anthology.sh" "kokin"))"
assert_count "Female --within kokin: 84 poems" "$JSON_F_WITHIN" \
    '.results.bindings | length' "84"

finish
