# WordNet Relations

WordNet defines a number of synsets/senses relations, as can be observed by inspection of the wn-created SQLite3 database `wn.db` (`relation_types` table):

| rowid | type              |
| ----- | ----------------- |
| 1     | also              |
| 2     | antonym           |
| 3     | attribute         |
| 4     | causes            |
| 5     | derivation        |
| 6     | domain_region     |
| 7     | domain_topic      |
| 8     | entails           |
| 9     | exemplifies       |
| 10    | has_domain_region |
| 11    | has_domain_topic  |
| 12    | holo_member       |
| 13    | holo_part         |
| 14    | holo_substance    |
| 15    | hypernym          |
| 16    | hyponym           |
| 17    | instance_hypernym |
| 18    | instance_hyponym  |
| 19    | is_exemplified_by |
| 20    | mero_member       |
| 21    | mero_part         |
| 22    | mero_substance    |
| 23    | participle        |
| 24    | pertainym         |
| 25    | similar           |
Of particular interest are hierarchical relations:

| rowid | type              |
| ----- | ----------------- |
| 6     | domain_region     |
| 7     | domain_topic      |
| 10    | has_domain_region |
| 11    | has_domain_topic  |
| 12    | holo_member       |
| 13    | holo_part         |
| 14    | holo_substance    |
| 15    | hypernym          |
| 16    | hyponym           |
| 20    | mero_member       |
| 21    | mero_part         |
| 22    | mero_substance    |

Note, that for each relation type, WordNet actually defines two complementary terms, describing the same relation from the parent and child perspectives (and including corresponding essentially duplicated records in associated M2M tables, particularly, `synset_relations` and `sense_relations`, need to verify which one is which parent/child):

| Kind                   | rowid | side1          | rowid | side2             | Single-Parent Design |
| ---------------------- | ----- | -------------- | ----- | ----------------- | -------------------- |
| **Geographical**       | 6     | domain_region  | 10    | has_domain_region | ?                    |
| **Subject Domain**     | 7     | domain_topic   | 11    | has_domain_topic  | NO                   |
| **Collection/Member**  | 12    | holo_member    | 20    | mero_member       | NO                   |
| **Component/Assembly** | 13    | holo_part      | 21    | mero_part         | NO                   |
| **Material/Assembly**  | 14    | holo_substance | 22    | mero_substance    | NO                   |
| **General/Specific**   | 15    | hypernym       | 16    | hyponym           | YES                  |

[According to ChatGPT](https://chatgpt.com/c/693e9e4f-832c-8326-9230-1eda8382f264) (not yet verified)
- `General/Specific/Hypernym` is designed to be a single-parent hierarchy (tree/forest, a DAG with single parent per node).
- Other hierarchies should be treated as multiparent graphs.

Note, at least `Subject Domain` include "loops" (multiple paths with the same leaf/root nodes but different inner nodes). "Loops" may potentially involve strictly distinct paths (both containing nodes not present in the other one) and shortcut paths (where the "shorted" path includes edges shorting some of the inner nodes in the full paths). While more complicated constructs are possible in theories, such as both paths containing edges shorting some of the inner nodes of the other paths, it is not clear yet whether such cases exist in `WN` hierarchies.

Note, when extracting specific hierarchies from the `xxx_relations` tables. For all inner nodes, these tables should contain at least one record for each of the two types `side1/side2`, and all such nodes can be selected via edges from the `xxx_relations` tables of either complementary relation type. The two sets created via either `side1/side2` **for inner nodes** should be "mirror" images with `source_rowid` and `target_rowid` columns swapped, reflecting the two `parent/child` perspectives.

At the same time, `leaf/root` nodes only participate in one of the two complementary relations, either labeled as `side1` or `side2`. In practice, the two resulting edge subsets selected via `side1/side2` will include either `leaf` or `root` edges (one will include one, the other - other). So, between the `source_rowid` and `target_rowid` fields in the two selected subsets, one will reference (in addition two inner nodes) either `leaf` or `root` nodes. There are multiple ways to extract all nodes participating in the full hierarchy. For example,  select edges using one of the two complementary relations, then select appropriate terminal edges (`leaf` or `root` type depending on the primary relation used). Alternatively, because path enumeration loop begins with either `leaf` or `root` nodes and walks the hierarchy terminating in the counterpart, the missing nodes may be selected by taking the terminal nodes from the enumerated paths set.

