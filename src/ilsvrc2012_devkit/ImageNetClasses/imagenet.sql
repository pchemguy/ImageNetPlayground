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
    in_nodes AS (
        SELECT DISTINCT nodes.value AS wnrid
        FROM filtered, json_each(filtered.path_rid) AS nodes
        ORDER BY wnrid
    ),
    ilsvrc_full AS (
        SELECT
            rid,
            sid,
            path_rid,
            path_sid,
            depth,
            coalesce(ilsvrc_class_id, -1) AS ilsvrc_class_id
        FROM imagenet, in_nodes
        WHERE imagenet.rid = wnrid
        ORDER BY iif(ilsvrc_class_id > 0, ilsvrc_class_id, 1001), substr(path_sid, 1, length(path_sid) - 1)
    ),
    json_data AS (
        SELECT
            json_object(
                'rid', json_group_array(rid),
                'sid', json_group_array(sid),
                'path_rid', json_group_array(path_rid),
                'ilsvrc_class_id', json_group_array(ilsvrc_class_id)
            ) AS data
        FROM ilsvrc_full
    )
SELECT * FROM json_data;
