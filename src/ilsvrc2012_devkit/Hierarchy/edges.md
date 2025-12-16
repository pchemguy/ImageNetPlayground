# Purpose

Materialize the `domain_topic` (or another relation) relation into a TEMP, memory-backed table (`temp.edges`) for fast downstream graph traversal and path analysis.

This module:
- Forces SQLite to store all TEMP objects in memory (`PRAGMA temp_store = MEMORY`).
- Drops and recreates `temp.edges` to ensure a clean, deterministic state.
- Extracts directed edges from `synset_relations` filtered to:
    - relation type = 'domain_topic'
    - noun synsets only (`pos = 'n'`)
- Denormalizes both numeric rowids and human-readable synset identifiers
  to avoid repeated joins in later queries.

# Table Schema

```sql
temp.edges(
    rowid          INTEGER  PRIMARY KEY,  -- inherited from synset_relations.rowid
    source_rowid   INTEGER  NOT NULL,      -- child synset rowid
    source_synid   TEXT     NOT NULL,      -- child synset identifier (case-insensitive)
    target_rowid   INTEGER  NOT NULL,      -- parent/domain synset rowid
    target_synid   TEXT     NOT NULL       -- parent/domain synset identifier
)
```

# Semantics

Each row represents a directed edge:

`source_rowid  -->  target_rowid`

corresponding to the WordNet / OMW `domain_topic` relation.

# Notes

- The table is TEMP and connection-local; it is dropped automatically when the connection closes.
- Two UNIQUE constraints enforce pairwise uniqueness of connected `synsets` (including reversed order), effectively preventing duplicate or symmetric edges from appearing, but more importantly, define indexes on both fields without separate INDEX statements.
- This table is intended to be consumed by recursive CTEs performing root–leaf path enumeration and dominance/shortcut pruning.

# Dependencies

Requires the following base tables to be present and populated:
- `synset_relations`
- `synsets`
- `relation_types`

This module should be executed before any path enumeration or hierarchy analysis modules that reference `temp.edges`.

