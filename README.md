# hachidaishu-rdf

An RDF dataset of classical Japanese waka poetry (古今和歌集 Kokinshu, 後撰和歌集 Gosenshu, 拾遺和歌集 Shuishu, 後拾遺和歌集 Goshuishu — the first four of the eight imperial anthologies, 八代集), plus a set of SPARQL query scripts for looking things up by word, concept (WLSP semantic classification), gender, or poem.

## Requirements

- [Apache Jena](https://jena.apache.org/)'s `arq` command-line SPARQL query tool
- [`jq`](https://jqlang.org/)

Either must be on `PATH`. Install however you like, e.g.:

```sh
# nix
nix shell nixpkgs#apache-jena nixpkgs#jq

# Homebrew
brew install jena jq
```

## Data (`data/`)

| File | Contents |
|---|---|
| `waka-batch.ttl` | Poems (`waka:Waka`): identifier, creator(s), headnote, ku (5 metrical segments), topic (部立), voice/gender-switch info |
| `book-batch.ttl` | Anthology volumes (`waka:Book`, 巻) and which poems belong to which |
| `lex-batch.ttl` | Dictionary entries (`ontolex:LexicalEntry`/`LexicalSense`), including compound-word decomposition |
| `concept-batch.ttl` | WLSP semantic classification hierarchy (`skos:Concept`), including place-name and person-name categories |
| `concept-example.ttl` | Additional concept schemes not from WLSP: 部立 (anthology section topics), 官位, 宗教状態 |
| `author-batch.ttl`, `author-example.ttl` | Poets (`foaf:Person`): name, gender, court rank, religious status |
| `occurrence-batch.ttl` | Every word's occurrence at every position in every poem (`waka:TokenOccurrence`), linking poems to dictionary entries |

## Queries (`queries/`)

Each query is a standalone shell script. Run it directly (`./queries/poems-by-word.sh ...`) from anywhere — paths are resolved relative to the script itself. Output is always [SPARQL Results JSON](https://www.w3.org/TR/sparql11-results-json/) on stdout: a flat `{"head": {"vars": [...]}, "results": {"bindings": [...]}}` object, one entry in `bindings` per result row, each row a map from variable name to `{"type": ..., "value": ...}` (or, for numbers, an extra `"datatype"` key).

**Word and concept arguments are local names, not full URIs** — e.g. `たつ【立つ】`, `BG-02-3060`. Use `all-words.sh` / `all-concepts.sh` to find valid values.

### Catalogs (no input)

- **`all-words.sh`** — every word with at least one real occurrence in the corpus.
  Output: `?word` (e.g. `"とし【年】"`).
- **`all-concepts.sh`** — every WLSP/place/person concept actually referenced by some word.
  Output: `?concept` (local name, e.g. `"BG-02-3060"`), `?label` (human-readable "broader-leaf" string, e.g. `"思考・認識・知解-思考・認識・知解"` — see "Concept labels" below).

### Poem lookup

- **`poem-by-id.sh <poem-id>`** — a poem's full metadata. `<poem-id>` is `{kokin|gosen|shuui|goshuui}-<number>`, e.g. `gosen-1`.
  Output: `?p ?o` — every (predicate, object) pair on that poem, e.g. `dcterms:creator`, `waka:ku` (×5), `dcterms:subject`, `dcterms:isPartOf` (its book/volume).

### By word

- **`poems-by-word.sh <word>`** — which poems contain this exact word.
  Output: `?waka` (poem URI).
- **`word-context-in-poem.sh <word> <poem-id>`** — every other word in that poem, at the position(s) this word occurs.
  Output: `?pos` (1-based position in the poem), `?otherEntry` (the other word), `?kind` — `"word"` for an ordinarily-occurring word at its own position, or `"compound-sibling"` for another component of a compound word that the query word is (only) embedded in (shares the compound's own `?pos`, since it has no independent position of its own).
- **`word-context-concept-in-poem.sh <word> <poem-id>`** — same as above, but each other word replaced by its concept(s) (a word can map to more than one concept if it has multiple dictionary senses).
  Output: `?pos`, `?concept` (label string), `?kind`.

### By concept

- **`poems-by-concept.sh <concept>`** — which poems contain a word referencing this concept.
  Output: `?waka`.
- **`concept-context-in-poem.sh <concept> <poem-id>`** — like `word-context-in-poem.sh`, but matches any word referencing the given concept (there can be several), and excludes any other word that *also* references that concept (rather than just excluding one literal word).
  Output: `?pos`, `?otherEntry`, `?kind`.
- **`concept-context-concept-in-poem.sh <concept> <poem-id>`** — same match as above, output mapped to concepts.
  Output: `?pos`, `?concept`, `?kind`.

### By gender

`<gender>` is `Male` or `Female`. Gender-switched poetic voice (a poem performed in an assumed gender, whether or not it matches the biographical author) counts, and a poem jointly composed by both a male and a female poet appears for both genders.

- **`poems-by-gender.sh <gender>`** — poems attributable to this gender.
  Output: `?waka`.
- **`gender-context-in-poem.sh <gender> <poem-id>`** — the words in that poem attributable to this gender. For an ordinary single-voice poem this is every word in it; for a poem jointly composed by two authors of different genders (a kami-no-ku/shimo-no-ku exchange), only the half attributed to the given gender.
  Output: `?pos`, `?entry`.
- **`gender-context-concept-in-poem.sh <gender> <poem-id>`** — same, mapped to concepts.
  Output: `?pos`, `?concept`.

## Concept labels

`?concept`/`?label` values combining two levels are written `broader-leaf`: `leaf` is the matched concept's own label, `broader` is its immediate parent in the WLSP hierarchy (**not** the top-level category — e.g. not "体"/"用"/"相"). If a concept has no finer subdivision below its parent, `broader` and `leaf` can be identical text (e.g. `"川・湖-川・湖"`) — that's the real classification, not a formatting bug.

## Compound words

Some words only ever appear in the corpus as part of a larger compound (e.g. a place name's individual components). The `*-context-in-poem.sh` / `*-context-concept-in-poem.sh` queries surface these as `"compound-sibling"` rows. When a compound word has more than one plausible decomposition into components, the decomposition with fewer components is preferred; ties are broken by sort order.
