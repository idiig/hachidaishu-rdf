#!/usr/bin/env bash
# Test for ../poems-by-topic.sh: topic (部立, e.g. 春上/恋一) => poem item
# list. Broader-inclusive: matches the topic itself AND anything whose
# dcterms:subject is a skos:broader-descendant of it (scheme:部立, see
# concept-example.ttl), because 部立 subdivisions are asymmetric across
# anthologies -- some poems are tagged with the coarse topic:春 directly,
# others with a finer topic:春上/春中/春下, and a caller asking for "春"
# wants both.
#
# topic:春上 is asserted on wakaid:gosen-1 (waka-batch.ttl line 49), on
# 241 poems total, and has skos:broader topic:春 (concept-example.ttl).
# topic:春 is asserted directly on wakaid:shuui-1 (no finer subdivision
# in Shuishu) and on 78 poems total. All verified via ad hoc arq COUNT
# queries.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON_LEAF="$("$QUERIES_DIR/poems-by-topic.sh" "春上")"
assert_true "gosen-1 is among the 春上 results" "$JSON_LEAF" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/gosen-1")'
assert_count "exactly 241 poems have topic 春上 (leaf topic: no broadening below it)" "$JSON_LEAF" \
    '.results.bindings | length' "241"

JSON_BROAD="$("$QUERIES_DIR/poems-by-topic.sh" "春")"
assert_true "shuui-1 (direct topic:春) is among the 春 results" "$JSON_BROAD" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/shuui-1")'
assert_true "gosen-1 (topic:春上, a narrower topic) is also among the 春 results" "$JSON_BROAD" \
    '[.results.bindings[].waka.value] | any(. == "https://example.org/waka/id/gosen-1")'
assert_count "exactly 522 poems have topic 春 or narrower (78 direct + 444 春上/春中/春下)" "$JSON_BROAD" \
    '.results.bindings | length' "522"

# --within chains this query on top of a prior result set (here,
# poems-by-anthology.sh's own output) instead of searching the whole
# corpus -- 134 kokin poems have topic 春 or narrower (verified via ad
# hoc arq COUNT query restricted to the kokin- prefix).
JSON_BROAD_WITHIN="$("$QUERIES_DIR/poems-by-topic.sh" "春" --within <("$QUERIES_DIR/poems-by-anthology.sh" "kokin"))"
assert_count "春 --within kokin: 134 poems" "$JSON_BROAD_WITHIN" \
    '.results.bindings | length' "134"

finish
