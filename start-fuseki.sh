#!/usr/bin/env bash
# Start a Jena Fuseki SPARQL HTTP endpoint over this dataset -- in
# memory, read-only, reloaded fresh from data/*.ttl on every start.
# Requires `fuseki-server` (Apache Jena Fuseki) on PATH.
#
# Usage: ./start-fuseki.sh [port]   (default port: 3030)
#
# Endpoint: http://localhost:<port>/hachidaishu/sparql
#
# Any program can POST/GET SPARQL there over the standard SPARQL 1.1
# Protocol -- e.g. the exact query text embedded in any queries/*.sh
# script:
#   curl -G http://localhost:3030/hachidaishu/sparql \
#     --data-urlencode 'query=PREFIX waka: <https://example.org/waka/ontology#>
#   PREFIX lex: <https://example.org/waka/lexicon/>
#   SELECT DISTINCT ?waka WHERE {
#     ?occ waka:instantiates lex:とし【年】 ; waka:ofWaka ?waka .
#   }' \
#     -H "Accept: application/sparql-results+json"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-3030}"
FUSEKI="${FUSEKI:-fuseki-server}"

cd "$ROOT/data"
exec "$FUSEKI" \
  --file=lex-batch.ttl \
  --file=concept-batch.ttl \
  --file=concept-example.ttl \
  --file=waka-batch.ttl \
  --file=author-batch.ttl \
  --file=author-example.ttl \
  --file=occurrence-batch.ttl \
  --file=book-batch.ttl \
  --port="$PORT" \
  /hachidaishu
