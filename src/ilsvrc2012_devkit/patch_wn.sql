-- Open meta.db with ImageNet-1K metadata as main and wn WordNet database wn.db as wn.

UPDATE wn.synsets
SET metadata =  replace(replace(json_set(metadata, '$.imagenet', true), ':', ': '), '","', '", "')
WHERE wn.synsets.id IN (SELECT omwid FROM main.synsets);
