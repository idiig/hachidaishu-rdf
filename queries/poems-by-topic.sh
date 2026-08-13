#!/usr/bin/env bash
# poems-by-topic.sh <topic-local-name> [--within <file-or->]
# topic (部立, e.g. 春上/恋一) => poem item list. Broader-inclusive:
# matches the topic itself AND any poem tagged with a skos:broader-
# descendant of it (via the `skos:broader*` property path), since 部立
# subdivision is asymmetric across anthologies -- some poems carry the
# coarse topic (e.g. topic:春 directly, when an anthology doesn't
# subdivide it) and others carry a finer one (topic:春上/春中/春下), and
# a caller asking for "春" wants both. For a leaf topic with nothing
# narrower than it (e.g. 春上 itself, or any of 恋一..恋六), this is
# equivalent to an exact match. Independent scheme from the WLSP concept
# hierarchy poems-by-concept.sh queries (see concept-example.ttl's
# scheme:部立), so it is its own script rather than a mode of
# poems-by-concept.sh.
#
# <topic-local-name> is the topic: local name as it appears in
# concept-example.ttl (e.g. "春上", "恋一"), not a full URI.
#
# --within <file-or-> optionally restricts the search to a prior result
# set (SPARQL Results JSON with a ?waka field) instead of the whole
# corpus -- see poems-by-word.sh's --within for the chaining example.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

TOPIC="$1"
WITHIN=""
if [ "${2:-}" = "--within" ]; then
    WITHIN="$(within_values_clause "$3")"
fi

run_query waka-batch.ttl concept-example.ttl <<EOF
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX skos:    <http://www.w3.org/2004/02/skos/core#>
PREFIX topic:   <https://example.org/waka/topic/>

SELECT DISTINCT ?waka WHERE {
  $WITHIN
  ?waka dcterms:subject ?t .
  ?t skos:broader* topic:$TOPIC .
}
ORDER BY ?waka
EOF
