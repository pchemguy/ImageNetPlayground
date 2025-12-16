# Purpose

`walk.sql` module defines a single SQLite query (CTE pipeline) that:

1) Constructs a directed graph from `temp.edges` representing a single relation type
   (expected: WordNet/OMW `domain_topic`), where each row is a directed edge:

   `source (child)  -->  target (parent)`

2) Enumerates all simple directed paths from *roots* to *leaves* in that graph,
   using a cycle-safe recursive CTE.

3) Filters the resulting path set to retain only "complete" root->leaf paths
   (discarding intermediate partial paths produced during recursion).

4) Identifies and removes "shortcut" paths between the same (root, leaf) endpoints,
   where a shorter path omits one or more intermediate nodes present in a longer path.
   Shortcut detection here is based on unordered node containment (set inclusion),
   not prefix matching and not order-aware subsequence matching.

The final output is a table of pruned root->leaf paths with associated metadata.

# Dependencies

This query depends on a pre-built TEMP table:

`temp.edges`

which is expected to be created/populated by a separate SQL module. The `edges` table
must contain, at minimum, the following columns (names as used in this query):

```sql
- source_rowid   INTEGER  -- edge source node ID
- source_synid   TEXT     -- edge source synset identifier (human-readable)
- target_rowid   INTEGER  -- edge target node ID
- target_synid   TEXT     -- edge target synset identifier (human-readable)
```

Semantics assumed:
- The graph is directed: source_rowid -> target_rowid.
- Nodes are synsets (or other identifiers) in a single POS slice (commonly nouns).
- The graph is intended to be a DAG; however, the recursion includes cycle
  protection to handle anomalies and prevent infinite recursion.

# Output

The final SELECT returns rows from `filtered_paths` with columns:

```sql
- root_rid   INTEGER  -- starting root node rowid
- root_sid   TEXT     -- starting root synset id (string)
- leaf_rid   INTEGER  -- (via ->>)  -- terminal leaf node rowid (as text)
- leaf_sid   TEXT     -- terminal leaf synset id
- path_sid   TEXT     -- JSON array of synset IDs along the path (root..leaf)
- path_rid   TEXT     -- JSON array of rowids along the path (root..leaf)
- depth      INTEGER  -- number of nodes in the path array
```
# Step-by-step logic (by CTE)

1) `relation_sources`
   Collects distinct nodes that appear as sources in the edge list:

   `relation_sources(rid, sid) := DISTINCT (source_rowid, source_synid)`

   This is used to determine which nodes have outgoing edges in the chosen relation.

2) `relation_targets`
   Collects distinct nodes that appear as targets in the edge list:

   `relation_targets(rid, sid) := DISTINCT (target_rowid, target_synid)`

   This is used to determine which nodes have incoming edges.

3) `root_nodes`
   Identifies root nodes of the directed graph as nodes that appear as targets but
   never as sources:

   `root = target_nodes \ source_nodes`

```sql
relation_targets LEFT JOIN relation_sources
WHERE relation_sources.rid IS NULL
```

   Interpretation:
 - Roots have incoming edges but no outgoing edges within this relation graph
   when traversed in the root->leaf direction used below (target -> source).

4) leaf_nodes
   Identifies leaf nodes as nodes that appear as sources but never as targets:

   `leaf = source_nodes \ target_nodes`

   Interpretation:
     - Leaves have outgoing edges but no incoming edges within this relation graph,
       again relative to the chosen traversal direction.

5) `paths_LOOP` (recursive)
   Enumerates simple paths from each root to reachable descendants.

   Seed (non-recursive term):
     - Start at each root node `rn`.
     - Initialize path arrays with the root only.
     - Set `curr_rid` to the current node (initially root).
     - Initialize `depth = 1`.

   Recursive step:
     - From current node `p.curr_rid`, follow edges where:

       `e.target_rowid = p.curr_rid`

       This traverses from parent/target to child/source (root->leaf direction).

     - Append the child/source node onto the JSON arrays:
           path_sid := json_insert(p.path_sid, '$[#]', e.source_synid)
           path_rid := json_insert(p.path_rid, '$[#]', e.source_rowid)

     - Increase depth.

   Cycle protection:
     - Prevent revisiting a node already present in `p.path_rid`:
       `NOT EXISTS (SELECT 1 FROM json_each(p.path_rid) WHERE value = e.source_rowid)`

     This ensures each produced path is a simple path (no repeated nodes).

   Safety valve:
     - Hard cap depth to prevent runaway recursion in pathological graphs:
           `p.depth < 64`

   Result:
     - `paths_LOOP` contains both intermediate partial paths and full root->leaf
       paths; subsequent CTEs restrict to the latter.

6) `preflitered_paths`
   Filters to "complete" root->leaf paths only.
    - Discards trivial paths of depth 1 (root-only).
    - Extracts the terminal node of each path as (leaf_rid, leaf_sid).
    - Keeps only those paths whose last node is a known leaf.

   This discards intermediate recursion products where the last node has children.

7) `multipath_index`
   
   Identifies endpoint pairs (root_rid, leaf_rid) that have multiple distinct path
   depths (i.e., multiple different paths exist between the same endpoints).

   Process:
     - Deduplicate by (root_rid, leaf_rid, depth)
     - Group by (root_rid, leaf_rid)
     - Keep those with `count(*) > 1`

   Rationale:
     Shortcut pruning is only relevant when there is more than one candidate path
     between the same endpoints.

8) `multipaths`
   Selects the subset of `preflitered_paths` that belongs to endpoint pairs identified
   by `multipath_index`, and assigns a `path_id`:

   `path_id := row_number() over (ORDER BY root_sid, leaf_sid, depth DESC, path_sid)`

   Notes:
     - `path_id` is currently introduced only at this stage (after multipath selection).
     - `path_id` is used downstream to refer to candidate paths in dominance testing.

9) `dominance_matrix`
   Constructs all (dominant_path, shortcut_path) candidate pairs for each shared
   endpoint pair (root, leaf), where the dominant path is strictly longer:

   `dominant.depth > shortcut.depth`

   Output columns:
     - All dominant path columns (aliased as d.*)
     - `short_id`              := shortcut path_id
     - `shortcut_path_rid`     := shortcut path JSON (rowids)

   This matrix is the candidate set for subset testing.

10) `masked_paths`
    Performs unordered subset testing of shortcut path nodes against dominant path nodes.

    Mechanism (per (dominant, shortcut) pair):
      - Expand shortcut node array:
        j`son_each(dm.shortcut_path_rid) AS sub`
      - LEFT JOIN dominant node array expansion:
        `json_each(dm.path_rid) AS dom`
        on equality of node IDs: `sub.value = dom.value`
      - For each shortcut node:
          `dom.value IS NULL` is true when that node is missing from the dominant path.
      - Aggregate over all shortcut nodes for the pair:
          keep_sub := MAX(dom.value IS NULL)
        Interpretation:
          keep_sub = 0  => all shortcut nodes were found in dominant path (TRUE subset)
          keep_sub = 1  => at least one shortcut node missing (NOT a subset)

    Grouping key:
      `GROUP BY dm.path_id, dm.short_id`
    ensures subset testing is performed per candidate pair.

    Important semantic note:
      This is *unordered* containment:
        nodes(shortcut) ⊆ nodes(dominant)
      Node order is intentionally ignored, and endpoint nodes are included
      (see TODOs regarding discarding endpoints).

11) `filtered_paths`
    Filters the full set of `preflitered_paths`, removing those shortcut paths whose
    node sets are fully contained in some longer path between the same endpoints.

    Current implementation removes paths by JSON equality on `path_rid` (See TODOs below.):

```sql
WHERE NOT pp.path_rid IN (
    SELECT shortcut_path_rid FROM masked_paths WHERE keep_sub = 0
)
```

# TODO / Future improvements

1) Introduce stable path identifiers earlier
   Currently `path_id` is introduced only in `multipaths`, which excludes single-path
   endpoint pairs and forces later pruning to use JSON equality (in `filtered_paths`).

   Improvement:
     - Assign a `path_id` immediately after `preflitered_paths` (i.e., once complete
       root->leaf paths are known), and carry it through all downstream CTEs.
     - Then prune shortcuts by `short_id` rather than by `shortcut_path_rid`.

   Benefits:
     - Avoid JSON equality comparisons in the final filter.
     - Simplify `filtered_paths` to an anti-join on IDs.

2) Fast-path pruning for length-2 "direct" paths
   Commented in the query:
     - If there exists any longer path between the same (root, leaf), then a direct
       length-2 path (root->leaf) is always a shortcut.
   Proposed approach:
     - Remove depth=2 paths up front for any endpoint pair that has depth>2, then
       recompute `multipath_index`.

3) Discard endpoints during subset testing
   The current subset test includes root and leaf nodes in containment checks.
   Depending on your intended semantics, you may want to:
     - remove the first and last node from both arrays before testing containment
       (i.e., compare only interior nodes),
     - or keep endpoints but treat them as always-matching constraints.

   This end points match already, so no need to include them in subset testing (only test inner nodes).

4) Replace JSON-based final pruning with ID-based pruning
   Best practice is to avoid JSON equality in hot paths.

5) Performance optimizations and materialization strategy
   For large graphs or high path counts:
     - Consider materializing `preflitered_paths` or `multipaths` into TEMP tables
       and indexing (root_rid, leaf_rid, depth), and possibly an extracted
       (root_rid, leaf_rid) endpoint index.
     - Consider splitting `path_rid` into (root_rid, leaf_rid, depth, path_rid) and
       storing endpoints as plain INTEGER columns to reduce JSON operations.
     - If acceptable, enforce additional graph constraints in `temp.edges` (e.g.,
       uniqueness, absence of self-loops) to reduce recursion branching.

6) Correctness safeguards
   - Keep the cycle check and depth cap; they prevent pathological recursion.
   - Optionally detect and report presence of cycles by tracking when the depth cap is reached or when recursion attempts are blocked frequently.

# Notes / Caveats

- The notion of "root" and "leaf" is defined purely with respect to the directed
  edge set present in `temp.edges`. If the edge set is incomplete or filtered
  (e.g., nouns-only), roots/leaves are relative to that induced subgraph.
- This module intentionally treats containment as unordered. If you later decide
  that order matters (true subsequence containment), the `masked_paths` join must
  be replaced with an order-aware constraint over JSON indices.

