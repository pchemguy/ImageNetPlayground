WITH
    ilsvrc AS (
        SELECT rowid, sid, metadata ->> '$.imagenet' AS ilsvrc_class_id
        FROM synsets
        WHERE ilsvrc_class_id <= 1000
    ),
    imagenet AS (
        SELECT mps.*, ilsvrc.ilsvrc_class_id
        FROM "temp"."mpaths" AS mps
        LEFT JOIN ilsvrc
        ON mps.rid = ilsvrc.rowid
        ORDER BY ilsvrc_class_id ASC NULLS LAST
    ),
    filtered AS (
        SELECT * FROM imagenet WHERE NOT ilsvrc_class_id IS NULL
    ),
    in_hierarchy AS (
        SELECT DISTINCT nodes.value AS rid
        FROM filtered, json_each(filtered.path_rid) AS nodes
        ORDER BY rid
    )
SELECT * FROM in_hierarchy;
