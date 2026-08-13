#!/usr/bin/env bash
# poem-by-id.sh <poem-id>
# id => poem item. Flat (predicate, object) property bag for the
# wakaid:<poem-id> subject -- deliberately generic (no hand-picked
# property list) so it stays correct as new properties get added
# (dcterms:isPartOf/book-batch.ttl, waka:hasOccurrence/occurrence-batch.ttl,
# etc.) without needing to edit this script.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

POEM="$1"

run_query waka-batch.ttl book-batch.ttl <<EOF
PREFIX wakaid: <https://example.org/waka/id/>

SELECT ?p ?o WHERE {
  wakaid:$POEM ?p ?o .
}
EOF
