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


| CTE               | Explanation                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `domain_edges`    | Collects hierarchy edges.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `paths_LOOP`      | Walks hierarchy (works for both single- and multiparent hierarchies) via recursive CTEs. ==**IMPORTANT**: **flawed** logic in the seed subquery: instead of selecting leaf nodes only, it seeds the rCTE with every node from the hierarchy, except for the root nodes, that is including all inner nodes! **THIS MUST BE FIXED!** In fact, should probably go straight to reversing direction instead.==                                                                                                                                                                                 |
| `maximal_paths`   | Performs recursion postprocessing, discarding intermediate results.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `multi_path_mask` | Labels subset of paths involving multipaths. ==**IMPORTANT**: **flawed** concept. The idea was to extract all paths involving multiparent nodes. The idea is that multiple paths terminating at the same leaf nodes are only possible if the leaf has multiple parents. However, a path may contain inner multiparent nodes and still be the only path yielding to a particular leaf.== What I am really interested in selecting paths, including all distinct paths with identical `root/leaf` nodes (involving shortcut candidates, which should be checked and potentially discarded). |
| `shortcut_mask`   | Attempts to identify shortcut paths. ==**IMPORTANT**: **flawed** logic. The present implementation does not correctly restrains the JOIN to ensure ==                                                                                                                                                                                                                                                                                                                                                                                                                                     |

