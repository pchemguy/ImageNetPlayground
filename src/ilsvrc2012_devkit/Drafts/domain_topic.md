https://chatgpt.com/c/693e9e4f-832c-8326-9230-1eda8382f264

This SQLite SQL draft traces [subject domain](../WORDNET_RELATIONS.md) multiparent hierarchy. The code also attempts to discard `shortcut` paths, that is paths formed from "full" (`dominant`) paths by dropping some of the inner nodes. This code actually does not check inner node order in favor of a simpler code.

> [!NOTE]
> 
> The original `wn.synsets` table has been enriched:  
>     Attribute `imagenet` has been added to the `metadata` JSON field, indicating synset index in the `ILSVRC2012_devkit_t12.tar.gz/data/meta.mat` metadata.

Present implementation starts with `leaf` nodes and walks the hierarchy up towards roots. This approach is somewhat simpler mentally when considering single parent hierarchies, but functionally it does not matter at all, which sides are considered as beginning/end, and I should probably switch to conventional design with paths starting with root nodes (leftmost nodes in JSON array) and walking towards leaf nodes at the other end.

| CTE             | Explanation                                                                              |
| --------------- | ---------------------------------------------------------------------------------------- |
| `domain_edges`  | Collects hierarchy edges.                                                                |
| `paths_LOOP`    | Walks hierarchy (works for both single- and multiparent hierarchies) via recursive CTEs. |
| `maximal_paths` | Performs recursion postprocessing, discarding intermediate results.                      |
|                 |                                                                                          |

