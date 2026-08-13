#!/usr/bin/env bash
# poems-by-word.sh <word-local-name> [--within <file-or->]
# word => poem item list. Direct occurrences only (waka:instantiates the
# word itself) -- per memo.org's "query word for poem items" spec, no
# compound-decomposition handling here (that's only specified for the
# "context ... within a poem item" queries, see word-context-in-poem.sh).
#
# <word-local-name> must be the exact lex: local name as it appears in
# lex-batch.ttl (e.g. "とし【年】", "の\*"), not free text -- look it up
# first if unsure (e.g. via poems-by-word's own SPARQL FILTER/CONTAINS
# pattern used ad hoc earlier in conversation).
#
# --within <file-or-> optionally restricts the search to a prior result
# set (SPARQL Results JSON with a ?waka field, e.g. another
# poems-by-*.sh script's own stdout) instead of the whole corpus -- lets
# queries be chained/narrowed recursively, e.g.:
#   poems-by-anthology.sh kokin | poems-by-word.sh とし【年】 --within -
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

WORD="$1"
WITHIN=""
if [ "${2:-}" = "--within" ]; then
    WITHIN="$(within_values_clause "$3")"
fi

run_query waka-batch.ttl occurrence-batch.ttl <<EOF
PREFIX waka: <https://example.org/waka/ontology#>
PREFIX lex:  <https://example.org/waka/lexicon/>

SELECT DISTINCT ?waka WHERE {
  $WITHIN
  ?occ waka:instantiates lex:$WORD ;
       waka:ofWaka ?waka .
}
ORDER BY ?waka
EOF
