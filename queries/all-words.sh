#!/usr/bin/env bash
# all-words.sh
# No input -- lists every distinct word actually used in the corpus (has
# at least one real waka:TokenOccurrence), as bare lex: local names
# (e.g. "とし【年】"), directly reusable as the <word-local-name> argument
# to poems-by-word.sh / word-context-in-poem.sh / word-context-concept-in-poem.sh.
# Output field: ?word (a plain string, not a URI -- stripped of the
# lex: namespace prefix here so callers don't need to do that
# themselves).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

RAW="$(run_query occurrence-batch.ttl <<EOF
PREFIX waka: <https://example.org/waka/ontology#>

SELECT DISTINCT ?entry WHERE {
  ?occ waka:instantiates ?entry .
}
ORDER BY ?entry
EOF
)"

echo "$RAW" | jq '
{
  head: { vars: ["word"] },
  results: { bindings: (
    .results.bindings | map({
      word: { type: "literal", value: (.entry.value | sub("^https://example\\.org/waka/lexicon/"; "")) }
    })
  ) }
}
'
