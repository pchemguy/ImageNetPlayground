SELECT rowid, sid, metadata ->> '$.imagenet' AS ilsvrc_class_id
FROM synsets
WHERE imagenet_class_id <= 1000
ORDER BY imagenet_class_id;
