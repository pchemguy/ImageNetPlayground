https://chatgpt.com/c/693e9e4f-832c-8326-9230-1eda8382f264

# Multiparent Hierarchy Walking in SQLite SQL

This SQLite SQL draft traces [subject domain](../WORDNET_RELATIONS.md) multiparent hierarchy. The code also attempts to discard `shortcut` paths, that is paths formed from "full" (`dominant`) paths by dropping some of the inner nodes. This code actually does not check inner node order in favor of a simpler code.

> [!NOTE]
> 
> The original `wn.synsets` table has been enriched:  
>     Attribute `imagenet` has been added to the `metadata` JSON field, indicating synset index in the `ILSVRC2012_devkit_t12.tar.gz/data/meta.mat` metadata.

Present implementation starts with `leaf` nodes and walks the hierarchy up towards roots. This approach is somewhat simpler mentally when considering single parent hierarchies, but functionally it does not matter at all, which sides are considered as beginning/end, and I should probably switch to conventional design with paths starting with root nodes (leftmost nodes in JSON array) and walking towards leaf nodes at the other end.

## CTE Notes

### `domain_edges`

Collects hierarchy edges.

### `paths_LOOP`

The main rCTE implementing hierarchy walking. Walks hierarchy in the leaf-to-root direction (works for both single- and multiparent hierarchies). 

> [!ERROR]
> 
> **Flawed** logic in the seed subquery: instead of selecting leaf nodes only, it seeds the rCTE with every node from the hierarchy, except for the root nodes, that is including all inner nodes! **THIS MUST BE FIXED!** In fact, should probably go straight to reversing direction instead.

### `maximal_paths`

Performs recursion postprocessing, discarding intermediate results.

### `multi_path_mask`

Labels subset of paths involving multipaths. 

> [!ERROR]
> 
> **Flawed** concept. The idea was to extract all paths involving multiparent nodes. The idea is that multiple paths terminating at the same leaf nodes are only possible if the leaf has multiple parents. However, a path may contain inner multiparent nodes and still be the only path yielding to a particular leaf.

 What I am really interested in is selecting a path set that includes all paths subsets with identical `root/leaf` nodes (involving shortcut candidates, which should be checked and potentially discarded).

> [!NOTE]
> 
> If two distinct paths have the same ends **AND LENGTH**, such paths are "strictly" distinct in a sense that both paths must include nodes not present in the other one. In any `dominant/shortcut` candidate pair both paths must have
> - identical ends AND
> - different length
>
> The longer path is a dominant candidate, the shorter path is shortcut candidate.

Strictly speaking, within a set of multiple paths having the same ends, any path of length 2 can be immediately labeled as a shortcut (no further checks are necessary) and any path of length of at least 3 needs to be checked against every paths of at least one node longer as a potential shortcut.

### `shortcut_mask`

A set of CTEs  leading to `shortcut_mask`attempt to identify shortcut paths that can be discarded, but the logic is generally deficient, though it may produce correct results in fairly simple cases.

==The ultimate idea is that if nodes of both paths are exploded as rows, and the table containing the shortcut candidate is left joined against the table containing dominant candidate nodes on node id's, then the shortcut check passes if every shortcut node has a non-null join result. Then test for non-null field value from the right-hand side table:==

```sql
SELECT sn.rowid, max(dn.rowid IS NULL) AS mask
FROM shortcut_nodes AS sn
LEFT JOIN dominant_nodes AS dn
ON  sn.ends = dn.ends
AND sn.node = dn.node
GROUP BY sn.rowid
```

> [!ERROR]
>  
>  While generally sound, the present implementation attempts to construct two tables, one containing dominant candidates and one shortcut candidates, following by full explosion of all paths. One immediate issue is that, when there are more than 2 paths within a subset (identified via `sn.ends = dn.ends`), the test `sn.node = dn.node` matches all nodes against all nodes, mixing path nodes.

### `root_items`

Adds missing `root` nodes by enumerating constructed paths and taking terminal nodes.

## Alternative Approach

> [!NOTE]
> 
> See ../hierarchy.sql
> 
> Consider creating `edges` CTE first with source/target rid/sid first OR actually creating a TEMP table with proper indexes OR a view (must use parent indexes).

1. Select the set of multipath candidates, labeling each row with (required criteria: for each `ends` value at least two rows must exist having different `path_length`)

```sql
    ...
    json_array(path_rid ->> 0, path_rid ->> -1) AS ends,
    json_array_length(path_rid) AS path_length,
    ...
```

2. In principle, any path of length 2 can be immediately labeled as `shortcut`, all such paths can be removed from the table along with any `ends` sets that would fail to meet required criteria above.
3. Transform the remaining paths by removing first/last nodes - we only need to test the inner nodes further.
4. Instead of exploding all paths into one joint table, it should be possible to perform pairwise join test as in `shortcut_mask` by immediate joining of `json_each` `tables` constructed in-situ from the two corresponding JSON array fields.
