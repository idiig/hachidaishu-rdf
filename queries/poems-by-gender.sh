#!/usr/bin/env bash
# poems-by-gender.sh <Male|Female> [--within <file-or->]
# gender => poem item list. Per memo.org's notes: (1) gender-switched
# poetic voice (waka:poeticVoice) counts as that gender even when the
# biographical dcterms:creator is a different gender; (2) joint M/F
# compositions are included for BOTH genders -- this falls out for free
# from dcterms:creator being multi-valued (matching ANY creator of the
# target gender already includes a poem that also has a creator of the
# other gender).
#
# --within <file-or-> optionally restricts the search to a prior result
# set (SPARQL Results JSON with a ?waka field) instead of the whole
# corpus -- see poems-by-word.sh's --within for the chaining example.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

GENDER="$1"
WITHIN=""
if [ "${2:-}" = "--within" ]; then
    WITHIN="$(within_values_clause "$3")"
fi

run_query waka-batch.ttl author-batch.ttl author-example.ttl <<EOF
PREFIX waka:   <https://example.org/waka/ontology#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX schema: <https://schema.org/>

SELECT DISTINCT ?waka WHERE {
  $WITHIN
  {
    ?waka dcterms:creator ?p .
  } UNION {
    ?waka waka:poeticVoice ?p .
  }
  ?p schema:gender schema:$GENDER .
}
ORDER BY ?waka
EOF
