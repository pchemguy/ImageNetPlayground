Create a single page web app to visualize and explorer the hierarchy of ImageNet-1K classes. The  source data is a JSON object following the schema:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ImageNet Synset Mapping Data",
  "description": "Schema for validating the structure of WordNet/ImageNet ID mappings and paths.",
  "type": "object",
  "properties": {
    "rid": {
      "type": "array",
      "items": {
        "description": "Synset rowid from OMW WordNet database (integer). This field is generally not unique due to DAG nature of WordNet relations.",
        "type": "integer"
      }
    },
    "sid": {
      "type": "array",
      "items": {
        "description": "Synset ID, formatted as 'word.pos.number' (strings).",
        "type": "string",
        "pattern": "^[a-z0-9_'-]+\\.[a-z]+\\.[0-9]+$"
      }
    },    
    },
    "path_rid": {
      "type": "array",
      "items": {
        "description": "An array of rowid's/rid's representing materialized path of synset corresponding to the 'rid' hierarchy, including current rid as the last array member.",
        "uniqueItems": true,
        "type": "array",
        "items": {
          "type": "integer"
        }
      }
    },
    "ilsvrc_class_id": {
      "type": "array",
      "items": {
        "description": "ILSVRC class ID corresponding to the entries. Contains integers and -1 for unmapped items that are present in paths of mapped items.",
        "type": "integer"
      }
    }
  },
  "required": [
    "rid",
    "sid",
    "path_rid",
    "ilsvrc_class_id"
  ],
  "examples": [
    {
      "rid": [11040, 10920, 10920, 10980, 10980, 1, 3, 2],
      "sid": [
        "kit_fox.n.01",
        "english_setter.n.01",
        "english_setter.n.01",
        "siberian_husky.n.01",
        "siberian_husky.n.01",
        "entity.n.01",
        "abstraction.n.06",
        "physical_entity.n.01"
      ],
      "path_rid": [
        [1, 2, 5, 6, 8, 9, 19, 7467, 7496, 9595, 9686, 10766, 10812, 11031, 11040],
        [1, 2, 5, 6, 8, 9, 19, 7467, 7496, 9595, 9686, 10766, 10812, 10816, 10834, 10907, 10918, 10920],
        [1, 2, 5, 6, 8, 9, 19, 6725, 10816, 10834, 10907, 10918, 10920],
        [1, 2, 5, 6, 8, 9, 19, 7467, 7496, 9595, 9686, 10766, 10812, 10816, 10936, 10977, 10980],
        [1, 2, 5, 6, 8, 9, 19, 6725, 10816, 10936, 10977, 10980],
        [1],
        [1, 3],
        [1, 2]
      ],
      "ilsvrc_class_id": [1, 2, 2, 3, 3, -1, -1, -1]
    }
  ]
}
```

