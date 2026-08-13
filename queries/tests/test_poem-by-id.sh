#!/usr/bin/env bash
# Test for ../poem-by-id.sh: id => poem item (flat property bag).
# Ground truth: wakaid:gosen-1's full content was hand-verified earlier
# in conversation -- dcterms:creator person:藤原敏行, 5 waka:ku lines,
# dcterms:subject topic:春上, waka:voiceGenderSwitched false.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assert.sh"

JSON="$("$QUERIES_DIR/poem-by-id.sh" "gosen-1")"

assert_true "dcterms:creator is person:藤原敏行" "$JSON" \
    '[.results.bindings[] | select(.p.value == "http://purl.org/dc/terms/creator" and .o.value == "https://example.org/waka/person/藤原敏行")] | length == 1'

assert_count "5 waka:ku lines" "$JSON" \
    '[.results.bindings[] | select(.p.value == "https://example.org/waka/ontology#ku")] | length' 5

assert_true "dcterms:subject is topic:春上" "$JSON" \
    '[.results.bindings[] | select(.p.value == "http://purl.org/dc/terms/subject" and .o.value == "https://example.org/waka/topic/春上")] | length == 1'

finish
