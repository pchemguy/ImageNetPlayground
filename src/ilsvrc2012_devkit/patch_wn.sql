-- Open meta.db with ImageNet-1K metadata as main and wn WordNet database wn.db as wn.

UPDATE wn.synsets
SET metadata =  replace(replace(
                    json_set(metadata, '$.imagenet', ms.synset_id), ':', ': '), '","', '", "')
FROM main.synsets AS ms
WHERE wn.synsets.id = ms.omwid;
