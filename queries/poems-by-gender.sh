#!/usr/bin/env bash
# poems-by-gender.sh <Male|Female>
# gender => poem item list. Per memo.org's notes: (1) gender-switched
# poetic voice (waka:poeticVoice) counts as that gender even when the
# biographical dcterms:creator is a different gender; (2) joint M/F
# compositions are included for BOTH genders -- this falls out for free
# from dcterms:creator being multi-valued (matching ANY creator of the
# target gender already includes a poem that also has a creator of the
# other gender).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

GENDER="$1"

run_query waka-batch.ttl author-batch.ttl author-example.ttl <<EOF
PREFIX waka:   <https://example.org/waka/ontology#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX schema: <https://schema.org/>

SELECT DISTINCT ?waka WHERE {
  {
    ?waka dcterms:creator ?p .
  } UNION {
    ?waka waka:poeticVoice ?p .
  }
  ?p schema:gender schema:$GENDER .
}
ORDER BY ?waka
EOF
