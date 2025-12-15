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

Note, that for each relation type, WordNet actually defines two terms, describing the same relation from the parent and child side (and including corresponding records into associated M2M tables, particularly, `synset_relations` and `sense_relations`).

