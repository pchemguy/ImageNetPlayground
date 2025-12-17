DELETE FROM "temp"."mpaths";

WITH RECURSIVE
    relation_sources AS (
        SELECT DISTINCT e.source_rowid AS rid, e.source_synid AS sid
        FROM temp.edges AS e
        ORDER BY e.source_synid
    ),
    relation_targets AS (
        SELECT DISTINCT e.target_rowid AS rid, e.target_synid AS sid
        FROM temp.edges AS e
        ORDER BY e.target_synid
    ),
    root_nodes AS (
        SELECT rt.*
        FROM relation_targets AS rt
        LEFT JOIN relation_sources AS rs
        ON rt.rid = rs.rid
        WHERE rs.rid IS NULL
          AND rt.sid like 'entity%'
        ORDER BY rt.sid
    ),
    leaf_nodes AS (
        SELECT rs.*
        FROM relation_sources AS rs
        LEFT JOIN relation_targets AS rt
        ON rt.rid = rs.rid
        WHERE rt.rid IS NULL
        ORDER BY rs.sid
    ),

    paths_LOOP AS (
        -- seed: every synset that participates in the hierarchy defined by edges.
        SELECT DISTINCT
            rn.rid AS root_rid,
            rn.sid AS root_sid,
            rn.rid AS curr_rid,

            json_array(rn.sid) AS path_sid,
            json_array(rn.rid) AS path_rid,

            1 AS depth
        FROM root_nodes AS rn

        UNION ALL

        -- recursive step: append child
        SELECT
            p.root_rid,
            p.root_sid,
            e.source_rowid AS curr_rid,

            json_insert(p.path_sid, '$[#]', e.source_synid) AS path_sid,
            json_insert(p.path_rid, '$[#]', e.source_rowid) AS path_rid,

            p.depth + 1
        FROM paths_LOOP AS p
        JOIN temp.edges AS e
          ON e.target_rowid = p.curr_rid

        -- cycle safety
        WHERE NOT EXISTS (
            SELECT 1 FROM json_each(p.path_rid) WHERE value = e.source_rowid
        )

        -- optional hard stop (safety valve)
        AND p.depth < 64
    ),
    paths AS (
        SELECT
            curr_rid AS rid,
            path_sid ->> -1 AS sid,
            path_rid,
            path_sid,
            depth
        FROM paths_LOOP
    )
INSERT INTO "temp"."mpaths"
SELECT *
FROM paths
ORDER BY substr(substr(path_sid, 1, length(path_sid)-1), 2);
