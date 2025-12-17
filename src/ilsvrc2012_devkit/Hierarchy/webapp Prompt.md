Create a single page web app to visualize and explorer the hierarchy of ImageNet-1K classes. The  source data is a JSON object

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
        "description": "Synset rowid from OMW WordNet database (integer).",
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
        "description": "An array of rowid's/rid's representing materialized path of synset corresponding to the 'rid' hierarchy.",
        "type": "array",
        "items": {
          "type": "integer"
        }
      }
    },
    "ilsvrc_class_id": {
      "type": "array",
      "description": "List of ILSVRC class IDs corresponding to the entries. Contains integers and -1 for unmapped items.",
      "items": {
        "type": "integer"
      }
    }
  },
  "required": [
    "rid",
    "sid",
    "path_rid",
    "ilsvrc_class_id"
  ]
}
```



```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ImageNet Hierarchy Data",
  "type": "object",
  "properties": {
    "rid": {
      "type": "array",
      "description": "Array of unique record identifiers (integers, synset rowids from OMW WordNet database).",
      "items": {
        "type": "integer"
      }
    },
    "sid": {
      "type": "array",
      "description": "Array of semantic identifiers (synsets), formatted as 'word.pos.number'.",
      "items": {
        "type": "string",
        "pattern": "^[a-z0-9_'-]+\\.[a-z]+\\.[0-9]+$"
      }
    },
    "path_rid": {
      "type": "array",
      "description": "Array of strings, where each string represents a stringified list of integer IDs representing a materialized hierarchy path.",
      "items": {
        "type": "string",
        "pattern": "^\\[[0-9,]+\\]$"
      }
    },
    "ilsvrc_class_id": {
      "type": "array",
      "description": "Array of ILSVRC class IDs. Includes integers (1-1000) and -1 for non-ILSVRC nodes.",
      "items": {
        "type": "integer",
        "minimum": -1,
        "maximum": 1000
      }
    }
  },
  "required": [
    "rid",
    "sid",
    "path_rid",
    "ilsvrc_class_id"
  ],
  "additionalProperties": false
}
```
